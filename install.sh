#!/usr/bin/env bash

# Arch Dotfiles Installation Script
# Independent installation for Hyprland + QuickShell desktop environment

set -e

cd "$(dirname "$0")"
export base="$(pwd)"

# Colors for output
RED='\e[31m'
GREEN='\e[32m'
BLUE='\e[34m'
YELLOW='\e[33m'
NC='\e[0m' # No Color

#####################################################################################
# Functions
#####################################################################################

print_step() {
    echo -e "${BLUE}[$0]: $1${NC}"
}

print_error() {
    echo -e "${RED}[$0]: ERROR: $1${NC}"
}

print_success() {
    echo -e "${GREEN}[$0]: $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}[$0]: WARNING: $1${NC}"
}

# Check if we're on Arch Linux
check_arch() {
    if ! command -v pacman >/dev/null 2>&1; then
        print_error "pacman not found. This script only works on Arch Linux or Arch-based distributions."
        exit 1
    fi
}

# Prevent running as root
check_not_root() {
    if [[ $EUID -eq 0 ]]; then
        print_error "This script should NOT be run as root or with sudo."
        exit 1
    fi
}

# Install yay if not present
install_yay() {
    if command -v yay >/dev/null 2>&1; then
        print_success "yay is already installed"
        return 0
    fi

    print_step "Installing yay AUR helper..."
    
    # Install base-devel if not present
    sudo pacman -S --needed --noconfirm base-devel git
    
    # Clone and build yay
    cd /tmp
    git clone https://aur.archlinux.org/yay-bin.git
    cd yay-bin
    makepkg -si --noconfirm
    cd "$base"
    rm -rf /tmp/yay-bin
    
    print_success "yay installed successfully"
}

# Install packages from dependencies.txt
install_packages() {
    print_step "Installing packages from dependencies.txt..."
    
    if [[ ! -f "dependencies.txt" ]]; then
        print_error "dependencies.txt not found!"
        exit 1
    fi
    
    # Remove comments and empty lines, then install
    grep -v '^#' dependencies.txt | grep -v '^$' | xargs yay -S --needed --noconfirm
    
    print_success "All packages installed successfully"
}

# Setup Python environment for QuickShell
setup_python_environment() {
    print_step "Setting up Python environment for QuickShell..."
    
    if [[ ! -f "requirements.txt" ]]; then
        print_error "requirements.txt not found!"
        exit 1
    fi
    
    # Set environment variables
    export UV_NO_MODIFY_PATH=1
    export ILLOGICAL_IMPULSE_VIRTUAL_ENV="${XDG_STATE_HOME:-$HOME/.local/state}/quickshell/.venv"
    
    # Check if virtual environment already exists
    if [[ -d "$ILLOGICAL_IMPULSE_VIRTUAL_ENV" ]]; then
        print_success "Python virtual environment already exists"
    else
        # Create virtual environment directory
        mkdir -p "$(dirname "$ILLOGICAL_IMPULSE_VIRTUAL_ENV")"
        
        # Create Python 3.12 virtual environment (required for Pillow compatibility)
        print_step "Creating Python virtual environment at $ILLOGICAL_IMPULSE_VIRTUAL_ENV..."
        uv venv --prompt .venv "$ILLOGICAL_IMPULSE_VIRTUAL_ENV" -p 3.12
    fi
    
    # Always install/update packages (uv pip install is idempotent)
    print_step "Installing/updating Python packages..."
    source "$ILLOGICAL_IMPULSE_VIRTUAL_ENV/bin/activate"
    uv pip install -r requirements.txt
    deactivate
    
    print_success "Python environment setup completed"
}

# Configure user groups and system access
setup_user_groups() {
    print_step "Configuring user groups and hardware access..."
    
    # Check if user is already in required groups
    user_groups=$(groups "$(whoami)")
    groups_to_add=()
    
    for group in video i2c input; do
        if [[ ! $user_groups =~ $group ]]; then
            groups_to_add+=("$group")
        fi
    done
    
    if [[ ${#groups_to_add[@]} -gt 0 ]]; then
        print_step "Adding user to groups: ${groups_to_add[*]}"
        sudo usermod -aG "$(IFS=,; echo "${groups_to_add[*]}")" "$(whoami)"
        print_success "Added user to required groups"
    else
        print_success "User already in all required groups (video, i2c, input)"
    fi
    
    # Check if i2c-dev module config already exists
    if [[ -f "/etc/modules-load.d/i2c-dev.conf" ]] && grep -q "i2c-dev" "/etc/modules-load.d/i2c-dev.conf"; then
        print_success "i2c-dev module already configured"
    else
        print_step "Configuring i2c-dev module to load at boot"
        echo "i2c-dev" | sudo tee /etc/modules-load.d/i2c-dev.conf >/dev/null
        print_success "Configured i2c-dev module to load at boot"
    fi
}

# Enable and start required services
setup_services() {
    print_step "Enabling system services..."
    
    # Enable ydotool for automation/typing
    systemctl --user enable ydotool --now
    print_success "Enabled ydotool service"
    
    # Enable Bluetooth
    sudo systemctl enable bluetooth --now
    print_success "Enabled Bluetooth service"
}

# Configure desktop environment settings
setup_desktop_settings() {
    print_step "Configuring desktop environment settings..."
    
    # Set default font to Rubik
    gsettings set org.gnome.desktop.interface font-name 'Rubik 11'
    print_success "Set default font to Rubik 11"
    
    # Enable dark theme preference
    gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
    print_success "Enabled dark theme preference"
}

# Install Fish shell plugins using fisher
setup_fish_plugins() {
    print_step "Installing Fish shell plugins..."
    
    # Check if fish is installed
    if ! command -v fish >/dev/null 2>&1; then
        print_error "Fish shell not found. This should have been installed with the packages."
        return 1
    fi
    
    # Check which plugins are already installed
    local plugins_needed=()
    
    if ! fish -c "fisher list | grep -q 'PatrickF1/fzf.fish'" 2>/dev/null; then
        plugins_needed+=("PatrickF1/fzf.fish")
    fi
    
    if ! fish -c "fisher list | grep -q 'icezyclon/zoxide.fish'" 2>/dev/null; then
        plugins_needed+=("icezyclon/zoxide.fish")
    fi
    
    if [[ ${#plugins_needed[@]} -eq 0 ]]; then
        print_success "All Fish plugins already installed"
        return 0
    fi
    
    # Install fisher if not present, then install needed plugins
    fish -c "
        if not functions -q fisher
            echo 'Installing fisher...'
            curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source
            fisher install jorgebucaran/fisher
        end
        
        # Install only the needed plugins
        set plugins_to_install ${plugins_needed[*]}
        for plugin in \$plugins_to_install
            echo \"Installing \$plugin...\"
            fisher install \$plugin
        end
    " 2>/dev/null || {
        print_warning "Failed to install fisher plugins. You may need to install them manually after first login."
        print_step "Manual installation commands:"
        echo "  fish -c 'fisher install PatrickF1/fzf.fish'"
        echo "  fish -c 'fisher install icezyclon/zoxide.fish'"
        return 0
    }
    
    print_success "Fish plugins installed successfully"
}

# Install dotfiles using rsync (like END4)
install_dotfiles() {
    print_step "Installing dotfiles to ~/.config/..."
    
    if [[ ! -d "config/.config" ]]; then
        print_error "config/.config directory not found!"
        exit 1
    fi
    
    # Create necessary directories
    XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
    XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
    mkdir -p "$XDG_CONFIG_HOME" "$XDG_DATA_HOME"
    
    print_step "Copying configuration files with rsync..."
    
    # Copy all .config directories using rsync with --delete to ensure clean sync
    for config_dir in config/.config/*/; do
        if [[ -d "$config_dir" ]]; then
            dirname=$(basename "$config_dir")
            print_step "Installing $dirname configuration..."
            rsync -av --delete "$config_dir" "$XDG_CONFIG_HOME/"
        fi
    done
    
    # Copy individual config files (if any)
    for config_file in config/.config/*; do
        if [[ -f "$config_file" ]]; then
            filename=$(basename "$config_file")
            print_step "Installing $filename configuration..."
            rsync -av "$config_file" "$XDG_CONFIG_HOME/"
        fi
    done
    
    # Copy .local/share files if they exist
    if [[ -d "config/.local/share" ]]; then
        print_step "Installing .local/share files..."
        rsync -av config/.local/share/ "$XDG_DATA_HOME/"
    fi
    
    print_success "Dotfiles installed successfully"
    
    # Create default monitors.conf if it doesn't exist
    MONITORS_CONF="$XDG_CONFIG_HOME/hypr/hyprland/monitors.conf"
    if [[ ! -f "$MONITORS_CONF" ]]; then
        print_step "Creating default monitors.conf..."
        cat > "$MONITORS_CONF" << 'EOF'
# MONITOR CONFIG
# To see device name, use `hyprctl monitors`
monitor = , preferred, auto, 1
EOF
        print_success "Created default monitors.conf"
    else
        print_success "monitors.conf already exists, skipping creation"
    fi
    
    # Create wallpaper symlink
    print_step "Setting up wallpaper directory..."
    mkdir -p "$HOME/Pictures"
    WALLPAPER_LINK="$HOME/Pictures/Wallpapers"
    if [[ ! -L "$WALLPAPER_LINK" && ! -d "$WALLPAPER_LINK" ]]; then
        ln -s "$base/wallpapers" "$WALLPAPER_LINK"
        print_success "Created wallpaper symlink: ~/Pictures/Wallpapers -> $base/wallpapers"
    elif [[ -L "$WALLPAPER_LINK" ]]; then
        print_success "Wallpaper symlink already exists"
    else
        print_warning "~/Pictures/Wallpapers exists but is not a symlink - skipping"
    fi
    
    # Reload Hyprland if running
    if pgrep -x hyprland >/dev/null; then
        print_step "Reloading Hyprland configuration..."
        hyprctl reload || print_warning "Failed to reload Hyprland (this is normal if not running)"
    fi
}

#####################################################################################
# Main installation
#####################################################################################

print_step "Starting Arch Dotfiles installation"
echo

# Preliminary checks
check_arch
check_not_root

# System update
print_step "Updating system packages..."
sudo pacman -Syu --noconfirm

# Install yay
install_yay

# Install packages
install_packages

# Setup Python environment
setup_python_environment

# Configure user groups and hardware access
setup_user_groups

# Enable services
setup_services

# Configure desktop settings
setup_desktop_settings

# Install dotfiles
install_dotfiles

# Install Fish plugins
setup_fish_plugins

print_success "Installation completed!"
echo
print_step "Next steps:"
echo "1. Logout and login again (for group changes to take effect)"
echo "2. At login screen, select 'Hyprland' from the session list"
echo "3. Enjoy your new desktop setup!"
echo
print_step "Useful keybinds after login:"
echo "• Super+H = Toggle cheatsheet"
echo "• Super+Ctrl+Alt+W = Change wallpaper"
echo "• Super+Return = Terminal"
echo "• Super+E = File manager"
echo "• Super = Toggle overview/launcher"
echo
print_warning "Important: Do NOT select UWSM session - use regular Hyprland"
print_warning "Note: Existing config files were overwritten for clean installation"