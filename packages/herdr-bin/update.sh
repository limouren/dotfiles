#!/usr/bin/env bash

# Update hashes.json to the latest stable herdr release.
# The asset name for each system is read from hashes.json, so add a new
# system there first, then run this script.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HASHES_FILE="$SCRIPT_DIR/hashes.json"
REPO="herdrdev/herdr"

current_version=$(jq -r '.version' "$HASHES_FILE")
latest_tag=$(curl -fsSL "https://api.github.com/repos/$REPO/releases/latest" | jq -r '.tag_name')
latest_version="${latest_tag#v}"

if [[ -z "$latest_version" || "$latest_version" == "null" ]]; then
	echo "Error: could not read the latest release of $REPO" >&2
	exit 1
fi

echo "Current: $current_version, Latest: $latest_version"

if [[ "$current_version" == "$latest_version" && "${FORCE:-0}" != "1" ]]; then
	echo "Already up to date"
	exit 0
fi

updated=$(jq --arg version "$latest_version" '.version = $version' "$HASHES_FILE")

while IFS=$'\t' read -r system asset_name; do
	url="https://github.com/$REPO/releases/download/$latest_tag/$asset_name"
	echo "Prefetching $system: $url"
	hash=$(nix store prefetch-file --json "$url" | jq -r '.hash')
	updated=$(jq --arg system "$system" --arg hash "$hash" \
		'.assets[$system].hash = $hash' <<<"$updated")
done < <(jq -r '.assets | to_entries[] | [.key, .value.name] | @tsv' "$HASHES_FILE")

echo "$updated" >"$HASHES_FILE.tmp"
mv "$HASHES_FILE.tmp" "$HASHES_FILE"

echo "Updated to $latest_version"
