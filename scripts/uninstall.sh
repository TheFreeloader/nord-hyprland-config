#!/bin/bash

# Uninstall Script for Nord Hyprland Config
# This script removes installed configurations and restores backups

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log() {
    echo -e "${GREEN}[UNINSTALL]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[UNINSTALL]${NC} $1"
}

error() {
    echo -e "${RED}[UNINSTALL]${NC} $1"
}

# List available backups
list_backups() {
    local backup_dirs=($(find "$HOME" -maxdepth 1 -name ".config_backup_*" -type d 2>/dev/null))
    
    if [[ ${#backup_dirs[@]} -eq 0 ]]; then
        error "No backup directories found"
        exit 1
    fi
    
    echo "Available backup directories:"
    for i in "${!backup_dirs[@]}"; do
        echo "$((i+1))) $(basename "${backup_dirs[$i]}")"
    done
    
    echo ""
    read -p "Select backup to restore (number): " choice
    
    if [[ "$choice" -ge 1 && "$choice" -le ${#backup_dirs[@]} ]]; then
        echo "${backup_dirs[$((choice-1))]}"
    else
        error "Invalid selection"
        exit 1
    fi
}

# Remove current configs
remove_configs() {
    local configs=("hypr" "waybar" "rofi" "alacritty" "btop")
    
    log "Removing current configurations..."
    
    for config in "${configs[@]}"; do
        local config_path="$HOME/.config/$config"
        if [[ -d "$config_path" ]]; then
            log "Removing $config configuration..."
            rm -rf "$config_path"
        fi
    done
}

# Restore backup
restore_backup() {
    local backup_dir="$1"
    
    if [[ ! -d "$backup_dir" ]]; then
        error "Backup directory does not exist: $backup_dir"
        exit 1
    fi
    
    log "Restoring configurations from backup..."
    
    # Restore .config files
    if [[ -d "$backup_dir/.config" ]]; then
        cp -r "$backup_dir/.config"/* "$HOME/.config/" 2>/dev/null || true
        log "Configuration files restored"
    fi
    
    # Restore themes
    if [[ -d "$backup_dir/.themes" ]]; then
        cp -r "$backup_dir/.themes" "$HOME/" 2>/dev/null || true
        log "Themes restored"
    fi
    
    if [[ -d "$backup_dir/.local/share/themes" ]]; then
        mkdir -p "$HOME/.local/share"
        cp -r "$backup_dir/.local/share/themes" "$HOME/.local/share/" 2>/dev/null || true
        log "Local themes restored"
    fi
}

# Remove themes
remove_themes() {
    log "Removing Nord themes..."
    
    # Remove Nordic theme
    rm -rf "$HOME/.themes/Nordic" 2>/dev/null || true
    rm -rf "$HOME/.local/share/themes/Nordic" 2>/dev/null || true
    
    # Remove cursor theme
    rm -rf "$HOME/.local/share/icons/Nordic-cursors" 2>/dev/null || true
    
    # Remove GTK configurations
    rm -f "$HOME/.config/gtk-3.0/settings.ini" 2>/dev/null || true
    rm -f "$HOME/.config/gtk-4.0/settings.ini" 2>/dev/null || true
    rm -f "$HOME/.gtkrc-2.0" 2>/dev/null || true
    
    log "Themes removed"
}

# Remove environment configurations
remove_environment() {
    log "Removing environment configurations..."
    
    rm -f "$HOME/.config/environment.d/hyprland.conf" 2>/dev/null || true
    
    log "Environment configurations removed"
}

# Remove utility scripts
remove_scripts() {
    log "Removing utility scripts..."
    
    rm -f "$HOME/.local/bin/screenshot" 2>/dev/null || true
    rm -f "$HOME/.local/bin/change-wallpaper" 2>/dev/null || true
    
    log "Utility scripts removed"
}

# Remove autostart entries
remove_autostart() {
    log "Removing autostart entries..."
    
    rm -f "$HOME/.config/autostart/nm-applet.desktop" 2>/dev/null || true
    rm -f "$HOME/.config/autostart/blueman-applet.desktop" 2>/dev/null || true
    
    log "Autostart entries removed"
}

# Show uninstall menu
show_uninstall_menu() {
    echo ""
    echo -e "${BLUE}╔══════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║              Nord Hyprland Config Uninstaller        ║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo "Choose uninstall option:"
    echo "1) Full uninstall and restore from backup"
    echo "2) Remove configs only (keep themes)"
    echo "3) Remove themes only (keep configs)"
    echo "4) Remove everything (no restore)"
    echo "0) Cancel"
    echo ""
}

# Full uninstall with restore
full_uninstall_restore() {
    log "Starting full uninstall with backup restore..."
    
    # Select backup
    local backup_dir=$(list_backups)
    
    # Remove current configs
    remove_configs
    remove_themes
    remove_environment
    remove_scripts
    remove_autostart
    
    # Restore backup
    restore_backup "$backup_dir"
    
    log "Full uninstall and restore completed!"
}

# Remove configs only
remove_configs_only() {
    log "Removing configurations only..."
    
    remove_configs
    remove_environment
    remove_scripts
    remove_autostart
    
    log "Configurations removed!"
}

# Remove themes only
remove_themes_only() {
    log "Removing themes only..."
    
    remove_themes
    
    log "Themes removed!"
}

# Remove everything
remove_everything() {
    warn "This will remove everything without restoring backups!"
    read -p "Are you sure? (y/N): " confirm
    
    if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
        log "Removing everything..."
        
        remove_configs
        remove_themes
        remove_environment
        remove_scripts
        remove_autostart
        
        log "Everything removed!"
    else
        log "Operation cancelled"
    fi
}

# Main function
main() {
    while true; do
        show_uninstall_menu
        read -p "Enter your choice: " choice
        
        case $choice in
            1)
                full_uninstall_restore
                break
                ;;
            2)
                remove_configs_only
                break
                ;;
            3)
                remove_themes_only
                break
                ;;
            4)
                remove_everything
                break
                ;;
            0)
                log "Uninstall cancelled."
                exit 0
                ;;
            *)
                error "Invalid option. Please choose 0-4."
                ;;
        esac
    done
    
    echo ""
    echo -e "${GREEN}════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}Uninstall completed! You may want to restart your session.${NC}"
    echo -e "${GREEN}════════════════════════════════════════════════════════${NC}"
}

# Run main function
main "$@"
