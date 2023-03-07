#!/usr/bin/env bash
set -Eeuo pipefail
shopt -s inherit_errexit

function main() {
  # shellcheck source=./.env.sh
  . "$(dirname "$(realpath -m "$0")")/.env.sh"

  # Create a temporary directory to prepare packages
  tmp_dir="$(umask 077 >/dev/null && mktemp -d)"
  function tmp_dir_cleanup() { rm -rf -- "$tmp_dir"; }
  trap tmp_dir_cleanup INT TERM EXIT

  # Retrieve the project version
  local project_version
  project_version="$(grep 'version: ' <"${src_dir}/meson.build" | head -n1 | cut -d"'" -f2)"

  # Create .deb structure
  local deb_dir="${tmp_dir}/deb"
  mkdir -p -- "${deb_dir}/DEBIAN"
  cat <<EOF >"${deb_dir}/DEBIAN/control"
Package: yaru818-theme
Version: ${project_version}
Architecture: all
Maintainer: Nathan Poirier <nathan@poirier.io>
Recommends: humanity-icon-theme
Description: Yaru818 theme
EOF
  cat <<EOF >"${deb_dir}/DEBIAN/conffiles"
/etc/apparmor.d/abstractions/base.d/yaru818-theme
EOF
  cat <<'EOF' >"${deb_dir}/DEBIAN/postinst"
#!/bin/sh
set -e
if [ "$1" = "configure" ]; then
    apparmor_parser -r -T -W /etc/apparmor.d/ || true
fi
EOF

  # - Copy resources
  mkdir -p -- "${deb_dir}/usr/share"
  cp -Ta -- "${build_dir}/_out/share" "${deb_dir}/usr/share"

  # - Move themes and icons to /opt to allow "simple" flatpak compatibility
  local files file src dst
  files=(
    gnome-shell/theme/Yaru818
    gnome-shell/theme/Yaru818-dark
    gtksourceview-2.0/styles/Yaru818-dark.xml
    gtksourceview-2.0/styles/Yaru818.xml
    gtksourceview-3.0/styles/Yaru818-dark.xml
    gtksourceview-3.0/styles/Yaru818.xml
    gtksourceview-4/styles/Yaru818-dark.xml
    gtksourceview-4/styles/Yaru818.xml
    gtksourceview-5/styles/Yaru818-dark.xml
    gtksourceview-5/styles/Yaru818.xml
    icons/Yaru818
    icons/Yaru818-dark
    sounds/Yaru818
    themes/Yaru818
    themes/Yaru818-dark
  )
  mkdir -p -- "${deb_dir}/opt/yaru818-theme"
  for file in "${files[@]}"; do
    src="${deb_dir}/usr/share/${file}"
    dst="${deb_dir}/opt/yaru818-theme/${file}"
    mkdir -p -- "$(dirname "$dst")"
    mv -T -- "$src" "$dst"
    ln -s -- "/opt/yaru818-theme/${file}" "$src"
  done

  # - Add AppArmor profile
  local apparmor_base_dir="${deb_dir}/etc/apparmor.d/abstractions/base.d"
  mkdir -p -- "$apparmor_base_dir"
  cat <<EOF >"${apparmor_base_dir}/yaru818-theme"
#########################################
# Yaru818 theme abstraction
#
# AppArmor profiles often allow access to /usr/share
# But it will fail because we are using symbolic links to /opt/yaru818-theme
#########################################

/opt/yaru818-theme/** r,
EOF

  # - Ensure correct files permissions
  find "${deb_dir}" -type d -exec chmod 0755 {} \;
  find "${deb_dir}" -type f -exec chmod 0644 {} \;
  chmod 755 "${deb_dir}/DEBIAN/postinst"

  # - Copy scripts
  cp -- "${src_dir}/configure-flatpak.sh" "${deb_dir}/opt/yaru818-theme/configure-flatpak"

  # Create package
  mkdir -p -- "$packages_dir"
  dpkg-deb --build --root-owner-group -- "$deb_dir" "${packages_dir}/yaru818-theme_${project_version}_all.deb"

  #
  echo "Done!"
}

main "$@"
exit 0
