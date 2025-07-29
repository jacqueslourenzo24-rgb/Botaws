# Usa uma imagem base oficial da AWS para PHP no Lambda (versão 8.2).
FROM public.ecr.aws/docker/library/php:8.2-fpm

# Define o diretório de trabalho dentro do contêiner para o diretório de tarefa do Lambda.
# Usamos /var/task, que é o diretório padrão para o código do Lambda.
WORKDIR /var/task

# Copia todos os arquivos do seu projeto para o diretório de trabalho do contêiner.
COPY . /var/task

# Instala as extensões PHP necessárias para cURL, mbstring, e zip.
# As extensões PHP geralmente são instaladas com 'docker-php-ext-install' nessas imagens.
# Certifique-se de que curl e mbstring estão disponíveis. zip é necessário para a extensão zip.
RUN docker-php-ext-install curl mbstring zip

# Instala o Composer (se ainda não estiver na imagem) e as dependências
# Usamos apt-get para instalar 'unzip' e 'git', pois a imagem é baseada em Debian.
RUN apt-get update && apt-get install -y \
    unzip \
    git \
    && rm -rf /var/lib/apt/lists/* # Limpa o cache para reduzir o tamanho da imagem
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Instala as dependências do Composer.
# Use --no-dev para não instalar dependências de desenvolvimento em produção.
RUN composer install --no-dev --optimize-autoloader

# Garante que o PHP-FPM escute no endereço 9000, que é a porta padrão que o Lambda espera.
# O arquivo de configuração pode variar, este é um exemplo comum.
COPY php-fpm.conf /etc/php/8.2/fpm/pool.d/www.conf
# O Lambda espera que o handler esteja em app.php ou similar no diretório raiz
# Renomeamos webhook.php para app.php para compatibilidade com o runtime PHP do Lambda
RUN mv /var/task/webhook.php /var/task/app.php

# CMD é o comando que será executado quando o contêiner iniciar.
# O Lambda com imagens de contêiner para PHP espera o runtime do Bref ou uma aplicação FastCGI.
# Usamos o comando que inicia o PHP-FPM, que o Lambda invocará.
# Para o runtime de imagens de container do Lambda, o 'CMD' é o ponto de entrada da função.
# Para este cenário, o Lambda RIE (Runtime Interface Emulator) se conecta ao FPM.
CMD ["php-fpm"]
