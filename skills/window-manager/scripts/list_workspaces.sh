#!/usr/bin/env bash
set -euo pipefail
hyprctl workspaces -j | jq 'map({id, name, monitor, windows, hasfullscreen, lastwindowtitle})'
