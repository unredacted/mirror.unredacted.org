FROM caddy:2-alpine

# ── Install sync tools ──────────────────────────────────────────────────────
RUN apk add --no-cache \
    rsync \
    wget \
    bash \
    dcron \
    tzdata \
    stunnel \
    git \
    perl

# ── Install Debian ftpsync (archvsync) ──────────────────────────────────
RUN git clone --depth=1 https://salsa.debian.org/mirror-team/archvsync.git /opt/ftpsync \
    && chmod +x /opt/ftpsync/bin/*

# ── Set timezone (adjust as needed) ─────────────────────────────────────────
ENV TZ=UTC

# ── Copy configuration ──────────────────────────────────────────────────────
COPY Caddyfile /etc/caddy/Caddyfile
COPY mirrors.conf /etc/mirror/mirrors.conf
COPY ftpsync.conf /etc/ftpsync/ftpsync.conf

# ── Copy scripts ─────────────────────────────────────────────────────────────
COPY sync-mirrors.sh /usr/local/bin/sync-mirrors.sh
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/sync-mirrors.sh /usr/local/bin/entrypoint.sh

# ── Cron: sync every hour ────────────────────────────────────────────────
RUN echo "0 * * * * flock -n /var/run/lock/mirror-sync /usr/local/bin/sync-mirrors.sh >> /var/log/mirror/cron.log 2>&1" \
    | crontab -

# ── Volume for mirror data (persists across redeploys) ───────────────────────
VOLUME ["/data/mirror"]

EXPOSE 3080

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
