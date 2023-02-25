#!/usr/bin/env bash
set -Eeuo pipefail
shopt -s inherit_errexit

function main() {
  # shellcheck source=./.env.sh
  . "$(dirname "$(realpath -m "$0")")/.env.sh"

  # Install themes locally
  install_theme "${build_dir}/_out/share" 'themes/Yaru818'
  install_theme "${build_dir}/_out/share" 'themes/Yaru818-dark'
  install_theme "${build_dir}/_out/share" 'icons/Yaru818'
  install_theme "${build_dir}/_out/share" 'icons/Yaru818-dark'

  #
  echo "Done!"
}

function install_theme() {
  local basedir name src dst
  basedir="$1"
  name="$2"

  echo "Install ${name}..."
  src="${basedir}/${name}"
  dst="${HOME}/.local/share/${name}"
  rm -rf -- "$dst"
  mkdir -p -- "$(dirname "$dst")"
  cp -a -- "$src" "$dst"
}

main "$@"
exit 0
