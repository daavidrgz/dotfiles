#!/usr/bin/env bash
set -euo pipefail
hyprctl activewindow -j | jq '{address, class, title, workspace: .workspace.name, floating, pid}'
