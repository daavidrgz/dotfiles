#!/usr/bin/env bash
# List open windows: address, class, title, workspace, floating.
set -euo pipefail
hyprctl clients -j | jq -r '
  map({
    address,
    class,
    title,
    workspace: .workspace.name,
    floating,
    pid,
    monitor
  })
'
