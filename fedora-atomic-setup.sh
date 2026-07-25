#!/usr/bin/env bash

# Exit immediately if a command exits with a non-zero status
set -euo pipefail

echo "=================================================================="
echo " 🚀 Starting Fedora COSMIC Atomic Setup Script"
echo "=================================================================="

# Pre-flight check: Ensure user is not running as root directly
if [ "$EUID" -eq 0 ]; then
  echo "❌ Error: Do not run this script with 'sudo ./setup-atomic.sh'."
  echo "   Run it as a regular user: './setup-atomic.sh'."
  echo "   The script will prompt for sudo access when needed."
  exit 1
fi

# ==============================================================================
# SECTION 1: VARIABLES & CONFIGURATION
# ==============================================================================

# Path Variables
readonly DOTFILES_DIR="$HOME/dotfiles"
readonly CONFIG_DIR="$HOME/.config"
readonly WALLPAPER_DIR="$HOME/.local/share/wallpapers"
readonly DOCUMENTS_DIR="$HOME/Documents"
readonly FONT_DIR="$HOME/.local/share/fonts"

# Container Names
readonly DEV_CONTAINER_NAME="dev-main"

# Package Arrays
readonly DAILY_FLATPAKS=(
  com.brave.Browser
  io.mpv.Mpv
  org.videolan.VLC
  org.qbittorrent.qBittorrent
  org.localsend.localsend_app
)

readonly DEV_FLATPAKS=(
  com.vscodium.codium
  com.jetbrains.IntelliJ-IDEA-Community
)

readonly DEV_CONTAINER_PKGS=(
  7zip
  alacritty
  eza
  fd-find
  fzf
  gcc
  git
  golang
  make
  neovim
  python3-pip
  ripgrep
  tree-sitter-cli
  tmux
  unzip
  uv
  lazygit
  lazydocker
)

readonly CREATION_FLATPAKS=(
  com.obsproject.Studio
  org.kde.kdenlive
  org.gimp.GIMP
  dev.storyapps.starc
)

readonly NERD_FONTS=("JetBrainsMono" "Meslo" "SourceCodePro" "FiraCode")

# ==============================================================================
# SECTION 2: BASE SYSTEM SETUP (rpm-ostree level tweaks)
# ==============================================================================
echo -e "\n⚙️  Section 2: Base System Setup (rpm-ostree)..."

# Pause background rpm-ostree timer to prevent lock contention
sudo systemctl stop rpm-ostreed-automatic.timer || true

echo " -> 🔄 Staging base system upgrades..."
sudo rpm-ostree upgrade || true

FEDORA_VER=$(rpm -E %fedora)
echo " -> 📦 Staging NVIDIA drivers, UI fonts, container runtimes, and host tools..."
# Combined into a single rpm-ostree commit for efficiency
sudo rpm-ostree install --apply-live --needed -y \
  "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-${FEDORA_VER}.noarch.rpm" \
  "https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-${FEDORA_VER}.noarch.rpm" \
  akmod-nvidia \
  xorg-x11-drv-nvidia-cuda \
  rsms-inter-fonts \
  distrobox \
  podman \
  git \
  curl \
  unzip || echo "⚠️ Notice: Some ostree layers staged for next reboot."

echo " -> 🔋 Configuring Lenovo Battery Conservation Service (60% Threshold)..."
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
sudo systemctl enable lenovo-conservation.service --now || true

# ==============================================================================
# SECTION 3: DAILY DRIVING SETUP (flatpak only)
# ==============================================================================
echo -e "\n🌐 Section 3: Daily Driving Setup (Flatpaks)..."

echo " -> Enabling Flathub repository..."
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

echo " -> Installing Daily Driving & Media Flatpaks in parallel batch..."
flatpak install -y --or-update flathub "${DAILY_FLATPAKS[@]}" || true

echo " -> Installing Multimedia Runtime Extension Codecs..."
flatpak install -y flathub org.freedesktop.Platform.ffmpeg-full || true

# ==============================================================================
# SECTION 4: DEVELOPMENT SETUP (flatpak + dnf inside Distrobox)
# ==============================================================================
echo -e "\n💻 Section 4: Development Setup..."

echo " -> Installing Development Flatpaks..."
flatpak install -y --or-update flathub "${DEV_FLATPAKS[@]}" || true

echo " -> Fast-pulling base image via Podman..."
podman pull --quiet registry.fedoraproject.org/fedora:latest || true

echo " -> Setting up Distrobox dev container ('$DEV_CONTAINER_NAME')..."
if ! distrobox list | grep -q "$DEV_CONTAINER_NAME"; then
    distrobox create --name "$DEV_CONTAINER_NAME" --image registry.fedoraproject.org/fedora:latest --yes
fi

echo " -> Tuning DNF & installing CLI packages inside Distrobox..."
distrobox enter "$DEV_CONTAINER_NAME" -- bash -c "
  # Optimize DNF inside container: parallel downloads + skip documentation
  sudo tee -a /etc/dnf/dnf.conf > /dev/null << 'EOF'
[main]
max_parallel_downloads=10
tsflags=nodocs
EOF

  # Install COPR repositories and packages with weak-deps skipped
  sudo dnf copr enable atim/lazygit -y --quiet
  sudo dnf copr enable atim/lazydocker -y --quiet
  sudo dnf install -y --setopt=install_weak_deps=False ${DEV_CONTAINER_PKGS[*]}
"

echo " -> Exporting container shortcuts to host desktop..."
distrobox enter "$DEV_CONTAINER_NAME" -- distrobox-export --app lazygit || true
distrobox enter "$DEV_CONTAINER_NAME" -- distrobox-export --app lazydocker || true

# ==============================================================================
# SECTION 5: PERSONALIZATION SETUP (configs, notes, walls, fonts)
# ==============================================================================
echo -e "\n🎨 Section 5: Personalization Setup..."

# Content Creation Applications
echo " -> Installing Content Creation Flatpaks in parallel batch..."
flatpak install -y --or-update flathub "${CREATION_FLATPAKS[@]}" || true

# Sync Dotfiles Repository & Symlinks
echo " -> Syncing Dotfiles..."
if [ ! -d "$DOTFILES_DIR" ]; then
    git clone git@github.com:revpos/dotfiles "$DOTFILES_DIR" || \
    git clone https://github.com/revpos/dotfiles.git "$DOTFILES_DIR" || true
else
    git -C "$DOTFILES_DIR" pull origin main --quiet || echo "⚠️ Could not update dotfiles."
fi

mkdir -p "$CONFIG_DIR"

HOME_FILES=(.bashrc .git-prompt.sh .vimrc .zshrc)
for file in "${HOME_FILES[@]}"; do
    if [ -f "$DOTFILES_DIR/$file" ]; then
        cp -b "$DOTFILES_DIR/$file" "$HOME/"
    fi
done

CONFIG_FOLDERS=(alacritty ghostty git kitty starship tmux)
for folder in "${CONFIG_FOLDERS[@]}"; do
    if [ -d "$DOTFILES_DIR/$folder" ]; then
        if [ -d "$CONFIG_DIR/$folder" ]; then
            mv "$CONFIG_DIR/$folder" "$CONFIG_DIR/${folder}.bak.$(date +%s)"
        fi
        cp -r "$DOTFILES_DIR/$folder" "$CONFIG_DIR/"
    fi
done

# Neovim Kickstart Setup
echo " -> Setting up Neovim Kickstart configuration..."
if [ ! -d "$CONFIG_DIR/nvim/.git" ]; then
    [ -d "$CONFIG_DIR/nvim" ] && mv "$CONFIG_DIR/nvim" "$CONFIG_DIR/nvim.bak.$(date +%s)"
    git clone https://github.com/nvim-lua/kickstart.nvim.git "$CONFIG_DIR/nvim"
fi

if [ -f "$DOTFILES_DIR/nvim/init.lua" ]; then
    cp "$DOTFILES_DIR/nvim/init.lua" "$CONFIG_DIR/nvim/init.lua"
fi

# Clone Notes repository directly to the root of ~/Documents
echo " -> Syncing Personal Notes directly into ~/Documents..."
mkdir -p "$DOCUMENTS_DIR"
if [ ! -d "$DOCUMENTS_DIR/.git" ]; then
    git clone git@github.com:revpos/notes "$DOCUMENTS_DIR" || \
    git clone https://github.com/revpos/notes.git "$DOCUMENTS_DIR" || true
else
    git -C "$DOCUMENTS_DIR" pull || echo "⚠️ Could not update notes repository."
fi

# Sync Wallpapers
echo " -> Syncing Wallpapers..."
if [ ! -d "$WALLPAPER_DIR/.git" ]; then
    mkdir -p "$HOME/.local/share"
    git clone git@github.com:revpos/walls "$WALLPAPER_DIR" || \
    git clone https://github.com/revpos/walls.git "$WALLPAPER_DIR" || true
else
    git -C "$WALLPAPER_DIR" pull || echo "⚠️ Could not update wallpapers."
fi

# Fonts & Nerd Fonts (Parallelized downloads)
echo " -> Deploying Fonts..."
mkdir -p "$FONT_DIR"
if [ -d "$DOTFILES_DIR/fonts" ]; then
    cp -r "$DOTFILES_DIR/fonts/"* "$FONT_DIR/"
fi

for font in "${NERD_FONTS[@]}"; do
    if [ ! -d "$FONT_DIR/$font" ]; then
        (
            echo "    -> Downloading $font Nerd Font in background..."
            mkdir -p "$FONT_DIR/$font"
            curl -sSLo "/tmp/$font.zip" "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/$font.zip"
            unzip -oq "/tmp/$font.zip" -d "$FONT_DIR/$font"
            rm -f "/tmp/$font.zip"
        ) &
    fi
done

# Wait for background font downloads before updating cache
wait

if command -v fc-cache &> /dev/null; then
    fc-cache -f "$FONT_DIR"
fi

# ==============================================================================
# COMPLETION SUMMARY & NEXT STEPS
# ==============================================================================
echo -e "\n=================================================================="
echo " ✅ Post-Installation Script Completed Successfully!"
echo "=================================================================="
echo " 📌 Immediate Next Steps:"
echo "    1. REBOOT your system via 'systemctl reboot' to apply staged OS/NVIDIA layers."
echo "    2. Verify GPU status after rebooting using 'nvidia-smi'."
echo "    3. Access your development environment via 'distrobox enter $DEV_CONTAINER_NAME'."
echo "=================================================================="