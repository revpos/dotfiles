# ~/.bashrc

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

# --- Aliases ---
alias ..="cd .."

alias l='ls -CF'
alias ls='eza --color=auto'
alias ll='eza -lh --icons --git'
alias la='eza -lAh --icons --git'
alias ls='ls --color=auto'

alias grep='grep --color=auto'
alias ff="fastfetch -c examples/13.jsonc"
alias tree="eza -T --icons"
alias tmux="tmux -u"

alias cdc="cd ~/revpos/"


# . "$HOME/.local/bin/env"
export PATH="$HOME/.cargo/bin:$PATH"


# --- Default prompt, basic ---
# PS1='[\u@\h \W]\$ '

mkcd() {
    mkdir -p "$1" && cd "$1"
}

# cd and ls in one step
cl() {
    cd "$1" && ls;
}

# --- Scaffold git local and remote repos with initial commit
mkproj() {
    # 1. Ensure a project name was provided
    if [ -z "$1" ]; then
        echo "Error: Please provide a project name."
        return 1
    fi

    local PROJECT_NAME="$1"
    local TARGET_DIR="$HOME/revpos/$PROJECT_NAME"

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


# --- Better prompt, efficient & Prod-ready prompt by Claude---
# __git_branch_info() {
#   git rev-parse --git-dir > /dev/null 2>&1 || return
#   local branch
#   branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null) || return
#   local display=":${branch}"
#   [ "$branch" = "HEAD" ] && display=":detached@$(git rev-parse --short HEAD 2>/dev/null)"
#   git diff --quiet 2>/dev/null || display="${display}*"
#   echo "$display"
# }

# Added Git branch highlight with 256-color orange (most accurate to Git logo / Alacritty orange)
# PS1='\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[38;5;202m\]$(__git_branch_info)\[\033[00m\] \$ '

# Custom git branch orange color highlight, for 256 color support
# PS1='\[\033[01;34m\]\w\[\033[38;5;202m\]$(__git_branch_info)\[\033[00m\] \$ '

# Default alacritty blue for pwd and red for git branch
# PS1='\[\033[01;34m\]\w\[\033[91m\]$(__git_branch_info)\[\033[00m\] \$ '

# # === Bash Shell Prompts(Short & Long) created from bash-prompt-generator.org ===
. ~/.git-prompt.sh

# # Full Shell Prompt
# PROMPT_COMMAND='PS1_CMD1=$(__git_ps1 " (%s)")';
# PS1='\n\[\e[32;1m\]\u\[\e[0;2m\]@\[\e[0;32;1m\]\h\[\e[0;2m\]:\[\e[0;94m\]\w\[\e[31m\]${PS1_CMD1}\[\e[0m\] \$\[\033[00m\] '

# Short Shell Prompt
PROMPT_COMMAND='PS1_CMD1=$(__git_ps1 " (%s)")';
PS1='\[\e[94;1m\]\w\[\e[0;31m\]${PS1_CMD1}\[\e[0m\] \$\[\033[00m\] '

# # === Git Stash Cyberpunk Prompt ===
# # Add to ~/.bashrc or ~/.bash_profile
#
# # Colors
# CYAN='\[\e[38;2;0;245;212m\]'
# PURPLE='\[\e[38;2;155;93;229m\]'
# PINK='\[\e[38;2;247;37;133m\]'
# BLUE='\[\e[38;2;76;201;240m\]'
# WHITE='\[\e[38;2;224;224;255m\]'
# DIM='\[\e[38;2;80;80;120m\]'
# RESET='\[\e[0m\]'
# BOLD='\[\e[1m\]'
#
# # Git branch + stash info
# git_prompt() {
#   local branch stash_count stash_str
#   branch=$(git symbolic-ref --short HEAD 2>/dev/null) || return
#   stash_count=$(git stash list 2>/dev/null | wc -l | tr -d ' ')
#
#   if [ "$stash_count" -gt 0 ]; then
#     stash_str=" ${PINK}⬡${stash_count}${RESET}"
#   else
#     stash_str=""
#   fi
#
#   echo " ${DIM}on${RESET} ${PURPLE}${BOLD} ${branch}${RESET}${stash_str}"
# }
#
# # Build the prompt
# build_prompt() {
#   local exit_code=$?
#   local arrow_color
#   [ $exit_code -eq 0 ] && arrow_color="${CYAN}" || arrow_color="${PINK}"
#
#   PS1="${DIM}╭─${RESET}${BLUE}${BOLD}\u${RESET}${DIM}@${RESET}${CYAN}\h${RESET} ${WHITE}\w${RESET}$(git_prompt)\n${DIM}╰─${RESET}${arrow_color}${BOLD}❯${RESET} "
# }
#
# PROMPT_COMMAND=build_prompt

