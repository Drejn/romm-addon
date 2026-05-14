#!/bin/bash
set -e

set -euo pipefail
log() { echo "[RomM Addon] $*"; }

OPTIONS="/data/options.json"

if [ ! -f "$OPTIONS" ]; then
    log "ERRORE: file opzioni non trovato in $OPTIONS"
    exit 1
fi

# ── Leggi le opzioni da HA ────────────────────────────────────────────────────

MARIADB_HOST=$(jq -r '.mariadb_host // "core-mariadb"' "$OPTIONS")
MARIADB_PORT=$(jq -r '.mariadb_port // 3306' "$OPTIONS")
MARIADB_USER=$(jq -r '.mariadb_user // ""' "$OPTIONS")
MARIADB_PASS=$(jq -r '.mariadb_password // ""' "$OPTIONS")
MARIADB_DB=$(jq -r '.mariadb_database // "romm"' "$OPTIONS")
IGDB_ID=$(jq -r '.igdb_client_id // ""' "$OPTIONS")
IGDB_SECRET=$(jq -r '.igdb_client_secret // ""' "$OPTIONS")
SS_USER=$(jq -r '.screenscraper_user // ""' "$OPTIONS")
SS_PASS=$(jq -r '.screenscraper_password // ""' "$OPTIONS")

# ── Validazione ───────────────────────────────────────────────────────────────
if [ -z "$MARIADB_USER" ] || [ -z "$MARIADB_PASS" ]; then
    log "ERRORE: devi compilare mariadb_user e mariadb_password nella configurazione addon!"
    exit 1
fi

# ── Secret key ────────────────────────────────────────────────────────────────
SECRET_KEY_FILE="/data/romm_secret_key"
if [ ! -f "$SECRET_KEY_FILE" ]; then
    log "Generazione ROMM_AUTH_SECRET_KEY..."
    openssl rand -hex 32 > "$SECRET_KEY_FILE"
fi
export ROMM_AUTH_SECRET_KEY=$(cat "$SECRET_KEY_FILE")

# ── Database ──────────────────────────────────────────────────────────────────
export DB_HOST="$MARIADB_HOST"
export DB_PORT="$MARIADB_PORT"
export DB_USER="$MARIADB_USER"
export DB_PASSWD="$MARIADB_PASS"
export DB_NAME="$MARIADB_DB"

# ── Metadati ──────────────────────────────────────────────────────────────────
[ -n "$IGDB_ID" ]     && export IGDB_CLIENT_ID="$IGDB_ID"
[ -n "$IGDB_SECRET" ] && export IGDB_CLIENT_SECRET="$IGDB_SECRET"
[ -n "$SS_USER" ]     && export SCREENSCRAPER_USER="$SS_USER"
[ -n "$SS_PASS" ]     && export SCREENSCRAPER_PASSWORD="$SS_PASS"

# ── Percorsi ──────────────────────────────────────────────────────────────────
# ROMM_BASE_PATH=/share così sia /share/roms che /share/romm
# sono sotto lo stesso genitore e RomM non blocca l'accesso ai file
export ROMM_BASE_PATH=/share/romm

mkdir -p /share/romm/resources
mkdir -p /share/romm/assets
mkdir -p /share/romm/config
mkdir -p /share/romm/library

# Crea il config.yml se non esiste
if [ ! -f "/share/romm/config/config.yml" ]; then
    log "Creazione config.yml..."
    touch /share/romm/config/config.yml
fi
# Libreria ROM: path diretto, niente symlink

log "ROMM_BASE_PATH: $ROMM_BASE_PATH"

log "Database:       MariaDB @ $MARIADB_HOST/$MARIADB_DB"
log "Avvio RomM sulla porta 8080..."

# ── Avvio ─────────────────────────────────────────────────────────────────────
if [ -f "/init" ]; then
    exec /init
elif [ -f "/start.sh" ]; then
    exec /start.sh
elif [ -f "/docker-entrypoint.sh" ]; then
    exec /docker-entrypoint.sh
else
    log "ERRORE: entrypoint non trovato. Contenuto di /:"
    ls -la /
    exit 1
fi


# Read options.json if present
INTERNAL_SECRET_DEFAULT="secret"
ROM_LIBRARY_DEFAULT="/share/romm/library"

if [ -f /data/options.json ]; then
  INTERNAL_SECRET=$(jq -r '.internal_secret // empty' /data/options.json)
  ROM_LIBRARY_PATH=$(jq -r '.rom_library_path // empty' /data/options.json)
fi

INTERNAL_SECRET=${INTERNAL_SECRET:-$INTERNAL_SECRET_DEFAULT}
ROM_LIBRARY_PATH=${ROM_LIBRARY_PATH:-$ROM_LIBRARY_DEFAULT}


export INTERNAL_SECRET
export ROM_LIBRARY_PATH

# Render nginx config from template by replacing placeholder
if [ -f /etc/nginx/nginx.conf ]; then
  # backup existing
  cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.bak || true
fi

sed "s|__INTERNAL_SECRET__|${INTERNAL_SECRET}|g" /nginx.conf.template > /etc/nginx/nginx.conf

# Ensure uvicorn binds to localhost:8081 (only accessible inside container)
uvicorn app.main:app --host 127.0.0.1 --port 8081 &

# Start nginx in foreground
nginx -g "daemon off;"

