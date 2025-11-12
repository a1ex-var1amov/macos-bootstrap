# --- Homebrew completions BEFORE compinit ---
if [[ -d /opt/homebrew/share/zsh/site-functions ]]; then
  fpath=(/opt/homebrew/share/zsh/site-functions $fpath)
elif [[ -d /usr/local/share/zsh/site-functions ]]; then
  fpath=(/usr/local/share/zsh/site-functions $fpath)
fi

# --- Static, cached completions for wrapper names (no subprocess on startup) ---
# Generate once:
#   mkdir -p ~/.zsh/completions
#   kubectl completion zsh > ~/.zsh/completions/_kubectl
#   oc completion zsh       > ~/.zsh/completions/_oc
fpath=($HOME/.zsh/completions $fpath)

# --- Completion (cached, once) ---
# Use a per-host/version dump to avoid unnecessary rebuilds
ZSH_COMPDUMP="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/.zcompdump-${HOST}-${ZSH_VERSION}"
mkdir -p "${ZSH_COMPDUMP:h}"
autoload -Uz compinit
# Use -C to skip expensive checks when the compdump exists
if [[ -f $ZSH_COMPDUMP ]]; then
  compinit -C -d "$ZSH_COMPDUMP"
else
  compinit -i -d "$ZSH_COMPDUMP"
fi
setopt complete_aliases

# --- History and shell options ---
HISTFILE="${XDG_STATE_HOME:-$HOME/.local/state}/zsh/history"
mkdir -p "${HISTFILE:h}"
HISTSIZE=200000
SAVEHIST=200000
setopt INC_APPEND_HISTORY        # write history incrementally
setopt SHARE_HISTORY             # share history across sessions
setopt HIST_IGNORE_ALL_DUPS      # remove older duplicate entries
setopt HIST_FIND_NO_DUPS         # skip duplicates when searching
setopt HIST_REDUCE_BLANKS        # trim superfluous blanks
setopt HIST_IGNORE_SPACE         # ignore commands starting with space
setopt HIST_VERIFY               # show command with history expansion before running
setopt HIST_FCNTL_LOCK           # use better locking for history file
setopt EXTENDED_HISTORY          # save timestamp and duration
setopt EXTENDED_GLOB             # better globbing
setopt INTERACTIVE_COMMENTS      # allow comments in interactive shell
setopt AUTO_PUSHD PUSHD_SILENT PUSHD_IGNORE_DUPS
setopt CORRECT                   # correct typos in commands
setopt COMPLETE_IN_WORD          # complete from both ends of a word
setopt ALWAYS_TO_END             # move cursor to end after completion
setopt AUTO_CD                   # cd by typing directory name if it's not a command
setopt AUTO_LIST                 # automatically list choices on ambiguous completion
setopt AUTO_MENU                 # show completion menu on successive tab presses
setopt NO_BEEP                   # disable beep on error
setopt NO_CASE_GLOB              # case-insensitive globbing
setopt NUMERIC_GLOB_SORT         # sort numeric filenames numerically

# Optional: byte-compile compdump for tiny extra speed
[[ ! -f ${ZSH_COMPDUMP}.zwc || $ZSH_COMPDUMP -nt ${ZSH_COMPDUMP}.zwc ]] && zcompile -R -- "${ZSH_COMPDUMP}.zwc" "$ZSH_COMPDUMP"

# --- Wrapper functions with fallback ---
kubectl() { if (( $+commands[kubecolor] )); then command kubecolor "$@"; else command kubectl "$@"; fi }
oc()      { if (( $+commands[kubecolor] )); then KUBECOLOR_KUBECTL=oc command kubecolor "$@"; else command oc "$@"; fi }

compdef _kubectl kubectl
compdef _oc oc

# --- PATH ---
# Deduplicate PATH entries
typeset -U path

# Add to PATH (prepend for priority)
path=("${KREW_ROOT:-$HOME/.krew}/bin" "$HOME/.local/bin" $path)

# Export PATH
export PATH

# --- Plugins (guarded). Keep ONLY ONE highlighter; fast is, well, faster. ---
# zsh-autosuggestions
[[ -r /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh ]] && \
  source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh

# zsh-fast-syntax-highlighting (load AFTER completion & autosuggestions)
[[ -r /opt/homebrew/opt/zsh-fast-syntax-highlighting/share/zsh-fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh ]] && \
  source /opt/homebrew/opt/zsh-fast-syntax-highlighting/share/zsh-fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh

# If you prefer the regular highlighter, comment out the fast one above and use this instead (but not both):
# [[ -r /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]] && \
#   source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# zoxide (smart cd)
(( $+commands[zoxide] )) && eval "$(zoxide init zsh)"

# fzf (fuzzy finder): key bindings and completion
[[ -r /opt/homebrew/opt/fzf/shell/key-bindings.zsh ]] && source /opt/homebrew/opt/fzf/shell/key-bindings.zsh
[[ -r /opt/homebrew/opt/fzf/shell/completion.zsh    ]] && source /opt/homebrew/opt/fzf/shell/completion.zsh

# --- Completion styling ---
zstyle ':completion:*' menu select                              # enable selection menu
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'      # case-insensitive matching
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"        # use LS_COLORS for completion
zstyle ':completion:*' group-name ''                            # group results
zstyle ':completion:*' format '%B%d%b'                         # format group names
zstyle ':completion:*:descriptions' format '%U%F{cyan}%d%f%u'  # format descriptions
zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#)*=0=01;31'
zstyle ':completion:*' rehash true                              # rehash on completion

# zsh-vi-mode (enhanced vi-mode; safe to load without bindkey -v)
[[ -r /opt/homebrew/share/zsh-vi-mode/zsh-vi-mode.plugin.zsh ]] && \
  source /opt/homebrew/share/zsh-vi-mode/zsh-vi-mode.plugin.zsh

# direnv (per-directory environment automation)
(( $+commands[direnv] )) && eval "$(direnv hook zsh)"

# Load history file after all plugins (some plugins may reset history settings)
fc -R "$HISTFILE" 2>/dev/null || true

# fzf-tab (enhanced completion UI) — load if installed
if [[ -r "${HOME}/.zsh/plugins/fzf-tab/fzf-tab.plugin.zsh" ]]; then
  source "${HOME}/.zsh/plugins/fzf-tab/fzf-tab.plugin.zsh"
fi

# --- Optional: vi-mode to leverage Starship's vimcmd_symbol ---
# bindkey -v
# KEYTIMEOUT=1

# --- Aliases ---
# Directory navigation
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias ~="cd ~"
alias -- -="cd -"

# Listing
alias ll="ls -la"
alias la="ls -la"
alias l="ls -l"
alias ls="ls -G"  # colorized ls on macOS

# File operations
alias tailf="tail -f"
alias grep="grep --color=auto"
alias fgrep="fgrep --color=auto"
alias egrep="egrep --color=auto"

# Editors
alias vi="nvim"
alias vim="nvim"
alias edit="nvim"

# Kubernetes
alias k=kubectl
alias kgp="kubectl get pods"
alias kgs="kubectl get svc"
alias kgd="kubectl get deploy"
alias kgn="kubectl get nodes"
alias kdp="kubectl describe pod"
alias kdel="kubectl delete"
alias kaf="kubectl apply -f"
alias kdf="kubectl delete -f"
alias rke2-dev="kubie ctx sc-k8s-rke2-dev"
alias rke2-prod="kubie ctx sc-hwinf-02"

# Git shortcuts
alias gs="git status"
alias ga="git add"
alias gc="git commit"
alias gp="git push"
alias gl="git pull"
alias gd="git diff"
alias gb="git branch"
alias gco="git checkout"
alias glog="git log --oneline --graph --decorate"

# System
alias df="df -h"
alias du="du -h"
alias free="top -l 1 | head -n 10 | grep PhysMem"  # macOS memory info
alias ports="lsof -i -P -n | grep LISTEN"          # show listening ports

# Safety
alias rm="rm -i"
alias cp="cp -i"
alias mv="mv -i"

# Misc
alias reload="source ~/.zshrc"
alias path="echo $PATH | tr ':' '\n'"
alias now="date '+%Y-%m-%d %H:%M:%S'"

# --- Useful functions ---
# Create directory and cd into it
mkcd() { mkdir -p "$1" && cd "$1" }

# Extract various archive formats
extract() {
  if [ -f "$1" ]; then
    case "$1" in
      *.tar.bz2)   tar xjf "$1"     ;;
      *.tar.gz)    tar xzf "$1"     ;;
      *.bz2)       bunzip2 "$1"     ;;
      *.rar)       unrar e "$1"     ;;
      *.gz)        gunzip "$1"      ;;
      *.tar)       tar xf "$1"      ;;
      *.tbz2)      tar xjf "$1"     ;;
      *.tgz)       tar xzf "$1"     ;;
      *.zip)       unzip "$1"       ;;
      *.Z)         uncompress "$1"  ;;
      *.7z)        7z x "$1"        ;;
      *)           echo "'$1' cannot be extracted via extract()" ;;
    esac
  else
    echo "'$1' is not a valid file"
  fi
}

# Find files by name (case-insensitive)
ff() { find . -type f -iname "*$1*" }

# Find directories by name (case-insensitive)
fdir() { find . -type d -iname "*$1*" }

# Quick search in history
h() { history | grep "$1" }

# Show top 10 commands from history
topcmd() { history | awk '{print $2}' | sort | uniq -c | sort -rn | head -10 }

# --- Environment variables ---
export EDITOR="nvim"
export VISUAL="nvim"
export PAGER="less"
export LESS="-R"

# --- Extra tools ---
[[ -r ~/.config/k8pk.sh ]] && source ~/.config/k8pk.sh

# --- Prompt ---
eval "$(starship init zsh)"

# --- History: Save on exit ---
# Ensure history is saved when shell exits
zshaddhistory() {
  # This function is called before each command is added to history
  # Return 0 to add, 1 to skip
  return 0
}

# Save history on exit
zshexit() {
  fc -W "$HISTFILE" 2>/dev/null || true
}

# --- iTerm2 integration ---
test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"%
