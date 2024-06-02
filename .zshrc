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
# export JAVA_HOME=/usr/lib/jvm/java-11-openjdk
#export JAVA_HOME=/usr/lib/jvm/java-18-openjdk
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk
#export JAVA_HOME=/usr/lib/jvm/java-15-openjdk
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

# LS_COLORS
LS_COLORS='rs=0:di=01;34:ln=01;36:mh=00:pi=40;33:so=01;35:do=01;35:bd=40;33;01:cd=40;33;01:or=40;31;01:mi=00:su=37;41:sg=30;43:ca=00:tw=30;42:ow=34;42:st=37;44:ex=01;32:*.tar=01;31:*.tgz=01;31:*.arc=01;31:*.arj=01;31:*.taz=01;31:*.lha=01;31:*.lz4=01;31:*.lzh=01;31:*.lzma=01;31:*.tlz=01;31:*.txz=01;31:*.tzo=01;31:*.t7z=01;31:*.zip=01;31:*.z=01;31:*.dz=01;31:*.gz=01;31:*.lrz=01;31:*.lz=01;31:*.lzo=01;31:*.xz=01;31:*.zst=01;31:*.tzst=01;31:*.bz2=01;31:*.bz=01;31:*.tbz=01;31:*.tbz2=01;31:*.tz=01;31:*.deb=01;31:*.rpm=01;31:*.jar=01;31:*.war=01;31:*.ear=01;31:*.sar=01;31:*.rar=01;31:*.alz=01;31:*.ace=01;31:*.zoo=01;31:*.cpio=01;31:*.7z=01;31:*.rz=01;31:*.cab=01;31:*.wim=01;31:*.swm=01;31:*.dwm=01;31:*.esd=01;31:*.avif=01;35:*.jpg=01;35:*.jpeg=01;35:*.mjpg=01;35:*.mjpeg=01;35:*.gif=01;35:*.bmp=01;35:*.pbm=01;35:*.pgm=01;35:*.ppm=01;35:*.tga=01;35:*.xbm=01;35:*.xpm=01;35:*.tif=01;35:*.tiff=01;35:*.png=01;35:*.svg=01;35:*.svgz=01;35:*.mng=01;35:*.pcx=01;35:*.mov=01;35:*.mpg=01;35:*.mpeg=01;35:*.m2v=01;35:*.mkv=01;35:*.webm=01;35:*.webp=01;35:*.ogm=01;35:*.mp4=01;35:*.m4v=01;35:*.mp4v=01;35:*.vob=01;35:*.qt=01;35:*.nuv=01;35:*.wmv=01;35:*.asf=01;35:*.rm=01;35:*.rmvb=01;35:*.flc=01;35:*.avi=01;35:*.fli=01;35:*.flv=01;35:*.gl=01;35:*.dl=01;35:*.xcf=01;35:*.xwd=01;35:*.yuv=01;35:*.cgm=01;35:*.emf=01;35:*.ogv=01;35:*.ogx=01;35:*.aac=00;36:*.au=00;36:*.flac=00;36:*.m4a=00;36:*.mid=00;36:*.midi=00;36:*.mka=00;36:*.mp3=00;36:*.mpc=00;36:*.ogg=00;36:*.ra=00;36:*.wav=00;36:*.oga=00;36:*.opus=00;36:*.spx=00;36:*.xspf=00;36:*~=00;90:*#=00;90:*.bak=00;90:*.old=00;90:*.orig=00;90:*.part=00;90:*.rej=00;90:*.swp=00;90:*.tmp=00;90:*.dpkg-dist=00;90:*.dpkg-old=00;90:*.ucf-dist=00;90:*.ucf-new=00;90:*.ucf-old=00;90:*.rpmnew=00;90:*.rpmorig=00;90:*.rpmsave=00;90:';
export LS_COLORS

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
alias cpufetch='cpufetch --logo-intel-new'
alias df='df -h'
alias svgtopdf='inkscape --export-type=pdf'
alias shm='dpi-shutdown mobile'
alias shd='dpi-shutdown docked'
alias cleantex='rm *.aux *.fdb_latexmk *.fls *.synctex.gz *.log'

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

# Mix aliases
alias mixt='mix test --max-failures 1'
alias mixta='mix test'
alias mixdia='mix dialyzer'
alias mixcred='mix credo'
alias mixci='mix format && mix credo && mix dialyzer && mix test && mix compile'
alias mixc='mix compile'
alias mixd='mix deps.get'
alias mixclean='mix deps.clean --unused'

# Npm aliases
alias npi='npm install'
alias npd='npm run dev'

# Gtheme aliases
alias gt='gtheme theme apply'
alias gd='gtheme desktop apply'

# Work script
[[ -r "$HOME_DIR/source-scripts/work.sh" ]] && source $HOME_DIR/source-scripts/work.sh

# Setting the keybindings for history substring search
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down

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

# Completions style
zstyle ':completion:*' menu select
zstyle ':completion:*:default' list-colors ${(s.:.)LS_COLORS}
