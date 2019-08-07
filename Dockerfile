FROM alpine:3.10 as base
LABEL Maintainer="ahcometrue <1091109811@qq.com>" \
    Description="Lightweight container with Nginx 1.16 & PHP-FPM 7.2 & Yaf & MongoDB based on Alpine Linux. "

# trust this project public key to trust the packages.
ADD https://repos.php.earth/alpine/phpearth.rsa.pub /etc/apk/keys/phpearth.rsa.pub

# install packages
RUN echo "https://repos.php.earth/alpine/v3.9" >> /etc/apk/repositories \
    && apk --no-cache add \
    ca-certificates \
    nginx \
    supervisor \
    curl \
    openssl \
    openssl-dev \
    php7.2 \
    php7.2-fpm \
    php7.2-pdo \
    php7.2-pdo_mysql \
    php7.2-json \
    php7.2-openssl \
    php7.2-curl \
    php7.2-zlib \
    php7.2-phar \
    php7.2-intl \
    php7.2-dom \
    php7.2-xmlreader \
    php7.2-ctype \
    php7.2-session \
    php7.2-mbstring \
    php7.2-gd \
    php7.2-redis \
    php7.2-bcmath \
    php7.2-bz2 \
    php7.2-exif \
    php7.2-fileinfo \
    php7.2-iconv \
    php7.2-mbstring \
    php7.2-simplexml \
    php7.2-sockets \
    php7.2-tokenizer \
    php7.2-xmlwriter \
    php7.2-pecl-apcu \
    php7.2-opcache \
    php7.2-soap \
    php7.2-zip \
    && apk add --no-cache --repository http://dl-cdn.alpinelinux.org/alpine/edge/testing --allow-untrusted \
    php7.2-xhprof


# use apk evn install packages
ENV PHPIZE_DEPS autoconf file g++ gcc libc-dev make pkgconf re2c php7-dev php7-pear yaml-dev

RUN set -xe \
    && apk add --no-cache --repository "http://dl-cdn.alpinelinux.org/alpine/edge/testing" \
    --virtual .phpize-deps \
    $PHPIZE_DEPS \
    && sed -i 's/^exec $PHP -C -n/exec $PHP -C/g' $(which pecl) \
    && pecl channel-update pecl.php.net \
    && pecl install yaf \
    && echo "extension=yaf.so" > /etc/php7/conf.d/01_yaf.ini \
    && pecl install mongodb \
    && echo "extension=mongodb.so" > /etc/php7/conf.d/01_mongodb.ini \ 
    && rm -rf /usr/share/php7 \
    && rm -rf /tmp/* \
    && apk del .phpize-deps

# Configure nginx
COPY env_config/nginx.conf /etc/nginx/nginx.conf

# Configure PHP-FPM
COPY env_config/fpm-pool.conf /etc/php7/php-fpm.d/www.conf
COPY env_config/php.ini /etc/php7/conf.d/zzz_custom.ini

# Configure supervisord
COPY env_config/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Make sure files/folders needed by the processes are accessable when they run under the nobody user
RUN chown -R nobody.nobody /run && \
    chown -R nobody.nobody /var/lib/nginx && \
    chown -R nobody.nobody /var/tmp/nginx && \
    chown -R nobody.nobody /var/log/nginx

# Setup document root
RUN mkdir -p /var/www/html

# Make the document root a volume
VOLUME /var/www/html

# Switch to use a non-root user from here on
USER nobody

# Add application
WORKDIR /var/www/html
COPY --chown=nobody test_src/ /var/www/html/

# Expose the port nginx is reachable on
EXPOSE 8080

# Let supervisord start nginx & php-fpm
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]

# Configure a healthcheck to validate that everything is up&running
HEALTHCHECK --timeout=10s CMD curl --silent --fail http://127.0.0.1:8080/fpm-ping

# build test env images
FROM youyou/base as test