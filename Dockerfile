FROM php:8.4-fpm-alpine
# with alpine 3.14 -> ERROR /bin/sh: Operation not permitted
# uRequired Args ( inherited from start of file, or passed at bild )
ARG BUILD_DATE
ARG VCS_REF
ARG XDEBUG_VERSION

# Maintainer label
LABEL Maintainer="Julien SIMONCINI <julien@ixys.dev>" \
      Description="Container PHP 8.4 FPM based on Alpine with default config."

# Set SHELL flags for RUN commands to allow -e and pipefail
# Rationale: https://github.com/hadolint/hadolint/wiki/DL4006
SHELL ["/bin/ash", "-eo", "pipefail", "-c"]

# ------------------------------------- Install Packages Needed Inside Base Image --------------------------------------
# Add doppler packages and
RUN wget -q -t3 'https://packages.doppler.com/public/cli/rsa.8004D9FF50437357.key' -O /etc/apk/keys/cli@doppler-8004D9FF50437357.rsa.pub && \
    apk --update-cache add ca-certificates && \
    echo 'https://packages.doppler.com/public/cli/alpine/any-version/main' | tee -a /etc/apk/repositories && \
    # Install dependencies \
    apk add --no-cache --update \
            build-base \
            doppler \
            wget \
            curl \
            autoconf \
            cyrus-sasl-dev \
            fcgi \
            g++ \
            git \
            grep \
            imagemagick-dev \
            imagemagick \
            libffi \
            libgd \
            libgmpxx \
            libgsasl-dev \
            libintl \
            libjpeg-turbo \
            libmcrypt-dev \
            libssh2 \
            libtool \
            libxml2-dev \
            libzip \
            make \
            nodejs \
            npm \
            pcre-dev \
            sudo \
            vim \
            yaml \
            zlib

# ---------------------------------------- Install / Enable PHP Extensions ---------------------------------------------
RUN set -eux; \
    apk add --no-cache --virtual .build-deps \
        $PHPIZE_DEPS \
        icu-dev \
        freetype-dev \
        libjpeg-turbo-dev \
        libpng-dev \
        libwebp-dev \
        libxpm-dev \
        libxml2-dev \
        libzip-dev \
        oniguruma-dev \
        openssl-dev \
        zlib-dev \
        linux-headers \
    ; \
    docker-php-ext-configure gd \
        --with-freetype \
        --with-jpeg \
        --with-webp \
        --with-xpm \
    ; \
    docker-php-ext-install -j"$(nproc)" \
        opcache gd intl mysqli pdo_mysql pcntl xml exif ctype zip \
    ; \
    pecl install redis; \
    docker-php-ext-enable redis; \
    runDeps="$( \
      scanelf --needed --nobanner --format '%n#p' --recursive /usr/local/lib/php/extensions \
        | tr ',' '\n' \
        | awk -F'#' '{print $2}' \
        | sort -u \
        | xargs -r apk info --installed \
        | sort -u \
    )"; \
    apk add --no-cache --virtual .php-ext-rundeps $runDeps; \
    apk del .build-deps; \
    rm -rf /var/cache/apk/*

RUN set -eux \
# Fix php.ini settings for enabled extensions
#    && chmod +x "$(php -r 'echo ini_get("extension_dir");')"/* \
# Shrink binaries
    && (find /usr/local/bin -type f -print0 | xargs -n1 -0 strip --strip-all -p 2>/dev/null || true) \
    && (find /usr/local/lib -type f -print0 | xargs -n1 -0 strip --strip-all -p 2>/dev/null || true) \
    && (find /usr/local/sbin -type f -print0 | xargs -n1 -0 strip --strip-all -p 2>/dev/null || true) \
    && true

# ------------------------------------------------- Permissions --------------------------------------------------------

# - Clean bundled docker/users & recreate them with UID 1000 for docker compatability in dev container.
# - Create composer directories (since we run as non-root later)
RUN deluser --remove-home www-data && \
    adduser -u1000 -D www-data && \
    rm -rf /var/www /usr/local/etc/php-fpm.d/* && \
    mkdir -p /app /var/www/.composer && \
    chown -R www-data:www-data /app /var/www/.composer

# ------------------------------------------------ PHP Configuration ---------------------------------------------------

# Add Default Config
RUN mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"

# Add in Base PHP Config
COPY config/base-*   $PHP_INI_DIR/conf.d/
# Copy PHP Production Configuration
COPY config/prod-*   $PHP_INI_DIR/conf.d/

# ---------------------------------------------- PHP FPM Configuration -------------------------------------------------

# PHP-FPM config
COPY config/fpm/*.conf  /usr/local/etc/php-fpm.d/

# --------------------------------------------------- Scripts ----------------------------------------------------------

COPY scripts/*-base          \
     scripts/*-prod          \
     scripts/healthcheck-*   \
     scripts/command-loop    \
     # to
     /usr/local/bin/

RUN  chmod +x /usr/local/bin/*-base /usr/local/bin/*-prod /usr/local/bin/healthcheck-* /usr/local/bin/command-loop

# ---------------------------------------------------- Composer --------------------------------------------------------

# Copy composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Copy phpunit
# TODO: use phpunit/phpunit:latest when it will be available
#COPY --from=phpunit/phpunit /usr/local/bin/phpunit /usr/bin/phpunit

# ----------------------------------------------------- MISC -----------------------------------------------------------

WORKDIR /app
USER www-data

# Validate FPM config (must use the non-root user)
RUN php-fpm -t

# Expose port 9000
EXPOSE 9000

# ---------------------------------------------------- HEALTH ----------------------------------------------------------

HEALTHCHECK CMD ["healthcheck-liveness"]

# -------------------------------------------------- ENTRYPOINT --------------------------------------------------------

ENTRYPOINT ["entrypoint-prod"]
CMD ["php-fpm"]
