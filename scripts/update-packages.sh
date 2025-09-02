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

get_monitored_flake_tools() {
    # List of tools from flake inputs that should be monitored for updates
    # Add tool names here to monitor for updates from nix-ai-tools
    cat <<EOF
opencode
codex
EOF
}

update_package() {
    local package="$1"
    log "Updating $package..."

    # Use nix-update to update the package
    nix run github:Mic92/nix-update/1b5bc1e -- --file ./packages --version stable "$package"

    log "$package updated successfully"
}

update_nix_ai_tools_if_needed() {
    log "Checking nix-ai-tools for updates..."

    # Get list of monitored tools
    local monitored_tools
    monitored_tools=$(get_monitored_flake_tools)

    # Compare current flake input versions with upstream
    local has_updates=false
    while IFS= read -r tool; do
        local current_hash
        current_hash=$(nix eval --raw --impure --expr "let system = builtins.currentSystem; in (builtins.getFlake (toString ./.)).inputs.nix-ai-tools.packages.\${system}.$tool.drvPath" 2>/dev/null || echo "not-available")

        local upstream_hash
        upstream_hash=$(nix eval --raw "github:numtide/nix-ai-tools#$tool.drvPath" 2>/dev/null || echo "not-available")

        if [[ "$current_hash" != "$upstream_hash" ]]; then
            log "Update available for $tool (current: ${current_hash##*/}, upstream: ${upstream_hash##*/})"
            has_updates=true
            break
        fi
    done <<<"$monitored_tools"

    if [[ "$has_updates" == "true" ]]; then
        log "Tool updates found, updating nix-ai-tools..."
        nix flake update nix-ai-tools
        log "nix-ai-tools updated successfully"
    else
        log "No tool updates available in nix-ai-tools"
    fi
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

    # Check nix-ai-tools for updates
    update_nix_ai_tools_if_needed

    rebuild_home_manager
}

if [[ "${BASH_SOURCE[0]:-}" == "${0}" ]]; then
    main "$@"
fi
