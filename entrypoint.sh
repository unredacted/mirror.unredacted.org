#!/bin/bash
# ============================================================================
# entrypoint.sh — Starts cron (for scheduled syncs) and Caddy (file server)
# ============================================================================
set -euo pipefail

MIRROR_ROOT="${MIRROR_ROOT:-/data/mirror}"

echo "[entrypoint] Creating directories..."
mkdir -p "$MIRROR_ROOT" /var/log/mirror

echo "[entrypoint] Starting cron daemon..."
crond -b -l 2

echo "[entrypoint] Running initial sync in background..."
/usr/local/bin/sync-mirrors.sh &

echo "[entrypoint] Starting Caddy..."
exec caddy run --config /etc/caddy/Caddyfile --adapter caddyfile
