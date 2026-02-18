#!/bin/bash

set -euo pipefail

# Find the script directory and repo root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

log() {
	echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >&2
}

# Check if there are uncommitted changes in a specific path
has_changes() {
	local path="${1:-}"
	if [[ -n "$path" ]]; then
		if git diff --quiet "$path"; then
			return 1
		else
			return 0
		fi
	else
		if git diff --quiet; then
			return 1
		else
			return 0
		fi
	fi
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
pi-coding-agent
uv
EOF
}

update_package() {
	local package="$1"
	log "Updating $package..."

	# Get current version before update
	local old_version
	old_version=$(nix eval --raw --impure --expr "(import ./packages {}).$package.version" 2>/dev/null || echo "unknown")

	# Check if package has a standalone update script in packages/{package}/update.sh
	local update_script="$REPO_ROOT/packages/$package/update.sh"

	if [[ -x "$update_script" ]]; then
		log "Using custom update script for $package..."
		"$update_script"
	else
		log "Using nix-update for $package..."
		nix run github:Mic92/nix-update/1b5bc1e -- --file ./packages --version stable "$package"
	fi

	# Check if there are changes to commit
	if has_changes "packages/"; then
		# Get new version after update
		local new_version
		new_version=$(nix eval --raw --impure --expr "(import ./packages {}).$package.version" 2>/dev/null || echo "unknown")

		if [[ "$old_version" != "$new_version" ]]; then
			log "Updated $package: $old_version → $new_version"

			# Create commit with the specified format
			# Handle both single-file (packages/$package.nix) and directory (packages/$package/) layouts
			if [[ -d "packages/$package" ]]; then
				git add "packages/$package/"
			else
				git add "packages/$package.nix"
			fi
			git commit -m "Update $package: $old_version -> $new_version"
		else
			log "Package $package: no version change detected ($old_version), skipping commit"
		fi
	else
		log "$package: no changes detected"
	fi
}

rebuild_home_manager() {
	log "Rebuilding Home Manager configuration..."
	cd "$REPO_ROOT"
	home-manager switch
}

main() {
	local package="${1:-all}"

	# Change to repo root directory
	cd "$REPO_ROOT"

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

	# Rebuild Home Manager configuration
	rebuild_home_manager

	log "Package update process completed"
}

if [[ "${BASH_SOURCE[0]:-}" == "${0}" ]]; then
	main "$@"
fi
