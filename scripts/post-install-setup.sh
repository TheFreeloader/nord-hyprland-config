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

# Setup SDDM display manager and theme
setup_sddm() {
    log "Setting up SDDM display manager..."
    
    # Check if SDDM is installed
    if ! pacman -Q sddm &> /dev/null; then
        warn "SDDM is not installed, skipping SDDM setup"
        return
    fi
    
    # Create SDDM configuration directory if it doesn't exist
    ensure_directory "/etc/sddm.conf.d" true "SDDM config directory"
    
    # Configure SDDM theme
    local theme_configured=false
    
    # Try to configure Sugar Candy theme first
    if [[ -d "/usr/share/sddm/themes/sugar-candy" ]]; then
        log "Configuring Sugar Candy SDDM theme..."
        
        sudo tee /etc/sddm.conf.d/theme.conf > /dev/null << 'EOF'
[Theme]
Current=sugar-candy

[General]
HaltCommand=/usr/bin/systemctl poweroff
RebootCommand=/usr/bin/systemctl reboot
Numlock=on

[Autologin]
Relogin=false
Session=
User=

[Users]
MaximumUid=60000
MinimumUid=500
EOF
        
        log "Sugar Candy theme configured for SDDM"
        theme_configured=true
    
    # Try Corners theme as fallback
    elif [[ -d "/usr/share/sddm/themes/corners" ]]; then
        log "Configuring Corners SDDM theme as fallback..."
        
        sudo tee /etc/sddm.conf.d/theme.conf > /dev/null << 'EOF'
[Theme]
Current=corners

[General]
HaltCommand=/usr/bin/systemctl poweroff
RebootCommand=/usr/bin/systemctl reboot
Numlock=on

[Autologin]
Relogin=false
Session=
User=

[Users]
MaximumUid=60000
MinimumUid=500
EOF
        
        log "Corners theme configured for SDDM"
        theme_configured=true
    
    else
        # Create basic SDDM config without theme
        log "No SDDM themes found, using default configuration..."
        
        sudo tee /etc/sddm.conf.d/default.conf > /dev/null << 'EOF'
[General]
HaltCommand=/usr/bin/systemctl poweroff
RebootCommand=/usr/bin/systemctl reboot
Numlock=on

[Autologin]
Relogin=false
Session=
User=

[Users]
MaximumUid=60000
MinimumUid=500
EOF
        
        warn "No SDDM themes found. Install sddm-theme-sugar-candy or sddm-theme-corners-git for better appearance"
    fi
    
    # Enable and start SDDM service
    log "Enabling SDDM service..."
    if sudo systemctl enable sddm.service; then
        log "SDDM service enabled successfully"
    else
        error "Failed to enable SDDM service"
        return 1
    fi
    
    # Disable other display managers that might conflict
    local other_dms=("gdm" "lightdm" "lxdm" "xdm")
    for dm in "${other_dms[@]}"; do
        if systemctl is-enabled "$dm.service" &> /dev/null; then
            log "Disabling conflicting display manager: $dm"
            sudo systemctl disable "$dm.service" || true
        fi
    done
    
    log "SDDM setup completed successfully"
    
    if [[ "$theme_configured" == true ]]; then
        log "SDDM theme configured - you'll see it after reboot"
    fi
}

# Setup Chromebook-specific configurations
setup_chromebook_support() {
    log "Setting up Chromebook hardware support..."
    
    # Check if running on a Chromebook
    if [[ -e /proc/device-tree/compatible ]] && grep -q "google" /proc/device-tree/compatible 2>/dev/null; then
        log "Chromebook hardware detected"
    elif lsusb | grep -i "google\|chromebook" &> /dev/null; then
        log "Google/Chromebook hardware detected via USB"
    elif dmesg | grep -i "chromebook\|google" &> /dev/null 2>&1; then
        log "Chromebook hardware detected via dmesg"
    else
        log "Setting up generic Chromebook support configuration"
    fi
    
    # Create Chromebook-specific configuration
    local chromebook_config="$HOME/.config/hypr/chromebook.conf"
    
    cat > "$chromebook_config" << 'EOF'
# Chromebook-specific Hyprland configuration
# Source this file from your main hyprland.conf

# Chromebook keyboard optimizations
input {
    kb_options = caps:escape,altwin:swap_lalt_lwin
    
    touchpad {
        natural_scroll = true
        scroll_factor = 0.3
        middle_button_emulation = true
        tap_button_map = lrm
        clickfinger_behavior = true
        drag_lock = true
    }
}

# Enable gesture navigation (common on Chromebooks)
gestures {
    workspace_swipe = true
    workspace_swipe_fingers = 3
    workspace_swipe_distance = 300
    workspace_swipe_invert = true
}

# Chromebook-specific device rules
device {
    name = google-chromebook-pixel-keyboard
    kb_options = caps:escape,altwin:swap_lalt_lwin
}

device {
    name = at-translated-set-2-keyboard  
    kb_options = caps:escape,altwin:swap_lalt_lwin
}

# Common Chromebook touchpad names
device {
    name = atmel_mxt_ts
    sensitivity = 0.3
}

device {
    name = elan-touchpad
    sensitivity = 0.3
    natural_scroll = true
}

device {
    name = synaptics-touchpad
    sensitivity = 0.3 
    natural_scroll = true
}
EOF

    # Create kernel module configuration for Chromebook hardware
    local modules_conf="/etc/modules-load.d/chromebook.conf"
    
    if [[ ! -f "$modules_conf" ]]; then
        log "Creating Chromebook kernel modules configuration..."
        sudo tee "$modules_conf" > /dev/null << 'EOF'
# Chromebook-specific kernel modules
cros_ec
cros_ec_i2c
cros_ec_spi
cros_usbpd_charger
cros_usbpd_logger
chromeos_laptop
chromeos_pstore
EOF
    fi
    
    # Create udev rules for Chromebook hardware
    local udev_rules="/etc/udev/rules.d/90-chromebook.rules"
    
    if [[ ! -f "$udev_rules" ]]; then
        log "Creating Chromebook udev rules..."
        sudo tee "$udev_rules" > /dev/null << 'EOF'
# Chromebook-specific udev rules

# Fix keyboard backlight
SUBSYSTEM=="leds", KERNEL=="chromeos::kbd_backlight", TAG+="uaccess"

# Fix touchpad
KERNEL=="event*", ATTRS{name}=="Atmel maXTouch Touchpad", SYMLINK+="input/touchpad0"
KERNEL=="event*", ATTRS{name}=="Elan Touchpad", SYMLINK+="input/touchpad0"

# Fix audio
SUBSYSTEM=="sound", ATTRS{id}=="bytcht-es8316", TAG+="uaccess"
SUBSYSTEM=="sound", ATTRS{id}=="byt-max98090", TAG+="uaccess"

# Power management
KERNEL=="cros-ec-accel*", TAG+="uaccess"
KERNEL=="cros-ec-gyro*", TAG+="uaccess"
KERNEL=="cros-ec-light*", TAG+="uaccess"
EOF
    fi
    
    # Create Chromebook utility scripts
    local scripts_dir="$HOME/.local/bin"
    
    # Chromebook keyboard backlight script
    cat > "$scripts_dir/chromebook-kbd-backlight" << 'EOF'
#!/bin/bash
# Chromebook keyboard backlight control

BACKLIGHT_PATH="/sys/class/leds/chromeos::kbd_backlight/brightness"
MAX_PATH="/sys/class/leds/chromeos::kbd_backlight/max_brightness"

if [[ ! -f "$BACKLIGHT_PATH" ]]; then
    echo "Chromebook keyboard backlight not found"
    exit 1
fi

case "$1" in
    "up"|"+"|"increase")
        if [[ -f "$MAX_PATH" ]]; then
            max_brightness=$(cat "$MAX_PATH")
            current=$(cat "$BACKLIGHT_PATH")
            new_brightness=$((current + max_brightness / 10))
            if [[ $new_brightness -gt $max_brightness ]]; then
                new_brightness=$max_brightness
            fi
            echo $new_brightness | sudo tee "$BACKLIGHT_PATH" > /dev/null
        fi
        ;;
    "down"|"-"|"decrease")
        current=$(cat "$BACKLIGHT_PATH")
        max_brightness=$(cat "$MAX_PATH" 2>/dev/null || echo 100)
        new_brightness=$((current - max_brightness / 10))
        if [[ $new_brightness -lt 0 ]]; then
            new_brightness=0
        fi
        echo $new_brightness | sudo tee "$BACKLIGHT_PATH" > /dev/null
        ;;
    "toggle"|"t")
        current=$(cat "$BACKLIGHT_PATH")
        if [[ $current -eq 0 ]]; then
            max_brightness=$(cat "$MAX_PATH" 2>/dev/null || echo 100)
            echo $((max_brightness / 2)) | sudo tee "$BACKLIGHT_PATH" > /dev/null
        else
            echo 0 | sudo tee "$BACKLIGHT_PATH" > /dev/null
        fi
        ;;
    *)
        echo "Usage: $0 [up|down|toggle]"
        echo "Current brightness: $(cat "$BACKLIGHT_PATH")"
        ;;
esac
EOF
    
    chmod +x "$scripts_dir/chromebook-kbd-backlight"
    
    # Update Hyprland config to source chromebook.conf
    local hyprland_conf="$HOME/.config/hypr/hyprland.conf"
    if [[ -f "$hyprland_conf" ]] && ! grep -q "chromebook.conf" "$hyprland_conf"; then
        echo "" >> "$hyprland_conf"
        echo "# Chromebook-specific configuration" >> "$hyprland_conf"
        echo "source = ~/.config/hypr/chromebook.conf" >> "$hyprland_conf"
    fi
    
    log "Chromebook support configuration completed"
    log "• Created chromebook-specific config: ~/.config/hypr/chromebook.conf"
    log "• Added kernel modules: /etc/modules-load.d/chromebook.conf"
    log "• Added udev rules: /etc/udev/rules.d/90-chromebook.rules"
    log "• Created utility script: chromebook-kbd-backlight"
    
    warn "Note: Reboot required for kernel modules and udev rules to take effect"
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
    setup_sddm
    setup_chromebook_support
    
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
