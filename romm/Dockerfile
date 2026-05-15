FROM rommapp/romm:4.9.0-alpha.2

RUN apk add curl jq openssl
COPY run.sh /run.sh
RUN chmod +x /run.sh

CMD ["/run.sh"]
