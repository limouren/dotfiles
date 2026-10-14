#!/bin/bash

set -euo pipefail

# Source Nix environment for launchd and systemd
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
    local outcome="$1"
    local title="$2"
    local message="$3"

    log "NOTIFICATION: $title - $message"

    case "$(uname -s)" in
        Darwin)
            local sound="Glass"
            [[ "$outcome" == "failure" ]] && sound="Basso"
            terminal-notifier -title "$title" -message "$message" -sound "$sound" \
                -execute "open ~/Library/Logs/home-manager-sync.log"
            ;;
        Linux)
            local urgency="normal"
            [[ "$outcome" == "failure" ]] && urgency="critical"
            notify-send --app-name="Home Manager Sync" --urgency="$urgency" \
                "$title" "$message" || true
            ;;
    esac
}

main() {
    cd "$REPO_ROOT" || {
        notify failure "Home Manager Sync Failed" "Failed to change to config directory"
        exit 1
    }

    log "Fetching latest changes from remote..."
    if ! git fetch origin; then
        notify failure "Home Manager Sync Failed" "Failed to fetch from remote repository"
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
        notify failure "Home Manager Sync Failed" "Failed to pull changes from remote"
        exit 1
    fi

    log "Switching Home Manager configuration..."
    if ! home-manager switch; then
        notify failure "Home Manager Sync Failed" "home-manager switch failed"
        exit 1
    fi

    log "Sync complete!"
    notify success "Home Manager Sync" "Successfully updated with $behind commits"
}

if [[ "${BASH_SOURCE[0]:-}" == "${0}" ]]; then
    main "$@"
fi
