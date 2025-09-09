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

# Install Graphite theme via git (faster than AUR)
install_graphite_theme() {
    local graphite_theme_dir="$HOME/.themes/Graphite-nord-Dark"
    
    if [[ ! -d "$graphite_theme_dir" ]]; then
        log "Installing Graphite Nord theme via git (faster than AUR)..."
        
        # Create temporary directory
        local temp_dir=$(mktemp -d)
        
        # Download Graphite theme
        if command -v git &> /dev/null; then
            git clone https://github.com/vinceliuice/Graphite-gtk-theme.git "$temp_dir/Graphite"
            
            # Remove git metadata to avoid permission issues
            rm -rf "$temp_dir/Graphite/.git"
            
            # Install the theme with nord and dark tweaks
            cd "$temp_dir/Graphite"
            
            if [[ -f "./install.sh" ]]; then
                log "Installing Graphite with nord and dark tweaks..."
                ./install.sh -l -t -c dark -s --tweaks nord
                log "Graphite nord dark theme installed successfully"
            fi
            
            # Cleanup
            rm -rf "$temp_dir"
        else
            warn "Git not found. Please install git first"
        fi
    else
        log "Graphite nord theme already exists"
    fi
}

# Install Papirus icon theme via pacman/yay
install_papirus_icons() {
    log "Installing Papirus icon theme..."
    
    # Try pacman first, then yay
    if pacman -Q papirus-icon-theme &> /dev/null; then
        log "Papirus icon theme is already installed"
    elif pacman -S --noconfirm papirus-icon-theme 2>/dev/null; then
        log "Papirus icon theme installed via pacman"
    elif command -v yay &> /dev/null && yay -S --noconfirm papirus-icon-theme; then
        log "Papirus icon theme installed via yay"
    else
        warn "Failed to install Papirus icon theme"
    fi
    
    # Set Nordic color variant if papirus-folders is available
    if command -v papirus-folders &> /dev/null; then
        papirus-folders -C nordic --theme Papirus-Dark || warn "Failed to set Nordic color scheme"
        log "Papirus icons set to Nordic color scheme"
    elif command -v yay &> /dev/null; then
        # Install papirus-folders from AUR
        yay -S --noconfirm papirus-folders-git 2>/dev/null || yay -S --noconfirm papirus-folders 2>/dev/null || true
        if command -v papirus-folders &> /dev/null; then
            papirus-folders -C nordic --theme Papirus-Dark || warn "Failed to set Nordic color scheme"
            log "Papirus icons set to Nordic color scheme"
        fi
    fi
}

# Install fonts via pacman/yay
install_fonts() {
    log "Installing fonts..."
    
    local fonts=(
        "ttf-jetbrains-mono"
        "ttf-jetbrains-mono-nerd"
        "noto-fonts"
        "noto-fonts-emoji"
    )
    
    for font in "${fonts[@]}"; do
        if pacman -Q "$font" &> /dev/null; then
            log "$font is already installed"
        elif pacman -S --noconfirm "$font" 2>/dev/null; then
            log "$font installed via pacman"
        elif command -v yay &> /dev/null && yay -S --noconfirm "$font" 2>/dev/null; then
            log "$font installed via yay"
        else
            warn "Failed to install $font"
        fi
    done
    
    # Refresh font cache
    if command -v fc-cache &> /dev/null; then
        fc-cache -fv
        log "Font cache refreshed"
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
gtk-theme-name=Graphite-nord-Dark
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
gtk-theme-name=Graphite-nord-Dark
gtk-icon-theme-name=Papirus-Dark
gtk-font-name=JetBrains Mono 10
gtk-cursor-theme-name=Nordic-cursors
gtk-cursor-theme-size=24
gtk-application-prefer-dark-theme=1
EOF
    
    # GTK2 settings
    cat > "$HOME/.gtkrc-2.0" << EOF
gtk-theme-name="Graphite-nord-Dark"
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

# Install cursor theme via yay
install_cursor_theme() {
    log "Installing Nordic cursor theme..."
    
    # Try to install Nordic/Nordzy cursors via yay
    if command -v yay &> /dev/null; then
        if yay -S --noconfirm nordzy-cursors-git || yay -S --noconfirm nordzy-cursors; then
            log "Nordic cursor theme installed successfully via yay"
            return 0
        elif yay -S --noconfirm nordic-cursors-git || yay -S --noconfirm nordic-cursors; then
            log "Nordic cursor theme installed successfully via yay"
            return 0
        else
            warn "Failed to install Nordic cursor theme via yay"
        fi
    else
        warn "yay not found, cannot install Nordic cursor theme"
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
    install_fonts
    install_graphite_theme
    install_papirus_icons
    install_cursor_theme
    
    # Configure GTK settings
    configure_gtk_settings
    
    log "Themes installation completed!"
    
    # Post-installation notes
    echo ""
    echo -e "${BLUE}Theme installation notes:${NC}"
    echo "• GTK theme: Graphite Nord Dark"
    echo "• Icon theme: Papirus-Dark with Nordic colors"
    echo "• Cursor theme: Nordic cursors"
    echo "• Font: JetBrains Mono"
    echo ""
    echo "You may need to restart applications or re-login for themes to take effect"
}

# Run main function
main "$@"
