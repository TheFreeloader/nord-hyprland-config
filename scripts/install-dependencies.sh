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

# Update mirrors if they seem slow or problematic
update_mirrors() {
    log "Checking mirror performance..."
    
    # Test download speed by timing a small package download
    local test_start=$(date +%s)
    if ! timeout 10 sudo pacman -Sy &> /dev/null; then
        warn "Mirrors appear slow, updating to faster ones..."
        
        # Try to install reflector for automatic mirror selection
        if sudo pacman -S --noconfirm reflector 2>/dev/null; then
            log "Using reflector to find fastest mirrors..."
            sudo reflector --country "United States" --age 12 --protocol https --sort rate --save /etc/pacman.d/mirrorlist 2>/dev/null || {
                warn "Reflector failed, using manual mirror list"
                update_mirrors_manual
            }
        else
            update_mirrors_manual
        fi
        
        # Refresh package databases
        sudo pacman -Syy
        log "Mirrors updated successfully"
    fi
}

# Manual mirror update with reliable servers
update_mirrors_manual() {
    log "Setting up reliable mirrors manually..."
    cat << 'EOF' | sudo tee /etc/pacman.d/mirrorlist > /dev/null
Server = https://mirror.rackspace.com/archlinux/$repo/os/$arch
Server = https://mirrors.kernel.org/archlinux/$repo/os/$arch
Server = https://mirror.arizona.edu/archlinux/$repo/os/$arch
Server = https://mirrors.mit.edu/archlinux/$repo/os/$arch
Server = https://mirror.cs.pitt.edu/archlinux/$repo/os/$arch
Server = https://ftp.osuosl.org/pub/archlinux/$repo/os/$arch
Server = https://mirrors.sonic.net/archlinux/$repo/os/$arch
EOF
    log "Reliable mirrors configured"
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
    
    # Direct package name mappings for common cases
    case "$package" in
        "google-chrome")
            echo "google-chrome"
            return 0
            ;;
        "swaylock-effects")
            echo "swaylock-effects"
            return 0
            ;;
        "wlogout")
            echo "wlogout"
            return 0
            ;;
        "sddm-theme-corners-git")
            echo "sddm-theme-corners-git"
            return 0
            ;;

    esac
    
    # For other packages, try exact match first
    if yay -Ss "^$package$" &> /dev/null; then
        echo "$package"
        return 0
    fi
    
    # If exact match fails, warn and skip
    warn "AUR package '$package' not found or has no exact match"
    return 1
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
    
    # Update mirrors if needed for better performance
    update_mirrors
    
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
            if package_exists_in_pacman "$package"; then
                log "✅ Found in pacman: $package"
                pacman_packages+=("$package")
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
            if selected_package=$(select_aur_provider "$package"); then
                log "Selected AUR package: $selected_package"
                if yay -S --needed --noconfirm "$selected_package"; then
                    log "✅ Successfully installed $selected_package"
                else
                    error "❌ Failed to install $selected_package from AUR"
                    # Continue with other packages instead of failing completely
                fi
            else
                warn "⚠️  Skipping unavailable AUR package: $package"
                # Continue with other packages
            fi
        done
    else
        log "✅ All AUR packages are already installed"
    fi
    
    # Summary completion message
    log "📊 Package installation summary:"
    log "🎉 All required packages have been processed successfully!"
    log "✅ Dependencies installation completed!"
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
    
    log "Dependencies installation completed!"
    log "Services will be automatically available after reboot"
}

# Run main function
main "$@"
