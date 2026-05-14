ARG BUILD_FROM
FROM $BUILD_FROM AS base

# Installa bashio e dipendenze base
RUN apk add --no-cache \
    bash \
    curl \
    openssl

# Scarica e installa l'immagine RomM copiando i suoi file
FROM rommapp/romm:latest AS romm_source

# Stage finale basato sull'immagine HA
FROM base

# Copia i file di RomM dall'immagine upstream
COPY --from=romm_source /app /app
COPY --from=romm_source /usr/local/lib/python3* /usr/local/lib/
COPY --from=romm_source /usr/local/bin/python3* /usr/local/bin/
COPY --from=romm_source /usr/local/bin/uvicorn /usr/local/bin/uvicorn

# Copia lo script di avvio
COPY run.sh /run.sh
RUN chmod +x /run.sh

# Porta interna di RomM
EXPOSE 8080

CMD ["/run.sh"]
