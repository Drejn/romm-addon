#!/usr/bin/with-contenv bashio

bashio::log.info "Avvio RomM..."

# ── Leggi le opzioni dall'interfaccia HA ──────────────────────────────────────
DB_TYPE=$(bashio::config 'db_type')
ROM_LIBRARY=$(bashio::config 'rom_library_path')
IGDB_ID=$(bashio::config 'igdb_client_id')
IGDB_SECRET=$(bashio::config 'igdb_client_secret')
SS_USER=$(bashio::config 'screenscraper_user')
SS_PASS=$(bashio::config 'screenscraper_password')

# ── Genera la secret key se non esiste già ────────────────────────────────────
SECRET_KEY_FILE="/data/romm_secret_key"
if [ ! -f "$SECRET_KEY_FILE" ]; then
    bashio::log.info "Generazione ROMM_AUTH_SECRET_KEY..."
    openssl rand -hex 32 > "$SECRET_KEY_FILE"
fi
export ROMM_AUTH_SECRET_KEY=$(cat "$SECRET_KEY_FILE")

# ── Configurazione database ───────────────────────────────────────────────────
if [ "$DB_TYPE" = "mariadb" ]; then
    bashio::log.info "Utilizzo MariaDB come database..."

    MARIADB_HOST=$(bashio::config 'mariadb_host')
    MARIADB_PORT=$(bashio::config 'mariadb_port')
    MARIADB_USER=$(bashio::config 'mariadb_user')
    MARIADB_PASS=$(bashio::config 'mariadb_password')
    MARIADB_DB=$(bashio::config 'mariadb_database')

    if bashio::config.is_empty 'mariadb_host' || bashio::config.is_empty 'mariadb_user' || bashio::config.is_empty 'mariadb_password'; then
        bashio::log.error "Con db_type=mariadb devi compilare mariadb_host, mariadb_user e mariadb_password!"
        exit 1
    fi

    export DB_HOST="$MARIADB_HOST"
    export DB_PORT="$MARIADB_PORT"
    export DB_USER="$MARIADB_USER"
    export DB_PASSWD="$MARIADB_PASS"
    export DB_NAME="$MARIADB_DB"
else
    bashio::log.info "Utilizzo SQLite come database..."
    # RomM usa SQLite automaticamente se DB_HOST non è impostato
    unset DB_HOST
fi

# ── Metadati ──────────────────────────────────────────────────────────────────
[ -n "$IGDB_ID" ]     && export IGDB_CLIENT_ID="$IGDB_ID"
[ -n "$IGDB_SECRET" ] && export IGDB_CLIENT_SECRET="$IGDB_SECRET"
[ -n "$SS_USER" ]     && export SCREENSCRAPER_USER="$SS_USER"
[ -n "$SS_PASS" ]     && export SCREENSCRAPER_PASSWORD="$SS_PASS"

# ── Percorsi ──────────────────────────────────────────────────────────────────
export ROMM_BASE_PATH="/data/romm"
mkdir -p "$ROMM_BASE_PATH/resources"
mkdir -p "$ROMM_BASE_PATH/assets"
mkdir -p "$ROMM_BASE_PATH/config"

# Mappa la libreria ROM configurata dall'utente
if [ ! -d "$ROM_LIBRARY" ]; then
    bashio::log.warning "La cartella ROM '$ROM_LIBRARY' non esiste. Verrà creata."
    mkdir -p "$ROM_LIBRARY"
fi

# Link simbolico: RomM si aspetta la libreria in /romm/library
ln -sfn "$ROM_LIBRARY" /romm/library || true

bashio::log.info "Libreria ROM: $ROM_LIBRARY"
bashio::log.info "Database: $DB_TYPE"
bashio::log.info "Avvio del server RomM sulla porta 8080..."

# ── Avvio ─────────────────────────────────────────────────────────────────────
exec python3 -m uvicorn main:app \
    --host 0.0.0.0 \
    --port 8080 \
    --workers 2 \
    --app-dir /app
