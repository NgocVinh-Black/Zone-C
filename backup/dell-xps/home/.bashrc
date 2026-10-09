#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

# ble.sh: goi y lenh cu tu lich su (autosuggestion)
[[ -f ~/.local/share/blesh/ble.sh ]] && source -- ~/.local/share/blesh/ble.sh --attach=none

# Lich su lenh: luu nhieu, khong trung, ghi ngay
HISTSIZE=50000
HISTFILESIZE=100000
HISTCONTROL=ignoreboth:erasedups
shopt -s histappend
PROMPT_COMMAND="history -a${PROMPT_COMMAND:+; $PROMPT_COMMAND}"

alias ls='ls --color=auto'
alias grep='grep --color=auto'
PS1='[\u@\h \W]\$ '
export PATH="$HOME/.local/bin:$PATH"

# Banner Zone-C khi mo terminal
zonec-banner
fastfetch

# Gan ble.sh (de o cuoi file)
[[ ${BLE_VERSION-} ]] && ble-attach
