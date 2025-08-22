#!/bin/bash

set -euo pipefail

# Source Nix environment for launchd
if [[ -f /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]]; then
    # Temporarily disable unbound variable check for nix-daemon.sh
    set +u
    # shellcheck source=/dev/null
    source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
    set -u
fi

# Find the repo root
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >&2
}

notify() {
    local title="$1"
    local message="$2"
    local sound="${3:-Glass}"
    
    terminal-notifier -title "$title" -message "$message" -sound "$sound"
    log "NOTIFICATION: $title - $message"
}

main() {
    cd "$REPO_ROOT" || {
        notify "Home Manager Sync Failed" "Failed to change to config directory" "Basso"
        exit 1
    }

    log "Fetching latest changes from remote..."
    if ! git fetch origin; then
        notify "Home Manager Sync Failed" "Failed to fetch from remote repository" "Basso"
        exit 1
    fi

    # Check if there are updates
    local current_branch
    current_branch=$(git branch --show-current)
    local behind
    behind=$(git rev-list --count "HEAD..origin/$current_branch")

    if [[ "$behind" -eq 0 ]]; then
        log "Already up to date"
        exit 0
    fi

    log "Pulling $behind commits..."
    if ! git pull origin "$current_branch"; then
        notify "Home Manager Sync Failed" "Failed to pull changes from remote" "Basso"
        exit 1
    fi

    log "Switching Home Manager configuration..."
    if ! home-manager switch; then
        notify "Home Manager Sync Failed" "home-manager switch failed" "Basso"
        exit 1
    fi

    log "Sync complete!"
    notify "Home Manager Sync" "Successfully updated with $behind commits" "Glass"
}

if [[ "${BASH_SOURCE[0]:-}" == "${0}" ]]; then
    main "$@"
fi
