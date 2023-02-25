local repo_dir upstream_dir local_dir src_dir build_dir
repo_dir="$(dirname "$(realpath -m "$0")")"
upstream_dir="$(realpath -m "${repo_dir}/upstream")"
local_dir="$(realpath -m "${repo_dir}/local")"
src_dir="$(realpath -m "${repo_dir}/src")"
build_dir="$(realpath -m "${repo_dir}/build")"
packages_dir="$(realpath -m "${repo_dir}/packages")"
