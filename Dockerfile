ARG PHP_VERSION=8.2
ARG COMPOSER_VERSION=2.5.4
ARG NGINX_VERSION=1.22
ARG MYSQL_VERSION=8.0.32
ARG ALPINE_VERSION=3.17

FROM composer:${COMPOSER_VERSION} AS composer

FROM php:${PHP_VERSION}-fpm-alpine${ALPINE_VERSION} AS threeci-php-fpm

# Install dependencies
RUN apk add --no-cache \
    sudo \
    zip \
    unzip \
    git \
    curl \
    bash \
    icu-dev \
    libzip-dev \
    libxml2-dev \
    oniguruma-dev \
    linux-headers \
  ;

# Install php extension
RUN docker-php-ext-configure intl \
    && docker-php-ext-install pdo pdo_mysql opcache zip xml mbstring intl \
    && docker-php-ext-enable intl

RUN apk add --no-cache --virtual .build-deps $PHPIZE_DEPS \
    && pecl install apcu xdebug \
    && docker-php-ext-enable apcu xdebug

# Update config php
COPY .docker/php/conf.d /usr/local/etc/php/conf.d/

# Install Symfony cli
RUN curl -1sLf 'https://dl.cloudsmith.io/public/symfony/stable/setup.alpine.sh' | sudo -E bash
RUN apk add symfony-cli

# Install composer
COPY --from=composer /usr/bin/composer /usr/bin/composer
ENV COMPOSER_ALLOW_SUPERUSER=1
RUN set -eux; \
    composer clear-cache

WORKDIR /var/www/html

CMD ["php-fpm"]

FROM nginx:${NGINX_VERSION}-alpine${ALPINE_VERSION} AS threeci-nginx

# Config nginx
COPY .docker/nginx/conf.d /etc/nginx/conf.d/

FROM mysql:${MYSQL_VERSION}-debian AS threeci-mysql