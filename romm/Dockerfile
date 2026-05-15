FROM rommapp/romm:latest

# Installa dipendenze HA
RUN apk add --no-cache curl jq openssl

# Patcha nginx per servire i file da /share/romm/library
# invece di /romm/library (path persistente su HAOS)
RUN sed -i 's|alias "/romm/library/";|alias "/share/romm/library/";|g' \
    /etc/nginx/conf.d/default.conf

# Verifica che la patch sia stata applicata
RUN grep -n "alias" /etc/nginx/conf.d/default.conf

# Copia lo script di avvio
COPY run.sh /run.sh
RUN chmod +x /run.sh

EXPOSE 8080
CMD ["/run.sh"]
