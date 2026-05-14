#!/bin/bash
set -e

log() { echo "[RomM Addon] $*"; }

OPTIONS="/data/options.json"
if [ ! -f "$OPTIONS" ]; then log "ERRORE: options non trovato"; exit 1; fi

# ── Leggi le opzioni ──────────────────────────────────────────────────────────
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

if [ -z "$MARIADB_USER" ] || [ -z "$MARIADB_PASS" ]; then
    log "ERRORE: mariadb_user e mariadb_password obbligatori!"; exit 1
fi

# ── Secret key ────────────────────────────────────────────────────────────────
SECRET_KEY_FILE="/data/romm_secret_key"
if [ ! -f "$SECRET_KEY_FILE" ]; then
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

# ── DEBUG: trova LIBRARY_BASE_PATH ────────────────────────────────────────────
log "=== DEBUG LIBRARY_BASE_PATH ==="
log "Cerco LIBRARY_BASE_PATH nel codice:"
grep -rn "LIBRARY_BASE_PATH\|ROMM_BASE_PATH\|library_base\|base_path" \
    /backend/config/ /backend/utils/ /backend/handler/filesystem/base_handler.py \
    2>/dev/null | grep -v ".pyc" | head -30
log "Variabili d'ambiente RomM riconosciute:"
grep -rn "os.environ\|os.getenv\|environ.get" /backend/config/ 2>/dev/null | head -20
log "=== FINE DEBUG ==="

# ── Percorsi ──────────────────────────────────────────────────────────────────
# /romm/library è montato da HAOS come volume — copiamo le ROM dentro
log "Sincronizzazione ROM in /romm/library..."
if [ -d "$ROM_LIBRARY" ]; then
    # Copia solo i file mancanti (non sovrascrive, non cancella)
    cp -rn "$ROM_LIBRARY"/. /romm/library/ 2>/dev/null || true
fi

mkdir -p /romm/resources /romm/assets /romm/config
[ ! -f "/romm/config/config.yml" ] && touch /romm/config/config.yml

chmod -R 755 /romm/library 2>/dev/null || true

log "Libreria ROM: $ROM_LIBRARY → /romm/library"
log "Database:     MariaDB @ $MARIADB_HOST/$MARIADB_DB"
log "Avvio RomM sulla porta 8080..."

if [ -f "/init" ]; then exec /init
elif [ -f "/start.sh" ]; then exec /start.sh
elif [ -f "/docker-entrypoint.sh" ]; then exec /docker-entrypoint.sh
else log "ERRORE: entrypoint non trovato"; ls -la /; exit 1
fi
