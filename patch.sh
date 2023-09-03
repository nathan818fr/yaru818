#!/usr/bin/env bash
set -Eeuo pipefail
shopt -s inherit_errexit

function main() {
  # shellcheck source=./.env.sh
  . "$(dirname "$(realpath -m "$0")")/.env.sh"

  # Base
  cp -- "${src_dir}/meson.build" "${src_dir}/meson_options.txt" "${local_dir}"
  local accent_color='#0073E5'

  # Update accent color
  # - cinnamon-shell
  sed -i -- "s/^\$accent_bg_color:.*/\$accent_bg_color: ${accent_color};/" "${local_dir}/cinnamon-shell/src/sass/_palette.scss"
  find "${local_dir}/cinnamon-shell/src" -name '*.svg' -exec sed -i '
    s/#eb6637/#0069D1/g;
    s/#e95420/#0069D1/g;
    s/#f3aa90/#6EB2F7/g;
    s/#d14515/#0057AD/g;
    s/#e84d17/#0061C2/g;
    ' {} \;

  # - gtk
  sed -i -- "s/^    \$color:.*/    \$color: ${accent_color};@return \$color;/" "${local_dir}/common/accent-colors.scss.in"
  sed -i -- 's/^  is_accent = .*/  is_accent = true/' "${local_dir}/gtk/src/meson.build"

  # Patch
  # - icons
  cp -Ta -- "${local_dir}/icons/Yaru-blue" "${local_dir}/icons/Yaru"
  cp -Ta -- "${local_dir}/icons/Yaru-blue" "${local_dir}/icons/Yaru-dark"
  sed -i -- "s/args.theme_name,/args.theme_name.replace('Yaru', 'Yaru818'),/" "${local_dir}/icons/src/generate-index-theme.py"

  # - cinnamon-shell
  inject_scss_patch "${src_dir}/cinnamon-patch.scss" "${local_dir}/cinnamon-shell/src/cinnamon-shell.scss.in"

  # - gtk
  inject_scss_patch "${src_dir}/gtk3-patch.scss" "${local_dir}/gtk/src/default/gtk-3.0/gtk"*".scss"
  inject_scss_patch "${src_dir}/gtk4-patch.scss" "${local_dir}/gtk/src/default/gtk-4.0/gtk"*".scss"

  # - gtksourceview
  cp -Ta -- "${src_dir}/gtksourceview/dark.xml.in" "${local_dir}/gtksourceview/gtksourceview/dark.xml.in"
  cp -Ta -- "${src_dir}/gtksourceview/dark-5.xml.in" "${local_dir}/gtksourceview/gtksourceview-5/dark.xml.in"

  #
  echo 'Done!'
}

function inject_scss_patch() {
  local patch_file orig_file
  patch_file="$1"
  shift

  for orig_file in "$@"; do
    sed -i -- '/\/\/[ ]*SCSS_PATCH[ ]*$/d' "$orig_file"
    printf "@import '%s'; // SCSS_PATCH\n" "$patch_file" >>"$orig_file"
  done
}

main "$@"
exit 0
