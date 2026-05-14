FROM rommapp/romm:latest
RUN apk add --no-cache curl jq openssl
COPY patch_nginx.sh /tmp/patch_nginx.sh
RUN chmod +x /tmp/patch_nginx.sh
RUN /tmp/patch_nginx.sh
COPY run.sh /run.sh
RUN chmod +x /run.sh
EXPOSE 8080
CMD ["/run.sh"]
