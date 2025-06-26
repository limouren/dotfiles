#!/bin/bash

set -euo pipefail

HOME_NIX_FILE="$(dirname "$0")/../home.nix"
PACKAGE_NAME="@anthropic-ai/claude-code"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >&2
}

get_current_version() {
    grep -o 'claude-version = "[^"]*"' "$HOME_NIX_FILE" | cut -d'"' -f2
}

get_latest_version() {
    curl -s "https://registry.npmjs.org/$PACKAGE_NAME" | \
        jq -r '.["dist-tags"].latest'
}

get_package_hash() {
    local version="$1"
    local url="https://registry.npmjs.org/$PACKAGE_NAME/-/claude-code-${version}.tgz"
    
    # Get hash in SRI format directly
    nix-prefetch-url --unpack "$url" --type sha256 2>/dev/null | \
        xargs nix hash to-sri --type sha256
}

update_home_nix() {
    local new_version="$1"
    local new_hash="$2"
    
    if [[ "${DRY_RUN:-}" == "true" ]]; then
        log "DRY_RUN: Would update home.nix with version $new_version and hash $new_hash"
        return 0
    fi
    
    log "Updating home.nix with version $new_version and hash $new_hash"
    
    # Update version
    sed -i.bak "s/claude-version = \"[^\"]*\"/claude-version = \"$new_version\"/" "$HOME_NIX_FILE"
    
    # Update hash - only for claude-code section
    sed -i.bak "/claude-code.*overrideAttrs/,/});/{s/hash = \"[^\"]*\"/hash = \"$new_hash\"/;}" "$HOME_NIX_FILE"
    
    # Remove backup file
    rm -f "${HOME_NIX_FILE}.bak"
}

rebuild_home_manager() {
    log "Rebuilding Home Manager configuration..."
    home-manager switch
}

main() {
    log "Checking for Claude Code updates..."
    
    current_version=$(get_current_version)
    latest_version=$(get_latest_version)
    
    log "Current version: $current_version"
    log "Latest version: $latest_version"
    
    if [[ "$current_version" == "$latest_version" ]]; then
        log "Already on latest version"
        exit 0
    fi
    
    log "New version available: $latest_version"
    log "Fetching package hash..."
    
    new_hash=$(get_package_hash "$latest_version")
    log "New hash: $new_hash"
    
    update_home_nix "$latest_version" "$new_hash"
    
    if [[ "${DRY_RUN:-}" != "true" ]]; then
        rebuild_home_manager
        log "Successfully updated Claude Code to version $latest_version"
    else
        log "DRY_RUN mode: Would update to version $latest_version with hash $new_hash"
    fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi