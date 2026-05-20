---
name: chrome-cdp
description: Interact with local Chrome browser session (only on explicit user approval after being asked to inspect, debug, or interact with a page open in Chrome)
---

# Chrome CDP

Lightweight Chrome DevTools Protocol CLI. Connects directly to per-page WebSockets — no Puppeteer, no daemons, instant.

## Prerequisites

- [Bun](https://bun.sh) (the script's shebang is `#!/usr/bin/env bun`). Bun starts ~2× faster than Node for this script (~70ms vs ~160ms per command). If Bun isn't installed, swap the shebang to `#!/usr/bin/env node` — the code uses only standard APIs (`WebSocket`, `fetch`, `fs`) so Node 22+ works unchanged.
- Chrome launched with `--remote-debugging-port=9222` **and** a dedicated `--user-data-dir`. The default profile silently ignores `--remote-debugging-port` since Chrome 136+. Override the port with `CDP_PORT`.

Recommended launch (e.g. as a `.desktop` Exec line):

```
google-chrome-stable --remote-debugging-port=9222 --user-data-dir=$HOME/.config/chrome-cdp-profile
```

Verify with `curl http://127.0.0.1:9222/json/version` — should return JSON.

## Commands

All commands use `scripts/cdp.mjs`. The `<target>` is a **unique** targetId prefix from `list`; copy the full prefix shown in the `list` output. Ambiguous prefixes are rejected.

```bash
scripts/cdp.mjs list                              # list open pages
scripts/cdp.mjs snap    <target>                  # accessibility tree
scripts/cdp.mjs eval    <target> <expr>           # evaluate JS
scripts/cdp.mjs shot    <target> [file]           # viewport screenshot (default /tmp/screenshot.png)
scripts/cdp.mjs html    <target> [selector]       # page or element HTML
scripts/cdp.mjs nav     <target> <url>            # navigate and wait for load
scripts/cdp.mjs net     <target>                  # resource timing entries
scripts/cdp.mjs click   <target> <selector>       # click by CSS selector
scripts/cdp.mjs clickxy <target> <x> <y>          # click at CSS pixel coords
scripts/cdp.mjs type    <target> <text>           # Input.insertText at focus — works in cross-origin iframes
scripts/cdp.mjs loadall <target> <selector> [ms]  # click "load more" until gone (default 1500ms)
scripts/cdp.mjs evalraw <target> <method> [json]  # raw CDP command passthrough
```

`shot` captures the **viewport only**. Scroll first with `eval` if you need content below the fold.

## Coordinates

`shot` saves an image at native resolution: image pixels = CSS pixels × DPR. CDP Input events (`clickxy` etc.) take **CSS pixels**.

```
CSS px = screenshot image px / DPR
```

`shot` prints the DPR for the current page.

## Tips

- Prefer `snap` over `html` for page structure.
- Use `type` (not eval) to enter text in cross-origin iframes — `click`/`clickxy` to focus first, then `type`.
- Avoid index-based DOM selection (`querySelectorAll(...)[i]`) across multiple `eval` calls when the DOM can change between them. Collect data in a single `eval` or use stable selectors.
