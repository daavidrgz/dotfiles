if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Language
export LANG=en_GB.utf8

# Default editor
export VISUAL=nano
export EDITOR=$VISUAL

# Config files
export XDG_CONFIG_HOME=/home/david/.config

# Sxhkd
export SXHKD_SHELL=/bin/bash

# Default PATH
export PATH=/usr/local/bin:/usr/bin:/bin:/usr/local/sbin:/home/david/.local/bin

# Flutter
#export ANDROID_HOME=/home/david/.android/android-sdk
#export PATH=$PATH:$ANDROID_HOME/emulator
#export PATH=$PATH:$ANDROID_HOME/platform-tools/
#export PATH=$PATH:$ANDROID_HOME/tools/bin/
#export PATH=$PATH:$ANDROID_HOME/tools/
#export PATH=$PATH:/home/david/.android/flutter/bin

# Rust
export PATH=$PATH:/home/david/.cargo/bin

# Java
export JAVA_HOME=/usr/lib/jvm/java-11-openjdk
export PATH=$PATH:$JAVA_HOME/bin

# Custom Scripts
export PATH=$PATH:/home/david/scripts

# Temporal exports
export PATH=$PATH:/home/david/works/ri/lucene-9.0.0/bin

# Fix the Java problem
export _JAVA_AWT_WM_NONREPARENTING=1

# Lines configured by zsh-newuser-install
HISTFILE=~/.zsh_history
HISTSIZE=50000
SAVEHIST=50000
bindkey -e

# Completions
autoload -Uz compinit && compinit

# ZSH Plugins
source /usr/share/zsh-theme-powerlevel10k/powerlevel10k.zsh-theme
source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
# source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source /usr/share/zsh/plugins/zsh-history-substring-search/zsh-history-substring-search.zsh
# source /usr/share/zsh/plugins/zsh-autocomplete/zsh-autocomplete.plugin.zsh

[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# Temporal aliases
alias cdd='cd ~/github/gtheme-desktops'
alias cdw='cd ~/github/gtheme-wallpapers'
alias cdt='cd ~/github/gtheme-themes'
alias cdg='cd ~/github/gtheme'
alias cdc='cd ~/.config/gtheme'


# Default aliases
alias la='ls -A'
alias l='ls -CF'
alias ls='ls --color=auto'
alias dir='dir --color=auto'
alias vdir='vdir --color=auto'
alias grep='grep --color=auto'

# My aliases
alias ll='LC_COLLATE=C ls -alhF --group-directories-first'
alias tree='tree -C'
alias cat='bat'
alias catp='bat -p'
alias llle='exa -l -ga --octal-permissions'
alias feh='feh -Fd --draw-tinted --conversion-timeout 5'
alias vtop="vtop --theme brew"
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

# Git aliases
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gst='git status'
alias gpl='git pull'
alias fgc='git add .;git commit -m "Fast committed";git push'

# Cargo aliases
alias cb='cargo build'
alias cc='cargo check'
alias cr='cargo run -q'
alias ct='cargo test'

# Gtheme aliases
alias gt='gtheme theme apply'
alias gd='gtheme desktop apply'

# Dir autojump
[[ -r "/usr/share/z/z.sh" ]] && source /usr/share/z/z.sh

eval $(thefuck --alias)

# Setting the correct key bindings
bindkey  "^[[H"   beginning-of-line
bindkey  "^[[F"   end-of-line
bindkey  "^[[3~"  delete-char

bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down

# Colored man pages
export LESS_TERMCAP_mb=$'\E[1;34m'     # begin bold
export LESS_TERMCAP_md=$'\E[1;34m'     # begin blink
export LESS_TERMCAP_me=$'\E[0m'        # reset bold/blink
export LESS_TERMCAP_so=$'\E[01;35m'    # begin reverse video
export LESS_TERMCAP_se=$'\E[0m'        # reset reverse video
export LESS_TERMCAP_us=$'\E[1;32m'     # begin underline
export LESS_TERMCAP_ue=$'\E[0m'        # reset underline
