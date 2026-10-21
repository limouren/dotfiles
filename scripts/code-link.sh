#!/usr/bin/env bash
#
# Print a link that opens each path in the local VS Code
# through Remote-SSH. Works over plain SSH and in herdr panes.
#
# herdr opens only http(s) links on the client, so the link goes through
# vscode.dev, which redirects to the vscode-remote URL.

set -euo pipefail

# The SSH host name that the local machine uses for this machine.
readonly SSH_HOST="${CODE_LINK_SSH_HOST:-$(uname -n)}"

# Inside a VS Code terminal, the Remote-SSH CLI already opens local windows.
run_vscode_cli_if_available() {
	[[ -n "${VSCODE_IPC_HOOK_CLI:-}" ]] || return 0

	local self candidate
	self="$(realpath "$0")"
	while IFS= read -r candidate; do
		if [[ "$(realpath "$candidate")" != "$self" ]]; then
			exec "$candidate" "$@"
		fi
	done < <(type -ap code)
}

# Percent-encode $1. Keep unreserved characters and the characters in $2.
url_encode() {
	local LC_ALL=C
	local input="$1" keep="${2:-}" encoded="" char i
	for ((i = 0; i < ${#input}; i++)); do
		char="${input:i:1}"
		if [[ "$char" == [A-Za-z0-9._~-] || "$keep" == *"$char"* ]]; then
			encoded+="$char"
		else
			printf -v char '%%%02X' "'$char"
			encoded+="$char"
		fi
	done
	printf '%s' "$encoded"
}

print_link() {
	local path="$1" uri link
	# Encode the path for the vscode:// URL, then the URL for the query.
	uri="vscode://vscode-remote/ssh-remote+${SSH_HOST}$(url_encode "$path" /)"
	link="https://vscode.dev/redirect?url=$(url_encode "$uri")"

	printf '\e]8;;%s\e\\\e[4;34mClick to open %s in VS Code\e[24;39m\e]8;;\e\\\n' \
		"$link" "$path"
}

main() {
	run_vscode_cli_if_available "$@"

	if (($# == 0)); then
		set -- .
	fi

	local target
	for target in "$@"; do
		print_link "$(realpath -m -- "$target")"
	done
}

main "$@"
