FROM rommapp/romm:latest

RUN apk add --no-cache nginx curl jq openssl

COPY nginx.conf.template /nginx.conf.template
COPY run.sh /run.sh
COPY app /app

RUN chmod +x /run.sh

EXPOSE 
