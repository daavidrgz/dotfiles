---
name: system-commands
description: Control system-level functions on Linux (Wayland/Hyprland): volume, brightness, screenshots, clipboard, notifications, media playback, screen lock, power. Use when the user asks to change volume/brightness, take a screenshot, copy/paste, send a notification, play/pause music, lock the screen, suspend, or reboot.
---

# System Commands

Common system control on this Wayland/Hyprland setup. Stick to the listed tools — they're the ones installed and wired into the desktop.

## Audio (PipeWire via wpctl / pamixer)

```bash
wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.5         # absolute (0.0–1.5)
wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+         # relative
wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-
wpctl set-mute   @DEFAULT_AUDIO_SINK@ toggle
wpctl get-volume @DEFAULT_AUDIO_SINK@             # query
wpctl set-mute   @DEFAULT_AUDIO_SOURCE@ toggle    # mic
```

Cap at 100% when setting absolute to avoid clipping unless the user explicitly asks to boost.

## Brightness (brightnessctl)

```bash
brightnessctl set 50%
brightnessctl set 10%+
brightnessctl set 10%-
brightnessctl get
brightnessctl --device=<dev> set 50%   # specific device
```

## Screenshots (grim + slurp + wl-copy)

```bash
grim ~/Pictures/screenshot-$(date +%Y%m%d-%H%M%S).png       # full screen
grim -g "$(slurp)" /tmp/sel.png                              # region select
grim -g "$(slurp)" - | wl-copy --type image/png              # region to clipboard
grim - | wl-copy --type image/png                            # full screen to clipboard
```

Prefer saving to `~/Pictures/` with timestamp unless the user gives a path.

## Clipboard (wl-clipboard)

```bash
echo "text" | wl-copy
wl-paste
wl-paste --type image/png > /tmp/img.png
wl-copy --clear
```

## Notifications (notify-send / mako or swaync)

```bash
notify-send "Title" "Body message"
notify-send -u critical -t 10000 "Urgent" "Body"   # urgency: low|normal|critical
notify-send -i dialog-information "Title" "Body"
```

## Media playback (playerctl)

```bash
playerctl play-pause
playerctl next
playerctl previous
playerctl status
playerctl metadata --format '{{artist}} - {{title}}'
playerctl --player=spotify play
playerctl -l    # list players
```

## Screen lock / idle / power

```bash
hyprlock                 # lock now (Hyprland's locker)
systemctl suspend        # suspend
systemctl hibernate
systemctl poweroff
systemctl reboot
loginctl lock-session
```

**Always confirm before** `poweroff`, `reboot`, or `hibernate` unless the user was unambiguous in this turn.

## Display / monitors

```bash
hyprctl monitors -j                                  # list monitors as JSON
hyprctl keyword monitor "DP-1, 2560x1440@144, 0x0, 1"
wlr-randr                                            # alternative query
```

## Network

```bash
nmcli device wifi list
nmcli device wifi connect <SSID> password <pwd>
nmcli connection show --active
nmcli radio wifi on/off
```

## Process / app control

```bash
pgrep -af <name>
pkill <name>
kill -9 <pid>
```

## Patterns

**"Make it quieter"** → `wpctl set-volume @DEFAULT_AUDIO_SINK@ 10%-`. Don't query first unless the user asks for the current value.

**"Screenshot this region and copy it"** → `grim -g "$(slurp)" - | wl-copy --type image/png` then `notify-send "Screenshot copied"`.

**"Lock the screen"** → `hyprlock` (returns immediately; lock runs in foreground of its own session).

**"What's playing?"** → `playerctl metadata --format '{{artist}} — {{title}}'`.
