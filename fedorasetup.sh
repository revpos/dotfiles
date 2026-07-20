#!/usr/bin/env bash

# Exit immediately if a command exits with a non-zero status
set -e

echo "=================================================================="
echo " 🚀 Starting Fedora KDE Unified Post-Install Setup Script"
echo "=================================================================="

# Target paths
DOTFILES_DIR="$HOME/dotfiles"
CONFIG_DIR="$HOME/.config"
WALLPAPER_DIR="$HOME/.local/share/wallpapers"
NOTES_DIR="$HOME/Documents/notes"
FONT_DIR="$HOME/.local/share/fonts"

# Pre-flight check: Ensure user is not running as root directly
if [ "$EUID" -eq 0 ]; then
  echo "❌ Error: Do not run this script with 'sudo ./fedorasetup.sh'."
  echo "   Run it as a regular user: './fedorasetup.sh'."
  echo "   The script will prompt for sudo access when needed."
  exit 1
fi

# ==============================================================================
# STEP 1: Enable Repositories & System Upgrade
# ==============================================================================
echo -e "\n⚙️  Step 1: Enabling Core Repositories & Upgrading System..."

# Ensure prerequisite CLI utilities are present
if ! command -v git &> /dev/null; then
    echo " -> 📥 Installing Git..."
    sudo dnf install -y git
fi
sudo dnf install -y dnf-plugins-core

# Enable RPM Fusion (Free & Non-Free) for NVIDIA drivers & media codecs
echo " -> 📦 Enabling RPM Fusion (Free & Non-Free) and Cisco H.264..."
sudo dnf install -y \
  https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-"$(rpm -E %fedora)".noarch.rpm \
  https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-"$(rpm -E %fedora)".noarch.rpm
sudo dnf config-manager setopt fedora-cisco-openh264.enabled=1

# Enable selected COPR Repositories
echo " -> 📦 Enabling COPR repositories for lazygit & lazydocker..."
sudo dnf copr enable atim/lazygit -y
sudo dnf copr enable atim/lazydocker -y

echo " -> 🔄 Performing initial system package upgrade..."
sudo dnf upgrade -y

# ==============================================================================
# STEP 2: Hardware Drivers & Acceleration (NVIDIA RTX 3050 + Intel Xe)
# ==============================================================================
echo -e "\n🎮 Step 2: Installing Graphics Drivers & Hardware Acceleration..."

# Install proprietary NVIDIA drivers and CUDA development tools
echo " -> 📦 Installing akmod-nvidia and CUDA packages..."
sudo dnf install -y akmod-nvidia xorg-x11-drv-nvidia-cuda

echo " -> 🛠️  Compiling NVIDIA kernel modules (this may take 2-3 minutes)..."
sudo akmods --force
sudo dracut --force

# Hardware Acceleration & Codecs for Intel QuickSync + NVIDIA NVENC
echo " -> 🎬 Swapping to full FFmpeg and installing Intel VA-API drivers..."
sudo dnf swap -y ffmpeg-free ffmpeg --allowerasing
sudo dnf install -y intel-media-driver

# ==============================================================================
# STEP 3: Lenovo Battery Conservation Service
# ==============================================================================
echo -e "\n🔋 Step 3: Configuring Lenovo Battery Conservation Mode (60% Threshold)..."

sudo tee /etc/systemd/system/lenovo-conservation.service > /dev/null << 'EOF'
[Unit]
Description=Enable Lenovo Battery Conservation Mode
After=multi-user.target

[Service]
Type=oneshot
ExecStart=/bin/sh -c 'echo 1 > /sys/bus/platform/drivers/ideapad_laptop/VPC2004:00/conservation_mode 2>/dev/null || true'

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable --now lenovo-conservation.service
echo " -> ⚡ Battery conservation mode service enabled successfully."

# ==============================================================================
# STEP 4: Sync Dotfiles Repository
# ==============================================================================
echo -e "\n📂 Step 4: Syncing Dotfiles Repository..."

if [ ! -d "$DOTFILES_DIR" ]; then
    echo " -> 📥 Cloning dotfiles repository..."
    git clone git@github.com:revpos/dotfiles "$DOTFILES_DIR"
else
    echo " -> 📦 Dotfiles directory exists. Pulling latest updates..."
    git -C "$DOTFILES_DIR" pull origin main --quiet || echo "⚠️ Could not pull latest changes (offline or local uncommitted changes)."
fi

mkdir -p "$CONFIG_DIR"

# ==============================================================================
# STEP 5: Deploy Dotfiles & Application Configurations
# ==============================================================================
echo -e "\n📂 Step 5: Deploying dotfiles and .config folders..."

HOME_FILES=(.bashrc .git-prompt.sh .vimrc .zshrc)
for file in "${HOME_FILES[@]}"; do
    if [ -f "$DOTFILES_DIR/$file" ]; then
        echo " -> Copying $file to $HOME/"
        cp "$DOTFILES_DIR/$file" "$HOME/"
    fi
done

CONFIG_FOLDERS=(alacritty ghostty git kitty starship tmux)
for folder in "${CONFIG_FOLDERS[@]}"; do
    if [ -d "$DOTFILES_DIR/$folder" ]; then
        echo " -> Copying $folder configuration to $CONFIG_DIR/"
        rm -rf "$CONFIG_DIR/$folder"
        cp -r "$DOTFILES_DIR/$folder" "$CONFIG_DIR/"
    fi
done

# ==============================================================================
# STEP 6: Neovim Kickstart Setup
# ==============================================================================
echo -e "\n⚡ Step 6: Setting up Neovim (Kickstart)..."

if [ ! -d "$CONFIG_DIR/nvim/.git" ]; then
    echo " -> 📥 Cloning clean kickstart.nvim repository..."
    rm -rf "$CONFIG_DIR/nvim"
    git clone https://github.com/nvim-lua/kickstart.nvim.git "$CONFIG_DIR/nvim"
else
    echo " -> Neovim Git repository already exists, skipping clone."
fi

if [ -f "$DOTFILES_DIR/nvim/init.lua" ]; then
    echo " -> ⚙️  Applying custom init.lua from dotfiles..."
    cp "$DOTFILES_DIR/nvim/init.lua" "$CONFIG_DIR/nvim/init.lua"
else
    echo " -> ⚠️  Warning: ~/dotfiles/nvim/init.lua not found!"
fi

# ==============================================================================
# STEP 7: DNF Bulk Package Installation
# ==============================================================================
echo -e "\n📦 Step 7: Installing native system packages from fedorapkgs.txt..."

PACKAGES_FILE="$DOTFILES_DIR/fedorapkgs.txt"
if [ -f "$PACKAGES_FILE" ]; then
    # Filter out blank lines and comments
    PKGS=$(sed '/^#/d; /^$/d' "$PACKAGES_FILE")
    if [ -n "$PKGS" ]; then
        echo " -> Installing: $PKGS"
        sudo dnf install -y $PKGS
    else
        echo " -> ⚠️  fedorapkgs.txt is empty."
    fi
else
    echo " -> ⚠️  Warning: fedorapkgs.txt not found! Skipping DNF package batch."
fi

# ==============================================================================
# STEP 8: Flatpak Applications (Content Creation & Primary Desktop Tools)
# ==============================================================================
echo -e "\n📦 Step 8: Setting up Flathub and Installing Flatpak Apps..."

flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

echo " -> Installing Flatpak stack (VSCodium, Zen Browser, OBS Studio, Kdenlive, MPV, VLC)..."
flatpak install -y flathub \
  com.vscodium.codium \
  io.github.zen_browser.zen \
  com.obsproject.Studio \
  org.kde.kdenlive \
  io.mpv.Mpv \
  org.videolan.VLC

# ==============================================================================
# STEP 9: Sync Wallpapers, Personal Notes & Custom Fonts
# ==============================================================================
echo -e "\n🖼️  Step 9: Syncing Wallpapers..."
if [ ! -d "$WALLPAPER_DIR/.git" ]; then
    echo " -> 📥 Cloning wallpapers repository..."
    rm -rf "$WALLPAPER_DIR"
    mkdir -p "$HOME/.local/share"
    git clone git@github.com:revpos/walls "$WALLPAPER_DIR"
else
    echo " -> Wallpapers repository exists. Pulling updates..."
    git -C "$WALLPAPER_DIR" pull || echo "⚠️  Could not update wallpapers."
fi

echo -e "\n📝 Syncing Notes..."
if [ ! -d "$NOTES_DIR/.git" ]; then
    echo " -> 📥 Cloning personal notes repository..."
    rm -rf "$NOTES_DIR"
    mkdir -p "$HOME/Documents"
    git clone git@github.com:revpos/notes "$NOTES_DIR"
else
    echo " -> Notes repository exists. Pulling updates..."
    git -C "$NOTES_DIR" pull || echo "⚠️  Could not update notes."
fi

echo -e "\n🔤 Syncing Fonts..."
mkdir -p "$FONT_DIR"
if [ -d "$DOTFILES_DIR/fonts" ]; then
    echo " -> Copying custom fonts to $FONT_DIR/..."
    cp -r "$DOTFILES_DIR/fonts/"* "$FONT_DIR/"

    if command -v fc-cache &> /dev/null; then
        echo " -> 🔄 Refreshing font cache..."
        fc-cache -f
    fi
else
    echo " -> ⚠️  Warning: ~/dotfiles/fonts directory not found!"
fi

# ==============================================================================
# COMPLETION SUMMARY & NEXT STEPS
# ==============================================================================
echo -e "\n=================================================================="
echo " ✅ Post-Installation Script Completed Successfully!"
echo "=================================================================="
echo " 📌 Immediate Next Steps:"
echo "    1. REBOOT your system to load the newly compiled NVIDIA drivers."
echo "    2. After rebooting, run 'nvidia-smi' in terminal to confirm GPU state."
echo "    3. Open KDE System Settings -> Colors & Themes -> Select Breeze Dark."
echo "    4. Right-click bottom panel -> Edit Mode -> Add Spacers to center icons."
echo "=================================================================="
