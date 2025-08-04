# Use a imagem oficial do PHP 8.2 com FPM
FROM php:8.2-fpm

# Instale dependências do sistema necessárias
RUN apt-get update && apt-get install -y git zip unzip \
    && docker-php-ext-install pdo pdo_mysql

# Instale o Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Defina o diretório de trabalho
WORKDIR /app

# Copie os arquivos de código
COPY . /app

# Instale as dependências do Composer
RUN composer install --no-dev --optimize-autoloader

# Configure o PHP-FPM para a porta 8080 (padrão do Cloud Run)
COPY php-fpm.conf /usr/local/etc/php-fpm.d/zz-docker.conf

# Exponha a porta do FPM
EXPOSE 8080

# Inicie o FPM
CMD ["php-fpm", "-F", "--allow-to-run-as-root"]
