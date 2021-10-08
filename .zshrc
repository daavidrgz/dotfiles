# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Completions
autoload -Uz compinit && compinit

# Language
export LANG=en_GB.utf8

# Default editor
export VISUAL=nano

# Config files
export XDG_CONFIG_HOME=/home/david/.config

# Sxhkd
export SXHKD_SHELL=/bin/bash

# Default PATH
export PATH=/usr/local/bin:/usr/bin:/bin:/usr/local/sbin:/home/david/.local/bin

# Java
export JAVA_HOME=/usr/lib/jvm/java-11-openjdk
export PATH=$PATH:$JAVA_HOME/bin

# Custom Scripts
export PATH=$PATH:/home/david/Scripts

# Temporal exports
export PATH=$PATH:/home/david/Documents/GitHub/gtheme

# Fix the Java problem
export _JAVA_AWT_WM_NONREPARENTING=1

# Lines configured by zsh-newuser-install
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
bindkey -e
# End of lines configured by zsh-newuser-install
# The following lines were added by compinstall
# zstyle :compinstall filename '/home/david/.zshrc'

# autoload -Uz compinit
# compinit
# End of lines added by compinstall

source /usr/share/zsh-theme-powerlevel10k/powerlevel10k.zsh-theme
source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
# source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source /usr/share/zsh/plugins/zsh-history-substring-search/zsh-history-substring-search.zsh
# source /usr/share/zsh/plugins/zsh-autocomplete/zsh-autocomplete.plugin.zsh

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# Default aliases
alias la='ls -A'
alias l='ls -CF'

alias ls='ls --color=auto'
alias dir='dir --color=auto'
alias vdir='vdir --color=auto'

alias grep='grep --color=auto'

# My aliases
alias ll='ls -alF --group-directories-first'
alias tree='tree -C'
alias cat='bat'
alias llle='exa -l -ga --octal-permissions'
alias feh='feh -Fd --draw-tinted --conversion-timeout 5'
alias vtop="vtop --theme brew"
alias onesync='rclone sync -P OneDrive:Música/Canciones\ Hi-Res Music'
alias xokas='firefox twitch.tv/elxokas &>/dev/null &; disown %1'
alias ttyc='tty-clock -c -s -b'
alias purge='sudo pacman -Rns $(pacman -Qdtq)'
alias bcat='/bin/cat'
alias pdf='zathura --fork'
alias dup='kitty . &; disown'
alias f='fuck'
alias du='du -d 1 -ha'
alias lll='lsd -la --group-dirs first'
alias unimatrix='unimatrix -s 96 -f -l o'

# Git aliases
alias ga='git add'
alias gc='git commit'
alias gp='git push'

# Key press rate
xset r rate 200 40

# Setting the correct key bindings
bindkey  "^[[H"   beginning-of-line
bindkey  "^[[F"   end-of-line
bindkey  "^[[3~"  delete-char

bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down

eval $(thefuck --alias)

export LESS_TERMCAP_mb=$'\E[1;34m'     # begin bold
export LESS_TERMCAP_md=$'\E[1;34m'     # begin blink
export LESS_TERMCAP_me=$'\E[0m'        # reset bold/blink
export LESS_TERMCAP_so=$'\E[01;35m'    # begin reverse video
export LESS_TERMCAP_se=$'\E[0m'        # reset reverse video
export LESS_TERMCAP_us=$'\E[1;32m'     # begin underline
export LESS_TERMCAP_ue=$'\E[0m'        # reset underline
