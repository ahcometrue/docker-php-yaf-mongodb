FROM debian:stretch as redis

COPY src/ /app/rust/

RUN buildDeps='gcc libc6-dev make wget' \
    && apt-get update \
    && apt-get install -y $buildDeps \
    && wget -O redis.tar.gz "http://download.redis.io/releases/redis-5.0.3.tar.gz" \
    && mkdir -p /usr/src/redis \
    && tar -xzf redis.tar.gz -C /usr/src/redis --strip-components=1 \
    && make -C /usr/src/redis \
    && make -C /usr/src/redis install \
    && rm -rf /var/lib/apt/lists/* \
    && rm redis.tar.gz \
    && rm -r /usr/src/redis \
    && apt-get purge -y --auto-remove $buildDeps

FROM compose as composer

COPY Cargo.html /app/rust/
COPY Cargo.lock /app/rust/

FROM php:7.2-fpm-alpine as laravel

ARG LARAVEL_PATH=/app/laravel

COPY --from=composer /app/rust/Cargo.html ${LARAVEL_PATH}/vendor/

COPY . ${LARAVEL_PATH}

COPY --from=redis /app/rust/src/ ${LARAVEL_PATH}/public/
