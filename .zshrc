# ==============================================================================
# .zshrc — Zsh Configuration
# ==============================================================================

# ------------------------------------------------------------------------------
# History
# ------------------------------------------------------------------------------
HISTFILE=~/.zsh_history
# HISTFILE="$XDG_STATE_HOME/zsh/history"
HISTSIZE=10000
SAVEHIST=10000
setopt HIST_IGNORE_DUPS       # Don't record duplicate commands
setopt HIST_IGNORE_SPACE      # Don't record commands starting with a space
setopt SHARE_HISTORY          # Share history across sessions
setopt APPEND_HISTORY         # Append rather than overwrite history

# ------------------------------------------------------------------------------
# Options
# ------------------------------------------------------------------------------
setopt AUTO_CD                # Type a directory name to cd into it
setopt CORRECT                # Suggest corrections for mistyped commands
setopt NO_BEEP                # No beeping

# ------------------------------------------------------------------------------
# Completion
# ------------------------------------------------------------------------------
autoload -Uz compinit && compinit
zstyle ':completion:*' menu select          # Arrow-key navigable menu
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'  # Case-insensitive completion

# ------------------------------------------------------------------------------
# Prompt
# ------------------------------------------------------------------------------
autoload -Uz vcs_info
precmd() { vcs_info }
zstyle ':vcs_info:git:*' formats ' (%b)'   # Show current git branch

setopt PROMPT_SUBST
PROMPT='%F{cyan}%~%f%F{yellow}${vcs_info_msg_0_}%f %# '

# ------------------------------------------------------------------------------
# Keybindings
# ------------------------------------------------------------------------------
bindkey -e                          # Emacs-style key bindings (default)
bindkey '^[[A' history-search-backward   # Up arrow: search history backward
bindkey '^[[B' history-search-forward    # Down arrow: search history forward
bindkey '^[[1;5C' forward-word      # Ctrl+Right: move forward a word
bindkey '^[[1;5D' backward-word     # Ctrl+Left: move backward a word

# ------------------------------------------------------------------------------
# Aliases — Navigation
# ------------------------------------------------------------------------------
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

# ------------------------------------------------------------------------------
# Aliases — Listing
# ------------------------------------------------------------------------------
alias l='ls -CF'
alias ls='eza --color=auto'
alias ll='eza -lh --icons --git'
alias la='eza -lAh --icons --git'
alias tree="eza --tree --icons"

# Reuse ls completions for eza, avoids defining a separate completion function
compdef eza=ls

# ------------------------------------------------------------------------------
# Aliases — General
# ------------------------------------------------------------------------------
alias grep='grep --color=auto'
alias mkdir='mkdir -pv'             # Create parent dirs, show what was created
alias cp='cp -iv'                   # Interactive + verbose
alias mv='mv -iv'                   # Interactive + verbose
alias rm='rm -iv'                   # Interactive + verbose (prevents accidents)
alias df='df -h'                    # Human-readable disk usage
alias du='du -h'                    # Human-readable file sizes

alias ff="fastfetch -c examples/13.jsonc"
alias tmux="tmux -u"
alias code="vscodium"

# ------------------------------------------------------------------------------
# Aliases — Git
# ------------------------------------------------------------------------------
alias g='git'
alias gs='git status --short'
alias ga='git add'
alias gc='git commit'
alias glg='git log --oneline --graph --decorate --all'
alias gd='git diff'
alias gco='git checkout'
alias gb='git branch'

# ------------------------------------------------------------------------------
# Aliases for editing configs/dotfiles
# ------------------------------------------------------------------------------
alias cfg-bashrc='nvim ~/.bashrc'
alias cfg-zshrc='nvim ~/.zshrc'
alias cfg-alacritty='nvim ~/.config/alacritty/alacritty.toml'
alias cfg-ghostty='nvim ~/.config/ghostty/config.ghostty'
alias cfg-starship='nvim ~/.config/starship/starship.toml'
alias cfg-nvim='nvim ~/.config/nvim/init.lua'
alias cfg-tmux='nvim ~/.tmux.conf'

# ------------------------------------------------------------------------------
# Environment
# ------------------------------------------------------------------------------
export EDITOR='vim'                 # Default editor (change to nano/code/etc.)
export VISUAL="$EDITOR"
export LANG='en_US.UTF-8'
export LC_ALL='en_US.UTF-8'

# Add local bin to PATH
export PATH="$HOME/.local/bin:$HOME/bin:$PATH"

# ------------------------------------------------------------------------------
# Functions
# ------------------------------------------------------------------------------

# Create a directory and cd into it
mkcd() {
  mkdir -p "$1" && cd "$1"
}

# cd and ls in one step
cl() { cd "$1" && ls; }

# Scaffold a new project with a local & remote repos and an initial commit
mkproject() {
    # 1. Ensure a project name was provided
    if [ -z "$1" ]; then
        echo "Error: Please provide a project name."
        return 1
    fi

    local PROJECT_NAME="$1"
    local TARGET_DIR="$HOME/Projects/$PROJECT_NAME"

    # 2. Prevent overwriting an existing local directory
    if [ -d "$TARGET_DIR" ]; then
        echo "Error: Directory $TARGET_DIR already exists locally."
        return 1
    fi

    echo "🚀 Creating project '$PROJECT_NAME'..."

    # 3. Create and move into the directory
    mkdir -p "$TARGET_DIR"
    cd "$TARGET_DIR" || return 1

    # 4. Initialize local git repo with 'main' branch
    git init -b main

    # 5. Check for or create README.md
    if [ -f "README.md" ]; then
        echo "ℹ️ Existing README.md detected. Using it for the initial commit."
    else
        echo "📝 Creating new README.md..."
        echo "# $PROJECT_NAME" > README.md
    fi

    # 6. Stage and commit the README
    git add README.md
    git commit -m "Initial commit: Add README.md"

    # 7. Create remote GitHub repo with error handling
    echo "Creating remote GitHub repository..."

    # Run the creation command and capture any errors
    if ! gh repo create "$PROJECT_NAME" --private --source=. --remote=origin --push 2>/tmp/gh_err.log; then
        echo "⚠️  GitHub repository creation failed."

        # Check if the failure was specifically because it already exists
        if grep -q "already exists" /tmp/gh_err.log 2>/dev/null; then
            echo "💥 It looks like the remote repository '$PROJECT_NAME' already exists on GitHub."

            # Prompt the user to see if they want to link to the existing repo
            read -p "Would you like to link this local repo to the existing remote and push? (y/N): " -r RESPONSE
            if [[ "$RESPONSE" =~ ^[Yy]$ ]]; then
                echo "🔗 Linking to existing GitHub repository..."
                # Get your GitHub username dynamically to construct the remote URL
                local GH_USER
                GH_USER=$(gh api user --jq .login)

                git remote add origin "git@github.com:$GH_USER/$PROJECT_NAME.git"
                git push -u origin main
                echo "✅ Linked and pushed to existing remote!"
            else
                echo "❌ Operation aborted. Local repo remains unlinked."
            fi
        else
            # Print the actual error if it was something else (e.g., network issues)
            echo "Error details:"
            cat /tmp/gh_err.log
        fi
    else
        echo "✅ Project '$PROJECT_NAME' is ready and synced with GitHub!"
    fi

    # Clean up temporary error log
    rm -f /tmp/gh_err.log
}

# Extract common archive formats
extract() {
  if [ -f "$1" ]; then
    case "$1" in
      *.tar.bz2)  tar xjf "$1"  ;;
      *.tar.gz)   tar xzf "$1"  ;;
      *.tar.xz)   tar xJf "$1"  ;;
      *.bz2)      bunzip2 "$1"  ;;
      *.gz)       gunzip "$1"   ;;
      *.tar)      tar xf "$1"   ;;
      *.tbz2)     tar xjf "$1"  ;;
      *.tgz)      tar xzf "$1"  ;;
      *.zip)      unzip "$1"    ;;
      *.Z)        uncompress "$1" ;;
      *.7z)       7z x "$1"    ;;
      *)          echo "'$1' cannot be extracted via extract()" ;;
    esac
  else
    echo "'$1' is not a valid file"
  fi
}

# Quick HTTP server in current directory
serve() {
  python3 -m http.server "${1:-8000}"
}

# ------------------------------------------------------------------------------
# Local overrides (machine-specific config, not tracked in version control)
# ------------------------------------------------------------------------------
[ -f ~/.zshrc.local ] && source ~/.zshrc.local

# Starship shell prompt styling
eval "$(starship init zsh)"
export STARSHIP_CONFIG=~/.config/starship/starship.toml
