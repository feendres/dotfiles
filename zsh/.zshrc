# Path to your oh-my-zsh installation
export ZSH="$HOME/.oh-my-zsh"
# Force UTF-8 for Tmux and other tools to render icons correctly
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
# --- PLUGINS ---
# git: standard git aliases
# zsh-autosuggestions: ghost text completion
# zsh-syntax-highlighting: must be LAST in the list
plugins=(git zsh-autosuggestions zsh-syntax-highlighting)

source $ZSH/oh-my-zsh.sh

# --- CATPPUCCIN SYNTAX THEME ---
# This must run AFTER 'source $ZSH/oh-my-zsh.sh' because the plugin must be loaded first.
source "$ZSH/custom/themes/catppuccin_syntax/themes/catppuccin_macchiato-zsh-syntax-highlighting.zsh"

# --- USER CONFIG ---
eval "$(oh-my-posh init zsh --config ~/.config/ohmyposh/custom_catppuccin_macchiato.omp.json)"

alias ll="ls -l"
