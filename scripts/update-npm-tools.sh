#!/bin/bash

set -euo pipefail

TOML_FILE="$(dirname "$0")/../npm-tools.toml"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >&2
}

get_package_info() {
    local package="$1"
    local version npm_package

    # Extract version and npm_package from TOML using sed/grep
    if [[ -f "$TOML_FILE" ]] && grep -q "^\[$package\]" "$TOML_FILE"; then
        # Get the section for this package
        local section_start section_end
        section_start=$(grep -n "^\[$package\]" "$TOML_FILE" | cut -d: -f1)
        section_end=$(tail -n +$((section_start + 1)) "$TOML_FILE" | grep -n "^\[" | head -n1 | cut -d: -f1)

        if [[ -n "$section_end" ]]; then
            section_end=$((section_start + section_end))
        else
            section_end=$(wc -l <"$TOML_FILE")
            section_end=$((section_end + 1))
        fi

        # Extract version and npm_package from the section
        version=$(sed -n "${section_start},${section_end}p" "$TOML_FILE" | grep "^version = " | sed 's/version = "\(.*\)"/\1/')
        npm_package=$(sed -n "${section_start},${section_end}p" "$TOML_FILE" | grep "^npm_package = " | sed 's/npm_package = "\(.*\)"/\1/')
    fi

    echo -e "${version:-}\t${npm_package:-}"
}

get_latest_version() {
    local package_name="$1"
    curl -s "https://registry.npmjs.org/$package_name" |
        jq -r '.["dist-tags"].latest'
}

update_toml() {
    local package="$1"
    local new_version="$2"

    if [[ "${DRY_RUN:-}" == "true" ]]; then
        log "DRY_RUN: Would update $package to version $new_version"
        return 0
    fi

    log "Updating $package to version $new_version"

    # Update TOML file using sed
    # Find the package section and update the version line
    sed -i.bak "/^\[$package\]/,/^\[/ s/^version = .*/version = \"$new_version\"/" "$TOML_FILE"
    rm -f "${TOML_FILE}.bak"
}

rebuild_home_manager() {
    log "Rebuilding Home Manager configuration..."
    home-manager switch
}

update_package() {
    local package="$1"
    log "Checking for $package updates..."

    # Get current version and npm package name
    package_info=$(get_package_info "$package")
    current_version=$(echo "$package_info" | cut -f1)
    npm_package=$(echo "$package_info" | cut -f2)

    if [[ -z "$npm_package" ]]; then
        log "Package $package not found in configuration"
        return 1
    fi

    latest_version=$(get_latest_version "$npm_package")

    log "$package current version: $current_version"
    log "$package latest version: $latest_version"

    if [[ -z "$latest_version" || "$latest_version" == "null" ]]; then
        log "$package: Unable to fetch latest version (package may not exist)"
        return 1
    fi

    if [[ "$current_version" == "$latest_version" ]]; then
        log "$package already on latest version"
        return 0
    fi

    log "$package new version available: $latest_version"

    update_toml "$package" "$latest_version"

    local status_msg="Successfully updated $package to version $latest_version"
    local dry_run_msg="DRY_RUN mode: Would update $package to version $latest_version"

    if [[ "${DRY_RUN:-}" != "true" ]]; then
        log "$status_msg"
    else
        log "$dry_run_msg"
    fi
}

get_all_packages() {
    # Extract all package names using grep and sed
    if [[ -f "$TOML_FILE" ]]; then
        grep "^\[" "$TOML_FILE" | sed 's/^\[\(.*\)\]$/\1/' | tr '\n' ' '
    fi
}

main() {
    local package="${1:-all}"

    if [[ "$package" == "all" ]]; then
        packages=$(get_all_packages)
        for pkg in $packages; do
            update_package "$pkg"
        done
    else
        update_package "$package"
    fi

    if [[ "${DRY_RUN:-}" != "true" ]]; then
        rebuild_home_manager
    fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
