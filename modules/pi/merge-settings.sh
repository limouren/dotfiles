#!/usr/bin/env bash
# Merge declared pi settings into the writable settings.json.
#
# Pi writes settings.json at runtime (deviceId, lastChangelogVersion,
# /settings changes), so the file cannot be a read-only store symlink.
# Instead, on every switch:
#   1. Keys declared in the previous switch but no longer declared are removed.
#   2. Declared keys are deep-merged over the current file (declared wins).
#   3. Keys pi added at runtime are kept.
#
# Usage: merge-settings.sh SETTINGS_FILE DECLARED_FILE PREVIOUS_DECLARED_FILE

set -euo pipefail

settings_file=$1
declared_file=$2
previous_declared_file=$3

read_json_or_empty() {
  if [[ -s $1 ]]; then cat "$1"; else echo '{}'; fi
}

current=$(read_json_or_empty "$settings_file")
previous=$(read_json_or_empty "$previous_declared_file")

if ! merged=$(
  jq -n \
    --argjson current "$current" \
    --argjson previous "$previous" \
    --slurpfile declared "$declared_file" '
    # Paths to every non-object value; arrays count as leaves because
    # pi replaces arrays instead of merging them.
    def leaf_paths:
      to_entries[] as {key: $key, value: $value}
      | if ($value | type) == "object" and ($value | length) > 0
        then [$key] + ($value | leaf_paths)
        else [$key]
        end;

    $declared[0] as $declared
    | ([$previous | leaf_paths] - [$declared | leaf_paths]) as $undeclared
    | reduce $undeclared[] as $path ($current; try delpaths([$path]) catch .)
    | . * $declared
  '
); then
  echo "pi: skipping settings merge; $settings_file or $previous_declared_file is not valid JSON" >&2
  exit 0
fi

if [[ $merged != "$(jq . <<<"$current")" ]]; then
  mkdir -p "$(dirname "$settings_file")"
  tmp_file=$(mktemp "$settings_file.XXXXXX")
  printf '%s\n' "$merged" >"$tmp_file"
  chmod 644 "$tmp_file"
  mv "$tmp_file" "$settings_file"
fi

mkdir -p "$(dirname "$previous_declared_file")"
install -m 644 "$declared_file" "$previous_declared_file"
