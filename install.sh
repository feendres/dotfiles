#!/bin/bash
set -e # Exit on error

echo "🚀 Starting Dotfiles Installation..."
if ! locale -a | grep -q "en_US.utf8"; then
  echo "Generating en_US.UTF-8 locale..."
  sudo locale-gen en_US.UTF-8
  sudo update-locale LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8
fi
# --- Install System Dependencies ---
# lazyvim needs git, fzf, ripgrep, fd
echo "📦 Checking system dependencies..."
# zsh is already included here, so apt-get will install it if missing
deps=(stow tmux zsh curl git build-essential ripgrep fd-find fzf unzip eza)
to_install=""

for pkg in "${deps[@]}"; do
  if ! dpkg -l | grep -q "^ii  $pkg "; then
    echo "🔍 $pkg is missing..."
    to_install="$to_install $pkg"
  fi
done

# Only run apt-get if we found missing packages
if [ -n "$to_install" ]; then
  echo "📦 Installing missing packages: $to_install"
  sudo apt-get update
  sudo apt-get install -y $to_install
else
  echo "✅ All system dependencies are already installed."
fi

# --- Install Tree-sitter CLI (REQUIRED for new LazyVim) ---
# We install the binary directly to avoid needing Node.js/NPM
if ! command -v tree-sitter &>/dev/null; then
  echo "⬇️  Installing tree-sitter-cli (Required for parsers)..."
  # Fetch the latest release version tag from GitHub API
  TS_VERSION=$(curl -s "https://api.github.com/repos/tree-sitter/tree-sitter/releases/latest" | grep -Po '"tag_name": "\K.*?(?=")')

  # Download the linux binary
  curl -Lo tree-sitter.gz "https://github.com/tree-sitter/tree-sitter/releases/download/${TS_VERSION}/tree-sitter-linux-x64.gz"

  # Unzip and install
  gzip -d tree-sitter.gz
  chmod +x tree-sitter
  sudo mv tree-sitter /usr/local/bin/

  echo "✅ tree-sitter-cli installed version: $(tree-sitter --version)"
else
  echo "✅ tree-sitter-cli is already installed."
fi

# --- Install nvim from pre-built binaries ---
echo "Installing nvim"
cd ~/
curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz
sudo rm -rf /opt/nvim-linux-x86_64
sudo tar -C /opt -xzf nvim-linux-x86_64.tar.gz
sudo ln -sf /opt/nvim-linux-x86_64/bin/nvim /usr/local/bin/nvim
rm nvim-linux-x86_64.tar.gz

# --- Install oh my posh ---
# Installs to ~/.local/bin so it doesn't need root
echo "🎨 Installing Oh My Posh..."
mkdir -p ~/.local/bin
curl -s https://ohmyposh.dev/install.sh | bash -s -- -d ~/.local/bin

# --- Install Oh My Zsh ---
# We must do this BEFORE installing plugins in section 5
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  echo "🔥 Installing Oh My Zsh..."
  # --unattended prevents it from jumping into zsh immediately and stopping the script
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

  # Remove the .zshrc it creates so we can stow our own later
  rm -f ~/.zshrc
else
  echo "✅ Oh My Zsh is already installed."
fi

# --- Install Zsh Plugins (OMZ Custom) ---
ZSH_CUSTOM=${ZSH_CUSTOM:-~/.oh-my-zsh/custom}

# zsh-autosuggestions (The "Ghost text" autocomplete)
if [ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]; then
  echo "⌨️  Cloning zsh-autosuggestions..."
  git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
fi

# We clone this specifically as requested
if [ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]; then
  echo "🌈 Cloning zsh-syntax-highlighting..."
  git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
fi

# ---  Symlinking dotfiles ---
echo "🔗 Symlinking dotfiles..."
cd ~/dotfiles

# SAFE MOVE FUNCTION: Only moves if source exists and isn't already a symlink
safe_backup() {
  if [ -e "$1" ] && [ ! -L "$1" ]; then
    echo "Backing up $1"
    mv "$1" "$1.bak"
  fi
}

# The OMZ installer might have created a fresh .zshrc, ensuring we back it up or remove it
safe_backup ~/.zshrc
safe_backup ~/.config/nvim
safe_backup ~/.local/share/nvim
safe_backup ~/.local/state/nvim
safe_backup ~/.cache/nvim
[ -f ~/.config/tmux/tmux.conf ] && rm -f ~/.config/tmux/tmux.conf

# Loop through directories (tmux, zsh, omp) and stow them
for d in */; do
  stow -t ~ "${d%/}" 2>/dev/null || true
done

# ---  Set Default Shell ---
echo "🐚 Checking default shell..."
if [ "$SHELL" != "$(which zsh)" ]; then
  echo "Changing default shell to zsh..."
  # Check if zsh is in /etc/shells
  if ! grep -q "$(which zsh)" /etc/shells; then
    echo "Adding zsh to /etc/shells"
    command -v zsh | sudo tee -a /etc/shells
  fi
  chsh -s "$(which zsh)"
  echo "✅ Shell changed! You may need to log out and back in."
fi

echo "✅ Dotfiles installed! Please restart your shell."
