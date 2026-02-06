#!/bin/bash
# ============================================================================
# sync-mirrors.sh — Reads mirrors.conf and syncs each enabled mirror
# ============================================================================
set -euo pipefail

MIRROR_ROOT="${MIRROR_ROOT:-/data/mirror}"
CONFIG_FILE="${CONFIG_FILE:-/etc/mirror/mirrors.conf}"
LOG_DIR="/var/log/mirror"
MAX_RANDOM_DELAY="${MAX_RANDOM_DELAY:-2400}"

mkdir -p "$MIRROR_ROOT" "$LOG_DIR"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"
}

sync_rsync() {
    local name="$1" source="$2" extra_args="$3"
    local dest="$MIRROR_ROOT/$name/"
    mkdir -p "$dest"

    log "RSYNC  | $name | $source -> $dest"
    # shellcheck disable=SC2086
    rsync -rt --delete --timeout=600 $extra_args "$source" "$dest" \
        >> "$LOG_DIR/${name//\//-}.log" 2>&1
}

sync_wget() {
    local name="$1" source="$2" extra_args="$3"
    local dest="$MIRROR_ROOT/$name/"
    mkdir -p "$dest"

    log "WGET   | $name | $source -> $dest"
    # shellcheck disable=SC2086
    wget --directory-prefix="$dest" --no-host-directories --cut-dirs=1 \
        --timestamping --continue --retry-connrefused --waitretry=10 \
        $extra_args "$source" \
        >> "$LOG_DIR/${name//\//-}.log" 2>&1
}

# ── Main ────────────────────────────────────────────────────────────────────

if [[ ! -f "$CONFIG_FILE" ]]; then
    log "ERROR: Config file not found: $CONFIG_FILE"
    exit 1
fi

# Random delay (0 to MAX_RANDOM_DELAY seconds) to avoid thundering herd
# and satisfy Tails' requirement for jittered sync times
DELAY=$(shuf -i 0-"$MAX_RANDOM_DELAY" -n 1)
log "========== Mirror sync started (delay: ${DELAY}s) =========="
sleep "$DELAY"

FAIL_COUNT=0

while IFS='|' read -r name method source extra_args; do
    # Skip comments and blank lines
    [[ -z "$name" || "$name" =~ ^[[:space:]]*# ]] && continue

    # Trim whitespace
    name="$(echo "$name" | xargs)"
    method="$(echo "$method" | xargs)"
    source="$(echo "$source" | xargs)"
    extra_args="$(echo "$extra_args" | xargs)"

    case "$method" in
        rsync)
            sync_rsync "$name" "$source" "$extra_args" || {
                log "FAIL   | $name | rsync exited with $?"
                ((FAIL_COUNT++))
            }
            ;;
        wget)
            sync_wget "$name" "$source" "$extra_args" || {
                log "FAIL   | $name | wget exited with $?"
                ((FAIL_COUNT++))
            }
            ;;
        *)
            log "SKIP   | $name | Unknown method: $method"
            ;;
    esac

done < "$CONFIG_FILE"

# Write a timestamp for the health check / status page
date -u '+%Y-%m-%dT%H:%M:%SZ' > "$MIRROR_ROOT/.last-sync"

if [[ $FAIL_COUNT -gt 0 ]]; then
    log "========== Sync finished with $FAIL_COUNT failure(s) =========="
    exit 1
else
    log "========== Sync finished successfully =========="
fi
