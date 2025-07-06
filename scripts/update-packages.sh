#!/bin/bash

set -euo pipefail

# Find the script directory and repo root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >&2
}

get_available_packages() {
    # Extract package names from packages/default.nix
    nix eval --json --impure --expr "builtins.attrNames (import $REPO_ROOT/packages {})" 2>/dev/null | jq -r '.[]'
}

update_package() {
    local package="$1"
    log "Updating $package..."

    # Determine version parameter
    local version_param="stable"
    if [[ "$package" == "claude-code" ]]; then
        local latest_version
        latest_version=$(npm view @anthropic-ai/claude-code version 2>/dev/null)

        if [[ -z "$latest_version" ]]; then
            log "Failed to get latest version for claude-code"
            return 1
        fi

        log "Latest claude-code version: $latest_version"
        version_param="$latest_version"
    fi

    # Use nix-update to update the package
    nix-shell -p nix-update --run "cd '$REPO_ROOT' && nix-update --file ./packages --version='$version_param' '$package'"

    log "$package updated successfully"
}

rebuild_home_manager() {
    log "Rebuilding Home Manager configuration..."
    cd "$REPO_ROOT"
    home-manager switch
}

main() {
    local package="${1:-all}"

    # Get list of available packages
    local available_packages
    available_packages=$(get_available_packages)

    if [[ "$package" == "all" ]]; then
        # Update all packages
        while IFS= read -r pkg; do
            update_package "$pkg"
        done <<<"$available_packages"
    elif echo "$available_packages" | grep -q "^$package$"; then
        # Update specific package
        update_package "$package"
    else
        log "Unknown package: $package"
        log "Available packages:"
        echo "$available_packages" | while read -r line; do echo "  $line"; done >&2
        log "Usage: $0 [package-name|all]"
        exit 1
    fi

    rebuild_home_manager
}

if [[ "${BASH_SOURCE[0]:-}" == "${0}" ]]; then
    main "$@"
fi
