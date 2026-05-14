#!/bin/bash
set -e

log() { echo "[RomM Addon] $*"; }

OPTIONS="/data/options.json"

if [ ! -f "$OPTIONS" ]; then
    log "ERRORE: file opzioni non trovato in $OPTIONS"
    exit 1
fi

# ── Leggi le opzioni da HA ────────────────────────────────────────────────────
DB_TYPE=$(jq -r '.db_type // "sqlite"' "$OPTIONS")
ROM_LIBRARY=$(jq -r '.rom_library_path // "/share/roms"' "$OPTIONS")
IGDB_ID=$(jq -r '.igdb_client_id // ""' "$OPTIONS")
IGDB_SECRET=$(jq -r '.igdb_client_secret // ""' "$OPTIONS")
SS_USER=$(jq -r '.screenscraper_user // ""' "$OPTIONS")
SS_PASS=$(jq -r '.screenscraper_password // ""' "$OPTIONS")

# ── Genera la secret key se non esiste già ────────────────────────────────────
SECRET_KEY_FILE="/data/romm_secret_key"
if [ ! -f "$SECRET_KEY_FILE" ]; then
    log "Generazione ROMM_AUTH_SECRET_KEY..."
    openssl rand -hex 32 > "$SECRET_KEY_FILE"
fi
export ROMM_AUTH_SECRET_KEY=$(cat "$SECRET_KEY_FILE")

# ── Configurazione database ───────────────────────────────────────────────────
if [ "$DB_TYPE" = "mariadb" ]; then
    log "Utilizzo MariaDB..."
    MARIADB_HOST=$(jq -r '.mariadb_host // ""' "$OPTIONS")
    MARIADB_PORT=$(jq -r '.mariadb_port // 3306' "$OPTIONS")
    MARIADB_USER=$(jq -r '.mariadb_user // ""' "$OPTIONS")
    MARIADB_PASS=$(jq -r '.mariadb_password // ""' "$OPTIONS")
    MARIADB_DB=$(jq -r '.mariadb_database // "romm"' "$OPTIONS")

    if [ -z "$MARIADB_HOST" ] || [ -z "$MARIADB_USER" ] || [ -z "$MARIADB_PASS" ]; then
        log "ERRORE: con db_type=mariadb devi compilare mariadb_host, mariadb_user e mariadb_password!"
        exit 1
    fi

    export DB_HOST="$MARIADB_HOST"
    export DB_PORT="$MARIADB_PORT"
    export DB_USER="$MARIADB_USER"
    export DB_PASSWD="$MARIADB_PASS"
    export DB_NAME="$MARIADB_DB"
else
    log "Utilizzo SQLite..."
    export ROMM_DB_DRIVER=sqlite
    unset DB_HOST
fi

# ── Metadati ──────────────────────────────────────────────────────────────────
[ -n "$IGDB_ID" ]     && export IGDB_CLIENT_ID="$IGDB_ID"
[ -n "$IGDB_SECRET" ] && export IGDB_CLIENT_SECRET="$IGDB_SECRET"
[ -n "$SS_USER" ]     && export SCREENSCRAPER_USER="$SS_USER"
[ -n "$SS_PASS" ]     && export SCREENSCRAPER_PASSWORD="$SS_PASS"

# ── Percorsi e cartelle dati persistenti ─────────────────────────────────────
mkdir -p /data/romm/resources
mkdir -p /data/romm/assets
mkdir -p /data/romm/config

# Crea il config.yml vuoto se non esiste (evita il CRITICAL al primo avvio)
if [ ! -f "/data/romm/config/config.yml" ]; then
    log "Creazione config.yml vuoto..."
    cat > /data/romm/config/config.yml << 'CONFIGEOF'
# RomM configuration file
# Documentazione: https://docs.romm.app/latest/Getting-Started/Configuration-File/
CONFIGEOF
fi

# Libreria ROM
if [ ! -d "$ROM_LIBRARY" ]; then
    log "Cartella ROM '$ROM_LIBRARY' non trovata, verrà creata."
    mkdir -p "$ROM_LIBRARY"
fi

# Collega le cartelle al percorso atteso da RomM
ln -sfn /data/romm/resources /romm/resources 2>/dev/null || true
ln -sfn /data/romm/assets    /romm/assets    2>/dev/null || true
ln -sfn /data/romm/config    /romm/config    2>/dev/null || true
ln -sfn "$ROM_LIBRARY"       /romm/library   2>/dev/null || true

log "Libreria ROM: $ROM_LIBRARY"
log "Database: $DB_TYPE"
log "Avvio RomM sulla porta 8080..."

# ── Avvio con l'entrypoint originale di RomM ─────────────────────────────────
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
