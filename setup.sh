#!/bin/bash

set -e

# === UTILS ===
log() {
  echo -e "\033[1;32m[✔]\033[0m $1"
}
warn() {
  echo -e "\033[1;33m[!]\033[0m $1"
}
err() {
  echo -e "\033[1;31m[✘]\033[0m $1"
}

install_if_missing() {
  if ! pacman -Q "$1" &>/dev/null; then
    log "Installing $1..."
    paru -S --noconfirm "$1"
  else
    warn "$1 is already installed. Skipping."
  fi
}

# === STEP 1: PARU ===
if ! command -v paru &>/dev/null; then
  log "Installing paru (AUR helper)..."
  git clone https://aur.archlinux.org/paru.git /tmp/paru
  pushd /tmp/paru >/dev/null
  makepkg -si --noconfirm
  popd >/dev/null
else
  warn "paru already installed. Skipping."
fi

# === STEP 2.: INSTALL PACKAGES FROM core.txt and aur.txt ===
CORE_FILE="$HOME/dotfiles/packages/core.txt"
AUR_FILE="$HOME/dotfiles/packages/aur.txt"

log "Installing packages from core.txt..."
if [[ -f "$CORE_FILE" ]]; then
  while IFS= read -r pkg; do
    [[ -z "$pkg" || "$pkg" == \#* ]] && continue
    install_if_missing "$pkg"
  done < "$CORE_FILE"
else
  warn "core.txt not found. Skipping core packages."
fi

log "Installing packages from aur.txt..."
if [[ -f "$AUR_FILE" ]]; then
  while IFS= read -r pkg; do
    [[ -z "$pkg" || "$pkg" == \#* ]] && continue
    if ! pacman -Q "$pkg" &>/dev/null; then
      log "Installing $pkg from AUR..."
      paru -S --noconfirm "$pkg" || err "Failed to install $pkg from AUR"
    else
      warn "$pkg already installed. Skipping."
    fi
  done < "$AUR_FILE"
else
  warn "aur.txt not found. Skipping AUR packages."
fi


# === STEP 3: ZSH SETUP ===
if [[ "$SHELL" == *"bash" ]]; then
  log "Switching shell from bash to zsh..."
  chsh -s "$(which zsh)"
else
  warn "Shell already set to zsh."
fi

# === STEP 4: OH MY ZSH ===
if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
  log "Installing Oh My Zsh..."
  RUNZSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
else
  warn "Oh My Zsh already installed."
fi

# === STEP 5: ZSH PLUGINS ===
ZSH_CUSTOM=${ZSH_CUSTOM:-~/.oh-my-zsh/custom}
[[ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]] &&
  git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions" &&
  log "Installed zsh-autosuggestions"

[[ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]] &&
  git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" &&
  log "Installed zsh-syntax-highlighting"

# === STEP 6: HARDLINK zshrc ===
if [[ -f "$HOME/.zshrc" ]]; then
  rm "$HOME/.zshrc"
fi
ln "$HOME/dotfiles/.zshrc" "$HOME/.zshrc" && log "Linked zshrc"

# === STEP 7: LINK kitty config ===
KITTY_CONF_DIR="$HOME/.config/kitty"
mkdir -p "$KITTY_CONF_DIR"
for file in "$HOME/dotfiles/kitty"/*; do
  target="$KITTY_CONF_DIR/$(basename "$file")"
  rm -f "$target"
  ln "$file" "$target" && log "Linked kitty: $(basename "$file")"
done

# === STEP 8: LINK VSCode settings.json ===
VSCODE_USER_DIR="$HOME/.config/Code/User"
mkdir -p "$VSCODE_USER_DIR"
if [[ -f "$VSCODE_USER_DIR/settings.json" ]]; then
  rm "$VSCODE_USER_DIR/settings.json"
fi
ln "$HOME/dotfiles/vscode/settings.json" "$VSCODE_USER_DIR/settings.json" && log "Linked VSCode settings.json"

# === DONE ===
log "✅ Setup complete! Restart shell or re-login to use zsh if changed."
