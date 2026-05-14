FROM rommapp/romm:latest

# Installa le dipendenze necessarie per leggere le opzioni di HA
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    jq \
    openssl \
    && rm -rf /var/lib/apt/lists/*

# Copia lo script di avvio
COPY run.sh /run.sh
RUN chmod +x /run.sh

EXPOSE 8080

CMD ["/run.sh"]
