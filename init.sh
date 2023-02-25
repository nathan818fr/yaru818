#!/usr/bin/env bash
set -Eeuo pipefail
shopt -s inherit_errexit

function main() {
  # shellcheck source=./.env.sh
  . "$(dirname "$(realpath -m "$0")")/.env.sh"

  # Copy relevant upstream files
  local relevant_files relevant_file path src dst
  relevant_files=(
    '.gitignore'

    # cinnamon-shell
    'cinnamon-shell/*'
    'cinnamon-shell/src/*'
    'cinnamon-shell/src/default/**'
    'cinnamon-shell/src/dark/**'

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

  rm -rf -- "$local_dir"
  mkdir -p "$local_dir"
  for relevant_file in "${relevant_files[@]}"; do
    while IFS= read -r -d $'\n' path; do
      src="${upstream_dir}/${path}"
      dst="${local_dir}/${path}"
      if [[ -d "$src" ]]; then
        mkdir -p -- "$dst"
      else
        cp -T --preserve=all -- "$src" "$dst"
      fi
    done < <(match_files "$upstream_dir" "$relevant_file")
  done

  #
  echo 'Done!'
}

function match_files() {
  local basedir="$1"
  local name="$2"

  pushd "$basedir" >/dev/null
  case "$name" in
  */\*) printf "%s\n" "${name:0:-2}"; find -- "${name:0:-2}" -mindepth 1 -maxdepth 1 ! -type d ;;
  */\*\*) find -- "${name:0:-3}" ;;
  *) printf "%s\n" "$name" ;;
  esac
  popd >/dev/null
}

main "$@"
exit 0
