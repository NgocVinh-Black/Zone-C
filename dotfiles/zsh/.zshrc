# Zone-C — zsh

HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt share_history hist_ignore_all_dups hist_reduce_blanks auto_cd interactive_comments

autoload -Uz compinit && compinit
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'

bindkey -e
bindkey '^[[1;5C' forward-word
bindkey '^[[1;5D' backward-word
bindkey '^[[H' beginning-of-line
bindkey '^[[F' end-of-line
bindkey '^[[3~' delete-char

# Plugins from the Arch repos, when installed.
[[ -r /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh ]] &&
    source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
[[ -r /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]] &&
    source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# Prompt: directory, git branch, arrow.
autoload -Uz vcs_info
precmd() { vcs_info }
zstyle ':vcs_info:git:*' formats ' %F{6}%b%f'
setopt prompt_subst
PROMPT='%F{4}%~%f${vcs_info_msg_0_} %(?.%F{2}.%F{1})❯%f '

export EDITOR=nvim
export PATH="$HOME/.local/bin:$PATH"

alias ls='ls --color=auto'
alias ll='ls -lah'
alias grep='grep --color=auto'
alias zc-log='qs -c zone-c log'
alias zc-restart='pkill -x qs; (qs -c zone-c >/dev/null 2>&1 &)'

# Machine-specific additions that are not tracked in git.
[[ -r ~/.zshrc.local ]] && source ~/.zshrc.local
