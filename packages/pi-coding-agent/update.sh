#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HASHES_FILE="$SCRIPT_DIR/hashes.json"
NPM_PACKAGE="@mariozechner/pi-coding-agent"

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
cd "$SCRIPT_DIR/../.."

echo "Updating hashes.json with placeholder..."
jq --arg version "$latest_version" \
	--arg sourceHash "$source_hash" \
	'.version = $version | .sourceHash = $sourceHash | .npmDepsHash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="' \
	"$HASHES_FILE" >"$HASHES_FILE.tmp" && mv "$HASHES_FILE.tmp" "$HASHES_FILE"

echo "Building to get npmDepsHash..."
build_log=$(mktemp)
nix-build -E 'let pkgs = import <nixpkgs> {}; in pkgs.callPackage ./packages/pi-coding-agent {}' >"$build_log" 2>&1 || true
npm_deps_hash=$(grep "got:" "$build_log" | awk '{print $2}')
rm -f "$build_log"

if [[ -z "$npm_deps_hash" ]]; then
	echo "Error: Failed to get npmDepsHash"
	exit 1
fi

echo "Updating hashes.json with correct npmDepsHash..."
jq --arg npmDepsHash "$npm_deps_hash" \
	'.npmDepsHash = $npmDepsHash' \
	"$HASHES_FILE" >"$HASHES_FILE.tmp" && mv "$HASHES_FILE.tmp" "$HASHES_FILE"

rm -rf "$extract_dir" "$tarball_file"

echo "Updated to $latest_version"
