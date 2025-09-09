#!/bin/bash

# Configuration Files Installation Script for Nord Hyprland Config
# This script copies configuration files to their appropriate locations

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_SOURCE_DIR="$(dirname "$SCRIPT_DIR")/.config"
BACKUP_DIR="$1"

log() {
    echo -e "${GREEN}[CONFIG]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[CONFIG]${NC} $1"
}

error() {
    echo -e "${RED}[CONFIG]${NC} $1"
}

# Backup existing config
backup_config() {
    local config_name="$1"
    local config_path="$HOME/.config/$config_name"
    
    if [[ -d "$config_path" ]] || [[ -f "$config_path" ]]; then
        log "Backing up existing $config_name config..."
        cp -r "$config_path" "$BACKUP_DIR/" 2>/dev/null || true
    fi
}

# Install specific config
install_config() {
    local config_name="$1"
    local source_path="$CONFIG_SOURCE_DIR/$config_name"
    local target_path="$HOME/.config/$config_name"
    
    if [[ ! -d "$source_path" ]]; then
        warn "$config_name config not found in source directory"
        return 1
    fi
    
    log "Installing $config_name config..."
    
    # Backup existing config
    backup_config "$config_name"
    
    # Create parent directory
    mkdir -p "$(dirname "$target_path")"
    
    # Copy config
    cp -r "$source_path" "$target_path"
    
    log "$config_name config installed successfully"
}

# Install all configs or specific ones based on parameters
main() {
    if [[ -z "$BACKUP_DIR" ]]; then
        error "Backup directory not provided"
        exit 1
    fi
    
    log "Starting configuration installation..."
    log "Backup directory: $BACKUP_DIR"
    
    # Create .config directory if it doesn't exist
    mkdir -p "$HOME/.config"
    
    # Install all configurations
    install_config "hypr"
    install_config "waybar"
    install_config "rofi"
    install_config "alacritty"
    install_config "btop"
    
    log "Configuration installation completed!"
    
    # Post-installation notes
    echo ""
    echo -e "${BLUE}Post-installation notes:${NC}"
    echo "• Hyprland: Make sure to set up your monitors in hyprland.conf"
    echo "• Waybar: Adjust network interface names if needed"
    echo "• Rofi: Theme should work out of the box"
    echo "• Alacritty: Font configuration included"
    echo "• btop: Nordic theme applied"
    echo ""
    echo "All original configs have been backed up to: $BACKUP_DIR"
}

# Run main function
main "$@"
