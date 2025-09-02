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

get_auto_updatable_packages() {
    # List of packages that have opted-in for automatic updates
    # Add package names here to enable auto-updates
    cat <<EOF
claude-code
EOF
}

update_package() {
    local package="$1"
    log "Updating $package..."

    # Use nix-update to update the package
    nix run github:Mic92/nix-update/1b5bc1e -- --file ./packages --version stable "$package"

    log "$package updated successfully"
}

rebuild_home_manager() {
    log "Rebuilding Home Manager configuration..."
    cd "$REPO_ROOT"
    home-manager switch
}

main() {
    local package="${1:-all}"

    # Get list of available and auto-updatable packages
    local available_packages
    local auto_updatable_packages
    available_packages=$(get_available_packages)
    auto_updatable_packages=$(get_auto_updatable_packages)

    if [[ "$package" == "all" ]]; then
        # Update only auto-updatable packages
        while IFS= read -r pkg; do
            update_package "$pkg"
        done <<<"$auto_updatable_packages"
    elif echo "$available_packages" | grep -q "^$package$"; then
        # Update specific package
        update_package "$package"
    else
        log "Unknown package: $package"
        log "Available packages:"
        echo "$available_packages" | while read -r line; do echo "  $line"; done >&2
        log "Auto-updatable packages:"
        echo "$auto_updatable_packages" | while read -r line; do echo "  $line"; done >&2
        log "Usage: $0 [package-name|all]"
        exit 1
    fi

    rebuild_home_manager
}

if [[ "${BASH_SOURCE[0]:-}" == "${0}" ]]; then
    main "$@"
fi
