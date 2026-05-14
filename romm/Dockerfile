FROM rommapp/romm:latest
RUN apk add --no-cache curl jq openssl
COPY nginx.conf /etc/nginx/nginx.conf
COPY run.sh /run.sh
RUN chmod +x /run.sh
EXPOSE 8080
CMD ["/run.sh"]
