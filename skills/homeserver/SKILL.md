---
name: homeserver
description: Interact with David's home server (hermo.dev) and its self-hosted services — Authentik, Sonarr, Radarr, Jackett, Jellyseerr, qBittorrent, etc. Use when the user asks to check, search, add, or manage media/torrents/users/SSO on the homeserver; SSH into it; mount the remote filesystem; or look at docker-compose apps.
---

# Homeserver

David's self-hosted box at **hermo.dev** behind Traefik + Let's Encrypt. Docker compose root: `~/remote/homeserver/` (mounted via sshfs).

## SSH

```bash
ssh server@hermo.dev -p 45811
```

## Mount remote filesystem

```bash
# Mount
sshfs server@hermo.dev:/home/server/ ~/remote/ -p 45811 -o follow_symlinks
# Unmount
fusermount -u ~/remote
```

Once mounted, the compose tree is at `~/remote/homeserver/`:
- `docker-compose.yml` — main, with includes
- `apps/<app>/docker-compose.yml` — per-app stacks
- `.env` — `DOMAIN=hermo.dev`, `APPDATADIR=...`

## Service API credentials

All URLs + keys live in `~/.secrets` (mode 600, sourced from `~/.zshrc`). **Always** `source ~/.secrets` first; never hardcode or ask the user for keys.

```bash
source ~/.secrets
# Now $AUTHENTIK_URL, $AUTHENTIK_TOKEN, $SONARR_URL, $SONARR_API_KEY, etc. are available
```

Never echo secret values back, never paste them into commits, logs, or notifications.

## Auth patterns by service

| Service | Auth | API base |
|---|---|---|
| **Authentik** | `Authorization: Bearer $AUTHENTIK_TOKEN` | `$AUTHENTIK_URL/api/v3/` |
| **Sonarr** | `X-Api-Key: $SONARR_API_KEY` | `$SONARR_URL/api/v3/` |
| **Radarr** | `X-Api-Key: $RADARR_API_KEY` | `$RADARR_URL/api/v3/` |
| **Jackett** | `?apikey=$JACKETT_API_KEY` | `$JACKETT_URL/api/v2.0/` |
| **Jellyseerr** | `X-Api-Key: $JELLYSEERR_API_KEY` | `$JELLYSEERR_URL/api/v1/` |
| **qBittorrent** | session cookie (POST `/api/v2/auth/login`) | `$QBIT_URL/api/v2/` |

If a service isn't in `~/.secrets`, **ask** before scraping config files for keys.

## Common calls

```bash
source ~/.secrets

# Sonarr — search for a series
curl -s -H "X-Api-Key: $SONARR_API_KEY" \
  "$SONARR_URL/api/v3/series/lookup?term=Severance" | jq '.[0:3]'

# Radarr — list all movies
curl -s -H "X-Api-Key: $RADARR_API_KEY" "$RADARR_URL/api/v3/movie" | jq 'length'

# Jellyseerr — pending requests
curl -s -H "X-Api-Key: $JELLYSEERR_API_KEY" \
  "$JELLYSEERR_URL/api/v1/request?filter=pending" | jq '.results'

# Authentik — list users
curl -s -H "Authorization: Bearer $AUTHENTIK_TOKEN" \
  "$AUTHENTIK_URL/api/v3/core/users/" | jq '.results | map({pk, username, email})'

# Jackett — search indexers
curl -s "$JACKETT_URL/api/v2.0/indexers/all/results?apikey=$JACKETT_API_KEY&Query=ubuntu" | jq '.Results[0:5]'
```

## qBittorrent (session auth)

```bash
source ~/.secrets
cookies=$(mktemp)
curl -s -c "$cookies" -d "username=$QBIT_USER&password=$QBIT_PASS" "$QBIT_URL/api/v2/auth/login"
curl -s -b "$cookies" "$QBIT_URL/api/v2/torrents/info" | jq 'map({name, state, progress})'
rm -f "$cookies"
```

## Adding a new app

1. Create `~/remote/homeserver/apps/<app>/docker-compose.yml`.
2. Append `- apps/<app>/docker-compose.yml` to the main `docker-compose.yml` includes list.
3. Use Traefik labels:

```yaml
labels:
  - "traefik.enable=true"
  - "traefik.http.routers.<app>.rule=Host(`<sub>.${DOMAIN}`)"
  - "traefik.http.services.<app>.loadbalancer.server.port=<port>"
  - "traefik.http.routers.<app>.entrypoints=websecure"
  - "traefik.http.routers.<app>.tls.certresolver=myresolver"
```

4. SSH in and `docker compose up -d <app>`.

## Patterns

**"What's downloading?"** → qBit `/torrents/info`, filter `state=downloading`, show name + progress%.
**"Add Show X to Sonarr"** → lookup → POST `/series` with the matched payload + qualityProfileId + rootFolderPath.
**"Approve all pending Jellyseerr requests"** → list pending → POST `/request/{id}/approve` for each. Confirm count first.
**"Restart service X"** → SSH, `cd ~/homeserver && docker compose restart <service>`.

## Gotchas

- Mount may not be active — check `mountpoint -q ~/remote` before reading.
- API tokens may rotate; if a call returns 401, tell the user, don't retry blindly.
- Destructive ops (delete user, remove movie, delete torrent + files) — always confirm first.
