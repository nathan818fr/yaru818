#!/usr/bin/env bash
set -Eeuo pipefail
shopt -s inherit_errexit
set -x

./init.sh
./patch.sh
./build.sh
./package_deb.sh
exit 0
