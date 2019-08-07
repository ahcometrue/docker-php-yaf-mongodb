FROM alpine:3.10 as base
LABEL Maintainer="ahcometrue <1091109811@qq.com>" \
    Description="Lightweight container with Nginx 1.16 & PHP-FPM 7.2 & Yaf & MongoDB based on Alpine Linux. "

# install packages
RUN echo  > /etc/apk/repositories \
    && echo "http://dl-cdn.alpinelinux.org/alpine/v3.9/main" >> /etc/apk/repositories \
    && echo "http://dl-cdn.alpinelinux.org/alpine/v3.9/community" >> /etc/apk/repositories \
    && apk --no-cache add \
    nginx \
    supervisor \
    curl \
    openssl \
    openssl-dev \
    php7 \
    php7-fpm \
    php7-pdo \
    php7-pdo_mysql \
    php7-json \
    php7-openssl \
    php7-curl \
    php7-zlib \
    php7-phar \
    php7-intl \
    php7-dom \
    php7-xmlreader \
    php7-ctype \
    php7-session \
    php7-mbstring \
    php7-gd \
    php7-redis \
    php7-bcmath \
    php7-bz2 \
    php7-exif \
    php7-fileinfo \
    php7-iconv \
    php7-mbstring \
    php7-simplexml \
    php7-sockets \
    php7-tokenizer \
    php7-xmlwriter \
    php7-pecl-apcu \
    php7-opcache \
    php7-soap \
    php7-zip \
    && apk add --no-cache --repository http://dl-cdn.alpinelinux.org/alpine/edge/testing --allow-untrusted \
    php7-xhprof

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