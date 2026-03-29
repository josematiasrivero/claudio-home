#!/bin/bash
# Backup all project databases to /backups/YYYY-MM-DD/
BACKUP_DIR="/backups/$(date +%Y-%m-%d)"
mkdir -p "$BACKUP_DIR"

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
        continue
    fi

    echo "[$(date +%H:%M:%S)] Backing up $name..."
    if PGPASSWORD="$pass" pg_dump -h "$host" -p "$port" -U "$user" "$db" \
        | gzip > "$BACKUP_DIR/${name}.sql.gz"; then
        echo "[$(date +%H:%M:%S)] $name done ($(du -h "$BACKUP_DIR/${name}.sql.gz" | cut -f1))"
    else
        echo "[$(date +%H:%M:%S)] FAIL $name"
    fi
done

# Clean up backups older than 30 days
find /backups -type d -mtime +30 -exec rm -rf {} + 2>/dev/null || true

echo "[$(date +%H:%M:%S)] All backups complete in $BACKUP_DIR"
