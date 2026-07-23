# ~/.bashrc

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

# Source global definitions
if [ -f /etc/bashrc ]; then
    . /etc/bashrc
fi

# User specific environment
if ! [[ "$PATH" =~ "$HOME/.local/bin:$HOME/bin:" ]]; then
    PATH="$HOME/.local/bin:$HOME/bin:$PATH"
fi
export PATH

# --- Aliases ---
alias ..="cd .."
alias ...="cd ../../"

alias ls='eza --color=auto --icons=always'
alias ll='eza -lh --icons --git'
alias la='eza -lAh --icons --git'
alias lt='eza -aT --color=always --group-directories-first --icons=always'
alias tree="eza -T --icons"

alias grep='grep --color=auto'
alias ff="fastfetch -c examples/13.jsonc"
alias tmux="tmux -2u"

# alias update='sudo cachyos-rate-mirrors && sudo pacman -Syu'
alias update='sudo dnf upgrade --refresh -y && sudo fwupdmgr refresh && sudo fwupdmgr update -y && flatpak update -y'

alias prime-run="__NV_PRIME_RENDER_OFFLOAD=1 __GLX_VENDOR_LIBRARY_NAME=nvidia"

# --- Functions ---
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

# Git Prompt Variables
GIT_PS1_SHOWDIRTYSTATE=true     # unstaged (*), staged (+)
GIT_PS1_SHOWSTASHSTATE=true     # stashed ($)
GIT_PS1_SHOWUNTRACKEDFILES=true # untracked (%)
GIT_PS1_SHOWUPSTREAM="auto"     # behind (<), ahead (>), diverged (<>), no diff (=)
GIT_PS1_SHOWSEPARATOR=1         # separator (...|...)
GIT_PS1_STATESEPARATOR="|"      # (<branch>|<status-symbols>)
GIT_PS1_COMPRESSSPARSESTATE=true # default (<branch>|SPARSE) -> (<branch>|?)
GIT_PS1_OMITSPARSESTATE=         # default (<branch>|SPARSE) -> (<branch>)
GIT_PS1_SHOWCONFLICTSTATE="yes"  # (<branch>|CONFLICT)
GIT_PS1_DESCRIBE_STYLE="branch"  # "contains": v1.6.2~35, "branch": main~2, "describe": v1.6.3-g4a2b, "default": raw exact commit hash
GIT_PS1_SHOWCOLORHINTS=true      # green = clean state, red = dirty state
GIT_PS1_HIDE_IF_PWD_IGNORED=true # no git status inside dir listed in .gitignore
# GIT_PS1_COLOR_PRE=
# GIT_PS1_COLOR_POST=

# Load Git prompt script
if [ -f ~/.git-prompt.sh ]; then
  source ~/.git-prompt.sh
fi

# Bash Shell (Long) Prompt - Green USER@HOST + Blue PWD + Red Git Prompt
# PROMPT_COMMAND='PS1_CMD1=$(__git_ps1 " (%s)")';
# PS1='\n\[\e[32;1m\]\u\[\e[0;2m\]@\[\e[0;32;1m\]\h\[\e[0;2m\]:\[\e[0;94m\]\w\[\e[31m\]${PS1_CMD1}\[\e[0m\]\n\$ '

# Bash Shell (Short) Prompt - Arrow NF Glyph + Blue PWD(base) + Colored Git Prompt
# PROMPT_COMMAND='PS1_CMD1=$(__git_ps1 " (%s)")'
# PS1='\[\e[34;1m\]\w\[\e[0;90m\]${PS1_CMD1}\[\e[0m\] \$ '  # for red git prompt, \[\e[0;31m\]]
PS1='\[\e[96m\]\[\e[0m\] \[\e[34;1m\]\W\[\e[0m\]$(__git_ps1 " (%s)") '
