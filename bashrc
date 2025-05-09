#!/bin/bash
# Source file if it exists and has a size greater than zero
[[ -s ~/.shell/exports.sh ]] && source ~/.shell/exports.sh
[[ -s ~/.shell/aliases.sh ]] && source ~/.shell/aliases.sh
[[ -s ~/.shell/sourcing.sh ]] && source ~/.shell/sourcing.sh

ssh() {
	if [ -n "$TMUX" ]; then
		tmux -2u rename-window "$(echo $* | rev | cut -d '@' -f1 | rev)"
		command ssh "$@"
		tmux -2u set-window-option automatic-rename "on" >/dev/null
	else
		command ssh "$@"
	fi
}
