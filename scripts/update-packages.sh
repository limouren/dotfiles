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
uv
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

	# Get current version before update
	local old_version
	old_version=$(nix eval --raw --impure --expr "(import ./packages {}).$package.version" 2>/dev/null || echo "unknown")

	# Use nix-update to update the package
	nix run github:Mic92/nix-update/1b5bc1e -- --file ./packages --version stable "$package"

	# Check if there are changes to commit
	if has_changes "packages/"; then
		# Get new version after update
		local new_version
		new_version=$(nix eval --raw --impure --expr "(import ./packages {}).$package.version" 2>/dev/null || echo "unknown")

		if [[ "$old_version" != "$new_version" ]]; then
			log "Updated $package: $old_version → $new_version"

			# Create commit with the specified format
			git add "packages/$package.nix"
			git commit -m "Update $package: $old_version -> $new_version"
		else
			log "Package $package: no version change detected ($old_version), skipping commit"
		fi
	else
		log "$package: no changes detected"
	fi
}

update_nix_ai_tools_if_needed() {
	log "Checking nix-ai-tools for updates..."

	# Get list of monitored tools
	local monitored_tools
	monitored_tools=$(get_monitored_flake_tools)

	# Collect information about tools with updates
	local updated_tools=""
	local has_updates=false
	local tool_version_changes=""
	while IFS= read -r tool; do
		local current_hash
		current_hash=$(nix eval --raw --impure --expr "let system = builtins.currentSystem; in (builtins.getFlake (toString ./.)).inputs.nix-ai-tools.packages.\${system}.$tool.drvPath" 2>/dev/null || echo "not-available")

		local upstream_hash
		upstream_hash=$(nix eval --raw "github:numtide/nix-ai-tools#$tool.drvPath" 2>/dev/null || echo "not-available")

		if [[ "$current_hash" != "$upstream_hash" ]]; then
			# Get current and upstream versions
			local current_version
			current_version=$(nix eval --raw --impure --expr "let system = builtins.currentSystem; in (builtins.getFlake (toString ./.)).inputs.nix-ai-tools.packages.\${system}.$tool.version" 2>/dev/null || echo "unknown")

			local upstream_version
			upstream_version=$(nix eval --raw "github:numtide/nix-ai-tools#$tool.version" 2>/dev/null || echo "unknown")

			log "Update available for $tool: $current_version → $upstream_version"

			if [[ -n "$updated_tools" ]]; then
				updated_tools="$updated_tools, $tool"
				tool_version_changes="$tool_version_changes, $tool: $current_version -> $upstream_version"
			else
				updated_tools="$tool"
				tool_version_changes="$tool: $current_version -> $upstream_version"
			fi
			has_updates=true
		fi
	done <<<"$monitored_tools"

	if [[ "$has_updates" == "true" ]]; then
		log "Tool updates found for: $updated_tools"
		log "Updating nix-ai-tools..."

		# Update the flake
		nix flake update nix-ai-tools

		# Check if there are changes to commit
		if has_changes "flake.lock"; then
			log "Updated nix-ai-tools: $tool_version_changes"

			# Create commit for flake update with version changes
			git add flake.lock
			git commit -m "Update $tool_version_changes"
		else
			log "nix-ai-tools: no changes detected in flake.lock"
		fi
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

	# Check nix-ai-tools for updates
	update_nix_ai_tools_if_needed

	# Rebuild Home Manager configuration
	rebuild_home_manager

	log "Package update process completed"
}

if [[ "${BASH_SOURCE[0]:-}" == "${0}" ]]; then
	main "$@"
fi
