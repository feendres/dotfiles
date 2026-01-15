#!/bin/bash
set -e # Exit on error

echo "🚀 Starting Dotfiles Installation..."

#!/bin/bash

# Define the list of tools you need
deps=(stow tmux zsh curl git)
to_install=""

# Loop through and check if they exist
for pkg in "${deps[@]}"; do
    if ! command -v "$pkg" &> /dev/null; then
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

# Installs to ~/.local/bin so it doesn't need root
echo "🎨 Installing Oh My Posh..."
mkdir -p ~/.local/bin
curl -s https://ohmyposh.dev/install.sh | bash -s -- -d ~/.local/bin

# --- 3. Install Zsh Plugins (OMZ Custom) ---
ZSH_CUSTOM=${ZSH_CUSTOM:-~/.oh-my-zsh/custom}

# A. zsh-autosuggestions (The "Ghost text" autocomplete)
if [ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]; then
    echo "⌨️  Cloning zsh-autosuggestions..."
    git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
fi

# B. Catppuccin Syntax Highlighting
# We clone this specifically as requested
if [ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]; then
    echo "🌈 Cloning zsh-syntax-highlighting..."
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
fi

if [ ! -d "$ZSH_CUSTOM/themes/catppuccin_syntax" ]; then
    echo "🎨 Cloning Catppuccin Syntax Highlighting..."
    mkdir -p "$ZSH_CUSTOM/themes"
    git clone https://github.com/catppuccin/zsh-syntax-highlighting.git "$ZSH_CUSTOM/themes/catppuccin_syntax"
fi

# Manual install of Catppuccin Tmux Theme
if [ ! -d "$HOME/.config/tmux/plugins/catppuccin/tmux" ]; then
    echo "🎨 Cloning Catppuccin Tmux theme..."
    mkdir -p ~/.config/tmux/plugins/catppuccin
    git clone -b v2.1.3 https://github.com/catppuccin/tmux.git ~/.config/tmux/plugins/catppuccin/tmux
fi

echo "🔗 Symlinking dotfiles..."
cd ~/dotfiles

# FIX: Delete existing config files so Stow can replace them
# We force remove (-f) .zshrc because common-utils created it
rm -f ~/.zshrc
rm -f ~/.config/tmux/tmux.conf

# Loop through directories (tmux, zsh, omp) and stow them
for d in */; do
    stow -t ~ "${d%/}" 2>/dev/null || true
done

echo "✅ Dotfiles installed! Please restart your shell or run 'zsh'."
