#!/usr/bin/env bash
# Find windows by fuzzy match against class or title (case-insensitive).
# Usage: find_window.sh <query>
set -euo pipefail
q="${1:?usage: find_window.sh <query>}"
hyprctl clients -j | jq -r --arg q "$q" '
  map(select(
    (.class // "" | ascii_downcase | contains($q | ascii_downcase)) or
    (.title // "" | ascii_downcase | contains($q | ascii_downcase))
  )) | map({address, class, title, workspace: .workspace.name})
'
