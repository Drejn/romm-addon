#!/usr/bin/env bash
set -euo pipefail

NGINX_CONF="/etc/nginx/nginx.conf"
BACKUP_CONF="/etc/nginx/nginx.conf.orig"

# Fai un backup del file originale (se non esiste già)
if [ ! -f "${BACKUP_CONF}" ]; then
  cp "${NGINX_CONF}" "${BACKUP_CONF}" || true
fi

# Contenuto della location da inserire
read -r -d '' LOCATION_BLOCK <<'EOF' || true
    # BEGIN romm_custom: internal decode location
    location = /decode_internal {
        internal;
        proxy_pass http://127.0.0.1:8998/decode;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header Cookie "";
        proxy_buffering off;
    }
    # END romm_custom
EOF

# Inserimento: trova il primo server { ... } che contiene "listen" su 8998 o il primo server e inserisci prima della chiusura del server
# Primo tentativo: cerca server che ascolta 8998
if grep -q "listen[[:space:]]\+.*8998" "${NGINX_CONF}"; then
  # Inserisci LOCATION_BLOCK prima della chiusura del server che contiene listen 8998
  awk -v loc="$LOCATION_BLOCK" '
    BEGIN { in_server=0; inserted=0 }
    {
      print $0
      if ($0 ~ /server[[:space:]]*\{/) { in_server=1; server_block_lines=1 }
      if (in_server && $0 ~ /listen[[:space:]]+.*8998/) { target_server=1 }
      if (in_server && $0 ~ /\}/) {
        if (target_server && !inserted) {
          print loc
          inserted=1
        }
        in_server=0
        target_server=0
      }
    }
  ' "${NGINX_CONF}" > "${NGINX_CONF}.patched" && mv "${NGINX_CONF}.patched" "${NGINX_CONF}"
else
  # Fallback: inserisci la location nel primo server block disponibile
  awk -v loc="$LOCATION_BLOCK" '
    BEGIN { in_server=0; inserted=0 }
    {
      print $0
      if ($0 ~ /server[[:space:]]*\{/) { in_server=1 }
      if (in_server && $0 ~ /\}/) {
        if (!inserted) {
          print loc
          inserted=1
        }
        in_server=0
      }
    }
  ' "${NGINX_CONF}" > "${NGINX_CONF}.patched" && mv "${NGINX_CONF}.patched" "${NGINX_CONF}"
fi

# Verifica sintassi nginx se disponibile
if command -v nginx >/dev/null 2>&1; then
  nginx -t || true
fi

echo "nginx.conf patched (backup at ${BACKUP_CONF})"
