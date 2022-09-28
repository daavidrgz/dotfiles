if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Default home folder
HOME_DIR=/home/david

# Default PATH
export PATH=/usr/local/bin:/usr/bin:/bin:/usr/local/sbin:$HOME_DIR/.local/bin

# Language
export LANG=en_GB.utf8

# Default apps
export VISUAL=nano
export EDITOR=$VISUAL
export FILE_EXPLORER=ranger

# Config files
export XDG_CONFIG_HOME=$HOME_DIR/.config

# Sxhkd
export SXHKD_SHELL=/bin/bash

# Node
export N_PREFIX=$HOME/.n
export PATH=$N_PREFIX/bin:$PATH

# Rust binaries
export PATH=$PATH:$HOME_DIR/.cargo/bin

# Ocaml binaries
export PATH=$PATH:$HOME_DIR/.opam/default/bin

# Java
#export JAVA_HOME=/usr/lib/jvm/java-11-openjdk
#export JAVA_HOME=/usr/lib/jvm/java-18-openjdk
export JAVA_HOME=/usr/lib/jvm/java-15-openjdk
export PATH=$PATH:$JAVA_HOME/bin
export _JAVA_AWT_WM_NONREPARENTING=1

# Custom Scripts
export PATH=$PATH:$HOME_DIR/scripts

# History
HISTFILE=~/.zsh_history
HISTSIZE=50000
SAVEHIST=50000
bindkey -e

# ZSH antidote to load plugins
ANTIDOTE_HOME=$HOME_DIR/.antidote
source /usr/share/zsh-antidote/antidote.zsh
antidote load

# Powerlevel10k config
[[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh

# Suffix aliases
alias -g ...='../..'
alias -g ....='../../..'
alias -g .....='../../../..'
alias -g ......='../../../../..'
alias -g .......='../../../../../..'

# Temporal aliases
alias cdd="cd $HOME_DIR/github/gtheme/desktops"
alias cdw="cd $HOME_DIR/github/gtheme/wallpapers"
alias cdt="cd $HOME_DIR/github/gtheme/themes"
alias cdg="cd $HOME_DIR/github/gtheme"
alias cdc="cd $HOME_DIR/.config/gtheme"

# Default aliases
alias la='ls -A'
alias l='ls -CF'
alias ls='ls --color=auto'
alias dir='dir --color=auto'
alias vdir='vdir --color=auto'
alias grep='grep --color=auto'

# Maven aliases
alias mvnc='mvn compile assembly:single'

# My aliases
alias ll='LC_COLLATE=C ls -alhF --group-directories-first'
alias tree='tree -C'
alias cat='bat'
alias catp='bat -p'
alias feh='feh -Fd --draw-tinted --conversion-timeout 5'
alias onesync='rclone sync -P OneDrive:Música/Canciones\ Hi-Res music'
alias xokas='firefox twitch.tv/elxokas &>/dev/null &; disown %1'
alias ttyc='tty-clock -c -s -b'
alias purge='sudo pacman -Rns $(pacman -Qdtq)'
alias bcat='/bin/cat'
alias pdf='zathura --fork'
alias dup='kitty . &; disown'
alias f='fuck'
alias du='du -d 1 -ha'
alias ell='exa -laF --icons --group-directories-first'
alias unimatrix='unimatrix -s 96 -f -l o'
alias r='ranger'
alias ncm='ncmpcpp'
alias c='code .'
alias rg='rg --hidden --no-ignore'
alias ..='cd ..'
alias cpufetch='cpufetch --logo-intel-new'
alias df='df -h'

# Git aliases
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gb='git branch'
alias gco='git checkout'
alias gst='git status'
alias gpl='git pull'
alias fgc='git add .;git commit -m "Fast committed";git push'

# Docker aliases
alias dpsi='docker images'
alias dps='docker ps'
alias dst='docker stop $(docker ps -q)'
alias drm='docker rm $(docker ps -qa)'
alias dcu='docker compose up'
alias dcd='docker compose down'
alias dcl='docker compose logs -f'

# Cargo aliases
alias cb='cargo build'
alias cc='cargo check'
alias cr='cargo run -q'
alias ct='cargo test'

# Node aliases
alias npd='npm run dev'

# Gtheme aliases
alias gt='gtheme theme apply'
alias gd='gtheme desktop apply'

# Work script
[[ -r "$HOME_DIR/source-scripts/work.sh" ]] && source $HOME_DIR/source-scripts/work.sh

# Setting the correct key bindings
bindkey  "^[[H"    beginning-of-line
bindkey  "^[[F"    end-of-line
bindkey  "^[[3~"   delete-char
bindkey  "^[[1;3C" forward-word
bindkey  "^[[1;3D" backward-word

# Colored man pages
export LESS_TERMCAP_mb=$'\E[1;34m'     # begin bold
export LESS_TERMCAP_md=$'\E[1;34m'     # begin blink
export LESS_TERMCAP_me=$'\E[0m'        # reset bold/blink
export LESS_TERMCAP_so=$'\E[01;35m'    # begin reverse video
export LESS_TERMCAP_se=$'\E[0m'        # reset reverse video
export LESS_TERMCAP_us=$'\E[1;32m'     # begin underline
export LESS_TERMCAP_ue=$'\E[0m'        # reset underline

# Completions + gtheme
fpath=($HOME_DIR/.gtheme/completions $fpath)
autoload -Uz compinit && compinit -u
zstyle ':completion:*' menu select