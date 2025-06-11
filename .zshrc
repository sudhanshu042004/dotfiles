# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:$HOME/.local/bin:/usr/local/bin:$PATH

#core and auth packages file path
CORE_FILE="$HOME/dotfiles/packages/core.txt"
AUR_FILE="$HOME/dotfiles/packages/aur.txt"

#ensure_path func
create() {
  if [[ "$1" == */ ]]; then
    # If the input ends with a slash, create directories
    mkdir -p "$1"
  else
    # Otherwise, create the file and its directory structure
    dir=$(dirname "$1")
    mkdir -p "$dir" && touch "$1"
  fi
}

#install package
ins() {
  if [[ -n "$1" ]]; then
    pkg="$1"
  else
    echo -n "Package name: "
    read pkg
  fi

  if pacman -Si "$pkg" &>/dev/null; then
    # file="$HOME/dotfiles/packages/core.txt"
    if ! grep -qxF "$pkg" "$CORE_FILE"; then
      echo "$pkg" >> "$CORE_FILE"
      echo "✅ Added $pkg to core.txt"
    else
      echo "⚠️  $pkg already in core.txt"
    fi

    echo "📦 Installing $pkg using pacman..."
    if sudo pacman -S --noconfirm "$pkg"; then
      echo "✅ Installed $pkg"
    else
      echo "❌ Failed to install $pkg with pacman"
    fi

  else
    echo -n "Package $pkg not found in core. Add to aur.txt? [Y/n]: "
    read ans
    if [[ "${ans:l}" != "n" ]]; then
      # file="$HOME/dotfiles/packages/aur.txt"
      if ! grep -qxF "$pkg" "$AUR_FILE"; then
        echo "$pkg" >> "$AUR_FILE"
        echo "✅ Added $pkg to aur.txt"
      else
        echo "⚠️  $pkg already in aur.txt"
      fi

      echo "🔍 Checking if $pkg exists in AUR..."
      if paru -Si "$pkg" &>/dev/null; then
        echo "📦 Installing $pkg using paru..."
        if paru -S --noconfirm "$pkg"; then
          echo "✅ Installed $pkg"
        else
          echo "❌ Failed to install $pkg from AUR"
        fi
      else
        echo "❌ Package '$pkg' not found in AUR. Removing from aur.txt..."
        sed -i "/^$pkg$/d" "$AUR_FILE"
      fi
    else
      echo "❌ Skipped adding $pkg"
    fi
  fi
}

# remove package
rem() {
  if [[ -z "$1" ]]; then
    echo "❌ Usage: rm_pkg <package-name>"
    return 1
  fi

  pkg="$1"

  # Check if installed
  if pacman -Q "$pkg" &>/dev/null; then
    echo "📦 Uninstalling $pkg..."
    sudo pacman -Rns --noconfirm "$pkg" && echo "✅ Removed $pkg from system"
  else
    echo "⚠️  $pkg is not installed"
  fi

  # Remove from core.txt or aur.txt
  if grep -qxF "$pkg" "$CORE_FILE"; then
    sed -i "/^$pkg$/d" "$CORE_FILE" && echo "🗑️  Removed $pkg from core.txt"
  fi

  if grep -qxF "$pkg" "$AUR_FILE"; then
    sed -i "/^$pkg$/d" "$AUR_FILE" && echo "🗑️  Removed $pkg from aur.txt"
  fi
}




# Path to your Oh My Zsh installation.
export ZSH="$HOME/.oh-my-zsh"
export PATH="$HOME/.cargo/bin:$PATH"


# Set name of the theme to load --- if set to "random", it will
# load a random theme each time Oh My Zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="alanpeabody"

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in $ZSH/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment one of the following lines to change the auto-update behavior
# zstyle ':omz:update' mode disabled  # disable automatic updates
# zstyle ':omz:update' mode auto      # update automatically without asking
# zstyle ':omz:update' mode reminder  # just remind me to update when it's time

# Uncomment the following line to change how often to auto-update (in days).
# zstyle ':omz:update' frequency 13

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# You can also set it to another string to have that shown instead of the default red dots.
# e.g. COMPLETION_WAITING_DOTS="%F{yellow}waiting...%f"
# Caution: this setting can cause issues with multiline prompts in zsh < 5.7.1 (see #5765)
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(git zsh-autosuggestions zsh-syntax-highlighting)

source $ZSH/oh-my-zsh.sh

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='nvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch $(uname -m)"

# Set personal aliases, overriding those provided by Oh My Zsh libs,
# plugins, and themes. Aliases can be placed here, though Oh My Zsh
# users are encouraged to define aliases within a top-level file in
# the $ZSH_CUSTOM folder, with .zsh extension. Examples:
# - $ZSH_CUSTOM/aliases.zsh
# - $ZSH_CUSTOM/macos.zsh
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"
export PATH="$HOME/.local/share/solana/install/active_release/bin:$PATH"

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
