#!/usr/bin/env bash
# Installation script for Fedora Linux

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

# Verify we're on Fedora
if ! [ -f /etc/os-release ] || ! grep -q "^ID=fedora" /etc/os-release; then
  echo_error "This script is for Fedora Linux only"
  exit 1
fi

echo_info "Fedora Linux installation script"

# ============================================================================
# 1. Enable COPR repositories
# ============================================================================
echo_info "Enabling COPR repositories..."

echo_info "Adding Hyprland COPR (solopasha/hyprland)..."
sudo dnf copr enable -y solopasha/hyprland || {
  echo_warn "COPR Hyprland may already be enabled"
}

# ============================================================================
# 2. Enable RPM Fusion
# ============================================================================
echo_info "Enabling RPM Fusion repositories..."

FEDORA_VERSION=$(rpm -E %fedora)

echo_info "Adding RPM Fusion Free..."
sudo dnf install -y "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-${FEDORA_VERSION}.noarch.rpm" || {
  echo_warn "RPM Fusion Free may already be enabled"
}

echo_info "Adding RPM Fusion NonFree..."
sudo dnf install -y "https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-${FEDORA_VERSION}.noarch.rpm" || {
  echo_warn "RPM Fusion NonFree may already be enabled"
}

# ============================================================================
# 3. Update system
# ============================================================================
echo_info "Upgrading system packages..."
sudo dnf upgrade -y || {
  echo_error "Failed to upgrade system"
  exit 1
}

# ============================================================================
# 4. Install system packages
# ============================================================================
echo_info "Installing system packages..."

PACKAGES=(
  # Hyprland stack (from COPR)
  hyprland hyprlock hypridle hyprpaper
  # Portals (xdg-desktop-portal-hyprland from COPR)
  xdg-desktop-portal xdg-desktop-portal-hyprland
  # WM tools
  waybar swaylock
  # Terminal
  kitty
  # Editor
  neovim
  # Shell
  zsh util-linux-user
  # CLI tools
  eza bat zoxide curl wget git
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
  google-noto-fonts
  # Icons
  papirus-icon-theme adwaita-icon-theme
)

# wlogout may be in COPR, try both standard and COPR
if ! dnf info wlogout &> /dev/null; then
  echo_warn "wlogout not found in default repos, may need to install from COPR or compile"
else
  PACKAGES+=(wlogout)
fi

echo "Installing: ${PACKAGES[*]}"
sudo dnf install -y "${PACKAGES[@]}" || {
  echo_error "Failed to install packages"
  exit 1
}

# ============================================================================
# 5. Install VSCode via Flatpak
# ============================================================================
echo_info "Installing Visual Studio Code via Flatpak..."

if ! command -v flatpak &> /dev/null; then
  echo_info "Installing Flatpak..."
  sudo dnf install -y flatpak || {
    echo_warn "Failed to install Flatpak (non-critical)"
  }
fi

if command -v flatpak &> /dev/null; then
  echo_info "Installing VS Code..."
  flatpak install -y flathub com.visualstudio.code || {
    echo_warn "Failed to install VS Code via Flatpak (non-critical)"
  }
else
  echo_warn "Flatpak not available, skipping VS Code"
fi

# ============================================================================
# 6. Install JetBrains Mono Nerd Font
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
# 7. Install Oh My Zsh (if not already installed)
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
# 8. Install Zsh plugins
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
# 9. Install Powerlevel10k theme
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
# 10. Install NVM (Node Version Manager)
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
# 11. Stow dotfiles
# ============================================================================
do_stow || {
  echo_error "Failed to stow dotfiles"
  exit 1
}

# ============================================================================
# 12. Install SDDM theme
# ============================================================================
install_sddm_theme || {
  echo_warn "Failed to install SDDM theme (non-critical)"
}

# ============================================================================
# 13. Enable systemd services
# ============================================================================
echo_info "Enabling systemd services..."

SERVICES=(sddm pipewire wireplumber)
for service in "${SERVICES[@]}"; do
  if systemctl list-unit-files --all | grep -q "^$service.service"; then
    echo_info "Enabling $service..."
    sudo systemctl enable --now "$service" || {
      echo_warn "Failed to enable $service"
    }
  else
    echo_warn "$service.service not found"
  fi
done

# ============================================================================
# 14. Change default shell to zsh
# ============================================================================
if [ "$SHELL" != "/usr/bin/zsh" ]; then
  echo_info "Changing default shell to zsh..."
  chsh -s /usr/bin/zsh || {
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
