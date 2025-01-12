FROM alpine:3.21

EXPOSE 749 88

RUN apk update && apk add \
    krb5-server

COPY start.sh /tmp
RUN chmod +x /tmp/start.sh
ENTRYPOINT ["/tmp/start.sh"]
