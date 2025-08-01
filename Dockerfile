# Usa uma imagem base oficial da AWS para PHP no Lambda (versão 8.2).
FROM public.ecr.aws/docker/library/php:8.2-fpm

# Define o diretório de trabalho dentro do contêiner para o diretório de tarefa do Lambda.
# Usamos /var/task, que é o diretório padrão para o código do Lambda.
WORKDIR /var/task

# Copia todos os arquivos do seu projeto para o diretório de trabalho do contêiner.
COPY . /var/task

# Instala as dependências de sistema para as extensões PHP e para o Composer.
# É crucial instalar essas bibliotecas ANTES de tentar instalar as extensões PHP.
RUN apt-get update && apt-get install -y \
    unzip \
    git \
    libcurl4-openssl-dev \
    libzip-dev \
    libonig-dev \
    && rm -rf /var/lib/apt/lists/* # Limpa o cache para reduzir o tamanho da imagem

# Instala as extensões PHP necessárias.
# Agora, com as libs de desenvolvimento instaladas acima, este passo deve funcionar.
RUN docker-php-ext-install curl mbstring zip

# Instala o Composer (se ainda não estiver na imagem) e as dependências.
# A imagem da *** já deve ter o Composer, mas é bom garantir as libs e o próprio Composer.
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Instala as dependências do Composer.
# Use --no-dev para não instalar dependências de desenvolvimento em produção.
RUN composer install --no-dev --optimize-autoloader

# Garante que o PHP-FPM escute no endereço 9000, que é a porta padrão que o Lambda espera.
COPY php-fpm.conf /etc/php/8.2/fpm/pool.d/www.conf
# O Lambda espera que o handler esteja em app.php ou similar no diretório raiz
# Renomeamos webhook.php para app.php para compatibilidade com o runtime PHP do Lambda
RUN mv /var/task/webhook.php /var/task/app.php

# CMD é o comando que será executado quando o contêiner iniciar.
# Para o runtime de imagens de container do Lambda, o 'CMD' é o ponto de entrada da função.
CMD ["php-fpm"]
