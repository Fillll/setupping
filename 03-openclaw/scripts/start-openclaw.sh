#!/bin/sh
set -eu

# Start vnStat collection daemon in background for continuous traffic stats.
mkdir -p /var/lib/vnstat

VNSTAT_IFACE="${VNSTAT_INTERFACE:-eth0}"
if [ -n "$VNSTAT_IFACE" ]; then
  vnstat --add -i "$VNSTAT_IFACE" >/dev/null 2>&1 || true
fi

# Run foreground daemon in background so this script can exec OpenClaw.
vnstatd -n >/tmp/vnstatd.log 2>&1 &

if command -v gosu >/dev/null 2>&1; then
  exec gosu node docker-entrypoint.sh "$@"
fi

if command -v su-exec >/dev/null 2>&1; then
  exec su-exec node docker-entrypoint.sh "$@"
fi

exec docker-entrypoint.sh "$@"
