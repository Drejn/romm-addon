FROM rommapp/romm:latest

RUN apk add curl jq openssl
COPY run.sh /run.sh
RUN chmod +x /run.sh

CMD ["/run.sh"]
