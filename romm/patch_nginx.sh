#!/usr/bin/env bash
set -euo pipefail

NGINX_CONF="/etc/nginx/nginx.conf"
BACKUP_CONF="/etc/nginx/nginx.conf.orig"
INSERTED_FLAG="/tmp/romm_nginx_patch_done"

# Non ripetere l'inserimento se già fatto in build precedente
if [ -f "${INSERTED_FLAG}" ]; then
  echo "Patch già applicata in questa immagine. Esco."
  exit 0
fi

# Backup del file originale (solo la prima volta)
if [ ! -f "${BACKUP_CONF}" ] && [ -f "${NGINX_CONF}" ]; then
  cp "${NGINX_CONF}" "${BACKUP_CONF}"
  echo "Backup creato: ${BACKUP_CONF}"
fi

# Scegli il percorso della library (adatta se necessario)
CANDIDATES=(
  "/share/romm/library"
  "/var/lib/romm/library"
  "/opt/romm/library"
)

LIB_PATH=""
for p in "${CANDIDATES[@]}"; do
  if [ -d "$p" ]; then
    LIB_PATH="$p"
    break
  fi
done

# Se nessun candidato esiste, usa il primo come default (l'utente dovrà adattare)
if [ -z "$LIB_PATH" ]; then
  LIB_PATH="${CANDIDATES[0]}"
  echo "Nessun percorso library esistente trovato; userò il percorso predefinito: ${LIB_PATH}"
fi

# Assicura trailing slash per alias
case "$LIB_PATH" in
  */) ;;
  *) LIB_PATH="${LIB_PATH}/" ;;
esac

# Crea symlink /var/lib/romm/library -> $LIB_PATH se non esiste e se possibile
if [ ! -e "/var/lib/romm/library" ]; then
  mkdir -p /var/lib/romm 2>/dev/null || true
  if ln -sfn "$LIB_PATH" /var/lib/romm/library 2>/dev/null; then
    echo "Symlink creato: /var/lib/romm/library -> ${LIB_PATH}"
  else
    echo "Impossibile creare symlink /var/lib/romm/library (potrebbe essere readonly). Continuo comunque."
  fi
fi

# Blocco location da inserire (modifica qui se vuoi un path diverso)
read -r -d '' LOCATION_BLOCK <<EOF || true
    # BEGIN romm_custom: internal library alias
    location /library/ {
        internal;
        alias ${LIB_PATH};
        # disabilita buffering per streaming
        proxy_buffering off;
    }
    # END romm_custom
EOF

# Funzione che inserisce il blocco nel server con listen su 8998 o nel primo server
insert_location() {
  local src="$1"
  local dst="${src}.patched"
  awk -v loc="$LOCATION_BLOCK" '
    BEGIN { in_server=0; target_server=0; inserted=0; server_level=0 }
    {
      print $0
      # rileva inizio server
      if ($0 ~ /server[[:space:]]*\{/) {
        in_server=1
        server_level=1
        server_text = $0
      }
      # se siamo dentro un server, cerca listen 8998
      if (in_server && $0 ~ /listen[[:space:]]+.*8998/) {
        target_server=1
      }
      # gestione annidamento graffe: conta livelli per server block robusto
      if (in_server) {
        # conta '{' e '}' per capire quando chiude il server
        n_open = gsub(/\{/, "{", $0)
        n_close = gsub(/\}/, "}", $0)
        server_level += n_open - n_close
        if (server_level <= 0) {
          if (target_server && !inserted) {
            print loc
            inserted=1
          } else if (!target_server && !inserted) {
            # fallback: inserisci nel primo server se non abbiamo trovato listen 8998
            print loc
            inserted=1
          }
          in_server=0
          target_server=0
          server_level=0
        }
      }
    }
  ' "$src" > "$dst" && mv "$dst" "$src"
}

# Verifica che il file esista
if [ ! -f "${NGINX_CONF}" ]; then
  echo "Errore: ${NGINX_CONF} non trovato. Esco."
  exit 1
fi

# Applica l'inserimento
insert_location "${NGINX_CONF}"
echo "Blocco location inserito in ${NGINX_CONF}."

# Verifica sintassi nginx se disponibile
if command -v nginx >/dev/null 2>&1; then
  if nginx -t; then
    echo "nginx -t OK"
  else
    echo "Attenzione: nginx -t ha segnalato errori. Controlla ${NGINX_CONF} e il backup ${BACKUP_CONF}."
  fi
else
  echo "nginx non disponibile in fase di build; verifica la sintassi a runtime."
fi

# Segna che la patch è stata applicata in questa immagine
touch "${INSERTED_FLAG}"
echo "Patch applicata con successo."
