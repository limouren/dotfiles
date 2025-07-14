#!/bin/bash

set -euo pipefail

# Parse git diff output to extract package version changes
# Usage: parse-package-changes.sh <diff_file>

DIFF_FILE="${1:-}"

if [[ -z "$DIFF_FILE" || ! -f "$DIFF_FILE" ]]; then
    echo "Usage: $0 <diff_file>"
    exit 1
fi

# Extract version changes from the diff
extract_version_changes() {
    local changes=""
    local current_package=""
    local old_version=""
    local new_version=""

    while IFS= read -r line; do
        # Look for diff headers indicating which file changed
        if [[ "$line" =~ ^diff\ --git\ a/packages/([^.]+)\.nix ]]; then
            # Process previous package if we have complete info
            if [[ -n "$current_package" && -n "$old_version" && -n "$new_version" ]]; then
                if [[ -n "$changes" ]]; then
                    changes="$changes\n"
                fi
                changes="${changes}- $current_package: $old_version → $new_version"
            fi

            # Start tracking new package
            current_package="${BASH_REMATCH[1]}"
            old_version=""
            new_version=""
        fi

        # Extract old version (line starting with -)
        if [[ "$line" =~ ^-.*version\ =\ \"([^\"]+)\" ]]; then
            old_version="${BASH_REMATCH[1]}"
        fi

        # Extract new version (line starting with +)
        if [[ "$line" =~ ^\+.*version\ =\ \"([^\"]+)\" ]]; then
            new_version="${BASH_REMATCH[1]}"
        fi
    done <"$DIFF_FILE"

    # Process the last package
    if [[ -n "$current_package" && -n "$old_version" && -n "$new_version" ]]; then
        if [[ -n "$changes" ]]; then
            changes="$changes\n"
        fi
        changes="${changes}- $current_package: $old_version → $new_version"
    fi

    echo -e "$changes"
}

# Extract and output version changes
version_changes=$(extract_version_changes)

if [[ -n "$version_changes" ]]; then
    # Output package names for commit title (one line, comma-separated with spaces)
    package_names=$(echo "$version_changes" | sed 's/^- \([^:]*\):.*$/\1/' | tr '\n' ',' | sed 's/,$//; s/,/, /g')
    echo "PACKAGES:$package_names"
    echo "DETAILS:"
    echo "$version_changes"
else
    echo "No version changes detected in packages/" >&2
    exit 1
fi
