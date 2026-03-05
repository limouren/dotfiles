#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
HASHES_FILE="$SCRIPT_DIR/hashes.json"
NPM_PACKAGE="@mariozechner/pi-coding-agent"

# Clean up temp files on exit
cleanup() {
	rm -rf "${tarball_file:-}" "${extract_dir:-}"
}
trap cleanup EXIT

current_version=$(jq -r '.version' "$HASHES_FILE")
latest_version=$(curl -s "https://registry.npmjs.org/$NPM_PACKAGE/latest" | jq -r '.version')

echo "Current: $current_version, Latest: $latest_version"

if [[ "$current_version" == "$latest_version" ]]; then
	echo "Already up to date"
	exit 0
fi

tarball_url="https://registry.npmjs.org/$NPM_PACKAGE/-/pi-coding-agent-$latest_version.tgz"

echo "Downloading tarball..."
tarball_file=$(mktemp)
curl -sL "$tarball_url" -o "$tarball_file"

echo "Calculating source hash..."
source_hash=$(nix hash file "$tarball_file")

echo "Extracting and generating package-lock.json..."
extract_dir=$(mktemp -d)
tar -xzf "$tarball_file" -C "$extract_dir" --strip-components=1
cd "$extract_dir"
npm install --package-lock-only --ignore-scripts 2>/dev/null
cp package-lock.json "$SCRIPT_DIR/package-lock.json"

echo "Calculating npmDepsHash..."
npm_deps_hash=$(nix shell nixpkgs#prefetch-npm-deps --command prefetch-npm-deps "$SCRIPT_DIR/package-lock.json" 2>/dev/null)

if [[ -z "$npm_deps_hash" ]]; then
	echo "Error: Failed to calculate npmDepsHash" >&2
	exit 1
fi

echo "Updating hashes.json..."
cd "$REPO_ROOT"
jq --arg version "$latest_version" \
	--arg sourceHash "$source_hash" \
	--arg npmDepsHash "$npm_deps_hash" \
	'.version = $version | .sourceHash = $sourceHash | .npmDepsHash = $npmDepsHash' \
	"$HASHES_FILE" >"$HASHES_FILE.tmp" && mv "$HASHES_FILE.tmp" "$HASHES_FILE"

echo "Updated to $latest_version"
