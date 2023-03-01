#!/bin/sh

set -x
flatpak override --user \
  --filesystem=xdg-config/gtk-2.0:ro \
  --filesystem=xdg-config/gtk-3.0:ro \
  --filesystem=xdg-config/gtk-4.0:ro \
  --filesystem=xdg-data/icons:ro \
  --filesystem=xdg-data/themes:ro \
  --filesystem=/opt/yaru818-theme:ro
{ set +x; } 2>/dev/null

for file in themes/Yaru818 themes/Yaru818-dark icons/Yaru818 icons/Yaru818-dark; do
  dir="$(dirname "${HOME}/.local/share/${file}")"
  set -x
  mkdir -p -- "$dir"
  ln -sfT -- "/opt/yaru818-theme/${file}/" "${HOME}/.local/share/${file}"
  { set +x; } 2>/dev/null
done

echo 'Done!'
exit 0
