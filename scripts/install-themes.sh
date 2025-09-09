#!/bin/bash

# Themes Installation Script for Nord Hyprland Config
# This script installs GTK themes, icon themes, and cursor themes

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
THEMES_SOURCE_DIR="$(dirname "$SCRIPT_DIR")/.themes"
BACKUP_DIR="$1"

log() {
    echo -e "${GREEN}[THEMES]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[THEMES]${NC} $1"
}

error() {
    echo -e "${RED}[THEMES]${NC} $1"
}

# Backup existing themes
backup_themes() {
    if [[ -d "$HOME/.themes" ]]; then
        log "Backing up existing .themes directory..."
        cp -r "$HOME/.themes" "$BACKUP_DIR/" 2>/dev/null || true
    fi
    
    if [[ -d "$HOME/.local/share/themes" ]]; then
        log "Backing up existing local themes..."
        mkdir -p "$BACKUP_DIR/.local/share"
        cp -r "$HOME/.local/share/themes" "$BACKUP_DIR/.local/share/" 2>/dev/null || true
    fi
}

# Install themes from .themes directory
install_themes() {
    if [[ ! -d "$THEMES_SOURCE_DIR" ]]; then
        warn "Themes directory not found: $THEMES_SOURCE_DIR"
        return 1
    fi
    
    log "Installing themes from .themes directory..."
    
    # Create themes directories
    mkdir -p "$HOME/.themes"
    mkdir -p "$HOME/.local/share/themes"
    
    # Copy themes
    cp -r "$THEMES_SOURCE_DIR"/* "$HOME/.themes/" 2>/dev/null || true
    cp -r "$THEMES_SOURCE_DIR"/* "$HOME/.local/share/themes/" 2>/dev/null || true
    
    log "Themes installed successfully"
}

# Download and install Nordic theme (if not present)
install_nordic_theme() {
    local nordic_theme_dir="$HOME/.themes/Nordic"
    
    # Check if Nordic theme is already installed via package manager
    if pacman -Q nordic-theme &> /dev/null; then
        log "Nordic theme is already installed via pacman"
        
        # Copy from system location to user location if needed
        if [[ -d "/usr/share/themes/Nordic" && ! -d "$nordic_theme_dir" ]]; then
            cp -r "/usr/share/themes/Nordic" "$HOME/.themes/"
            cp -r "/usr/share/themes/Nordic" "$HOME/.local/share/themes/" 2>/dev/null || true
            log "Nordic theme copied to user directories"
        fi
    elif [[ ! -d "$nordic_theme_dir" ]]; then
        log "Downloading Nordic GTK theme..."
        
        # Create temporary directory
        local temp_dir=$(mktemp -d)
        
        # Download Nordic theme
        if command -v git &> /dev/null; then
            git clone https://github.com/EliverLara/Nordic.git "$temp_dir/Nordic"
            
            # Copy theme
            cp -r "$temp_dir/Nordic" "$HOME/.themes/"
            cp -r "$temp_dir/Nordic" "$HOME/.local/share/themes/"
            
            # Cleanup
            rm -rf "$temp_dir"
            
            log "Nordic theme installed successfully"
        else
            warn "Git not found. Please install Nordic theme manually"
            warn "https://github.com/EliverLara/Nordic"
        fi
    else
        log "Nordic theme already exists"
    fi
}

# Install Papirus icon theme (if not present)
install_papirus_icons() {
    if pacman -Q papirus-icon-theme &> /dev/null; then
        log "Papirus icon theme is already installed"
        
        # Set Nordic color variant if papirus-folders is available
        if command -v papirus-folders &> /dev/null; then
            papirus-folders -C nordic --theme Papirus-Dark || warn "Failed to set Nordic color scheme"
            log "Papirus icons set to Nordic color scheme"
        fi
    else
        warn "Papirus icon theme not found. Please install it manually with: pacman -S papirus-icon-theme"
    fi
}

# Configure GTK settings
configure_gtk_settings() {
    log "Configuring GTK settings..."
    
    # GTK3 settings
    local gtk3_config="$HOME/.config/gtk-3.0/settings.ini"
    mkdir -p "$(dirname "$gtk3_config")"
    
    cat > "$gtk3_config" << EOF
[Settings]
gtk-theme-name=Nordic
gtk-icon-theme-name=Papirus-Dark
gtk-font-name=JetBrains Mono 10
gtk-cursor-theme-name=Nordic-cursors
gtk-cursor-theme-size=24
gtk-toolbar-style=GTK_TOOLBAR_BOTH_HORIZ
gtk-toolbar-icon-size=GTK_ICON_SIZE_LARGE_TOOLBAR
gtk-button-images=0
gtk-menu-images=0
gtk-enable-event-sounds=1
gtk-enable-input-feedback-sounds=0
gtk-xft-antialias=1
gtk-xft-hinting=1
gtk-xft-hintstyle=hintfull
gtk-xft-rgba=rgb
gtk-application-prefer-dark-theme=1
EOF
    
    # GTK4 settings
    local gtk4_config="$HOME/.config/gtk-4.0/settings.ini"
    mkdir -p "$(dirname "$gtk4_config")"
    
    cat > "$gtk4_config" << EOF
[Settings]
gtk-theme-name=Nordic
gtk-icon-theme-name=Papirus-Dark
gtk-font-name=JetBrains Mono 10
gtk-cursor-theme-name=Nordic-cursors
gtk-cursor-theme-size=24
gtk-application-prefer-dark-theme=1
EOF
    
    # GTK2 settings
    cat > "$HOME/.gtkrc-2.0" << EOF
gtk-theme-name="Nordic"
gtk-icon-theme-name="Papirus-Dark"
gtk-font-name="JetBrains Mono 10"
gtk-cursor-theme-name="Nordic-cursors"
gtk-cursor-theme-size=24
gtk-toolbar-style=GTK_TOOLBAR_BOTH_HORIZ
gtk-toolbar-icon-size=GTK_ICON_SIZE_LARGE_TOOLBAR
gtk-button-images=0
gtk-menu-images=0
gtk-enable-event-sounds=1
gtk-enable-input-feedback-sounds=0
gtk-xft-antialias=1
gtk-xft-hinting=1
gtk-xft-hintstyle="hintfull"
gtk-xft-rgba="rgb"
EOF
    
    log "GTK settings configured"
}

# Install cursor theme
install_cursor_theme() {
    log "Installing Nordic cursor theme..."
    
    local cursor_theme_dir="$HOME/.local/share/icons/Nordic-cursors"
    
    if [[ ! -d "$cursor_theme_dir" ]]; then
        local temp_dir=$(mktemp -d)
        
        if command -v git &> /dev/null; then
            git clone https://github.com/alvatip/Nordzy-cursors.git "$temp_dir/cursors"
            
            # Create icons directory
            mkdir -p "$HOME/.local/share/icons"
            
            # Copy cursor theme (assuming Nordzy has a Nordic variant)
            if [[ -d "$temp_dir/cursors/Nordzy-cursors" ]]; then
                cp -r "$temp_dir/cursors/Nordzy-cursors" "$HOME/.local/share/icons/Nordic-cursors"
            fi
            
            rm -rf "$temp_dir"
            log "Nordic cursor theme installed"
        else
            warn "Git not found. Please install cursor theme manually"
        fi
    else
        log "Nordic cursor theme already exists"
    fi
}

# Main function
main() {
    if [[ -z "$BACKUP_DIR" ]]; then
        error "Backup directory not provided"
        exit 1
    fi
    
    log "Starting themes installation..."
    log "Backup directory: $BACKUP_DIR"
    
    # Backup existing themes
    backup_themes
    
    # Install themes
    install_themes
    install_nordic_theme
    install_papirus_icons
    install_cursor_theme
    
    # Configure GTK settings
    configure_gtk_settings
    
    log "Themes installation completed!"
    
    # Post-installation notes
    echo ""
    echo -e "${BLUE}Theme installation notes:${NC}"
    echo "• GTK theme: Nordic (dark variant)"
    echo "• Icon theme: Papirus-Dark with Nordic colors"
    echo "• Cursor theme: Nordic cursors"
    echo "• Font: JetBrains Mono"
    echo ""
    echo "You may need to restart applications or re-login for themes to take effect"
}

# Run main function
main "$@"
