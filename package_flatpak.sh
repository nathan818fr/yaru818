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
  local branch='3.22'

  # Create flatpak structure
  cat <<EOF >"${tmp_dir}/org.gtk.Gtk3theme.Yaru818.appdata.xml"
<?xml version="1.0" encoding="UTF-8"?>
<component type="runtime">
  <id>org.gtk.Gtk3theme.Yaru818</id>
  <metadata_license>CC-BY-SA-4.0</metadata_license>
  <name>Yaru818 Theme</name>
  <summary>Yaru818 theme</summary>
  <description>
    <p>Yaru818 theme</p>
  </description>
</component>
EOF

  cat <<EOF >"${tmp_dir}/org.gtk.Gtk3theme.Yaru818.json"
{
  "id": "org.gtk.Gtk3theme.Yaru818",
  "branch": "${branch}",
  "runtime": "org.freedesktop.Platform",
  "runtime-version": "21.08",
  "build-extension": true,
  "sdk": "org.freedesktop.Sdk",
  "appstream-compose": false,
  "separate-locales": false,
  "modules": [
    {
      "name": "Yaru818",
      "buildsystem": "simple",
      "build-commands": [
        "tar -xf Yaru818.tar.gz",
        "install -dm755 /usr/share/runtime/share/themes/Yaru818",
        "cp -Ta ./themes/Yaru818 /usr/share/runtime/share/themes/Yaru818",
        "install -dm755 /usr/share/runtime/share/themes/Yaru818-dark",
        "cp -Ta ./themes/Yaru818-dark /usr/share/runtime/share/themes/Yaru818-dark"
      ],
      "sources": [
        {
          "type": "file",
          "path": "./Yaru818.tar.gz",
          "dest-filename": "Yaru818.tar.gz"
        }
      ]
    },
    {
      "name": "appdata",
      "buildsystem": "simple",
      "build-commands": [
        "install -Dm644 org.gtk.Gtk3theme.Yaru818.appdata.xml -t \${FLATPAK_DEST}/share/appdata",
        "appstream-compose --basename=org.gtk.Gtk3theme.Yaru818 --prefix=\${FLATPAK_DEST} --origin=flatpak org.gtk.Gtk3theme.Yaru818"
      ],
      "sources": [
        {
          "type": "file",
          "path": "org.gtk.Gtk3theme.Yaru818.appdata.xml"
        }
      ]
    }
  ]
}
EOF

  # Archive resources
  tar -czvf "${tmp_dir}/Yaru818.tar.gz" -C "${build_dir}/_out/share" \
    themes/Yaru818/index.theme \
    themes/Yaru818/gtk-3.0 \
    themes/Yaru818-dark/index.theme \
    themes/Yaru818-dark/gtk-3.0

  # Build flatpak and export a single bundle
  local archs=('x86_64')

  mkdir -p -- "$packages_dir"
  pushd "$tmp_dir" >/dev/null
  for arch in "${archs[@]}"; do
    flatpak-builder --arch="$arch" --force-clean -- ./flatpak-build org.gtk.Gtk3theme.Yaru818.json
    flatpak build-export --arch="$arch" -- ./flatpak-export ./flatpak-build "$branch"
    flatpak build-bundle --arch="$arch" --runtime -- ./flatpak-export \
      "${packages_dir}/org.gtk.Gtk3theme.Yaru818_${project_version}_${arch}.flatpak" \
      org.gtk.Gtk3theme.Yaru818 "$branch"
  done
  popd >/dev/null

  #
  echo "Done!"
}

main "$@"
exit 0
