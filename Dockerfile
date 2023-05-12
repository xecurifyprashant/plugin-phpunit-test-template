ARG PHP_IMAGE_TAG
FROM php:$PHP_IMAGE_TAG
ARG WORDPRESS_DB_PASSWORD
ENV WORDPRESS_DB_PASSWORD=$WORDPRESS_DB_PASSWORD
ARG WORDPRESS_VERSION
RUN echo "https://dl-cdn.alpinelinux.org/alpine/v3.9/main" >> /etc/apk/repositories &&\
    apk add --update --no-cache subversion mysql mysql-client git bash g++ make autoconf linux-headers && \
    set -ex; \
    docker-php-ext-install mysqli pdo pdo_mysql pcntl \
    && php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" \
    && php composer-setup.php --install-dir=/usr/bin --filename=composer \
    && docker-php-source extract \
    && pecl install xdebug-3.2.1 \
    && docker-php-ext-enable xdebug \
    && docker-php-source delete \
    && echo "xdebug.mode=debug" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
    && echo "xdebug.remote_autostart=off" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
    && echo "xdebug.client_port=9003" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
    && echo "xdebug.remote_handler=dbgp" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
    && echo "xdebug.discover_client_host=0" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
    && curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer \
    && rm -rf /tmp/* \
    && curl -L https://github.com/vishnubob/wait-for-it/raw/master/wait-for-it.sh > /tmp/wait-for-it.sh \
    && chmod +x /tmp/wait-for-it.sh
WORKDIR /tmp
COPY ./bin/install-wp-tests.sh /tmp/install-wp-tests.sh
RUN /tmp/install-wp-tests.sh wordpress_test root $WORDPRESS_DB_PASSWORD mysql $WORDPRESS_VERSION
COPY ./db-error.php /tmp/wordpress/wp-content/db-error.php
WORKDIR /wordpress
COPY composer.json /wordpress
RUN composer install
COPY . /wordpress
CMD /tmp/wait-for-it.sh mysql:3306 -- bin/install-db.sh wordpress_test root $WORDPRESS_DB_PASSWORD mysql
