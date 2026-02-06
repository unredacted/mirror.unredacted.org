# Mirror Site

A self-hosted mirror for Linux distros and privacy tools, served by [Caddy](https://caddyserver.com) with directory listing.

## Setup

1. Push this repo to your Git host
2. Deploy using Docker Compose: `docker compose up -d`
3. Ensure the `/data/mirror` volume persists across redeploys

## Adding or Removing Mirrors

Edit `mirrors.conf`. Each line follows the format:

```
NAME|METHOD|SOURCE|EXTRA_ARGS
```

For example:

```
my-distro|rsync|rsync://mirror.example.org/distro/|
some-project|wget|https://releases.example.org/|--mirror --no-parent
```

Comment out a line with `#` to disable it. Push your changes to redeploy.

## File Structure

```
├── Caddyfile            # Caddy web server configuration
├── Dockerfile           # Container image definition
├── docker-compose.yml   # Compose file for deployment
├── mirrors.conf         # Mirror list (edit this)
└── scripts/
    ├── entrypoint.sh    # Container startup (cron + caddy)
    └── sync-mirrors.sh  # Sync engine (reads mirrors.conf)
```

## Endpoints

| Path      | Description              |
|-----------|--------------------------|
| `/`       | Browse all mirrors       |
| `/health` | Health check (returns ok)|
| `/status` | Last sync timestamp      |

## Useful Commands

Check sync logs:

```
docker exec mirror-server cat /var/log/mirror/qubes.log
```

Trigger a manual sync:

```
docker exec mirror-server /usr/local/bin/sync-mirrors.sh
```

## Notes

- Mirrors sync every 6 hours by default. Change the cron schedule in the Dockerfile.
- Verify upstream rsync/wget URLs before your first sync, as endpoints can change.
- Make sure you have enough disk space. Mirror sizes vary but can be large (tens of GB each).
