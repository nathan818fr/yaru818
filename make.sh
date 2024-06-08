#!/usr/bin/env bash
set -Eeuo pipefail
shopt -s inherit_errexit

function main() {
  _init_vars

  if [[ $# -eq 0 ]]; then
    _print_usage
    return 0
  fi

  local cmd=$1
  shift
  case $cmd in
  all) cmd_all "$@" ;;
  init) cmd_init "$@" ;;
  patch) cmd_patch "$@" ;;
  build) cmd_build "$@" ;;
  package-deb) cmd_package_deb "$@" ;;
  install) cmd_install "$@" ;;
  *)
    _print_usage >&2
    return 1
    ;;
  esac
}

function _init_vars() {
  REPO_DIR=$(dirname -- "$(realpath -m -- "$0")")
  UPSTREAM_DIR="${REPO_DIR}/upstream"
  LOCAL_DIR="${REPO_DIR}/local"
  SRC_DIR="${REPO_DIR}/src"
  BUILD_DIR="${REPO_DIR}/build"
  PACKAGES_DIR="${REPO_DIR}/packages"
  XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
  declare -g -r REPO_DIR UPSTREAM_DIR LOCAL_DIR SRC_DIR BUILD_DIR PACKAGES_DIR XDG_DATA_HOME
}

function _print_usage() {
  cat <<EOF
Usage: $(basename -- "$0") <command>

Commands:
  all           Run init, patch, build, package-deb
  init          Initialize a clean local directory (from upstream)
  patch         Apply patches to the local directory
  build         Build the theme from the local directory
  package-deb   Package the built theme into a .deb file
  install       Install the built theme locally
EOF
}

function cmd_all() {
  cmd_init
  cmd_patch
  cmd_build
  cmd_package_deb
}

function cmd_init() {
  local relevant_files=(
    '.gitignore'

    # cinnamon-shell
    'cinnamon-shell/*'
    'cinnamon-shell/src/**'

    # common
    'common/**'

    # gnome-shell
    'gnome-shell/*'
    'gnome-shell/src/**'

    # gtk
    'gtk/*'
    'gtk/src/*'
    'gtk/src/data/**'
    'gtk/src/default/**'
    'gtk/src/dark/**'
    'gtksourceview/**'

    # icons
    'icons/*'
    'icons/meson/**'
    'icons/src/**'
    'icons/Yaru/**'
    'icons/Yaru-dark/**'
    'icons/Yaru-blue/**'

    # metacity
    'metacity/*'
    'metacity/src/*'
    'metacity/src/default/**'
    'metacity/src/dark/**'

    # sessions
    'sessions/**'

    # sounds
    'sounds/**'

    # ubuntu-unity
    'ubuntu-unity/*'
    'ubuntu-unity/src/*'
    'ubuntu-unity/src/default/**'
    'ubuntu-unity/src/dark/**'

    # xfwm4
    'xfwm4/*'
    'xfwm4/src/*'
    'xfwm4/src/default/**'
    'xfwm4/src/dark/**'
  )

  # Create a clean local directory
  rm -rf -- "$LOCAL_DIR"
  mkdir -p -- "$LOCAL_DIR"

  # Copy relevant files from upstream to local
  local relevant_file path src dst
  for relevant_file in "${relevant_files[@]}"; do
    while IFS= read -r -d $'\n' path; do
      src="${UPSTREAM_DIR}/${path}"
      dst="${LOCAL_DIR}/${path}"
      if [[ -d "$src" ]]; then
        mkdir -p -- "$dst"
      else
        cp -T --preserve=all -- "$src" "$dst"
      fi
    done < <(_match_files "$UPSTREAM_DIR" "$relevant_file")
  done

  #
  printf '[+] init: Done\n'
}

function cmd_patch() {
  # Base
  cp -t "$LOCAL_DIR" -- "${SRC_DIR}/meson.build" "${SRC_DIR}/meson_options.txt"
  local accent_color='#0073E5'

  # Update accent color
  # - cinnamon-shell
  sed -i -- "s/^\$accent_bg_color:.*/\$accent_bg_color: ${accent_color};/" "${LOCAL_DIR}/cinnamon-shell/src/sass/_palette.scss"
  find -- "${LOCAL_DIR}/cinnamon-shell/src" -name '*.svg' -exec sed -i '
    s/#eb6637/#0069D1/g;
    s/#e95420/#0069D1/g;
    s/#f3aa90/#6EB2F7/g;
    s/#d14515/#0057AD/g;
    s/#e84d17/#0061C2/g;
    ' {} \;

  # - gtk
  sed -i -- "s/^    \$color:.*/    \$color: ${accent_color};@return \$color;/" "${LOCAL_DIR}/common/accent-colors.scss.in"
  sed -i -- 's/^  is_accent = .*/  is_accent = true/' "${LOCAL_DIR}/gtk/src/meson.build"

  # Patch
  # - icons
  cp -Ta -- "${LOCAL_DIR}/icons/Yaru-blue" "${LOCAL_DIR}/icons/Yaru"
  cp -Ta -- "${LOCAL_DIR}/icons/Yaru-blue" "${LOCAL_DIR}/icons/Yaru-dark"
  sed -i -- "s/args.theme_name,/args.theme_name.replace('Yaru', 'Yaru818'),/" "${LOCAL_DIR}/icons/src/generate-index-theme.py"

  # - cinnamon-shell
  _inject_scss_patch "${SRC_DIR}/cinnamon-patch.scss" "${LOCAL_DIR}/cinnamon-shell/src/cinnamon-shell.scss.in"

  # - gtk
  _inject_scss_patch "${SRC_DIR}/gtk3-patch.scss" "${LOCAL_DIR}/gtk/src/default/gtk-3.0/gtk"*".scss"
  _inject_scss_patch "${SRC_DIR}/gtk4-patch.scss" "${LOCAL_DIR}/gtk/src/default/gtk-4.0/gtk"*".scss"

  # - gtksourceview
  cp -Ta -- "${SRC_DIR}/gtksourceview/dark.xml.in" "${LOCAL_DIR}/gtksourceview/gtksourceview/dark.xml.in"
  cp -Ta -- "${SRC_DIR}/gtksourceview/dark-5.xml.in" "${LOCAL_DIR}/gtksourceview/gtksourceview-5/dark.xml.in"

  #
  printf '[+] patch: Done\n'
}

function cmd_build() {
  # Run meson (setup)
  pushd "$LOCAL_DIR" >/dev/null
  rm -rf -- "$BUILD_DIR"
  meson setup -Dprefix="${BUILD_DIR}/_out" -- "$BUILD_DIR"
  popd >/dev/null

  # Run ninja (install)
  ninja -C "$BUILD_DIR" install

  #
  printf '[+] build: Done (see %s)\n' "${BUILD_DIR}/_out"
}

function cmd_package_deb() {
  # Create a temporary directory to prepare packages
  _init_tmp_dir

  # Retrieve the project version
  local project_version
  project_version="$(grep 'version: ' <"${SRC_DIR}/meson.build" | head -n1 | cut -d"'" -f2)"

  # Create .deb structure
  local deb_dir="${TMP_DIR}/deb"
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
  cp -Ta -- "${BUILD_DIR}/_out/share" "${deb_dir}/usr/share"

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
  find "$deb_dir" -type d -exec chmod 0755 {} \;
  find "$deb_dir" -type f -exec chmod 0644 {} \;
  chmod 755 "${deb_dir}/DEBIAN/postinst"

  # - Copy scripts
  cp -- "${SRC_DIR}/configure-flatpak.sh" "${deb_dir}/opt/yaru818-theme/configure-flatpak"

  # Create package
  mkdir -p -- "$PACKAGES_DIR"
  dpkg-deb --build --root-owner-group -- "$deb_dir" "${PACKAGES_DIR}/yaru818-theme_${project_version}_all.deb"

  #
  printf '[+] package-deb: Done\n'
}

function cmd_install() {
  # Install themes locally
  _install_theme "${BUILD_DIR}/_out/share" 'themes/Yaru818'
  _install_theme "${BUILD_DIR}/_out/share" 'themes/Yaru818-dark'
  _install_theme "${BUILD_DIR}/_out/share" 'icons/Yaru818'
  _install_theme "${BUILD_DIR}/_out/share" 'icons/Yaru818-dark'

  #
  printf '[+] install: Done\n'
}

function _match_files() {
  local basedir name
  basedir=$1
  name=$2

  pushd "$basedir" >/dev/null
  case "$name" in
  */\*)
    printf '%s\n' "${name:0:-2}"
    find -- "${name:0:-2}" -mindepth 1 -maxdepth 1 ! -type d
    ;;
  */\*\*) find -- "${name:0:-3}" ;;
  *) printf '%s\n' "$name" ;;
  esac
  popd >/dev/null
}

function _inject_scss_patch() {
  local patch_file orig_files
  patch_file=$1
  orig_files=("${@:2}")

  local orig_file
  for orig_file in "${orig_files[@]}"; do
    sed -i -- '/\/\/[ ]*SCSS_PATCH[ ]*$/d' "$orig_file"
    printf "@import '%s'; // SCSS_PATCH\n" "$patch_file" >>"$orig_file"
  done
}

function _install_theme() {
  local basedir name
  basedir=$1
  name=$2

  printf 'Install "%s" ...\n' "$name"
  local src dst
  src="${basedir}/${name}"
  dst="${XDG_DATA_HOME}/${name}"
  mkdir -p -- "$(dirname "$dst")"
  rm -rf -- "$dst"
  cp -Ta -- "$src" "$dst"
}

function _init_tmp_dir() {
  TMP_DIR="$(umask 077 >/dev/null && mktemp -d)"
  declare -g -r TMP_DIR
  function __cleanup_TMP_DIR() { rm -rf -- "$TMP_DIR"; }
  trap __cleanup_TMP_DIR INT TERM EXIT
}

eval 'main "$@";exit "$?"'
