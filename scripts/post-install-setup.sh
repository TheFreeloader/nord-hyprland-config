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

# Ensure directory exists - create if missing with comprehensive error handling
ensure_directory() {
    local dir="$1"
    local use_sudo="${2:-false}"
    local description="${3:-directory}"
    
    if [[ ! -d "$dir" ]]; then
        log "Creating $description: $dir"
        if [[ "$use_sudo" == "true" ]]; then
            if sudo mkdir -p "$dir"; then
                log "Successfully created $description: $dir"
            else
                error "Failed to create $description: $dir"
                return 1
            fi
        else
            if mkdir -p "$dir"; then
                log "Successfully created $description: $dir"
            else
                error "Failed to create $description: $dir"
                return 1
            fi
        fi
    fi
}

# Create all necessary directories upfront
create_all_directories() {
    log "Ensuring all necessary directories exist..."
    
    # User configuration directories
    ensure_directory "$HOME/.config" false "user config directory"
    
    # User local directories
    ensure_directory "$HOME/.local" false "user local directory"
    ensure_directory "$HOME/.local/bin" false "user bin directory"
    ensure_directory "$HOME/.local/share" false "user share directory"
    ensure_directory "$HOME/.local/share/applications" false "user applications directory"
    ensure_directory "$HOME/.local/share/fonts" false "user fonts directory"
    
    # User theme directories
    ensure_directory "$HOME/.themes" false "user themes directory"
    
    # User media directories
    ensure_directory "$HOME/Pictures" false "Pictures directory"
    ensure_directory "$HOME/Pictures/Wallpapers" false "wallpapers directory"
    ensure_directory "$HOME/Pictures/Screenshots" false "screenshots directory"
    
    # XDG directories
    ensure_directory "$HOME/Desktop" false "Desktop directory"
    ensure_directory "$HOME/Documents" false "Documents directory"
    ensure_directory "$HOME/Downloads" false "Downloads directory"
    ensure_directory "$HOME/Music" false "Music directory"
    ensure_directory "$HOME/Videos" false "Videos directory"
    
    log "All directories verified/created successfully"
}

# Setup wallpaper directory
setup_wallpapers() {
    log "Setting up wallpapers directory..."
    
    local wallpaper_dir="$HOME/Pictures/Wallpapers"
    mkdir -p "$wallpaper_dir"
    
    log "Wallpapers directory setup complete"
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

# Setup shell profile to auto-start Hyprland
setup_shell_profile() {
    log "Setting up shell profile for automatic Hyprland startup..."
    
    # Detect which shell profile file to use
    local profile_file=""
    local shell_name="$(basename "$SHELL")"
    
    case "$shell_name" in
        "bash")
            # For bash, prefer .bash_profile, fallback to .profile
            if [[ -f "$HOME/.bash_profile" ]]; then
                profile_file="$HOME/.bash_profile"
            else
                profile_file="$HOME/.profile"
            fi
            ;;
        "zsh")
            profile_file="$HOME/.zprofile"
            ;;
        *)
            # Generic fallback
            profile_file="$HOME/.profile"
            ;;
    esac
    
    log "Using profile file: $profile_file"
    
    # Hyprland auto-start code
    local hyprland_autostart='
# Auto-start Hyprland on TTY1 login
if [ -z "$WAYLAND_DISPLAY" ] && [ "$XDG_VTNR" -eq 1 ]; then
    # Set environment variables for Wayland
    export XDG_SESSION_TYPE=wayland
    export XDG_CURRENT_DESKTOP=Hyprland
    export XDG_SESSION_DESKTOP=Hyprland
    
    # Start Hyprland with UWSM if available, otherwise direct
    if command -v uwsm >/dev/null 2>&1; then
        echo "Starting Hyprland with UWSM session management..."
        exec uwsm start hyprland
    else
        echo "Starting Hyprland..."
        exec Hyprland
    fi
fi'
    
    # Check if auto-start is already configured
    if grep -q "Auto-start Hyprland" "$profile_file" 2>/dev/null; then
        log "Hyprland auto-start already configured in $profile_file"
        return
    fi
    
    # Add auto-start to profile
    echo "$hyprland_autostart" >> "$profile_file"
    log "Added Hyprland auto-start to $profile_file"
    log "Hyprland will automatically start on TTY1 after login"
    
    # Also create a manual start script for convenience
    cat > "$HOME/.local/bin/start-hyprland" << 'EOF'
#!/bin/bash
# Manual Hyprland starter script

# Set environment variables
export XDG_SESSION_TYPE=wayland
export XDG_CURRENT_DESKTOP=Hyprland
export XDG_SESSION_DESKTOP=Hyprland

# Start with UWSM if available
if command -v uwsm >/dev/null 2>&1; then
    echo "Starting Hyprland with UWSM..."
    exec uwsm start hyprland
else
    echo "Starting Hyprland directly..."
    exec Hyprland
fi
EOF
    
    chmod +x "$HOME/.local/bin/start-hyprland"
    log "Created manual starter script: start-hyprland"
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
    
    # Ensure we start from a safe directory
    cd "$HOME" || {
        error "Cannot access home directory"
        exit 1
    }
    
    # Create all necessary directories first
    create_all_directories
    
    setup_wallpapers
    setup_user_directories
    # Skip session management - session is managed externally
    # setup_uwsm
    # setup_shell_profile
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
    echo "• Autostart applications configured"
    echo "• Session management: Handled externally"
    echo ""
    echo -e "${YELLOW}Next steps:${NC}"
    echo "1. Start Hyprland through your external session manager"
    echo "2. Run 'change-wallpaper' to set a wallpaper"
    echo "3. Take a screenshot with Super+Shift+S"
    echo "4. Customize the config files in ~/.config/ as needed"
    echo ""
    echo -e "${GREEN}Manual start option:${NC}"
    echo "• Run 'start-hyprland' command if needed"
    echo ""
    echo "Enjoy your Nord Hyprland setup! 🎉"
}

# Run main function
main "$@"
