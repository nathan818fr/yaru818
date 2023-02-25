# Yaru818

My personal fork of the yaru theme (for cinnamon and gtk).

## Install

It is recommended to install
the [humanity-icon-theme](http://archive.ubuntu.com/ubuntu/pool/main/h/humanity-icon-theme/humanity-icon-theme_0.6.16_all.deb)
first.

Then download the theme .deb package
from [releases](https://github.com/nathan818fr/yaru818/releases) and install-it.

### Use the theme with flatpak

To be used with flatpak apps, the theme need to be copied to ~/.local/share
(see https://github.com/flatpak/flatpak/issues/4896
and https://github.com/flatpak/flatpak/issues/5040).

```
flatpak override -u --filesystem=xdg-data/themes:ro --filesystem=xdg-data/icons:ro
mkdir -p ~/.local/share/themes
rsync -a --del /usr/share/themes/Yaru818/ ~/.local/share/themes/Yaru818
rsync -a --del /usr/share/themes/Yaru818-dark/ ~/.local/share/themes/Yaru818-dark
mkdir -p ~/.local/share/icons
rsync -a --del /usr/share/icons/Yaru818/ ~/.local/share/icons/Yaru818
rsync -a --del /usr/share/icons/Yaru818-dark/ ~/.local/share/icons/Yaru818-dark
```

## Build

```sh
# 1. Copy relevant upstream files to the local directory
./init.sh

# 2. Apply patches to the local directory
./patch.sh

# 3. Run meson and ninja to build the local directory
./build.sh

# 4. Optional: Install locally
./install.sh

# 5. Optional: Create packages
./package_deb.sh
```
