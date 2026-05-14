FROM rommapp/romm:latest
RUN apk add --no-cache curl jq openssl
RUN mkdir -p /var/lib/romm && ln -sfn /share/romm/library /var/lib/romm/library
COPY run.sh /run.sh
RUN chmod +x /run.sh
EXPOSE 8080
CMD ["/run.sh"]
