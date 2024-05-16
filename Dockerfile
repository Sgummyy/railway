# Usa una base image con PHP e Node.js preinstallati
FROM node:14 as build

# Installa PHP e altre dipendenze necessarie
RUN apt-get update && \
    apt-get install -y \
    php \
    php-cli \
    php-mbstring \
    php-xml \
    php-zip \
    unzip \
    git \
    curl

# Installa Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Usa Yarn fornito da Node.js
RUN yarn --version

# Imposta la directory di lavoro
WORKDIR /app

# Copia i file del progetto
COPY . .

# Esegui le installazioni e le build
RUN composer install \
    && yarn \
    && yarn prod \
    && php artisan optimize \
    && php artisan config:cache \
    && php artisan route:cache \
    && php artisan view:cache \

# Usa una base image per PHP e Apache per il runtime
FROM php:7.4-apache

# Copia i file dal build stage
COPY --from=build /app /var/www/html

# Imposta i permessi corretti
RUN chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache

# Abilita mod_rewrite per Laravel
RUN a2enmod rewrite

# Esponi la porta 80
EXPOSE 80

# Comando di avvio per Apache
CMD ["apache2-foreground"]