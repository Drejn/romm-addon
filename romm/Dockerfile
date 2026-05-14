FROM rommapp/romm:latest
RUN apk add --no-cache curl jq openssl nginx
RUN mkdir -p /var/lib/romm && ln -sfn /share/romm/library /var/lib/romm/library
COPY nginx.conf.template /nginx.conf.template
COPY run.sh /run.sh
COPY app /app
COPY run.sh /run.sh
RUN chmod +x /run.sh
EXPOSE 8080
CMD ["/run.sh"]
