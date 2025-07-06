#!/bin/bash

set -euo pipefail

TOML_FILE="$(dirname "$0")/../npm-tools.toml"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >&2
}

get_package_info() {
    local package="$1"
    local version src_type src_hash npm_deps_hash npm_package github_repo

    # Extract fields from TOML using sed/grep
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

        # Extract fields from the section
        version=$(sed -n "${section_start},${section_end}p" "$TOML_FILE" | grep "^version = " | sed 's/version = "\(.*\)"/\1/')
        src_type=$(sed -n "${section_start},${section_end}p" "$TOML_FILE" | grep "^src_type = " | sed 's/src_type = "\(.*\)"/\1/')
        src_hash=$(sed -n "${section_start},${section_end}p" "$TOML_FILE" | grep "^src_hash = " | sed 's/src_hash = "\(.*\)"/\1/')
        npm_deps_hash=$(sed -n "${section_start},${section_end}p" "$TOML_FILE" | grep "^npm_deps_hash = " | sed 's/npm_deps_hash = "\(.*\)"/\1/')
        npm_package=$(sed -n "${section_start},${section_end}p" "$TOML_FILE" | grep "^npm_package = " | sed 's/npm_package = "\(.*\)"/\1/')
        github_repo=$(sed -n "${section_start},${section_end}p" "$TOML_FILE" | grep "^github_repo = " | sed 's/github_repo = "\(.*\)"/\1/')
    fi

    echo -e "${version:-}\t${src_type:-}\t${src_hash:-}\t${npm_deps_hash:-}\t${npm_package:-}\t${github_repo:-}"
}

get_latest_version() {
    local package_name="$1"
    curl -s "https://registry.npmjs.org/$package_name" |
        jq -r '.["dist-tags"].latest'
}

get_latest_github_version() {
    local github_repo="$1"

    local api_url="https://api.github.com/repos/${github_repo}/releases"
    local response=$(curl -s "$api_url")

    # Get latest stable release (exclude prereleases and nightly/alpha/beta/rc releases)
    echo "$response" | jq -r '.[] | select(.prerelease == false) | .tag_name' | grep -v -E '(nightly|alpha|beta|rc|dev)' | head -n1 | sed 's/^v//'
}

get_package_hash() {
    local package="$1"
    local version="$2"

    log "Calculating hash for $package version $version using nix-build approach"

    # Create a temporary nix expression that uses the actual source definition
    # but updates the version and sets a fake hash
    local temp_dir=$(mktemp -d)
    local current_dir=$(pwd)
    cat >"$temp_dir/default.nix" <<EOF
{ pkgs ? import <nixpkgs> {} }:
let 
  lib = pkgs.lib;
  npm-tools-config = builtins.fromTOML (builtins.readFile $current_dir/npm-tools.toml);
  # Update the version and set fake hash in the config
  updated-config = npm-tools-config // {
    $package = npm-tools-config.$package // { 
      version = "$version"; 
      src_hash = pkgs.lib.fakeHash;
    };
  };
  override = import $current_dir/npm-tools/$package.nix { inherit lib pkgs; npmTools = updated-config; };
in
override.src
EOF

    # Try to build and capture the hash error
    local result
    if result=$(nix-build "$temp_dir/default.nix" 2>&1); then
        log "Unexpected success building source"
        rm -rf "$temp_dir"
        return 1
    else
        # Extract hash from error message
        local hash=$(echo "$result" | grep -o 'got:.*sha256-[A-Za-z0-9+/=]*' | sed 's/got:[[:space:]]*//')
        rm -rf "$temp_dir"

        if [[ -n "$hash" ]]; then
            echo "$hash"
            return 0
        else
            log "Failed to extract hash from build error"
            return 1
        fi
    fi
}

get_npm_deps_hash() {
    local package="$1"
    local version="$2"
    local src_hash="$3"

    log "Calculating npm_deps_hash for $package version $version using prefetch-npm-deps"

    # Get the source path by building it with the correct version and src_hash
    local temp_dir=$(mktemp -d)
    local current_dir=$(pwd)
    cat >"$temp_dir/default.nix" <<EOF
{ pkgs ? import <nixpkgs> {} }:
let 
  lib = pkgs.lib;
  npm-tools-config = builtins.fromTOML (builtins.readFile $current_dir/npm-tools.toml);
  updated-config = npm-tools-config // {
    $package = npm-tools-config.$package // { 
      version = "$version"; 
      src_hash = "$src_hash";
    };
  };
  override = import $current_dir/npm-tools/$package.nix { inherit lib pkgs; npmTools = updated-config; };
in
override.src
EOF

    # Build the source to get its path in /nix/store
    local src_path
    if ! src_path=$(nix-build "$temp_dir/default.nix" --no-out-link 2>/dev/null); then
        log "Failed to build source for $package"
        rm -rf "$temp_dir"
        return 1
    fi
    rm -rf "$temp_dir"

    # Run prefetch-npm-deps on the source using nix-shell
    nix-shell -p prefetch-npm-deps --run "prefetch-npm-deps '$src_path/package-lock.json'" 2>/dev/null
}

update_toml() {
    local package="$1"
    local new_version="$2"
    local new_hash="$3"
    local new_npm_deps_hash="$4"

    if [[ "${DRY_RUN:-}" == "true" ]]; then
        local msg="DRY_RUN: Would update $package to version $new_version with hash $new_hash"
        if [[ -n "$new_npm_deps_hash" ]]; then
            msg="$msg and npm_deps_hash $new_npm_deps_hash"
        fi
        log "$msg"
        return 0
    fi

    local msg="Updating $package to version $new_version with hash $new_hash"
    if [[ -n "$new_npm_deps_hash" ]]; then
        msg="$msg and npm_deps_hash $new_npm_deps_hash"
    fi
    log "$msg"

    # Update TOML file using sed
    # Find the package section and update the version and hash lines
    # Use different delimiter to avoid issues with slashes in version strings
    sed -i.bak "/^\[$package\]/,/^\[/ s|^version = .*|version = \"$new_version\"|" "$TOML_FILE"
    sed -i.bak "/^\[$package\]/,/^\[/ s|^src_hash = .*|src_hash = \"$new_hash\"|" "$TOML_FILE"

    # Handle npm_deps_hash for packages that have it
    if grep -A 10 "^\[$package\]" "$TOML_FILE" | grep -q "^npm_deps_hash"; then
        if [[ -n "$new_npm_deps_hash" ]]; then
            sed -i.bak "/^\[$package\]/,/^\[/ s|^npm_deps_hash = .*|npm_deps_hash = \"$new_npm_deps_hash\"|" "$TOML_FILE"
        else
            log "WARNING: npm_deps_hash calculation failed for $package, keeping existing value"
        fi
    fi

    rm -f "${TOML_FILE}.bak"
}

rebuild_home_manager() {
    log "Rebuilding Home Manager configuration..."
    home-manager switch
}

update_package() {
    local package="$1"
    log "Checking for $package updates..."

    # Get current version and package information
    package_info=$(get_package_info "$package")
    current_version=$(echo "$package_info" | cut -f1)
    src_type=$(echo "$package_info" | cut -f2)
    current_src_hash=$(echo "$package_info" | cut -f3)
    current_npm_deps_hash=$(echo "$package_info" | cut -f4)
    npm_package=$(echo "$package_info" | cut -f5)
    github_repo=$(echo "$package_info" | cut -f6)

    if [[ -z "$src_type" ]]; then
        log "Package $package not found in configuration or missing src_type"
        return 1
    fi

    # Get latest version based on src_type
    case "$src_type" in
    "url")
        if [[ -n "$npm_package" ]]; then
            latest_version=$(get_latest_version "$npm_package")
        else
            log "npm_package not specified for url type source: $package"
            return 1
        fi
        ;;
    "github")
        if [[ -n "$github_repo" ]]; then
            latest_version=$(get_latest_github_version "$github_repo")
        else
            log "github_repo not specified for github type source: $package"
            return 1
        fi
        ;;
    *)
        log "Cannot determine latest version for $package (src_type: $src_type)"
        return 1
        ;;
    esac

    log "$package current version: $current_version"
    log "$package latest version: $latest_version"

    if [[ -z "$latest_version" || "$latest_version" == "null" ]]; then
        if [[ "$src_type" == "github" ]]; then
            log "$package: Unable to fetch latest release from GitHub (no releases or API error)"
        else
            log "$package: Unable to fetch latest version (package may not exist)"
        fi
        return 1
    fi

    if [[ "$current_version" == "$latest_version" ]]; then
        log "$package already on latest version"
        return 0
    fi

    log "$package new version available: $latest_version"

    # Calculate hash for new version
    new_hash=$(get_package_hash "$package" "$latest_version")
    if [[ -z "$new_hash" ]]; then
        log "Failed to calculate hash for $package version $latest_version"
        return 1
    fi

    # Calculate npm_deps_hash if the package has npm dependencies
    local new_npm_deps_hash=""
    if [[ -n "$current_npm_deps_hash" ]]; then
        log "Calculating npm_deps_hash for $package..."
        new_npm_deps_hash=$(get_npm_deps_hash "$package" "$latest_version" "$new_hash")
        if [[ -z "$new_npm_deps_hash" ]]; then
            log "Warning: Failed to calculate npm_deps_hash for $package"
        fi
    fi

    update_toml "$package" "$latest_version" "$new_hash" "$new_npm_deps_hash"

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

if [[ "${BASH_SOURCE[0]:-}" == "${0}" ]]; then
    main "$@"
fi
