#!/bin/bash

set -e

# === COLORS ===
GREEN="\033[1;32m"
YELLOW="\033[1;33m"
RED="\033[1;31m"
BLUE="\033[1;34m"
NC="\033[0m" # No Color

# === LOGGING ===
info()    { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[OK]${NC}   $1"; }
warn()    { echo -e "${YELLOW}[WARN]${NC} $1"; }
error()   { echo -e "${RED}[ERR]${NC}  $1"; }
step()    { echo -e "\n${BLUE}--- Step $1/$TOTAL_STEPS: $2 ---${NC}"; }

TOTAL_STEPS=9
CURRENT_STEP=1

install_if_missing() {
  GREEN="\033[1;32m"
  YELLOW="\033[1;33m"
  RED="\033[1;31m"
  BLUE="\033[1;34m"
  NC="\033[0m"

  info()    { echo -e "${BLUE}[INFO]${NC} $1"; }
  success() { echo -e "${GREEN}[OK]${NC}   $1"; }
  warn()    { echo -e "${YELLOW}[WARN]${NC} $1"; }
  error()   { echo -e "${RED}[ERR]${NC}  $1"; }

  local pkg="$1"
  if ! pacman -Q "$pkg" &>/dev/null; then
    info "Installing $pkg..."
    paru -S --noconfirm "$pkg" &>"/tmp/install_log_$pkg.txt" \
      && success "$pkg ✅" \
      || error "$pkg ❌ (see /tmp/install_log_$pkg.txt)"
  else
    warn "$pkg is already installed. Skipping."
  fi
}

export -f install_if_missing
export -f info
export -f warn
export -f error
export -f success

# === STEP 1: PARU ===
step $CURRENT_STEP "Installing paru (AUR helper)"
if ! command -v paru &>/dev/null; then
  info "Cloning paru repo..."
  git clone https://aur.archlinux.org/paru.git /tmp/paru
  pushd /tmp/paru >/dev/null
  makepkg -si --noconfirm
  popd >/dev/null
  success "paru installed."
else
  warn "paru already installed. Skipping."
fi
((CURRENT_STEP++))

# === STEP 2: GNU Parallel ===
step $CURRENT_STEP "Ensuring GNU Parallel is installed"
if ! command -v parallel &>/dev/null; then
  info "Installing GNU Parallel..."
  paru -S --noconfirm parallel
  success "GNU Parallel installed."
else
  warn "GNU Parallel already installed. Skipping."
fi
((CURRENT_STEP++))

# === STEP 3: Package Install ===
step $CURRENT_STEP "Installing packages with GNU Parallel"

CORE_FILE="$HOME/dotfiles/packages/core.txt"
AUR_FILE="$HOME/dotfiles/packages/aur.txt"

core_count=$(grep -vE '^\s*#|^\s*$' "$CORE_FILE" | wc -l 2>/dev/null || echo 0)
aur_count=$(grep -vE '^\s*#|^\s*$' "$AUR_FILE" | wc -l 2>/dev/null || echo 0)

info "Installing $core_count core packages and $aur_count AUR packages using $(nproc) parallel jobs..."

if [[ -f "$CORE_FILE" ]]; then
  grep -vE '^\s*#|^\s*$' "$CORE_FILE" | parallel --jobs "$(nproc)" install_if_missing
else
  warn "core.txt not found. Skipping core packages."
fi

if [[ -f "$AUR_FILE" ]]; then
  grep -vE '^\s*#|^\s*$' "$AUR_FILE" | parallel --jobs "$(nproc)" install_if_missing
else
  warn "aur.txt not found. Skipping AUR packages."
fi
((CURRENT_STEP++))

# === STEP 4: ZSH ===
step $CURRENT_STEP "Switching shell to Zsh"
if [[ "$SHELL" == *"bash" ]]; then
  info "Changing default shell to Zsh..."
  chsh -s "$(which zsh)"
  success "Shell changed to Zsh."
else
  warn "Shell already set to Zsh."
fi
((CURRENT_STEP++))

# === STEP 5: Oh My Zsh ===
step $CURRENT_STEP "Installing Oh My Zsh"
if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
  info "Installing Oh My Zsh..."
  RUNZSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
  success "Oh My Zsh installed."
else
  warn "Oh My Zsh already installed."
fi
((CURRENT_STEP++))

# === STEP 6: Zsh Plugins ===
step $CURRENT_STEP "Installing Zsh plugins"

ZSH_CUSTOM=${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}

[[ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]] && \
  git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions" && \
  success "Installed zsh-autosuggestions"

[[ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]] && \
  git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" && \
  success "Installed zsh-syntax-highlighting"
((CURRENT_STEP++))

# === STEP 7: Link .zshrc ===
step $CURRENT_STEP "Linking .zshrc"
if [[ -f "$HOME/.zshrc" ]]; then
  mv "$HOME/.zshrc" "$HOME/.zshrc.bak"
  info "Backed up existing .zshrc to .zshrc.bak"
fi
ln "$HOME/dotfiles/.zshrc" "$HOME/.zshrc" && success "Linked zshrc"
((CURRENT_STEP++))

# === STEP 8: Link Kitty Config ===
step $CURRENT_STEP "Linking Kitty config"
KITTY_CONF_DIR="$HOME/.config/kitty"
mkdir -p "$KITTY_CONF_DIR"
for file in "$HOME/dotfiles/kitty"/*; do
  target="$KITTY_CONF_DIR/$(basename "$file")"
  rm -f "$target"
  ln "$file" "$target" && success "Linked kitty: $(basename "$file")"
done
((CURRENT_STEP++))

# === STEP 9: Link VSCode settings ===
step $CURRENT_STEP "Linking VSCode settings.json"
VSCODE_USER_DIR="$HOME/.config/Code/User"
mkdir -p "$VSCODE_USER_DIR"
[[ -f "$VSCODE_USER_DIR/settings.json" ]] && rm "$VSCODE_USER_DIR/settings.json"
ln "$HOME/dotfiles/vscode/settings.json" "$VSCODE_USER_DIR/settings.json" && success "Linked VSCode settings.json"
((CURRENT_STEP++))

# === Cleanup and Done ===
info "Removing individual package logs from /tmp"
rm -f /tmp/install_log_*.txt

success "✅ Setup complete! Restart your shell or log out/in to use Zsh."
