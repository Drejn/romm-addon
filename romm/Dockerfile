FROM rommapp/romm:latest
RUN apk add --no-cache curl jq openssl
COPY 99-custom.conf /etc/nginx/conf.d/99-custom.conf
COPY run.sh /run.sh
RUN chmod +x /run.sh
EXPOSE 8080
CMD ["/run.sh"]
