FROM alpine:3.13 as api
LABEL Maintainer="Anit Shrestha <shrsthprios@gmail.com>" \
  Description="Lightweight container with Nginx 1.18 & PHP-FPM 8 based on Alpine Linux."

# Install packages and remove default server definition
RUN apk --no-cache add php8=8.0.2-r0 php8-fpm php8-opcache php8-mysqli php8-json \
  php8-openssl php8-curl php8-soap php8-zlib php8-xml php8-phar php8-intl php8-dom php8-xmlreader php8-tokenizer php8-ctype php8-session php8-simplexml \
  php8-mbstring php8-gd nginx supervisor curl php8-exif php8-zip php8-fileinfo php8-iconv php8-soap tzdata htop \
  php8-pecl-imagick php8-pecl-redis && \
  rm /etc/nginx/conf.d/default.conf

# Symling php8 => php
RUN ln -s /usr/bin/php8 /usr/bin/php

# Install PHP tools
RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar && chmod +x wp-cli.phar && mv wp-cli.phar /usr/local/bin/wp

# install composer
RUN php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" && php composer-setup.php --install-dir=/usr/local/bin --filename=composer

# Configure nginx
COPY .docker/nginx.conf /etc/nginx/nginx.conf

# Configure PHP-FPM
COPY .docker/fpm-pool.conf /etc/php8/php-fpm.d/www.conf
COPY .docker/php.ini /etc/php8/conf.d/custom.ini

# Configure supervisord
COPY .docker/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

ARG WORKDIR=/laravel
# Setup document root
RUN mkdir -p $WORKDIR

# Make sure files/folders needed by the processes are accessable when they run under the nobody user
RUN chown -R nobody.nobody $WORKDIR && \
  chown -R nobody.nobody /run && \
  chown -R nobody.nobody /var/lib/nginx && \
  chown -R nobody.nobody /var/log/nginx

# Switch to use a non-root user from here on
USER nobody

# Add application
WORKDIR $WORKDIR

#RUN chmod -R gu+w /var/www/html/storage
#
#RUN chmod -R guo+w /var/www/html/storage
#
#RUN chown -R nobody.nobody /var/www/html/storage && \
#    chown -R nobody.nobody /var/www/html/storage/framework/sessions && \
#    chown -R nobody.nobody /var/www/html/bootstrap/cache
#
#RUN chmod -R 777 /var/www/html/storage/logs
#USER nobody

# Expose the port nginx is reachable on
EXPOSE 8080

# Let supervisord start nginx & php-fpm
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]

# Configure a healthcheck to validate that everything is up&running
HEALTHCHECK --timeout=10s CMD curl --silent --fail http://127.0.0.1:8080/fpm-ping

