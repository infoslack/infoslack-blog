FROM alpine:latest
RUN apk upgrade --no-cache --available \
      && apk add --no-cache \
      ca-certificates \
      openssl \
      && rm -rf /var/cache/apk/*

ADD _site /blog
ADD /data/srv /srv
ADD /data/ansible /blog/ansible
ADD /data/docker  /blog/docker
ADD /data/metasploit /blog/metasploit
ADD /data/rubyconf2015 /blog/rubyconf2015
ADD /data/workshops /blog/workshops
COPY /data/caddy /usr/sbin/caddy
COPY /data/Caddyfile /etc/Caddyfile
