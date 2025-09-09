#!/bin/bash

# Post-Installation Setup Script for Nord Hyprland Config
# This script handles additional setup tasks after installation

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log() {
    echo -e "${GREEN}[SETUP]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[SETUP]${NC} $1"
}

error() {
    echo -e "${RED}[SETUP]${NC} $1"
}

# Setup wallpaper directory
setup_wallpapers() {
    log "Setting up wallpapers directory..."
    
    local wallpaper_dir="$HOME/Pictures/Wallpapers"
    mkdir -p "$wallpaper_dir"
    
    # Copy the existing Nord wallpaper from .themes directory
    local source_wallpaper="$HOME/.themes/nord/background/omarchy-nord-1.png"
    local dest_wallpaper="$wallpaper_dir/omarchy-nord-1.png"
    
    if [[ -f "$source_wallpaper" ]]; then
        log "Copying Nord wallpaper from .themes directory..."
        cp "$source_wallpaper" "$dest_wallpaper"
        
        # Also create a symlink as the default wallpaper
        ln -sf "$dest_wallpaper" "$wallpaper_dir/nord-default.png"
        
        log "Nord wallpaper set up successfully"
    else
        warn "Nord wallpaper not found at $source_wallpaper"
        warn "Make sure the .themes directory is installed first"
    fi
    
    log "Wallpapers directory setup complete"
}

# Configure SDDM theme
setup_sddm_theme() {
    log "Configuring SDDM theme..."
    
    # Check if SDDM is installed
    if ! pacman -Q sddm &> /dev/null; then
        warn "SDDM is not installed, skipping theme configuration"
        return
    fi
    
    # Create SDDM configuration directory if it doesn't exist
    if [[ ! -d "/etc/sddm.conf.d" ]]; then
        sudo mkdir -p /etc/sddm.conf.d
    fi
    
    # Configure Sugar Candy theme if available
    if [[ -d "/usr/share/sddm/themes/sugar-candy" ]]; then
        log "Configuring Sugar Candy SDDM theme..."
        
        # Create SDDM configuration for Sugar Candy theme
        sudo tee /etc/sddm.conf.d/theme.conf > /dev/null << EOF
[Theme]
Current=sugar-candy
EOF
        
        log "Sugar Candy theme configured for SDDM"
    elif [[ -d "/usr/share/sddm/themes/corners" ]]; then
        log "Configuring Corners SDDM theme as fallback..."
        
        # Create SDDM configuration for Corners theme
        sudo tee /etc/sddm.conf.d/theme.conf > /dev/null << EOF
[Theme]
Current=corners
EOF
        
        log "Corners theme configured for SDDM"
    else
        warn "No SDDM themes found. Make sure theme packages are installed."
    fi
    
    log "SDDM theme configuration complete"
}

# Setup user directories
setup_user_directories() {
    log "Creating user directories..."
    
    local dirs=(
        "$HOME/Pictures/Screenshots"
        "$HOME/Documents/Scripts"
        "$HOME/.local/bin"
        "$HOME/.cache/hyprland"
    )
    
    for dir in "${dirs[@]}"; do
        mkdir -p "$dir"
    done
    
    log "User directories created"
}

# Setup environment variables
setup_environment() {
    log "Setting up environment variables..."
    
    local env_file="$HOME/.config/environment.d/hyprland.conf"
    mkdir -p "$(dirname "$env_file")"
    
    cat > "$env_file" << EOF
# Hyprland Environment Variables
XCURSOR_SIZE=24
XCURSOR_THEME=Nordic-cursors

# Qt theme
QT_QPA_PLATFORMTHEME=qt5ct
QT_STYLE_OVERRIDE=kvantum

# GTK theme
GTK_THEME=Nordic

# XDG
XDG_CURRENT_DESKTOP=Hyprland
XDG_SESSION_DESKTOP=Hyprland
XDG_SESSION_TYPE=wayland

# Firefox
MOZ_ENABLE_WAYLAND=1

# Electron apps
ELECTRON_OZONE_PLATFORM_HINT=wayland
EOF
    
    log "Environment variables configured"
}

# Setup fonts
setup_fonts() {
    log "Refreshing font cache..."
    
    # Create local fonts directory
    mkdir -p "$HOME/.local/share/fonts"
    
    # Refresh font cache
    if command -v fc-cache &> /dev/null; then
        fc-cache -fv
        log "Font cache refreshed"
    else
        warn "fc-cache not found, please refresh font cache manually"
    fi
}

# Setup autostart applications
setup_autostart() {
    log "Setting up autostart applications..."
    
    local autostart_dir="$HOME/.config/autostart"
    mkdir -p "$autostart_dir"
    
    # Create desktop entries for autostart applications
    
    # NetworkManager Applet
    cat > "$autostart_dir/nm-applet.desktop" << EOF
[Desktop Entry]
Name=Network Manager Applet
Comment=Network Manager Applet
Exec=nm-applet
Terminal=false
Type=Application
Icon=network-workgroup
StartupNotify=false
X-GNOME-Autostart-enabled=true
EOF
    
    # Bluetooth Manager
    cat > "$autostart_dir/blueman-applet.desktop" << EOF
[Desktop Entry]
Name=Bluetooth Manager
Comment=Bluetooth Manager
Exec=blueman-applet
Terminal=false
Type=Application
Icon=bluetooth
StartupNotify=false
X-GNOME-Autostart-enabled=true
EOF
    
    log "Autostart applications configured"
}

# Create useful scripts
create_scripts() {
    log "Creating utility scripts..."
    
    local scripts_dir="$HOME/.local/bin"
    
    # Screenshot script
    cat > "$scripts_dir/screenshot" << 'EOF'
#!/bin/bash
# Screenshot script for Hyprland

case $1 in
    "full")
        grim ~/Pictures/Screenshots/screenshot_$(date +%Y%m%d_%H%M%S).png
        ;;
    "area")
        grim -g "$(slurp)" ~/Pictures/Screenshots/screenshot_$(date +%Y%m%d_%H%M%S).png
        ;;
    "window")
        grim -g "$(hyprctl activewindow | grep -oP 'at: \K[0-9,]+' | tr ',' ' ' | awk '{print $1 "," $2}')" ~/Pictures/Screenshots/screenshot_$(date +%Y%m%d_%H%M%S).png
        ;;
    *)
        echo "Usage: screenshot [full|area|window]"
        ;;
esac
EOF
    
    # Wallpaper changer script
    cat > "$scripts_dir/change-wallpaper" << 'EOF'
#!/bin/bash
# Wallpaper changer for Hyprland with swww

WALLPAPER_DIR="$HOME/Pictures/Wallpapers"

if [[ -z "$1" ]]; then
    # Choose random wallpaper
    WALLPAPER=$(find "$WALLPAPER_DIR" -type f \( -name "*.jpg" -o -name "*.png" -o -name "*.jpeg" \) | shuf -n 1)
else
    WALLPAPER="$1"
fi

if [[ -f "$WALLPAPER" ]]; then
    swww img "$WALLPAPER" --transition-type wipe --transition-duration 2
    echo "Wallpaper changed to: $(basename "$WALLPAPER")"
else
    echo "Wallpaper not found: $WALLPAPER"
fi
EOF
    
    # Make scripts executable
    chmod +x "$scripts_dir/screenshot"
    chmod +x "$scripts_dir/change-wallpaper"
    
    log "Utility scripts created"
}

# Setup XDG user directories
setup_xdg_dirs() {
    log "Setting up XDG user directories..."
    
    if command -v xdg-user-dirs-update &> /dev/null; then
        xdg-user-dirs-update
        log "XDG user directories updated"
    else
        warn "xdg-user-dirs-update not found"
    fi
}

# Main function
main() {
    log "Starting post-installation setup..."
    
    setup_wallpapers
    setup_sddm_theme
    setup_user_directories
    setup_environment
    setup_fonts
    setup_autostart
    create_scripts
    setup_xdg_dirs
    
    log "Post-installation setup completed!"
    
    echo ""
    echo -e "${BLUE}Setup Summary:${NC}"
    echo "• Wallpapers directory: ~/Pictures/Wallpapers"
    echo "• Screenshots directory: ~/Pictures/Screenshots"
    echo "• Utility scripts: ~/.local/bin/"
    echo "• Environment variables: ~/.config/environment.d/hyprland.conf"
    echo "• Autostart applications configured"
    echo ""
    echo -e "${YELLOW}Next steps:${NC}"
    echo "1. Log out and log back in (or reboot)"
    echo "2. Start Hyprland session"
    echo "3. Run 'change-wallpaper' to set a wallpaper"
    echo "4. Take a screenshot with Super+Shift+S"
    echo ""
    echo "Enjoy your Nord Hyprland setup! 🎉"
}

# Run main function
main "$@"
