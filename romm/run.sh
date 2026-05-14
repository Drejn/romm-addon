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
    log "ERRORE: devi compilare mariadb_user e mariadb_password!"
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

# ── DEBUG: leggi come RomM costruisce i path ──────────────────────────────────
log "=== DEBUG CODICE ==="
log "base_handler.py:"
cat /backend/handler/filesystem/base_handler.py 2>/dev/null | head -60 || log "non trovato"
log "roms_handler.py (sezione path):"
grep -n "base_path\|library\|file_path\|X-Archive\|ROMM_BASE" /backend/handler/filesystem/roms_handler.py 2>/dev/null | head -30 || log "non trovato"
log "nginx conf completa (location blocks):"
grep -A 10 "location" /etc/nginx/nginx.conf 2>/dev/null | head -60 || log "non trovato"
log "=== FINE DEBUG ==="

# ── Percorsi ──────────────────────────────────────────────────────────────────
# Usa /romm come base — è la cartella nativa di RomM
# e monta la libreria ROM direttamente in /romm/library
export ROMM_BASE_PATH=/romm

mkdir -p /romm/resources
mkdir -p /romm/assets
mkdir -p /romm/config

if [ ! -f "/romm/config/config.yml" ]; then
    touch /romm/config/config.yml
fi

if [ ! -d "$ROM_LIBRARY" ]; then
    mkdir -p "$ROM_LIBRARY"
fi

# Svuota /romm/library e rimpiazza con bind mount o copia symlink
rm -rf /romm/library
ln -sfn "$ROM_LIBRARY" /romm/library

# Fix permessi
chmod -R 755 "$ROM_LIBRARY" 2>/dev/null || true
chmod -R 755 /romm 2>/dev/null || true

log "ROMM_BASE_PATH: /romm"
log "Libreria ROM:   $ROM_LIBRARY -> /romm/library"
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
    log "ERRORE: entrypoint non trovato"
    ls -la /
    exit 1
fi
