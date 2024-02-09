FROM php:8.1-apache-bullseye AS php-base

# Dependencies
RUN apt-get update -y && apt-get install -y tzdata cron ssh libpng-dev libjpeg-dev zlib1g-dev libzip-dev git unzip subversion ca-certificates libicu-dev libxml2-dev libmcrypt-dev && apt-get autoremove -y && apt-get clean && rm -rf /var/lib/apt/lists/

# Install IMAGICK
#RUN apt-get update -y && apt-get install -y libmagickwand-dev --no-install-recommends && rm -rf /var/lib/apt/lists/*
#RUN mkdir -p /usr/src/php/ext/imagick; \
#    curl -fsSL https://github.com/Imagick/imagick/archive/06116aa24b76edaf6b1693198f79e6c295eda8a9.tar.gz | tar xvz -C "/usr/src/php/ext/imagick" --strip 1; \
#    docker-php-ext-install imagick;

# PHP Extensions - docker-php-ext-install
RUN docker-php-ext-install zip mysqli calendar

# PHP Extensions - docker-php-ext-install
# RUN docker-php-ext-install exif pdo pdo_mysql opcache intl soap

# PHP Extensions - docker-php-ext-configure
RUN docker-php-ext-configure intl

# PHP Extensions - docker-php-ext-configure
RUN docker-php-ext-configure gd --with-jpeg && docker-php-ext-install -j$(nproc) gd

# PHP Extensions - PECL
# RUN pecl install mcrypt && docker-php-ext-enable mcrypt

# Config
RUN a2enmod rewrite

RUN cp /usr/share/zoneinfo/Europe/Rome /etc/localtime && \
    echo "Europe/Rome" > /etc/timezone

RUN rm -rf /var/cache/apk/*

# Copy cron file to the cron.d directory
COPY cron /etc/cron.d/cron

# Give execution rights on the cron job
RUN chmod 0644 /etc/cron.d/cron

# Apply cron job
RUN crontab /etc/cron.d/cron

# Create the log file to be able to run tail
RUN mkdir -p /var/log/cron

FROM php-base AS php

# Override default config with custom PHP settings
ENV PHP_INI_DIR /usr/local/etc/php
COPY docker-config/* $PHP_INI_DIR/conf.d/
COPY php.ini $PHP_INI_DIR/

# Add a command to base-image entrypont scritp
RUN sed -i 's/^exec /service cron start\n\nexec /' /usr/local/bin/apache2-foreground
