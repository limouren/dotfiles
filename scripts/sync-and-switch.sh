#!/bin/bash

set -euo pipefail

# Find the repo root
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >&2
}

main() {
    cd "$REPO_ROOT"

    log "Fetching latest changes from remote..."
    git fetch origin

    # Check if there are updates
    local behind=$(git rev-list --count HEAD..origin/$(git branch --show-current))

    if [[ "$behind" -eq 0 ]]; then
        log "Already up to date"
        exit 0
    fi

    log "Pulling $behind commits..."
    git pull origin $(git branch --show-current)

    log "Switching Home Manager configuration..."
    home-manager switch

    log "Sync complete!"
}

if [[ "${BASH_SOURCE[0]:-}" == "${0}" ]]; then
    main "$@"
fi
