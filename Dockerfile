# Usar uma imagem base de PHP com o Lambda Runtime Interface Client (RIC)
# aws/aws-lambda-php-runtime:8.2 é uma imagem oficial da AWS para PHP no Lambda.
FROM public.ecr.aws/lambda/php:8.2

# Define o diretório de trabalho dentro do contêiner
WORKDIR ${LAMBDA_TASK_ROOT}

# Copia todos os arquivos do seu projeto para o diretório de trabalho do contêiner
# O LAMBDA_TASK_ROOT é o diretório onde o Lambda espera seu código.
COPY . ${LAMBDA_TASK_ROOT}

# Instala o Composer (se ainda não estiver na imagem) e as dependências
# A imagem da AWS já deve ter o Composer, mas é bom garantir as libs.
RUN yum install -y unzip git # 'yum' é o gerenciador de pacotes no ambiente AWS Linux
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Instala as dependências do Composer.
RUN composer install --no-dev --optimize-autoloader

# O CMD é o comando que o Lambda executa.
# Ele inicia o runtime para PHP e aponta para o seu webhook.php como handler.
# Note: O Lambda funciona com "handlers". Seu webhook.php precisa retornar a resposta HTTP.
CMD [ "webhook.php" ]
