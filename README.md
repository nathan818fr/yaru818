# Yaru818

My personal fork of the yaru theme (for cinnamon and gtk).

## Installation

### Prerequisites

It is recommended to install the [humanity-icon-theme] first, as our icon pack
depends on it.

```sh
sudo apt install ./humanity-icon-theme_VERSION.deb
```

### Distribution packages

**• Debian package (.deb)**\
Download the debian package from [releases] and install-it.

```sh
sudo apt install ./yaru818-theme_VERSION.deb
```

### Flatpak

Download the flatpak bundle from [releases] and install-it.

```sh
sudo flatpak install org.gtk.Gtk3theme.Yaru818_VERSION.flatpak
```

It is also recommended to allow flatpak to access your gtk configurations (it
will better follow your settings):

```sh
flatpak override --user --filesystem=xdg-config/gtk-2.0:ro --filesystem=xdg-config/gtk-3.0:ro
```

## Configuration

1. Select `Yaru818-dark` in the theme settings of your desktop-manager.\
   To apply it automatically to Cinnamon, run:
   ```sh
   gsettings set org.cinnamon.desktop.interface gtk-theme Yaru818-dark
   gsettings set org.cinnamon.desktop.interface icon-theme Yaru818-dark
   gsettings set org.cinnamon.theme name Yaru818-dark
   ```

2. Enable the dark variant by default in GTK applications:\
   *(otherwise some applications will use the light variant)*
   ```
   gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
   ```

### Cinnamon configuration

- Font Selection:
    - Default font: Sans Regular 9
    - Window title font: Sans Regular 9

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

[releases]: https://github.com/nathan818fr/yaru818/releases

[humanity-icon-theme]: http://archive.ubuntu.com/ubuntu/pool/main/h/humanity-icon-theme/humanity-icon-theme_0.6.16_all.deb
