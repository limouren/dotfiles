#!/usr/bin/env bash

# Bumps packages/claude-code/manifest.json to the latest upstream release.
# Mirrors the update script that nixpkgs ships for `claude-code-bin`:
#   https://github.com/NixOS/nixpkgs/blob/master/pkgs/by-name/cl/claude-code-bin/update.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_URL="https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases"

current_version=$(jq -r '.version' "$SCRIPT_DIR/manifest.json")
latest_version=$(curl -fsSL "$BASE_URL/latest")

echo "Current: $current_version, Latest: $latest_version"

if [[ "$current_version" == "$latest_version" ]]; then
	echo "Already up to date"
	exit 0
fi

echo "Downloading manifest for $latest_version..."
curl -fsSL "$BASE_URL/$latest_version/manifest.json" --output "$SCRIPT_DIR/manifest.json"

echo "Updated to $latest_version"
