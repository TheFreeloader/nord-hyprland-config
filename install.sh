#!/bin/bash

# Nord Hyprland Config - Minimal Installation Script
# Author: TheFreeloader
# Description: Minimal automatic installer for Arch Linux users

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_DIR="$SCRIPT_DIR/scripts"

# Log function
log() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root
check_root() {
    if [[ $EUID -eq 0 ]]; then
        error "This script should not be run as root!"
        exit 1
    fi
}

# Check if Arch Linux
check_arch() {
    if [[ ! -f /etc/arch-release ]]; then
        error "This minimal installer only supports Arch Linux"
        error "Please use the full installer for other distributions"
        exit 1
    fi
}

# Create backup directory
create_backup() {
    local backup_dir="$HOME/.config_backup_$(date +%Y%m%d_%H%M%S)"
    log "Creating backup directory: $backup_dir"
    mkdir -p "$backup_dir"
    echo "$backup_dir"
}

# Main installation function
main() {
    check_root
    check_arch
    
    # Check if scripts directory exists
    if [[ ! -d "$SCRIPTS_DIR" ]]; then
        error "Scripts directory not found: $SCRIPTS_DIR"
        exit 1
    fi
    
    echo ""
    echo -e "${BLUE}╔══════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║         Nord Hyprland Config - Minimal Installer    ║${NC}"
    echo -e "${BLUE}║                    Arch Linux Only                   ║${NC}"
    echo -e "${BLUE}║                                                      ║${NC}"
    echo -e "${BLUE}║  Automatically installs: yay, packages, configs,    ║${NC}"
    echo -e "${BLUE}║  themes, and enables network/bluetooth services     ║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    log "Starting minimal installation for Arch Linux..."
    
    # Create backup
    backup_dir=$(create_backup)
    
    # Install dependencies
    log "Installing dependencies..."
    bash "$SCRIPTS_DIR/install-dependencies.sh"
    
    # Install configs
    log "Installing configurations..."
    bash "$SCRIPTS_DIR/install-configs.sh" "$backup_dir"
    
    # Install themes
    log "Installing themes..."
    bash "$SCRIPTS_DIR/install-themes.sh" "$backup_dir"
    
    # Post-installation setup
    log "Running post-installation setup..."
    bash "$SCRIPTS_DIR/post-install-setup.sh"
    
    echo ""
    echo -e "${GREEN}════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}Installation completed successfully! 🎉${NC}"
    echo -e "${GREEN}════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "${BLUE}Next steps:${NC}"
    echo "1. Reboot your system"
    echo "2. Select Hyprland at login screen"
    echo "3. Enjoy your Nord-themed setup!"
    echo ""
    echo -e "${YELLOW}Backup created at: $backup_dir${NC}"
}

# Run main function
main "$@"
