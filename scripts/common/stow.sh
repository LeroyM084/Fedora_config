#!/usr/bin/env bash
# Logique Stow partagée pour Void et Fedora

DOTFILES="$HOME/.dotfiles"
CONFIG_PACKAGES=(hypr kitty nvim waybar wlogout fuzzel yazi mako btop)

# Stow les dotfiles dans ~/.config
do_stow() {
  echo "===== Stowing dotfiles ====="

  # Créer ~/.config s'il n'existe pas
  mkdir -p "$HOME/.config"

  # Stow chaque package dans son propre sous-dossier de ~/.config.
  # Les packages sont des dossiers "plats" (ex: hypr/hyprland.conf), donc on
  # cible ~/.config/<pkg>/ pour obtenir des symlinks par fichier au bon niveau.
  for pkg in "${CONFIG_PACKAGES[@]}"; do
    if [ -d "$DOTFILES/$pkg" ]; then
      echo "Stowing $pkg..."
      mkdir -p "$HOME/.config/$pkg"
      stow --target="$HOME/.config/$pkg" --dir="$DOTFILES" "$pkg" || {
        echo "❌ Failed to stow $pkg"
        return 1
      }
    else
      echo "⚠️  $DOTFILES/$pkg not found, skipping"
    fi
  done

  # Symlink zshrc (à la racine du repo)
  echo "Linking ~/.zshrc... & p10k"
  mkdir -p "$HOME"
  ln -sf "$DOTFILES/zshrc" "$HOME/.zshrc"
  ln -sf "$DOTFILES/p10k.zsh" "$HOME/.p10k.zsh"


  # Créer ~/.local/bin s'il n'existe pas et y mettre les scripts
  mkdir -p "$HOME/.local/bin"
  ln -sf "$DOTFILES/scripts/hyprlock-random.sh" "$HOME/.local/bin/hyprlock-random"

  echo "✅ Stow completed"
}

# Installer le thème SDDM Sugar (nécessite root)
install_sddm_theme() {
  echo "===== Installing SDDM Sugar theme ====="

  if ! command -v sudo &> /dev/null && ! command -v doas &> /dev/null; then
    echo "❌ Neither sudo nor doas found"
    return 1
  fi

  local sudo_cmd="sudo"
  if ! command -v sudo &> /dev/null; then
    sudo_cmd="doas"
  fi

  if [ ! -d "$DOTFILES/sugar" ]; then
    echo "⚠️  $DOTFILES/sugar not found, skipping"
    return 0
  fi

  echo "Copying Sugar theme to /usr/share/sddm/themes/..."
  $sudo_cmd cp -r "$DOTFILES/sugar" /usr/share/sddm/themes/ || {
    echo "❌ Failed to copy SDDM theme"
    return 1
  }

  echo "✅ SDDM theme installed"
}

# Note: do_stow et install_sddm_theme sont disponibles après `source` dans
# le shell courant — pas besoin d'`export -f` (incompatible zsh).
