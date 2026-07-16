#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

# --- Aliases ---
alias ..="cd .."
alias ...="cd ../../"

alias l='ls -CF'
alias ls='eza --color=auto'
alias ll='eza -lh --icons --git'
alias la='eza -lAh --icons --git'
# alias ls='ls --color=auto'
alias ls='eza -al --color=always --group-directories-first --icons=always'
alias lt='eza -aT --color=always --group-directories-first --icons=always'

alias grep='grep --color=auto'
alias ff="fastfetch -c examples/13.jsonc"
alias tree="eza -T --icons"
alias tmux="tmux -u"

alias update='sudo cachyos-rate-mirrors && sudo pacman -Syu'

# mkdir & cd in one step
mkcd() {
    mkdir -p "$1" && cd "$1"
}

# cd and ls in one step
cl() {
    cd "$1" && ls;
}

# --- Shell Prompt ---
# PS1='[\u@\h \W]\$ '

# # === Bash Shell Prompts(Short & Long) ===

# Git prompt config
### Status Indicators
export GIT_PS1_SHOWDIRTYSTATE=1      # Shows '*' for unstaged and '+' for staged changes
export GIT_PS1_SHOWUNTRACKEDFILES=1  # Shows '%' for untracked files
export GIT_PS1_SHOWUPSTREAM="auto"   # Shows '<', '>', '=', or '<>' relative to upstream
export GIT_PS1_SHOWSTASHSTATE=1      # Shows '$' if there are stashes

### Git Prompt Styling
export GIT_PS1_SHOWSEPARATOR=1       # Enable the separator functionality
export GIT_PS1_STATESEPARATOR="|"   # Space between branch name and indicators

### Behavior & Context Controls
export GIT_PS1_HIDE_IF_PWD_IGNORED=1 # This ignores the dir which is listed in .gitignore
# export GIT_PS1_SHOWCOLORHINTS=1      # Enable Git status color hints (Green for clean, Red for dirty)

### Detached HEAD Styling ("contains": v1.6.3.2~35, "branch": main~2, "describe": v1.6.3-g4a2b, "default": raw exact commit hash)
export GIT_PS1_DESCRIBE_STYLE="branch"

### Conflict Indicator
export GIT_PS1_SHOWCONFLICTSTATE="yes" # Unresolved Conflict(s) indicator


# Load Git prompt script
if [ -f ~/.git-prompt.sh ]; then
  source ~/.git-prompt.sh
fi


# Set the Bash Prompt

# Full Shell Prompt
# PROMPT_COMMAND='PS1_CMD1=$(__git_ps1 " (%s)")';
# PS1='\n\[\e[32;1m\]\u\[\e[0;2m\]@\[\e[0;32;1m\]\h\[\e[0;2m\]:\[\e[0;94m\]\w\[\e[31m\]${PS1_CMD1}\[\e[0m\]\n\$ '

# Short Shell Prompt
PROMPT_COMMAND='PS1_CMD1=$(__git_ps1 " (%s)")';
PS1='\[\e[34;1m\]\W\[\e[0;31m\]${PS1_CMD1}\[\e[0m\] \$ '
