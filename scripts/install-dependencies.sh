#!/bin/bash

# Dependencies Installation Script for Nord Hyprland Config
# This script installs all necessary packages and dependencies

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log() {
    echo -e "${GREEN}[DEPS]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[DEPS]${NC} $1"
}

error() {
    echo -e "${RED}[DEPS]${NC} $1"
}

# Ensure directory exists - create if missing
ensure_directory() {
    local dir="$1"
    local use_sudo="${2:-false}"
    
    if [[ ! -d "$dir" ]]; then
        log "Creating directory: $dir"
        if [[ "$use_sudo" == "true" ]]; then
            sudo mkdir -p "$dir"
        else
            mkdir -p "$dir"
        fi
    fi
}

# Create essential system directories
create_system_directories() {
    log "Ensuring system directories exist..."
    
    # User directories
    ensure_directory "$HOME/.config"
    ensure_directory "$HOME/.local/bin"
    ensure_directory "$HOME/.local/share"
    ensure_directory "$HOME/.local/share/applications"
    ensure_directory "$HOME/.local/share/icons"
    ensure_directory "$HOME/.local/share/themes"
    ensure_directory "$HOME/.themes"
    ensure_directory "$HOME/Pictures"
    ensure_directory "$HOME/Pictures/Wallpapers"
    ensure_directory "$HOME/Pictures/Screenshots"
    
    # System directories (with sudo)
    ensure_directory "/etc/sddm.conf.d" "true"
    ensure_directory "/usr/local/bin" "true"
    
    log "Essential directories created"
}

# Detect package manager
detect_package_manager() {
    if command -v pacman &> /dev/null; then
        echo "pacman"
    else
        echo "unknown"
    fi
}

# Install yay if not present
install_yay() {
    if ! command -v yay &> /dev/null; then
        log "Installing yay AUR helper..."
        
        # Save current directory to return to it later
        local original_dir="$PWD"
        
        # Check if base-devel and git are installed
        local build_deps=("base-devel" "git")
        local missing_build_deps=()
        
        for dep in "${build_deps[@]}"; do
            if ! pacman -Q "$dep" &> /dev/null; then
                missing_build_deps+=("$dep")
            fi
        done
        
        if [[ ${#missing_build_deps[@]} -gt 0 ]]; then
            log "Installing build dependencies: ${missing_build_deps[*]}"
            sudo pacman -S --needed --noconfirm "${missing_build_deps[@]}"
        fi
        
        # Create temporary directory in a safe location
        local temp_dir=$(mktemp -d -t yay-install.XXXXXX)
        log "Building yay in temporary directory: $temp_dir"
        
        # Change to temp directory
        if cd "$temp_dir"; then
            log "Changed to build directory: $temp_dir"
        else
            error "Failed to change to temporary directory"
            exit 1
        fi
        
        # Clone and build yay
        if git clone https://aur.archlinux.org/yay.git; then
            if cd yay; then
                if makepkg -si --noconfirm; then
                    log "yay installed successfully"
                    # Return to original directory or home as fallback
                    if [[ -d "$original_dir" ]]; then
                        cd "$original_dir" || cd "$HOME"
                    else
                        cd "$HOME"
                    fi
                else
                    error "Failed to build yay"
                    cd "$HOME"  # Safe fallback
                    rm -rf "$temp_dir"
                    exit 1
                fi
            else
                error "Failed to enter yay directory"
                cd "$HOME"  # Safe fallback
                rm -rf "$temp_dir"
                exit 1
            fi
        else
            error "Failed to clone yay repository"
            cd "$HOME"  # Safe fallback
            rm -rf "$temp_dir"
            exit 1
        fi
        
        # Cleanup from a safe directory
        cd "$HOME"
        rm -rf "$temp_dir"
        log "yay installation cleanup completed"
    else
        log "yay is already installed"
    fi
}

# Handle package provider selection for AUR packages
select_aur_provider() {
    local package="$1"
    log "Searching for AUR package: $package"
    
    # Get available packages matching the name
    local available_packages
    available_packages=$(yay -Ss "^$package$" 2>/dev/null | grep -E "^(aur|repo)/" | cut -d'/' -f2 | cut -d' ' -f1 | sort -u)
    
    if [[ -z "$available_packages" ]]; then
        # Try fuzzy search if exact match fails
        available_packages=$(yay -Ss "$package" 2>/dev/null | grep -E "^aur/" | head -5 | cut -d'/' -f2 | cut -d' ' -f1)
        
        if [[ -z "$available_packages" ]]; then
            warn "No AUR packages found for: $package"
            return 1
        else
            warn "Exact match not found, found similar packages: $available_packages"
            # Take the first match for automated installation
            package=$(echo "$available_packages" | head -n1)
            log "Auto-selecting: $package"
        fi
    fi
    
    echo "$package"
}

# Handle package alternatives and special cases
get_package_alternative() {
    local package="$1"
    
    case "$package" in
        "network-manager-applet")
            # Try different variations
            if package_exists_in_pacman "networkmanager-applet"; then
                echo "networkmanager-applet"
            elif package_exists_in_pacman "nm-applet"; then
                echo "nm-applet"
            else
                echo "$package"
            fi
            ;;
        "pulseaudio-bluetooth")
            # Check if pipewire setup is used instead
            if pacman -Q pipewire &> /dev/null; then
                if package_exists_in_pacman "pipewire-pulse"; then
                    echo "pipewire-pulse"
                else
                    echo "$package"
                fi
            else
                echo "$package"
            fi
            ;;
        "nordic-theme")
            # Nordic theme might be available under different names
            echo "nordic-theme"
            ;;
        *)
            echo "$package"
            ;;
    esac
}

# Check if package exists in pacman repos
package_exists_in_pacman() {
    local package="$1"
    pacman -Si "$package" &> /dev/null
}

# Smart package installation - tries pacman first, then yay
install_package_smart() {
    local package="$1"
    
    # Skip if already installed
    if pacman -Q "$package" &> /dev/null; then
        return 0
    fi
    
    # Try pacman first
    if package_exists_in_pacman "$package"; then
        log "Installing $package via pacman..."
        if sudo pacman -S --needed --noconfirm "$package"; then
            return 0
        else
            warn "Failed to install $package via pacman, trying AUR..."
        fi
    fi
    
    # Try yay if pacman fails or package not in repos
    log "Trying to install $package via AUR..."
    local selected_package
    selected_package=$(select_aur_provider "$package")
    
    if [[ -n "$selected_package" ]]; then
        log "Installing $selected_package via yay..."
        if yay -S --needed --noconfirm "$selected_package"; then
            return 0
        else
            error "Failed to install $selected_package via yay"
            return 1
        fi
    else
        error "Could not find package $package in any repository"
        return 1
    fi
}

# Install packages for Arch Linux (pacman)
install_arch_packages() {
    log "Detected Arch Linux, using pacman..."
    
    local all_packages=(
        "hyprland"
        "waybar"
        "rofi"
        "nautilus"
        "gnome-text-editor"
        "btop"
        "blueberry"
        "dunst"
        "grim"
        "slurp"
        "satty"
        "wl-clipboard"
        "swaybg"
        "mako"
        "pavucontrol"
        "brightnessctl"
        "playerctl"
        "pamixer"
        "pulsemixer"
        "polkit"
        "xdg-desktop-portal-hyprland"
        "qt6-wayland"
        "bluez-utils"
        "wiremix"
        "impala"
        "gvfs"
        "gvfs-mtp"
        "file-roller"
        "evince"
        "mpv"
        "imv"
        "tree"
        "wget"
        "curl"
        "xdg-user-dirs"
        "xdg-utils"
        "man-db"
        "man-pages"
        "cups"
        "cups-pdf"
        "system-config-printer"
        "gtk2"
        "gtk3"
        "gtk4"
        "gtk-engines"
        "sddm"
        "sddm-kcm"
        "alacritty"
        "uwsm"
        "sddm-theme-sugar-candy"
        "google-chrome"
        "hyprpicker"
        "swaylock-effects"
        "wlogout"
        "hyprshot"
        "wl-clip-persist"
        "wlsunset"
    )
    
    local aur_only_packages=(
        "sddm-theme-corners-git"
    )
    
    # Update system
    log "Updating system packages..."
    sudo pacman -Syu --noconfirm
    
    # Install yay first (needed for smart installation)
    install_yay
    
    # Separate packages into pacman and AUR based on availability
    local pacman_packages=()
    local fallback_to_aur=()
    
    log "🔍 Checking package availability in official repositories..."
    for package in "${all_packages[@]}"; do
        if ! pacman -Q "$package" &> /dev/null; then
            # Check for package alternatives
            local alt_package
            alt_package=$(get_package_alternative "$package")
            
            if package_exists_in_pacman "$alt_package"; then
                if [[ "$alt_package" != "$package" ]]; then
                    log "📦 Using alternative: $alt_package (instead of $package)"
                else
                    log "✅ Found in pacman: $package"
                fi
                pacman_packages+=("$alt_package")
            else
                warn "⚠️  $package not in official repos → will try AUR"
                fallback_to_aur+=("$package")
            fi
        else
            log "⏭️  Already installed: $package"
        fi
    done
    
    # Install packages from official repos first (PACMAN FIRST)
    if [[ ${#pacman_packages[@]} -gt 0 ]]; then
        log "📥 Installing ${#pacman_packages[@]} packages from official repositories..."
        log "Packages: ${pacman_packages[*]}"
        if sudo pacman -S --needed --noconfirm "${pacman_packages[@]}"; then
            log "✅ Successfully installed all pacman packages"
        else
            warn "⚠️  Some packages failed in batch install, retrying individually..."
            # Retry failed packages individually with smart fallback
            for package in "${pacman_packages[@]}"; do
                if ! pacman -Q "$package" &> /dev/null; then
                    log "🔄 Retrying: $package (will use AUR if pacman fails)"
                    install_package_smart "$package"
                fi
            done
        fi
    else
        log "✅ All official repository packages are already installed"
    fi
    
    # Install packages that need AUR (FALLBACK + AUR-ONLY)
    local all_aur_packages=("${fallback_to_aur[@]}" "${aur_only_packages[@]}")
    local missing_aur=()
    
    for package in "${all_aur_packages[@]}"; do
        if ! yay -Q "$package" &> /dev/null; then
            missing_aur+=("$package")
        fi
    done
    
    if [[ ${#missing_aur[@]} -gt 0 ]]; then
        log "🏗️  Installing ${#missing_aur[@]} packages from AUR (includes pacman fallbacks)..."
        log "AUR packages: ${missing_aur[*]}"
        for package in "${missing_aur[@]}"; do
            log "📦 Installing $package from AUR..."
            
            # Handle special cases and provider selection
            local selected_package
            selected_package=$(select_aur_provider "$package")
            
            if [[ -n "$selected_package" ]]; then
                if yay -S --needed --noconfirm "$selected_package"; then
                    log "✅ Successfully installed $selected_package"
                else
                    error "❌ Failed to install $selected_package from AUR"
                    # Continue with other packages instead of failing completely
                fi
            else
                error "❌ Could not find AUR package: $package"
                # Continue with other packages
            fi
        done
    else
        log "✅ All AUR packages are already installed"
    fi
    
    # Summary of installation
    log "📊 Package installation summary:"
    local total_installed=0
    local total_failed=0
    
    for package in "${all_packages[@]}" "${aur_only_packages[@]}"; do
        if pacman -Q "$package" &> /dev/null || yay -Q "$package" &> /dev/null; then
            ((total_installed++))
        else
            ((total_failed++))
            warn "Package not installed: $package"
        fi
    done
    
    log "Successfully installed: $total_installed packages"
    if [[ $total_failed -gt 0 ]]; then
        warn "Failed to install: $total_failed packages"
    fi
}



# Enable services
enable_services() {
    log "Enabling necessary services..."
    
    # Enable SDDM if not already enabled
    if systemctl list-unit-files | grep -q "sddm.service"; then
        if ! systemctl is-enabled sddm &> /dev/null; then
            sudo systemctl enable sddm
            log "SDDM display manager enabled"
        else
            log "SDDM is already enabled"
        fi
    fi
    
    # Enable CUPS printing service if not already active
    if systemctl list-unit-files | grep -q "cups.service"; then
        if ! systemctl is-active --quiet cups; then
            sudo systemctl enable --now cups
            log "CUPS printing service enabled and started"
        else
            log "CUPS printing service is already running"
        fi
    fi
}

# Main installation function
main() {
    log "Starting dependency installation..."
    
    # Ensure we start from a safe directory
    cd "$HOME" || {
        error "Cannot access home directory"
        exit 1
    }
    
    # Create essential directories first
    create_system_directories
    
    local package_manager=$(detect_package_manager)
    
    case $package_manager in
        "pacman")
            install_arch_packages
            ;;
        *)
            error "This minimal installer only supports Arch Linux"
            error "Please install dependencies manually or use the full installer"
            exit 1
            ;;
    esac
    
    enable_services
    
    log "Dependencies installation completed!"
}

# Run main function
main "$@"
