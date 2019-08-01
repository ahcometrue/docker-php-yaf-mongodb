FROM centos:latest as centos

COPY src/ /app/rust/

FROM compose as composer

COPY Cargo.html /app/rust/
COPY Cargo.lock /app/rust/


FROM php:7.2-fpm-alpine as laravel

ARG LARAVEL_PATH=/app/laravel

COPY --from=composer /app/rust/Cargo.html ${LARAVEL_PATH}/vendor/

COPY . ${LARAVEL_PATH}

COPY --from=centos /app/rust/src/ ${LARAVEL_PATH}/public/
