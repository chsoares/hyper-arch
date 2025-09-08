# hypr-arch

A modern Arch Linux desktop environment featuring Hyprland (Wayland compositor) and QuickShell (Qt/QML-based desktop shell).

## Features

- **Hyprland**: High-performance Wayland compositor with advanced window management
- **QuickShell**: Modern desktop shell built with Qt/QML for rich UI components
- **Modular Configuration**: Easy-to-customize modular configuration system
- **Modern Aesthetics**: Material Design 3 theming with dynamic wallpaper-based colors
- **Complete Desktop Environment**: 
  - Customizable status bar with system information
  - Overview/launcher with fuzzy search
  - Notification system
  - Settings interface (Super+I)
  - Resource monitoring
  - Weather integration
  - Audio/brightness controls
  - And much more...

## Installation

### Prerequisites
- Fresh Arch Linux installation
- Tested with GNOME as base environment

### Quick Install
```bash
git clone https://github.com/chsoares/hypr-arch.git
cd ~/hypr-arch
./install.sh
```

The install script will:
- Install all required packages via yay
- Set up Python environment for QuickShell
- Configure system services and user groups
- Install dotfiles and create necessary symlinks
- Set up wallpaper directory
- Configure default monitor settings

### Post-Installation
1. Logout and login again (for group changes to take effect)
2. At login screen, select **Hyprland** from the session list
3. On first run, a random wallpaper will be set and settings will open automatically

## Key Bindings
- `Super` = Toggle overview/launcher
- `Super+I` = Open settings
- `Super+H` = Toggle cheatsheet
- `Super+Return` = Terminal
- `Super+E` = File manager
- `Super+Ctrl+Alt+T` = Random wallpaper

## Based On
This project is based on the excellent [END-4 dotfiles](https://github.com/end-4/dots-hyprland), adapted and customized for a cleaner, more focused desktop experience.