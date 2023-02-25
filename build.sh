#!/usr/bin/env bash
set -Eeuo pipefail
shopt -s inherit_errexit

function main() {
  # shellcheck source=./.env.sh
  . "$(dirname "$(realpath -m "$0")")/.env.sh"

  # Run meson (setup)
  pushd "$local_dir" >/dev/null
  rm -rf -- "$build_dir"
  meson setup -Dprefix="${build_dir}/_out" -- "${build_dir}"
  popd >/dev/null

  # Run ninja (install)
  ninja -C "$build_dir" install

  #
  echo "Done! See: ${build_dir}/_out"
}

main "$@"
exit 0
