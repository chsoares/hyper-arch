# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is an Arch Linux dotfiles repository containing configuration files for a modern desktop environment setup using:
- **Hyprland** (Wayland compositor)
- **QuickShell** (Qt/QML-based desktop shell)
- **Fish** shell with Starship prompt
- **Various system utilities** (kitty, fastfetch, etc.)

## Installation and Setup

The dotfiles are managed using GNU Stow:
```bash
yay -Sy stow
cd ~/arch-dotfiles
stow config
```

This symlinks all configuration files from `config/.config/` to `~/.config/`.

## Architecture

### Directory Structure
- `config/.config/` - All application configuration files
- `config/.config/hypr/` - Hyprland window manager configuration
  - `hyprland.conf` - Main config file that sources modular config files
  - `hyprland/` - Modular configuration files (env, monitors, keybinds, etc.)
  - `hyprland/scripts/` - Utility scripts for window management, AI integration, screen recording
- `config/.config/quickshell/` - Desktop shell built with Qt/QML
  - `shell.qml` - Main shell entry point with module toggles
  - `modules/` - Modular UI components (bar, dock, notifications, etc.)
- `config/.config/fish/` - Fish shell configuration with aliases and integrations

### Key Components

**Hyprland Configuration**
- Modular configuration split across multiple files in `hyprland/`
- Custom scripts for window management, recording, AI integration
- Uses sourcing pattern: main config sources specialized configs

**QuickShell Desktop**
- QML-based desktop shell with lazy-loaded modules
- Modular architecture with toggleable components (bar, dock, overview, etc.)
- Integrated AI prompts and terminal color schemes

**Shell Environment**
- Fish shell with Starship prompt for rich terminal experience
- Custom aliases and integrations
- Fastfetch display on interactive sessions

## Configuration Management

When modifying configurations:
1. **Hyprland**: Add custom configurations to files in `hyprland/custom/` (referenced in comments)
2. **QuickShell**: Enable/disable modules via boolean properties in `shell.qml`
3. **Fish**: Custom aliases go in `~/.config/fish/aliases.fish`

## Key Scripts and Utilities

Located in `config/.config/hypr/hyprland/scripts/`:
- `hypr-snip.sh` - Screenshot utility
- `workspace_action.sh` - Workspace management
- `record.sh` - Screen recording
- `ai/` - AI integration scripts (primary buffer query, model loading)

## Development Notes

- This is a personal dotfiles setup, not a software project with build/test commands
- Changes should respect the existing modular architecture
- When adding new configurations, follow the established directory structure and naming conventions
- Configuration files use various formats (TOML, QML, shell scripts) depending on the application