FROM php:8.2-apache

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    curl \
    libpng-dev \
    libonig-dev \
    libxml2-dev \
    libzip-dev \
    zip \
    unzip \
    nodejs \
    npm

# Clear cache
RUN apt-get clean && rm -rf /var/lib/apt/lists/*

# Install PHP extensions
RUN docker-php-ext-install pdo_mysql mbstring exif pcntl bcmath gd zip

# Get latest Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Enable Apache mod_rewrite
RUN a2enmod rewrite

# Set working directory
WORKDIR /var/www/html

# Copy existing application directory contents
COPY . /var/www/html

# Copy existing application directory permissions
COPY --chown=www-data:www-data . /var/www/html

# Fix npm cache permissions
RUN chown -R www-data:www-data /var/www/html
RUN mkdir -p /var/www/html/.npm && chown -R www-data:www-data /var/www/html/.npm

# Change current user to www
USER www-data

# Set npm cache directory
ENV NPM_CONFIG_CACHE=/var/www/html/.npm

# Install dependencies
RUN composer install --no-dev --optimize-autoloader
RUN npm install
RUN npm run build

# Generate Laravel application key
RUN cp .env.example .env && php artisan key:generate

# Change back to root
USER root

# Set permissions
RUN chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache
RUN chmod -R 775 /var/www/html/storage /var/www/html/bootstrap/cache

# Configure Apache
COPY docker/apache.conf /etc/apache2/sites-available/000-default.conf

# Create startup script that properly handles Railway's PORT
RUN echo '#!/bin/bash\n\
set -e\n\
PORT=${PORT:-80}\n\
echo "Starting Apache on port $PORT"\n\
sed -i "s/*:80/*:$PORT/g" /etc/apache2/sites-available/000-default.conf\n\
echo "Listen $PORT" > /etc/apache2/ports.conf\n\
# Wait for database and run migrations\n\
echo "Waiting for database..."\n\
sleep 10\n\
echo "Running database migrations..."\n\
php artisan migrate --force || echo "Migration failed, continuing..."\n\
echo "Optimizing Laravel..."\n\
php artisan config:cache\n\
php artisan route:cache\n\
php artisan view:cache\n\
exec apache2-foreground' > /usr/local/bin/start-apache.sh && \
    chmod +x /usr/local/bin/start-apache.sh

# Expose port 80 (Railway will map to $PORT)
EXPOSE 80

CMD ["/usr/local/bin/start-apache.sh"]