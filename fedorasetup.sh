#!/usr/bin/env bash

# Exit immediately if a command exits with a non-zero status
set -e

echo "🔄 Step 1: Updating the system packages..."
sudo dnf upgrade -y

# Target directories
DOTFILES_DIR="$HOME/dotfiles"
CONFIG_DIR="$HOME/.config"

echo "📂 Step 2: Syncing/Setting up the Dotfiles Repository..."
if [ ! -d "$DOTFILES_DIR" ]; then
    echo " -> 📥 Cloning dotfiles repository..."
    git clone git@github.com:revpos/dotfiles "$DOTFILES_DIR"
    cd "$DOTFILES_DIR"
else
    echo " -> 📦 Dotfiles directory already exists. Pulling latest updates..."
    cd "$DOTFILES_DIR"
    git pull origin main --quiet || echo "⚠️  Could not pull latest changes (offline or uncommitted changes)."
fi

# Ensure remaining target directories exist
mkdir -p "$CONFIG_DIR"

echo "📦 Step 3: Checking system dependencies and external repositories..."
# Ensure git is installed
if ! command -v git &> /dev/null; then
    echo " -> 📥 git not found. Installing git..."
    sudo dnf install -y git
else
    echo " -> git is already installed."
fi

echo " -> ⚙️ Configuring external repositories..."
# Install core DNF plugins to allow Copr management
sudo dnf install -y dnf-plugins-core

# Enable Copr repositories for lazygit, lazydocker, and zen-browser
sudo dnf copr enable atim/lazygit -y
sudo dnf copr enable atim/lazydocker -y
sudo dnf copr enable sneexy/zen-browser -y

# Add the official VSCodium RPM Repository
sudo rpmkeys --import https://gitlab.com/paulcarroty/vscodium-deb-rpm-repo/-/raw/master/pub.gpg
printf "[gitlab.com_paulcarroty_vscodium_repo]\nname=download.vscodium.com\nbaseurl=https://download.vscodium.com/rpms/\nenabled=1\ngpgcheck=1\nrepo_gpgcheck=1\ngpgkey=https://gitlab.com/paulcarroty/vscodium-deb-rpm-repo/-/raw/master/pub.gpg\nmetadata_expire=1h\n" | sudo tee /etc/yum.repos.d/vscodium.repo

echo "📂 Step 4: Syncing home directory dotfiles..."
HOME_FILES=(.bashrc .git-prompt.sh .vimrc .zshrc)
for file in "${HOME_FILES[@]}"; do
    if [ -f "$DOTFILES_DIR/$file" ]; then
        echo " -> Copying $file to $HOME/"
        cp "$DOTFILES_DIR/$file" "$HOME/"
    fi
done

echo "📂 Step 5: Syncing standard .config directories..."
CONFIG_FOLDERS=(alacritty ghostty git kitty starship tmux)
for folder in "${CONFIG_FOLDERS[@]}"; do
    if [ -d "$DOTFILES_DIR/$folder" ]; then
        echo " -> Copying $folder to $CONFIG_DIR/"
        rm -rf "$CONFIG_DIR/$folder"
        cp -r "$DOTFILES_DIR/$folder" "$CONFIG_DIR/"
    fi
done

echo "⚡ Step 6: Setting up Neovim (Kickstart)..."
if [ ! -d "$CONFIG_DIR/nvim/.git" ]; then
    echo " -> 📥 Cloning clean kickstart.nvim copy..."
    rm -rf "$CONFIG_DIR/nvim"
    git clone https://github.com/nvim-lua/kickstart.nvim.git "$CONFIG_DIR/nvim"
else
    echo " -> Neovim Git repository already exists, skipping clone."
fi

if [ -f "$DOTFILES_DIR/nvim/init.lua" ]; then
    echo " -> ⚙️ Overwriting kickstart init.lua with your custom version..."
    cp "$DOTFILES_DIR/nvim/init.lua" "$CONFIG_DIR/nvim/init.lua"
else
    echo " -> ⚠️ Warning: ~/dotfiles/nvim/init.lua not found!"
fi

echo "📦 Step 7: Installing bulk packages from fedorapkgs.txt..."
PACKAGES_FILE="$DOTFILES_DIR/fedorapkgs.txt"
if [ -f "$PACKAGES_FILE" ]; then
    # Safely strip out comments (#) and blank lines from fedorapkgs.txt to prevent parser crashes
    PKGS=$(sed '/^#/d; /^$/d' "$PACKAGES_FILE")
    if [ -n "$PKGS" ]; then
        sudo dnf install -y $PKGS
    else
        echo " -> ⚠️ fedorapkgs.txt is empty."
    fi
else
    echo " -> ⚠️ Warning: fedorapkgs.txt not found! Skipping package installation."
fi

echo "🖼️  Step 8: Syncing Wallpapers..."
WALLPAPER_DIR="$HOME/.local/share/wallpapers"
if [ ! -d "$WALLPAPER_DIR/.git" ]; then
    echo " -> 📥 Creating directory and cloning wallpapers..."
    rm -rf "$WALLPAPER_DIR"
    mkdir -p "$HOME/.local/share"
    git clone git@github.com:revpos/walls "$WALLPAPER_DIR"
else
    echo " -> Wallpapers repository already exists. Pulling updates..."
    git -C "$WALLPAPER_DIR" pull || echo "⚠️  Could not update wallpapers."
fi

echo "📝 Step 9: Syncing Notes..."
NOTES_DIR="$HOME/Documents"
if [ ! -d "$NOTES_DIR/notes/.git" ]; then
    echo " -> 📥 Cloning notes into Documents..."
    rm -rf "$NOTES_DIR/notes"
    mkdir -p "$NOTES_DIR"
    git clone git@github.com:revpos/notes "$NOTES_DIR/notes"
else
    echo " -> Notes repository already exists. Pulling updates..."
    git -C "$NOTES_DIR/notes" pull || echo "⚠️  Could not update notes."
fi

echo "🔤 Step 10: Syncing Fonts..."
FONT_DIR="$HOME/.local/share/fonts"
mkdir -p "$FONT_DIR"
if [ -d "$DOTFILES_DIR/fonts" ]; then
    echo " -> Copying custom fonts to $FONT_DIR/..."
    cp -r "$DOTFILES_DIR/fonts/"* "$FONT_DIR/"
    
    if command -v fc-cache &> /dev/null; then
        echo " -> 🔄 Refreshing font cache..."
        fc-cache -f
    fi
else
    echo " -> ⚠️ Warning: ~/dotfiles/fonts directory not found!"
fi

echo "✅ All sync tasks, system upgrades, and package installations complete!"