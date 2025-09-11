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

# Parent directory (project root) - more robust resolution  
if [[ -n "$SCRIPT_DIR" && -d "$SCRIPT_DIR" ]]; then
    PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd 2>/dev/null)"
else
    # Fallback: assume we're in the scripts directory
    PROJECT_ROOT="$(cd .. && pwd 2>/dev/null)"
fi

# Source config directory with fallback
if [[ -n "$PROJECT_ROOT" && -d "$PROJECT_ROOT/.config" ]]; then
    CONFIG_SOURCE_DIR="$PROJECT_ROOT/.config"
else
    # Fallback to relative path
    CONFIG_SOURCE_DIR="../.config"
fi

log() {
    echo -e "${GREEN}[CONFIG]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[CONFIG]${NC} $1"
}

error() {
    echo -e "${RED}[CONFIG]${NC} $1"
}

# Validate that source directory exists
validate_source_directory() {
    if [[ ! -d "$CONFIG_SOURCE_DIR" ]]; then
        error "Config source directory not found: $CONFIG_SOURCE_DIR"
        error "Make sure you're running this script from the correct location"
        error "Expected structure: nord-hyprland-config/.config/ should exist"
        return 1
    fi
    log "Source config directory found: $CONFIG_SOURCE_DIR"
    return 0
}

# Ensure directory exists before operations
ensure_directory() {
    local dir="$1"
    if [[ ! -d "$dir" ]]; then
        log "Creating directory: $dir"
        mkdir -p "$dir" || {
            error "Failed to create directory: $dir"
            return 1
        }
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
    
    # Remove existing config if it exists to avoid nested directories
    if [[ -d "$target_path" ]]; then
        rm -rf "$target_path"
    fi
    
    # Create parent directory
    mkdir -p "$(dirname "$target_path")"
    
    # Copy config contents (not the directory itself)
    cp -r "$source_path" "$target_path"
    
    log "$config_name config installed successfully"
}

# Install all configs or specific ones based on parameters
main() {
    # Ensure we start from a safe directory
    cd "$HOME" || {
        error "Cannot access home directory"
        exit 1
    }
    
    # Validate source directory exists
    if ! validate_source_directory; then
        exit 1
    fi
    
    log "Starting configuration installation..."
    
    # Ensure all necessary directories exist
    ensure_directory "$HOME/.config"
    
    # Copy entire config directory at once to avoid nesting issues
    log "Installing all configuration files..."
    
    # Remove existing configs to avoid conflicts
    for config_dir in hypr waybar rofi alacritty btop; do
        if [[ -d "$HOME/.config/$config_dir" ]]; then
            log "Removing existing $config_dir config to avoid conflicts..."
            rm -rf "$HOME/.config/$config_dir"
        fi
    done
    
    # Copy all configs from source
    if [[ -d "$CONFIG_SOURCE_DIR" ]]; then
        log "Copying configuration files from $CONFIG_SOURCE_DIR"
        cp -r "$CONFIG_SOURCE_DIR"/* "$HOME/.config/" 2>/dev/null || {
            warn "Some config files may not have been copied"
        }
        log "Configuration files installed successfully"
    else
        error "Source configuration directory not found: $CONFIG_SOURCE_DIR"
        exit 1
    fi
    
    log "Configuration installation completed!"
    
    # Post-installation notes
    echo ""
    echo -e "${BLUE}Post-installation notes:${NC}"
    echo "• Hyprland: Make sure to set up your monitors in hyprland.conf"
    echo "• Waybar: Adjust network interface names if needed"
    echo "• Rofi: Theme should work out of the box"
    echo "• Alacritty: Font configuration included"
    echo "• btop: Nordic theme applied"
}

# Run main function
main "$@"
