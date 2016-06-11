FROM alpine:latest
RUN apk upgrade --no-cache --available \
      && apk add --no-cache \
      ca-certificates \
      openssl \
      && rm -rf /var/cache/apk/*

ADD _site /blog
