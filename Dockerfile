FROM centos:latest as centos

COPY src/ /app/rust/



FROM php:7.2-fpm as laravel

ARG LARAVEL_PATH=/app/laravel

COPY . ${LARAVEL_PATH}

COPY --from=centos /app/rust/src/ ${LARAVEL_PATH}/public/
