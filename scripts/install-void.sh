#!/usr/bin/env bash
# Installation script for Void Linux

set -e

DOTFILES="$HOME/.dotfiles"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source shared Stow functions
source "$SCRIPT_DIR/common/stow.sh"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo_info() { echo -e "${GREEN}[*]${NC} $1"; }
echo_warn() { echo -e "${YELLOW}[!]${NC} $1"; }
echo_error() { echo -e "${RED}[✗]${NC} $1"; }

# Verify we're on Void Linux
if ! [ -f /etc/os-release ] || ! grep -q "^ID=void" /etc/os-release; then
  echo_error "This script is for Void Linux only"
  exit 1
fi

echo_info "Void Linux installation script"

# Check for doas or sudo
if ! command -v doas &> /dev/null && ! command -v sudo &> /dev/null; then
  echo_error "Neither doas nor sudo found"
  exit 1
fi

SUDO_CMD="doas"
if ! command -v doas &> /dev/null; then
  SUDO_CMD="sudo"
fi

# ============================================================================
# 1. Enable non-free repos
# ============================================================================
echo_info "Enabling void-repo-nonfree..."
if ! xbps-query -l | grep -q void-repo-nonfree; then
  $SUDO_CMD xbps-install -Sy void-repo-nonfree || {
    echo_error "Failed to enable nonfree repo"
    exit 1
  }
else
  echo_warn "void-repo-nonfree already enabled"
fi

# Update package list
echo_info "Updating package list..."
$SUDO_CMD xbps-install -Sy || {
  echo_error "Failed to update package list"
  exit 1
}

# ============================================================================
# 2. Install system packages
# ============================================================================
echo_info "Installing system packages..."

PACKAGES=(
  # Hyprland stack
  hyprland hyprlock hypridle hyprpaper
  # Portals
  xdg-desktop-portal xdg-desktop-portal-hyprland
  # WM tools
  waybar wlogout swaylock
  # Terminal
  kitty
  # Editor
  neovim
  # Shell
  zsh
  # CLI tools
  eza bat zoxide curl wget
  # App launchers
  fuzzel wofi
  # File manager
  yazi
  # Browser
  firefox
  # Audio
  pipewire wireplumber pavucontrol
  # Input/Media
  brightnessctl playerctl
  # Screenshots
  grim slurp wl-clipboard
  # Video wallpaper
  mpv
  # Login manager
  sddm
  # Dotfiles manager
  stow
  # Fonts
  noto-fonts-ttf
  # Icons
  papirus-icon-theme adwaita-icon-theme
)

# Avoid reinstalling already installed packages
INSTALL_LIST=()
for pkg in "${PACKAGES[@]}"; do
  if ! xbps-query -l | grep -q "^ii  $pkg"; then
    INSTALL_LIST+=("$pkg")
  fi
done

if [ ${#INSTALL_LIST[@]} -gt 0 ]; then
  $SUDO_CMD xbps-install -y "${INSTALL_LIST[@]}" || {
    echo_error "Failed to install packages"
    exit 1
  }
else
  echo_warn "All packages already installed"
fi

# ============================================================================
# 3. Install JetBrains Mono Nerd Font
# ============================================================================
echo_info "Installing JetBrains Mono Nerd Font..."
mkdir -p "$HOME/.local/share/fonts"

if [ ! -f "$HOME/.local/share/fonts/JetBrainsMono/JetBrainsMono-Regular.ttf" ]; then
  TEMP_FONT="/tmp/JetBrainsMono.zip"
  curl -fsSL -o "$TEMP_FONT" \
    "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip" || {
    echo_error "Failed to download JetBrains Mono Nerd Font"
    exit 1
  }

  mkdir -p "$HOME/.local/share/fonts/JetBrainsMono"
  unzip -o "$TEMP_FONT" -d "$HOME/.local/share/fonts/JetBrainsMono" || {
    echo_error "Failed to extract JetBrains Mono Nerd Font"
    rm -f "$TEMP_FONT"
    exit 1
  }
  rm -f "$TEMP_FONT"

  fc-cache -fv || {
    echo_warn "Failed to rebuild font cache (non-critical)"
  }
else
  echo_warn "JetBrains Mono Nerd Font already installed"
fi

# ============================================================================
# 4. Install Oh My Zsh (if not already installed)
# ============================================================================
echo_info "Setting up Zsh and Oh My Zsh..."
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended || {
    echo_error "Failed to install Oh My Zsh"
    exit 1
  }
else
  echo_warn "Oh My Zsh already installed"
fi

# ============================================================================
# 5. Install Zsh plugins
# ============================================================================
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

declare -A PLUGINS=(
  [zsh-autosuggestions]="https://github.com/zsh-users/zsh-autosuggestions"
  [zsh-syntax-highlighting]="https://github.com/zsh-users/zsh-syntax-highlighting"
  [zsh-completions]="https://github.com/zsh-users/zsh-completions"
  [zsh-history-substring-search]="https://github.com/zsh-users/zsh-history-substring-search"
  [autoenv]="https://github.com/hyperupcall/autoenv"
)

for plugin in "${!PLUGINS[@]}"; do
  plugin_dir="$ZSH_CUSTOM/plugins/$plugin"
  if [ ! -d "$plugin_dir" ]; then
    echo_info "Installing $plugin..."
    git clone --depth 1 "${PLUGINS[$plugin]}" "$plugin_dir" || {
      echo_warn "Failed to install $plugin (non-critical)"
    }
  else
    echo_warn "$plugin already installed"
  fi
done

# ============================================================================
# 6. Install Powerlevel10k theme
# ============================================================================
THEME_DIR="$ZSH_CUSTOM/themes/powerlevel10k"
if [ ! -d "$THEME_DIR" ]; then
  echo_info "Installing Powerlevel10k..."
  git clone --depth=1 https://github.com/romkatv/powerlevel10k "$THEME_DIR" || {
    echo_error "Failed to install Powerlevel10k"
    exit 1
  }
else
  echo_warn "Powerlevel10k already installed"
fi

# ============================================================================
# 7. Install NVM (Node Version Manager)
# ============================================================================
if ! command -v nvm &> /dev/null && [ ! -s "$HOME/.nvm/nvm.sh" ]; then
  echo_info "Installing NVM..."
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.0/install.sh | bash || {
    echo_warn "Failed to install NVM (non-critical)"
  }
else
  echo_warn "NVM already installed"
fi

# ============================================================================
# 8. Stow dotfiles
# ============================================================================
do_stow || {
  echo_error "Failed to stow dotfiles"
  exit 1
}

# ============================================================================
# 9. Install SDDM theme
# ============================================================================
install_sddm_theme || {
  echo_warn "Failed to install SDDM theme (non-critical)"
}

# ============================================================================
# 10. Enable runit services
# ============================================================================
echo_info "Enabling runit services..."

SERVICES=(sddm dbus)
for service in "${SERVICES[@]}"; do
  if [ -d "/etc/sv/$service" ]; then
    if [ ! -L "/var/service/$service" ]; then
      echo_info "Enabling $service..."
      $SUDO_CMD ln -s "/etc/sv/$service" "/var/service/$service" || {
        echo_warn "Failed to enable $service (may already be enabled)"
      }
    else
      echo_warn "$service already enabled"
    fi
  else
    echo_warn "/etc/sv/$service not found (package may not be installed)"
  fi
done

# Optional pipewire service
if [ -d "/etc/sv/pipewire" ]; then
  if [ ! -L "/var/service/pipewire" ]; then
    $SUDO_CMD ln -s "/etc/sv/pipewire" "/var/service/pipewire" || {
      echo_warn "Failed to enable pipewire"
    }
  fi
fi

# ============================================================================
# 11. Change default shell to zsh
# ============================================================================
if [ "$SHELL" != "/bin/zsh" ]; then
  echo_info "Changing default shell to zsh..."
  chsh -s /bin/zsh || {
    echo_warn "Failed to change shell (may require relogin to take effect)"
  }
else
  echo_warn "Shell is already zsh"
fi

# ============================================================================
# Done
# ============================================================================
echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}✅ Installation complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "Next steps:"
echo "1. Reboot or relogin to apply shell change"
echo "2. Configure ~/.p10k.zsh for Powerlevel10k: run 'p10k configure'"
echo "3. Start Hyprland: type 'Hyprland' or select it from login manager"
echo ""
