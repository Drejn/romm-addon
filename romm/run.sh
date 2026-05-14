#!/bin/bash
set -e

log() { echo "[RomM Addon] $*"; }

OPTIONS="/data/options.json"

if [ ! -f "$OPTIONS" ]; then
    log "ERRORE: file opzioni non trovato in $OPTIONS"
    exit 1
fi

# ── Leggi le opzioni da HA ────────────────────────────────────────────────────
ROM_LIBRARY=$(jq -r '.rom_library_path // "/share/roms/roms"' "$OPTIONS")
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
export ROMM_BASE_PATH=/share

mkdir -p /share/romm/resources
mkdir -p /share/romm/assets
mkdir -p /share/romm/config

if [ ! -f "/share/romm/config/config.yml" ]; then
    log "Creazione config.yml..."
    touch /share/romm/config/config.yml
fi

if [ ! -d "$ROM_LIBRARY" ]; then
    log "Cartella ROM '$ROM_LIBRARY' non trovata, verrà creata."
    mkdir -p "$ROM_LIBRARY"
fi

# ── Fix permessi adattivo ─────────────────────────────────────────────────────
CURRENT_UID=$(id -u)
CURRENT_GID=$(id -g)
log "Utente corrente: uid=$CURRENT_UID gid=$CURRENT_GID"
log "Correzione permessi libreria ROM..."
chmod -R 755 "$ROM_LIBRARY" 2>/dev/null || true
chown -R "${CURRENT_UID}:${CURRENT_GID}" "$ROM_LIBRARY" 2>/dev/null || true
chown -R "${CURRENT_UID}:${CURRENT_GID}" /share/romm 2>/dev/null || true

log "ROMM_BASE_PATH: /share"
log "Libreria ROM:   $ROM_LIBRARY"
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
