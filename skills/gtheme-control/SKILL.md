---
name: gtheme-control
description: Apply themes, switch desktops, manage wallpapers, and tweak the gtheme dotfile/theme manager. Use when the user asks to change colors, switch theme, change desktop, set a wallpaper, or modify gtheme patterns/extras.
---

# gtheme Control

`gtheme` is a Rust-based dotfile + theme manager. Repo: `/home/david/github/gtheme/`, config: `~/.config/gtheme/`. It has 350+ themes and applies them across kitty, waybar, hyprland, rofi, fuzzel, swaync, wlogout, cava, vscode, and wallpapers via a pattern system.

## Most-used commands

```bash
gtheme t l                          # list themes
gtheme t apply <theme>              # apply theme to current desktop
gtheme t colors [theme]             # show theme color palette
gtheme d l                          # list desktops
gtheme d apply <desktop>            # switch desktop (optionally -t <theme>)
gtheme p l                          # list patterns
gtheme p enable/disable <pattern>   # toggle a pattern
gtheme p invert <pattern>           # swap fg/bg of a pattern
gtheme e enable/disable <extra>     # toggle an extra (vscode, wallpaper, ...)
gtheme fav add/remove <theme>       # favorites
gtheme config set <key> <value>     # user settings (font, monitor, battery, ...)
gtheme config show
```

## Common requests

**"Change to a dark theme"** → `gtheme t l` first to discover available themes; pick one matching the vibe; `gtheme t apply <name>`.

**"Show me what's available"** → `gtheme t l` for themes, or `gtheme d l` for desktops. Present a compact list, not the full dump.

**"Switch to my hypr desktop"** → `gtheme d apply hypr` (optionally `-t <theme>` to apply with a specific theme).

**"Change wallpaper to X"** → easiest path is editing the theme's TOML at `~/.config/gtheme/themes/themes/<theme>.toml`, updating the `[extras] wallpaper = [...]` line, then re-applying the theme.

**"Invert the colors of kitty"** → `gtheme p invert kitty`.

## Color palette

Every theme defines 19 colors (hex, no `#`): `background`, `foreground`, `cursor`, `selection-{foreground,background}`, and 8 ANSI pairs (`black`/`black-hg` ... `white`/`white-hg`).

On the **hypr desktop**, these map to Material You M3 tokens (primary/secondary/tertiary/surface/etc.). Patterns generate matching color files for hyprland, waybar (also imported by swaync + wlogout), rofi, kitty, quickshell, cava, fuzzel.

## Creating things

```bash
gtheme theme new-skeleton <name>     # empty theme TOML
gtheme desktop new-skeleton <name>   # empty desktop scaffold
```

## Theme TOML layout

`~/.config/gtheme/themes/themes/<name>.toml`:

```toml
name = 'MyTheme'

[extras]
vscode = ['Dracula']
wallpaper = ['~/wallpapers/dark.png']

[colors]
background = '1e1f28'
foreground = 'f8f8f2'
# ... 17 more
```

## Gotchas

- Hex colors are stored **without** `#` — patterns add `#` or `0x` as needed.
- After editing a theme TOML, re-apply with `gtheme t apply <name>` to regenerate pattern outputs.
- Post-scripts in `gtheme/post-scripts/` must match pattern names and be executable.
- The desktops submodule lives at `/home/david/github/gtheme/desktops/` (separate repo) → `git@github.com:daavidrgz/gtheme-desktops.git`.

---

## Reference

### Desktop directory layout

```
desktop_name/
├── desktop_config.json     # Pattern/extra enable flags
├── desktop_info.toml       # Metadata (author, deps, credits)
├── README.md
├── .config/                # Configs deployed to ~/.config/
└── gtheme/
    ├── patterns/           # Template files with color placeholders
    ├── post-scripts/       # Scripts run after pattern fills (name must match pattern)
    └── extras/             # Theme-specific scripts (wallpaper, vscode, etc.)
```

`desktop_config.json`:

```json
{
  "default_theme": "ThemeName",
  "actived": { "pattern-name": true },
  "inverted": { "pattern-name": false }
}
```

`desktop_info.toml`:

```toml
author = 'Name (@user)'
description = 'Description'
credits = 'https://...'
dependencies = ['pkg1', 'pkg2', 'optional-pkg (Optional)']
```

### Pattern syntax

Pattern files (`.pattern`) are templates with `<[property]>` placeholders.

- `<[output-file]>=~/.config/app/colors.conf` — **mandatory**, must be on its own line, sets output path.
- `<[color-name]>` — replaced with hex color value (no `#` prefix).
- `<[property|fallback]>` — fallback value if property not found.
- `<[theme-name]>` — replaced with current theme name.
- `<[default-font|JetBrains Mono]>` — user setting from `user_settings.toml`.

Example:

```
<[output-file]>=~/.config/kitty/colors.conf
foreground #<[foreground]>
background #<[background]>
color0 #<[black]>
color1 #<[red]>
```

**Pattern modules**: directories inside `patterns/` group sub-patterns (e.g. `spotify/spotify-colors.pattern`).

**Inversion**: swaps `foreground`↔`background` and `selection-foreground`↔`selection-background`. Useful when wallpaper colors clash.

### All color variables (19 standard)

| Variable | Description |
|---|---|
| `background` | Primary background |
| `foreground` | Primary text/foreground |
| `cursor` | Cursor color |
| `selection-background` | Selected text bg |
| `selection-foreground` | Selected text fg |
| `black` / `black-hg` | ANSI black / bright black |
| `red` / `red-hg` | ANSI red / bright red |
| `green` / `green-hg` | ANSI green / bright green |
| `yellow` / `yellow-hg` | ANSI yellow / bright yellow |
| `blue` / `blue-hg` | ANSI blue / bright blue |
| `magenta` / `magenta-hg` | ANSI magenta / bright magenta |
| `cyan` / `cyan-hg` | ANSI cyan / bright cyan |
| `white` / `white-hg` | ANSI white / bright white |

### User settings

Set via `gtheme config set <key> <value>`. Available in patterns as `<[key|fallback]>`:

- `default-font`, `default-font-size`
- `monitor`, `monitor-fallback`
- `backlight-card`, `battery`, `battery-adapter`

### Post-scripts

Shell scripts in `gtheme/post-scripts/` that run after a pattern is filled.

- Filename must match the pattern (e.g. `kitty.pattern` → `kitty.sh`).
- Receives output-file path as `$1`.
- Must be executable (`chmod +x`).
- Special: `desktop-exit.sh` runs when switching away from the desktop.

### Extras

Scripts in `gtheme/extras/` for theme-specific settings. Called with arguments from the theme's `[extras]` section.

```toml
[extras]
vscode = ['Dracula']
wallpaper = ['~/wallpapers/dark.png']
```

→ `extras/vscode.sh "Dracula"`, `extras/wallpaper.sh "~/wallpapers/dark.png"`

### Full theme TOML

`~/.config/gtheme/themes/themes/<name>.toml`:

```toml
name = 'ThemeName'

[extras]
vscode = ['Theme Name']
wallpaper = ['~/path/to/wallpaper.png']

[colors]
background = '1e1f28'
foreground = 'f8f8f2'
cursor = 'bbbbbb'
selection-background = '44475a'
selection-foreground = '1e1f28'
black = '000000'
black-hg = '545454'
red = 'ff5555'
red-hg = 'ff5454'
green = '50fa7b'
green-hg = '50fa7b'
yellow = 'f0fa8b'
yellow-hg = 'f0fa8b'
blue = 'bd92f8'
blue-hg = 'bd92f8'
magenta = 'ff78c5'
magenta-hg = 'ff78c5'
cyan = '8ae9fc'
cyan-hg = '8ae9fc'
white = 'bbbbbb'
white-hg = 'ffffff'
```

### Hypr desktop: Material You color mapping

The hypr desktop maps gtheme's 16-color palette to Material You (M3) tokens:

| gtheme color | M3 token | Usage |
|---|---|---|
| `background` | surface | Main backgrounds |
| `foreground` | on_surface | Main text |
| `blue` / `blue-hg` | primary / on_primary | Accent, active elements |
| `cyan` / `cyan-hg` | secondary / on_secondary | Secondary accent |
| `magenta` / `magenta-hg` | tertiary / on_tertiary | Tertiary accent |
| `red` / `red-hg` | error / on_error | Errors, destructive |
| `black` | surface_container | Elevated surfaces |
| `black-hg` | surface_container_high | Higher elevation |
| `white` | outline | Borders, dividers |
| `white-hg` | on_surface_variant | Secondary text |
| `selection-background` | inverse_surface | Inverted surfaces |
| `selection-foreground` | inverse_on_surface | Inverted text |
| `green` / `green-hg` | surface_bright / surface_dim | Surface variants |
| `yellow` / `yellow-hg` | primary_container / on_primary_container | Tinted surfaces |

Patterns that generate M3 color files:

- `hyprland-colors` → `~/.config/hypr/colors/colors.conf` (Hyprland `$var = rgba()`)
- `waybar-colors` → `~/.config/waybar/colors/colors.css` (CSS `@define-color`)
- `rofi` → `~/.config/rofi/colors.rasi` (Rofi `* { prop: val }`)
- `kitty` → `~/.config/kitty/colors.conf` (Kitty color defs)
- `quickshell-colors` → `~/.config/quickshell/matugen.json` (JSON for quickshell widgets)
- `cava` → `~/.config/cava/config`
- `fuzzel` → `~/.config/fuzzel/fuzzel.ini`

The `waybar-colors` CSS is also `@import`ed by swaync and wlogout stylesheets, so one pattern themes three apps.
