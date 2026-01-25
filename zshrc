# --- 1. ENVIRONNEMENT & PATH ---
export ZSH="$HOME/.oh-my-zsh"
export NVM_DIR="$HOME/.nvm"

# Regroupement du PATH
# On met .local/bin et tes scripts persos en priorité
export PATH="$HOME/.local/bin:$HOME/Documents/Fedora_config/scripts/cli2text:$HOME/.cargo/bin:$HOME/go/bin:$PATH"

# --- 2. CONFIGURATION OH-MY-ZSH ---
ZSH_THEME="strug"
DISABLE_AUTO_TITLE="false"
plugins=(git zsh-autosuggestions zsh-syntax-highlighting zsh-completions autoenv zsh-history-substring-search)

# Chargement de Oh-My-Zsh
source $ZSH/oh-my-zsh.sh

# --- 3. CHARGEMENT DES OUTILS EXTERNES ---
# NVM (Chargement paresseux recommandé pour la vitesse au démarrage)
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# Zoxide
eval "$(zoxide init zsh)"

# --- 4. FONCTIONS & ALIAS ---

mkcd() {
    mkdir -p "$1" && cd "$1"
}


# Alias
alias selfip='bash "$HOME/Documents/Fedora_config/scripts/selfip/script.sh"'
alias cli2text='node "$HOME/Documents/Fedora_config/scripts/cli2text/cli2text.js"'
alias code='flatpak run com.visualstudio.code'

if [ -e /home/mleroy/.nix-profile/etc/profile.d/nix.sh ]; then . /home/mleroy/.nix-profile/etc/profile.d/nix.sh; fi # added by Nix installer
