#!/bin/bash
# Backup all project databases to /backups/YYYY-MM-DD/
BACKUP_DIR="/backups/$(date +%Y-%m-%d)"
mkdir -p "$BACKUP_DIR"

RESULTS=""
FAILURES=0

declare -A DATABASES=(
    ["bearme"]="host.docker.internal:5010:bearme:bearme:bearme"
    ["invoiceme"]="host.docker.internal:6010:invoiceme:invoiceme:invoiceme"
    ["cotizador"]="host.docker.internal:3010:postgres:postgres:cotizador"
    ["archetype"]="host.docker.internal:4010:archetype:archetype:archetype"
)

for name in "${!DATABASES[@]}"; do
    IFS=':' read -r host port user pass db <<< "${DATABASES[$name]}"

    if ! pg_isready -h "$host" -p "$port" -U "$user" -t 3 &>/dev/null; then
        echo "[$(date +%H:%M:%S)] SKIP $name — not reachable at $host:$port"
        RESULTS="$RESULTS\n⏭️ $name — skipped (not reachable)"
        continue
    fi

    echo "[$(date +%H:%M:%S)] Backing up $name..."
    if PGPASSWORD="$pass" pg_dump -h "$host" -p "$port" -U "$user" "$db" \
        | gzip > "$BACKUP_DIR/${name}.sql.gz"; then
        SIZE=$(du -h "$BACKUP_DIR/${name}.sql.gz" | cut -f1)
        echo "[$(date +%H:%M:%S)] $name done ($SIZE)"
        RESULTS="$RESULTS\n✅ $name — $SIZE"
    else
        echo "[$(date +%H:%M:%S)] FAIL $name"
        RESULTS="$RESULTS\n❌ $name — failed"
        FAILURES=$((FAILURES + 1))
    fi
done

# Clean up backups older than 30 days
find /backups -type d -mtime +30 -exec rm -rf {} + 2>/dev/null || true

echo "[$(date +%H:%M:%S)] All backups complete in $BACKUP_DIR"

# Slack notification
if [ -n "$SLACK_WEBHOOK_URL" ]; then
    if [ "$FAILURES" -gt 0 ]; then
        ICON=":warning:"
        TITLE="DB Backup completed with errors"
    else
        ICON=":white_check_mark:"
        TITLE="DB Backup completed"
    fi

    PAYLOAD=$(cat <<EOF
{"text": "$ICON *$TITLE* — $(date +%Y-%m-%d)\n$(echo -e "$RESULTS")"}
EOF
    )
    curl -s -X POST -H 'Content-type: application/json' --data "$PAYLOAD" "$SLACK_WEBHOOK_URL"
fi
