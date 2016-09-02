FROM alpine:3.4
MAINTAINER Wonderfall <wonderfall@mondedie.fr>
MAINTAINER Hardware <contact@meshup.net>

ARG GPG_rainloop="3B79 7ECE 694F 3B7B 70F3  11A4 ED7C 49D9 87DA 4591"

ENV GID=991 UID=991

RUN echo "@commuedge https://nl.alpinelinux.org/alpine/edge/community" >> /etc/apk/repositories \
 && apk -U add \
    gnupg \
    nginx \
    supervisor \
    tini@commuedge \
    php7-fpm@commuedge \
    php7-curl@commuedge \
    php7-iconv@commuedge \
    php7-xml@commuedge \
    php7-dom@commuedge \
    php7-openssl@commuedge \
    php7-json@commuedge \
    php7-zlib@commuedge \
    php7-pdo_mysql@commuedge \
    php7-pdo_sqlite@commuedge \
    php7-sqlite3@commuedge \
 && cd /tmp \
 && wget -q http://repository.rainloop.net/v2/webmail/rainloop-community-latest.zip \
 && wget -q http://repository.rainloop.net/v2/webmail/rainloop-community-latest.zip.asc \
 && wget -q http://repository.rainloop.net/RainLoop.asc \
 && echo "Verifying authenticity of rainloop-community-latest.zip using GPG..." \
 && gpg --import RainLoop.asc \
 && FINGERPRINT="$(LANG=C gpg --verify rainloop-community-latest.zip.asc rainloop-community-latest.zip 2>&1 \
  | sed -n "s#Primary key fingerprint: \(.*\)#\1#p")" \
 && if [ -z "${FINGERPRINT}" ]; then echo "Warning! Invalid GPG signature!" && exit 1; fi \
 && if [ "${FINGERPRINT}" != "${GPG_rainloop}" ]; then echo "Warning! Wrong GPG fingerprint!" && exit 1; fi \
 && echo "All seems good, now unzipping rainloop-community-latest.zip..." \
 && mkdir /rainloop && unzip -q /tmp/rainloop-community-latest.zip -d /rainloop \
 && find /rainloop -type d -exec chmod 755 {} \; \
 && find /rainloop -type f -exec chmod 644 {} \; \
 && apk del gnupg \
 && rm -rf /tmp/* /var/cache/apk/* /root/.gnupg

COPY nginx.conf /etc/nginx/nginx.conf
COPY php-fpm.conf /etc/php7/php-fpm.conf
COPY supervisord.conf /etc/supervisor/supervisord.conf
COPY startup /usr/local/bin/startup

RUN chmod +x /usr/local/bin/startup

VOLUME /rainloop/data
EXPOSE 80
CMD ["/sbin/tini","--","startup"]
