#!/bin/bash

# Test script to check what packages would be installed
# This script only checks and reports, doesn't install anything

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[CHECK]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[CHECK]${NC} $1"
}

echo -e "${BLUE}Nord Hyprland Config - Installation Check${NC}"
echo "This script checks what would be installed/configured"
echo ""

# Check if Arch Linux
if [[ ! -f /etc/arch-release ]]; then
    echo -e "${RED}ERROR: Not Arch Linux - installer will not work${NC}"
    exit 1
fi

log "✓ Arch Linux detected"

# Check packages that would be installed
packages=(
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
    "networkmanager"
    "network-manager-applet"
    "pulseaudio-bluetooth"
    "bluez-utils"
    "thunar"
    "thunar-volman"
    "gvfs"
    "gvfs-mtp"
    "file-roller"
    "evince"
    "mpv"
    "imv"
    "tree"
    "wget"
    "curl"
    "unzip"
    "p7zip"
    "xdg-user-dirs"
    "xdg-utils"
    "man-db"
    "man-pages"
)

aur_packages=(
    "hyprpicker"
    "swaylock-effects"
    "wlogout"
    "nordic-theme"
    "hyprshot"
    "wl-clip-persist"
    "wlsunset"
)

echo ""
echo -e "${BLUE}Package Status Check:${NC}"

missing_packages=()
for package in "${packages[@]}"; do
    if pacman -Q "$package" &> /dev/null; then
        echo -e "  ✓ ${GREEN}$package${NC} (installed)"
    else
        echo -e "  - ${YELLOW}$package${NC} (would be installed)"
        missing_packages+=("$package")
    fi
done

echo ""
echo -e "${BLUE}AUR Package Status Check:${NC}"
if command -v yay &> /dev/null; then
    missing_aur=()
    for package in "${aur_packages[@]}"; do
        if yay -Q "$package" &> /dev/null; then
            echo -e "  ✓ ${GREEN}$package${NC} (installed)"
        else
            echo -e "  - ${YELLOW}$package${NC} (would be installed via yay)"
            missing_aur+=("$package")
        fi
    done
else
    echo -e "  ! ${YELLOW}yay${NC} (not found - would be installed automatically)"
    missing_aur=("${aur_packages[@]}")
    for package in "${aur_packages[@]}"; do
        echo -e "  - ${YELLOW}$package${NC} (would be installed via yay after yay installation)"
    done
fi

echo ""
echo -e "${BLUE}Configuration Files Check:${NC}"
configs=("hypr" "waybar" "rofi" "alacritty" "btop")
for config in "${configs[@]}"; do
    if [[ -d "$HOME/.config/$config" ]]; then
        echo -e "  ! ${YELLOW}~/.config/$config${NC} (exists - would be backed up)"
    else
        echo -e "  + ${GREEN}~/.config/$config${NC} (would be created)"
    fi
done

echo ""
echo -e "${BLUE}Summary:${NC}"
echo "• ${#missing_packages[@]} packages would be installed via pacman"
if ! command -v yay &> /dev/null; then
    echo "• yay AUR helper would be installed automatically"
    echo "• ${#aur_packages[@]} AUR packages would be installed via yay"
else
    echo "• ${#missing_aur[@]:-0} AUR packages would be installed via yay"
fi
echo "• All config files would be installed"
echo "• Nordic theme would be configured"
echo "• Network and Bluetooth services would be enabled"
echo "• Backup would be created with timestamp"

if [[ ${#missing_packages[@]} -eq 0 && ${#missing_aur[@]:-0} -eq 0 && -x "$(command -v yay)" ]]; then
    echo ""
    echo -e "${GREEN}✓ All packages already installed - installer would only configure files${NC}"
fi

echo ""
echo "Run './install.sh' to proceed with installation"
