FROM alpine:3.10
LABEL Maintainer="hanguang <hanguang@pyyx.com>" \
    Description="适用于友友项目的docker容器"

# install packages
RUN apk --no-cache add \
    nginx \
    supervisor \
    curl \
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