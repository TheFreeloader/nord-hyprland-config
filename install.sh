#!/bin/bash

# Nord Hyprland Config - Minimal Installation Script
# Author: TheFreeloader
# Description: Minimal automatic installer for Arch Linux users

# Remove set -e to handle errors gracefully
# set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_DIR="$SCRIPT_DIR/scripts"

# Validate scripts directory exists
if [[ ! -d "$SCRIPTS_DIR" ]]; then
    echo -e "${RED}[ERROR]${NC} Scripts directory not found: $SCRIPTS_DIR"
    echo -e "${RED}[ERROR]${NC} Make sure you're running this script from the nord-hyprland-config directory"
    exit 1
fi

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

# Enhanced logging with timestamps
log_with_time() {
    echo -e "${GREEN}[$(date '+%H:%M:%S')] [INFO]${NC} $1"
}

warn_with_time() {
    echo -e "${YELLOW}[$(date '+%H:%M:%S')] [WARN]${NC} $1"
}

error_with_time() {
    echo -e "${RED}[$(date '+%H:%M:%S')] [ERROR]${NC} $1"
}

# Function to run scripts with error handling
run_script() {
    local script_path="$1"
    local script_name="$2"
    local description="$3"
    shift 3  # Remove first 3 arguments, rest are script arguments
    
    log_with_time "Starting: $description"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    if [[ ! -f "$script_path" ]]; then
        error_with_time "Script not found: $script_path"
        return 1
    fi
    
    if [[ ! -x "$script_path" ]]; then
        error_with_time "Script not executable: $script_path"
        log "Making script executable..."
        chmod +x "$script_path"
    fi
    
    log_with_time "Executing: $script_name"
    if bash "$script_path" "$@"; then
        log_with_time "✅ SUCCESS: $description completed"
        echo ""
        return 0
    else
        local exit_code=$?
        error_with_time "❌ FAILED: $description (exit code: $exit_code)"
        warn_with_time "Continuing with next step..."
        echo ""
        return $exit_code
    fi
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
    local failed_steps=()
    local success_steps=()
    
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
    echo -e "${BLUE}║  Automatically installs: packages, configs, themes  ║${NC}"
    echo -e "${BLUE}║  Session management handled externally              ║${NC}"
    echo -e "${BLUE}║                                                      ║${NC}"
    echo -e "${BLUE}║  Enhanced with detailed logging and error recovery  ║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    log_with_time "Starting minimal installation for Arch Linux..."
    local start_time=$(date +%s)
    
    # Create backup
    backup_dir=$(create_backup)
    
    # Step 1: Install dependencies
    if run_script "$SCRIPTS_DIR/install-dependencies.sh" "install-dependencies.sh" "Dependencies Installation"; then
        success_steps+=("Dependencies")
    else
        failed_steps+=("Dependencies")
    fi
    
    # Step 2: Install configs
    if run_script "$SCRIPTS_DIR/install-configs.sh" "install-configs.sh" "Configuration Files Installation" "$backup_dir"; then
        success_steps+=("Configurations")
    else
        failed_steps+=("Configurations")
    fi
    
    # Step 3: Install themes
    if run_script "$SCRIPTS_DIR/install-themes.sh" "install-themes.sh" "Themes Installation" "$backup_dir"; then
        success_steps+=("Themes")
    else
        failed_steps+=("Themes")
    fi
    
    # Step 4: Post-installation setup
    if run_script "$SCRIPTS_DIR/post-install-setup.sh" "post-install-setup.sh" "Post-Installation Setup"; then
        success_steps+=("Post-Installation Setup")
    else
        failed_steps+=("Post-Installation Setup")
    fi
    
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    local minutes=$((duration / 60))
    local seconds=$((duration % 60))
    
    echo ""
    echo -e "${BLUE}════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}Installation Summary${NC}"
    echo -e "${BLUE}════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}Total time: ${minutes}m ${seconds}s${NC}"
    echo ""
    
    if [[ ${#success_steps[@]} -gt 0 ]]; then
        echo -e "${GREEN}✅ Successful steps (${#success_steps[@]}):${NC}"
        for step in "${success_steps[@]}"; do
            echo -e "   ${GREEN}▸${NC} $step"
        done
        echo ""
    fi
    
    if [[ ${#failed_steps[@]} -gt 0 ]]; then
        echo -e "${RED}❌ Failed steps (${#failed_steps[@]}):${NC}"
        for step in "${failed_steps[@]}"; do
            echo -e "   ${RED}▸${NC} $step"
        done
        echo ""
        warn_with_time "Some steps failed, but installation continued"
        echo -e "${YELLOW}You may need to run the failed steps manually${NC}"
    fi
    
    if [[ ${#failed_steps[@]} -eq 0 ]]; then
        echo -e "${GREEN}🎉 Installation completed successfully!${NC}"
    else
        echo -e "${YELLOW}⚠️  Installation completed with ${#failed_steps[@]} warnings${NC}"
    fi
    
    echo ""
    echo -e "${BLUE}Next steps:${NC}"
    echo "1. Check the output above for any failed steps"
    echo "2. Reboot your system"
    echo "3. Select Hyprland at login screen"
    echo "4. Enjoy your Nord-themed setup!"
    echo ""
    echo -e "${YELLOW}Backup created at: $backup_dir${NC}"
    echo -e "${BLUE}Log saved for debugging purposes${NC}"
}

# Run main function
main "$@"
