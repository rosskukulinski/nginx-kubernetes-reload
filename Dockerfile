FROM nginx:1.11-alpine
MAINTAINER Ross Kukulinski <ross@kukulinski.com>

ADD https://github.com/Yelp/dumb-init/releases/download/v1.2.0/dumb-init_1.2.0_amd64 /usr/local/bin/dumb-init
RUN chmod +x /usr/local/bin/dumb-init
ENTRYPOINT ["/usr/local/bin/dumb-init", "--"]

# install inotify
RUN apk update && apk add inotify-tools bash

COPY nginx-reload.sh /app/nginx-reload.sh
RUN chmod +x /app/nginx-reload.sh
COPY nginx.conf /etc/nginx/nginx.conf

EXPOSE 80 8080

ADD https://github.com/rosskukulinski/nginx-badbot-blocker/raw/master/VERSION_2/conf.d/blacklist.conf /etc/nginx-bots.d/blacklist.conf
ADD https://github.com/rosskukulinski/nginx-badbot-blocker/raw/master/VERSION_2/bots.d/whitelist-domains.conf /etc/nginx-bots.d/whitelist-domains.conf
ADD https://github.com/rosskukulinski/nginx-badbot-blocker/raw/master/VERSION_2/bots.d/whitelist-ips.conf /etc/nginx-bots.d/whitelist-ips.conf
ADD https://github.com/rosskukulinski/nginx-badbot-blocker/raw/master/VERSION_2/bots.d/blockbots.conf /etc/nginx-bots.d/blockbots.conf
ADD https://github.com/rosskukulinski/nginx-badbot-blocker/raw/master/VERSION_2/bots.d/ddos.conf /etc/nginx-bots.d/ddos.conf
CMD ["/app/nginx-reload.sh"]
