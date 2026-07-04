#!/bin/bash

# ==============================================================================
# sync.sh — Dotfiles Synchronization Script
# ==============================================================================
# Copies configuration files/directories to their respective target paths:
#   - App configs go to $XDG_CONFIG_HOME (defaulting to ~/.config/)
#   - Shell/editor configs go to $HOME (e.g. .bashrc, .zshrc, .vimrc, .tmux.conf)
# ==============================================================================

set -euo pipefail

# Target directories
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
HOME_DIR="$HOME"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Define color outputs
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Starting Dotfiles Synchronization ===${NC}"
echo -e "Source directory: ${YELLOW}$SCRIPT_DIR${NC}"
echo -e "Config directory: ${YELLOW}$XDG_CONFIG_HOME${NC}"
echo -e "Home directory:   ${YELLOW}$HOME_DIR${NC}"
echo

# Ensure config directory exists
mkdir -p "$XDG_CONFIG_HOME"

# List of directories to copy to XDG_CONFIG_HOME
CONFIG_DIRS=(
    "alacritty"
    "ghostty"
    "git"
    "nvim"
    "starship"
    "tmux"
    "Code"
)

# List of files to copy to HOME
HOME_FILES=(
    ".bashrc"
    ".vimrc"
    ".zshrc"
)

# Helper function to backup and copy an item
sync_item() {
    local src="$1"
    local dest="$2"

    # Verify source exists
    if [ ! -e "$src" ]; then
        echo -e "${YELLOW}Warning: Source path '$src' does not exist. Skipping.${NC}"
        return
    fi

    # Create parent directory for destination if it doesn't exist
    mkdir -p "$(dirname "$dest")"

    # Backup existing file/directory if it exists
    if [ -e "$dest" ]; then
        # Check if the existing item is a symlink or identical
        if [ -L "$dest" ]; then
            echo -e "Removing existing symbolic link: ${YELLOW}$dest${NC}"
            rm "$dest"
        elif diff -r "$src" "$dest" >/dev/null 2>&1; then
            echo -e "Skipping (already identical): ${GREEN}$dest${NC}"
            return
        else
            local backup="${dest}.bak"
            echo -e "Backing up existing configuration to: ${YELLOW}$backup${NC}"
            rm -rf "$backup"
            cp -r "$dest" "$backup"
        fi
    fi

    # Copy new configuration
    echo -e "Copying: ${BLUE}$src${NC} -> ${GREEN}$dest${NC}"
    cp -r "$src" "$dest"
}

# 1. Sync config directories to XDG_CONFIG_HOME
echo -e "${BLUE}--- Syncing application configs to $XDG_CONFIG_HOME ---${NC}"
for dir in "${CONFIG_DIRS[@]}"; do
    sync_item "$SCRIPT_DIR/$dir" "$XDG_CONFIG_HOME/$dir"
done

# 2. Sync core files to HOME
echo
echo -e "${BLUE}--- Syncing core dotfiles to $HOME_DIR ---${NC}"
for file in "${HOME_FILES[@]}"; do
    sync_item "$SCRIPT_DIR/$file" "$HOME_DIR/$file"
done

# 3. Special case: Sync tmux.conf to ~/.tmux.conf (since zshrc alias targets ~/.tmux.conf)
echo
echo -e "${BLUE}--- Syncing tmux config helper to ~/.tmux.conf ---${NC}"
if [ -f "$SCRIPT_DIR/tmux/tmux.conf" ]; then
    sync_item "$SCRIPT_DIR/tmux/tmux.conf" "$HOME_DIR/.tmux.conf"
fi

echo
echo -e "${GREEN}✔ Synchronization complete!${NC}"
