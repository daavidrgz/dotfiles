---
name: window-manager
description: Manage windows and applications on Hyprland (Wayland). Use when the user asks to open, close, focus, move, resize, or list windows; launch or quit applications; switch workspaces; toggle floating/tiling; or arrange the desktop. Wraps `hyprctl`.
---

# Window Manager (Hyprland)

Control the Hyprland Wayland compositor via `hyprctl`. All state queries support JSON output via `-j` — prefer JSON and parse with `jq`.

## Core operations

### Launch an application
```bash
hyprctl dispatch exec <command>
# Examples:
hyprctl dispatch exec kitty
hyprctl dispatch exec "firefox --new-window https://example.com"
hyprctl dispatch exec "[workspace 3] code"   # launch on a specific workspace
hyprctl dispatch exec "[float] thunar"        # launch as floating
```

### Close the active window
```bash
hyprctl dispatch killactive
```

### Close a specific window
```bash
hyprctl dispatch closewindow address:0x<address>
# Get address from `hyprctl clients -j`
```

### Focus a window
```bash
hyprctl dispatch focuswindow address:0x<address>
hyprctl dispatch focuswindow class:firefox        # by window class
hyprctl dispatch focuswindow title:"Visual Studio"  # by title substring
```

### Move focus directionally
```bash
hyprctl dispatch movefocus l   # left | r | u | d
```

## Listing state

Always prefer the helper scripts — they return clean JSON and are cheap.

- `scripts/list_windows.sh` — all open windows with address, class, title, workspace, floating
- `scripts/active_window.sh` — currently focused window
- `scripts/list_workspaces.sh` — workspaces with window counts
- `scripts/find_window.sh <query>` — fuzzy-match by class or title, returns address(es)

Raw equivalents:
```bash
hyprctl clients -j
hyprctl activewindow -j
hyprctl workspaces -j
hyprctl monitors -j
```

## Workspaces

```bash
hyprctl dispatch workspace 3              # switch to workspace 3
hyprctl dispatch workspace e+1            # next workspace
hyprctl dispatch workspace previous       # last visited
hyprctl dispatch movetoworkspace 5        # move active window to ws 5
hyprctl dispatch movetoworkspacesilent 5  # move without following
hyprctl dispatch togglespecialworkspace scratchpad  # named scratchpad
```

## Floating / tiling / fullscreen

```bash
hyprctl dispatch togglefloating
hyprctl dispatch fullscreen 0   # 0 = full, 1 = maximize, 2 = fake-full
hyprctl dispatch pin            # pin floating window across workspaces
hyprctl dispatch centerwindow
```

## Resize and move

```bash
hyprctl dispatch resizeactive 100 0      # +100px width
hyprctl dispatch resizeactive exact 1200 800
hyprctl dispatch moveactive 50 0
hyprctl dispatch moveactive exact 100 100
```

## Semantic launching

When the user says "open my browser" or "launch the terminal", resolve to their actual preferences. Common defaults on this system:

- **terminal** → `kitty`
- **file manager** → `thunar` or `nautilus`
- **editor** → `code` (VS Code) or `nvim` inside kitty
- **browser** → `firefox` or `chromium`

If multiple candidates exist, check what's installed (`which <cmd>`) before launching. If unsure which app the user means, ask.

## Patterns

**"Bring X to the front"** → find it with `find_window.sh X`, then `focuswindow address:...`. If no match, launch it.

**"Close everything on workspace N"** → list clients, filter by workspace, killwindow each address.

**"Open X next to Y"** → launch X, then if needed `movewindow` directionally relative to Y's address.

**"Show me what's open"** → run `list_windows.sh` and present a compact summary (class + title + workspace), not raw JSON.

## Gotchas

- Window addresses change every session — never cache them across runs.
- `dispatch exec` returns immediately; the window may take a moment to appear. If you need to act on it, poll `hyprctl clients` briefly.
- `killactive` requires a focused window; check `activewindow` first if scripting.
- Workspace IDs are integers; named workspaces (`special:scratchpad`) use the `name:` prefix.
