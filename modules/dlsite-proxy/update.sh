#!/usr/bin/env bash
# Pin the current DLBooster release in dlbooster-bootstrap.nix.
# Run it when DLBooster publishes a new release, or when the build fails
# with a hash mismatch for latest.zip.

set -euo pipefail

nix_file="$(dirname "${BASH_SOURCE[0]}")/dlbooster-bootstrap.nix"
url="https://client-dl-1.dlbooster.com/latest.zip"

new_hash=$(nix store prefetch-file --json "$url" | jq -r .hash)
old_hash=$(rg --only-matching --replace '$1' 'hash = "([^"]+)";' "$nix_file")

if [[ "$new_hash" == "$old_hash" ]]; then
	echo "DLBooster is up to date ($old_hash)" >&2
	exit 0
fi

rg --passthru --fixed-strings "$old_hash" --replace "$new_hash" "$nix_file" >"$nix_file.tmp"
mv "$nix_file.tmp" "$nix_file"
echo "DLBooster: $old_hash -> $new_hash" >&2
