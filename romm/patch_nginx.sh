#!/usr/bin/env bash
set -euo pipefail

NGINX_CONF="/etc/nginx/nginx.conf"
BACKUP_CONF="/etc/nginx/nginx.conf.orig"
FLAG="/tmp/romm_nginx_patch_done"

if [ -f "${FLAG}" ]; then
  echo "Patch già applicata in questa immagine. Esco."
  exit 0
fi

if [ ! -f "${NGINX_CONF}" ]; then
  echo "Errore: ${NGINX_CONF} non trovato. Esco."
  exit 1
fi

# Backup (solo la prima volta)
if [ ! -f "${BACKUP_CONF}" ]; then
  cp "${NGINX_CONF}" "${BACKUP_CONF}"
  echo "Backup creato: ${BACKUP_CONF}"
fi

# Individua percorso library esistente (adatta se necessario)
CANDIDATES=( "/share/romm/library" "/var/lib/romm/library" "/opt/romm/library" )
LIB_PATH=""
for p in "${CANDIDATES[@]}"; do
  if [ -d "$p" ]; then
    LIB_PATH="$p"
    break
  fi
done
if [ -z "$LIB_PATH" ]; then
  LIB_PATH="${CANDIDATES[0]}"
  echo "Nessun percorso library trovato; userò il predefinito: ${LIB_PATH}"
fi
case "$LIB_PATH" in */) ;; *) LIB_PATH="${LIB_PATH}/" ;; esac

# Crea symlink se possibile (non fallisce il build se non permesso)
if [ ! -e "/var/lib/romm/library" ]; then
  mkdir -p /var/lib/romm 2>/dev/null || true
  ln -sfn "$LIB_PATH" /var/lib/romm/library 2>/dev/null || true
fi

# Blocco da inserire (usa alias o location proxy a seconda del bisogno)
read -r -d '' LOCATION_BLOCK <<EOF || true
    # BEGIN romm_custom: internal library alias
    location /library/ {
        internal;
        alias ${LIB_PATH};
        proxy_buffering off;
    }
    # END romm_custom
EOF

# Se la patch è già presente nel file, esci
if grep -q "BEGIN romm_custom" "${NGINX_CONF}"; then
  echo "Patch già presente in ${NGINX_CONF}."
  touch "${FLAG}"
  exit 0
fi

# Funzione: inserisce locazione SOLO dentro http -> server
awk -v loc="$LOCATION_BLOCK" '
  BEGIN {
    in_http=0; in_server=0; http_level=0; server_level=0; inserted=0;
  }
  {
    print $0;
    # conta aperture/chiusure graffe per tracciare i livelli
    n_open = gsub(/\{/, "{", $0);
    n_close = gsub(/\}/, "}", $0);

    # entra in http
    if ($0 ~ /^[[:space:]]*http[[:space:]]*\{[[:space:]]*$/) {
      in_http=1;
      http_level += n_open - n_close;
      next;
    }
    if (in_http) {
      http_level += n_open - n_close;
      # entra in server
      if ($0 ~ /^[[:space:]]*server[[:space:]]*\{[[:space:]]*$/) {
        in_server=1;
        server_level = 1;
        next;
      }
      if (in_server) {
        # aggiorna livello server
        server_level += n_open - n_close;
        # se stiamo per chiudere il server, inserisci la location prima della chiusura
        if (server_level <= 0 && !inserted) {
          print loc;
          inserted=1;
          in_server=0;
        }
      }
      # se chiude http senza aver inserito nulla, fallback: inserisci prima della chiusura di http
      if (http_level <= 0 && !inserted) {
        print loc;
        inserted=1;
        in_http=0;
      }
    }
  }
' "${NGINX_CONF}" > "${NGINX_CONF}.patched" && mv "${NGINX_CONF}.patched" "${NGINX_CONF}"

echo "Blocco location inserito in ${NGINX_CONF} (sezione http->server)."

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

touch "${FLAG}"
echo "Patch applicata con successo."
