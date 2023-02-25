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
  sed -i -- "s/^\$accent_bg_color:.*/\$accent_bg_color: ${accent_color};/" \
    "${local_dir}/cinnamon-shell/src/default/_palette.scss" \
    "${local_dir}/cinnamon-shell/src/dark/_palette.scss"

  # - gtk
  cp -- "${src_dir}/accent-colors.scss.in" "${local_dir}/common/accent-colors.scss.in"
  sed -i -- "s/^    \$color:.*/    \$color: ${accent_color};/" "${local_dir}/common/accent-colors.scss.in"
  sed -i -- 's/^  is_accent = .*/  is_accent = true/' "${local_dir}/gtk/src/meson.build"

  # Patch
  # - icons
  cp -Ta -- "${local_dir}/icons/Yaru-blue" "${local_dir}/icons/Yaru"
  cp -Ta -- "${local_dir}/icons/Yaru-blue" "${local_dir}/icons/Yaru-dark"
  sed -i -- "s/args.theme_name,/args.theme_name.replace('Yaru', 'Yaru818'),/" "${local_dir}/icons/src/generate-index-theme.py"

  # - cinnamon-shell
  inject_scss_patch "${src_dir}/cinnamon-patch.scss" "${local_dir}/cinnamon-shell/src/"*"/cinnamon.scss"

  # - gtk
  inject_scss_patch "${src_dir}/gtk3-patch.scss" "${local_dir}/gtk/src/default/gtk-3.0/gtk"*".scss"
  inject_scss_patch "${src_dir}/gtk4-patch.scss" "${local_dir}/gtk/src/default/gtk-4.0/gtk"*".scss"

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
