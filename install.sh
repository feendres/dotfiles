#!/bin/bash
set -eo pipefail

echo "🚀 Starting Dotfiles Installation..."

# --- Locale ---
if ! locale -a | grep -q "en_US.utf8"; then
  echo "Generating en_US.UTF-8 locale..."
  sudo locale-gen en_US.UTF-8
  sudo update-locale LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8
fi

# --- Temp directory for all downloads ---
TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

# --- Install System Dependencies ---
echo "📦 Checking system dependencies..."
deps=(stow tmux zsh curl git build-essential ripgrep fd-find fzf unzip eza)
to_install=""

for pkg in "${deps[@]}"; do
  if ! dpkg -s "$pkg" &>/dev/null; then
    echo "🔍 $pkg is missing..."
    to_install="$to_install $pkg"
  fi
done

if [ -n "$to_install" ]; then
  echo "📦 Installing missing packages: $to_install"
  sudo apt-get update
  sudo apt-get install -y $to_install
else
  echo "✅ All system dependencies are already installed."
fi

# --- Install Tree-sitter CLI ---
if ! command -v tree-sitter &>/dev/null; then
  echo "⬇️  Installing tree-sitter-cli (Required for parsers)..."
  TS_VERSION=$(curl -s "https://api.github.com/repos/tree-sitter/tree-sitter/releases/latest" | grep -Po '"tag_name": "\K.*?(?=")')
  curl -Lo "$TMPDIR/tree-sitter.gz" "https://github.com/tree-sitter/tree-sitter/releases/download/${TS_VERSION}/tree-sitter-linux-x64.gz"
  gzip -d "$TMPDIR/tree-sitter.gz"
  chmod +x "$TMPDIR/tree-sitter"
  sudo mv "$TMPDIR/tree-sitter" /usr/local/bin/
  echo "✅ tree-sitter-cli installed: $(tree-sitter --version)"
else
  echo "✅ tree-sitter-cli is already installed."
fi

# --- Install Neovim ---
echo "⬇️  Installing Neovim..."
curl -Lo "$TMPDIR/nvim.tar.gz" https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz
sudo rm -rf /opt/nvim-linux-x86_64
sudo tar -C /opt -xzf "$TMPDIR/nvim.tar.gz"
sudo ln -sf /opt/nvim-linux-x86_64/bin/nvim /usr/local/bin/nvim
echo "✅ Neovim installed: $(nvim --version | head -1)"

# --- Install Oh My Posh ---
echo "🎨 Installing Oh My Posh..."
mkdir -p "$HOME/.local/bin"
curl -s https://ohmyposh.dev/install.sh | bash -s -- -d "$HOME/.local/bin"

# --- Install Oh My Zsh ---
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  echo "🔥 Installing Oh My Zsh..."
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
  rm -f "$HOME/.zshrc"
else
  echo "✅ Oh My Zsh is already installed."
fi

# --- Install Zsh Plugins ---
ZSH_CUSTOM=${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}

if [ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]; then
  echo "⌨️  Cloning zsh-autosuggestions..."
  git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
fi

if [ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]; then
  echo "🌈 Cloning zsh-syntax-highlighting..."
  git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
fi

# --- Symlink Dotfiles ---
echo "🔗 Symlinking dotfiles..."
cd "$HOME/dotfiles"

safe_backup() {
  local target="$1"
  local backup_path="${target}.bak"

  # Only act if the target is a real file/folder (not a symlink)
  if [ -e "$target" ] && [ ! -L "$target" ]; then
    echo "Backing up $target to $backup_path"

    # Forcefully remove existing backup so mv doesn't fail
    rm -rf "$backup_path"

    mv "$target" "$backup_path"
  fi
}

safe_backup "$HOME/.zshrc"
safe_backup "$HOME/.config/nvim"
safe_backup "$HOME/.local/share/nvim"
safe_backup "$HOME/.local/state/nvim"
safe_backup "$HOME/.cache/nvim"
safe_backup "$HOME/.config/tmux"

for d in */; do
  echo "Stowing $d..."
  # -R: Recursive, -t: Target, -v: Verbose
  stow -R -t "$HOME" "${d%/}" || echo "⚠️  stow conflict in $d — check manually"
done

# --- Set Default Shell ---
echo "🐚 Checking default shell..."
ZSH_PATH=$(command -v zsh)
CURRENT_USER="${USER:-$(whoami)}"
CURRENT_SHELL=$(getent passwd "$CURRENT_USER" | cut -d: -f7)

if [ "$CURRENT_SHELL" != "$ZSH_PATH" ]; then
  echo "Changing default shell to zsh..."

  if ! grep -q "$ZSH_PATH" /etc/shells; then
    echo "Adding zsh to /etc/shells..."
    echo "$ZSH_PATH" | sudo tee -a /etc/shells >/dev/null
  fi

  if sudo chsh -s "$ZSH_PATH" "$CURRENT_USER" 2>/dev/null || chsh -s "$ZSH_PATH" "$CURRENT_USER" 2>/dev/null; then
    echo "✅ Default shell changed to zsh."
  else
    echo "⚠️  Could not change default shell (normal in some containers). Zsh is still installed and usable."
  fi
else
  echo "✅ zsh is already the default shell."
fi

echo ""
echo "✅ Dotfiles installed! Please restart your shell."
