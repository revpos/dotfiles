# ~/.zshrc

# ------------------------------------------------------------------------------
# History
# ------------------------------------------------------------------------------
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt HIST_IGNORE_DUPS       # Don't record immediate duplicate commands
setopt HIST_IGNORE_ALL_DUPS   # Delete old duplicate entry if new entry is added
setopt HIST_SAVE_NO_DUPS      # Do not write duplicate events to history file
setopt HIST_FIND_NO_DUPS      # Do not display duplicates when searching history
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
# Completion (Fast 24-Hour Cache + Skip Security Audit)
# ------------------------------------------------------------------------------
autoload -Uz compinit

local zcompdump="${ZDOTDIR:-$HOME}/.zcompdump"

# Enable EXTENDED_GLOB for age-matching qualifiers
setopt EXTENDED_GLOB
if [[ -f "$zcompdump" && -n "${zcompdump}"(#qN.mh-24) ]]; then
  # Cache is under 24 hours old: use fast initialization (-C) and skip compaudit
  compinit -i -C -d "$zcompdump"
else
  # Rebuild dump file once every 24 hours
  compinit -i -d "$zcompdump"
fi
unsetopt EXTENDED_GLOB

zstyle ':completion:*' menu select          # Arrow-key navigable menu
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'  # Case-insensitive completion

# ------------------------------------------------------------------------------
# Prompt
# ------------------------------------------------------------------------------
typeset -g PS_DIR=""
typeset -g PS_GIT=""

# Git prompt config
export GIT_PS1_SHOWDIRTYSTATE=1      # Shows '*' for unstaged and '+' for staged changes
export GIT_PS1_SHOWUNTRACKEDFILES=1  # Shows '%' for untracked files
export GIT_PS1_SHOWUPSTREAM="auto"   # Shows '<', '>', '=', or '<>' relative to upstream
export GIT_PS1_SHOWSTASHSTATE=1      # Shows '$' if there are stashes
export GIT_PS1_SHOWSEPARATOR=1       # Enable separator
export GIT_PS1_STATESEPARATOR="|"   # Space between branch name and indicators
export GIT_PS1_HIDE_IF_PWD_IGNORED=1 # Ignores dirs in .gitignore
export GIT_PS1_DESCRIBE_STYLE="branch"
export GIT_PS1_SHOWCONFLICTSTATE="yes" # Unresolved conflict indicator

# Load Git prompt script
if [ -f ~/.git-prompt.sh ]; then
  source ~/.git-prompt.sh
fi

prompt_dir() {
  if [[ "$PWD" == "$HOME" ]]; then PS_DIR="~"; return; fi
  if [[ "$PWD" == "/" ]]; then PS_DIR="/"; return; fi

  local rel_path="${PWD/#$HOME/~}"
  local -a parts=(${(s:/:)rel_path})
  local MAX_DEPTH=2

  if [[ "$rel_path" == \~* ]]; then
    if (( ${#parts} - 1 > MAX_DEPTH )); then
      PS_DIR="../${parts[-1]}"
    else
      PS_DIR="$rel_path"
    fi
  else
    if (( ${#parts} > MAX_DEPTH )); then
      PS_DIR="../${parts[-1]}"
    else
      PS_DIR="$rel_path"
    fi
  fi
}

precmd() {
  prompt_dir
  if (( $+functions[__git_ps1] )); then
    PS_GIT=$(__git_ps1 " (%s)")
  else
    PS_GIT=""
  fi
}

setopt PROMPT_SUBST
PROMPT='%B%F{cyan}${PS_DIR}%f%b%F{8}${PS_GIT}%f %# '

# ------------------------------------------------------------------------------
# Keybindings
# ------------------------------------------------------------------------------
bindkey -e                          # Emacs-style key bindings (default)
bindkey '^[[A' history-search-backward   # Up arrow: search history backward
bindkey '^[[B' history-search-forward    # Down arrow: search history forward
bindkey '^[[1;5C' forward-word      # Ctrl+Right: move forward a word
bindkey '^[[1;5D' backward-word     # Ctrl+Left: move backward a word

# ------------------------------------------------------------------------------
# Aliases — Navigation & Listing
# ------------------------------------------------------------------------------
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

alias l='ls -CF'
alias ls='eza --color=auto'
alias ll='eza -lh --icons --git'
alias la='eza -lAh --icons --git'
alias tree="eza --tree --icons"

compdef eza=ls

# ------------------------------------------------------------------------------
# Aliases — General & Tools
# ------------------------------------------------------------------------------
alias grep='grep --color=auto'
alias mkdir='mkdir -pv'
alias cp='cp -iv'
alias mv='mv -iv'
alias rm='rm -iv'
alias df='df -h'
alias du='du -h'

alias ff="fastfetch -c examples/13.jsonc"
alias tmux="tmux -u"
alias code="vscodium"

# Git Aliases
alias g='git'
alias gs='git status --short'
alias ga='git add'
alias gc='git commit'
alias glg='git log --oneline --graph --decorate --all'
alias gd='git diff'
alias gco='git checkout'
alias gb='git branch'

# Config Editing Shortcuts
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
export EDITOR='nvim'
export VISUAL="$EDITOR"
export LANG='en_US.UTF-8'
export LC_ALL='en_US.UTF-8'

# Keep PATH clean and deduplicated
typeset -U path PATH
path=("$HOME/.local/bin" "$HOME/bin" $path)

# ------------------------------------------------------------------------------
# Functions
# ------------------------------------------------------------------------------
mkcd() { mkdir -p "$1" && cd "$1"; }
cl() { cd "$1" && ls; }

mkproject() {
    if [ -z "$1" ]; then
        echo "Error: Please provide a project name."
        return 1
    fi

    local PROJECT_NAME="$1"
    local TARGET_DIR="$HOME/Projects/$PROJECT_NAME"

    if [ -d "$TARGET_DIR" ]; then
        echo "Error: Directory $TARGET_DIR already exists locally."
        return 1
    fi

    echo "🚀 Creating project '$PROJECT_NAME'..."
    mkdir -p "$TARGET_DIR"
    cd "$TARGET_DIR" || return 1

    git init -b main

    if [ -f "README.md" ]; then
        echo "ℹ️ Existing README.md detected. Using it for the initial commit."
    else
        echo "📝 Creating new README.md..."
        echo "# $PROJECT_NAME" > README.md
    fi

    git add README.md
    git commit -m "Initial commit: Add README.md"

    echo "Creating remote GitHub repository..."
    if ! gh repo create "$PROJECT_NAME" --private --source=. --remote=origin --push 2>/tmp/gh_err.log; then
        echo "⚠️ GitHub repository creation failed."
        if grep -q "already exists" /tmp/gh_err.log 2>/dev/null; then
            echo "💥 Remote repository '$PROJECT_NAME' already exists on GitHub."
            read -p "Would you like to link this local repo to the existing remote and push? (y/N): " -r RESPONSE
            if [[ "$RESPONSE" =~ ^[Yy]$ ]]; then
                echo "🔗 Linking to existing GitHub repository..."
                local GH_USER
                GH_USER=$(gh api user --jq .login)
                git remote add origin "git@github.com:$GH_USER/$PROJECT_NAME.git"
                git push -u origin main
                echo "✅ Linked and pushed to existing remote!"
            else
                echo "❌ Operation aborted. Local repo remains unlinked."
            fi
        else
            echo "Error details:"
            cat /tmp/gh_err.log
        fi
    else
        echo "✅ Project '$PROJECT_NAME' is ready and synced with GitHub!"
    fi
    rm -f /tmp/gh_err.log
}

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

serve() { python3 -m http.server "${1:-8000}"; }

# Local machine overrides
[ -f ~/.zshrc.local ] && source ~/.zshrc.local
