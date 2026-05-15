FROM rommapp/romm:latest

# Installa dipendenze HA
RUN apk add --no-cache curl jq openssl nginx

# Mostra il contenuto attuale di default.conf per debug
RUN cat /etc/nginx/conf.d/default.conf

# Copia lo script di avvio
COPY run.sh /run.sh
RUN chmod +x /run.sh

EXPOSE 8080
CMD ["/run.sh"]
