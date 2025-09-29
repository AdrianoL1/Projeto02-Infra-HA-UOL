#!/bin/bash

# Variáveis de conexão com o RDS e EFS
RDS_HOST="USAR_SEU_RDS"
RDS_PORT=3306
DB_NAME="USAR_SEU_BANCO_DE_DADOS"
DB_USER="USAR_SEU_USUARIO"
DB_PASSWORD="USAR_SUA_SENHA"
EFS_ID="USAR_SEU_EFS_ID"
EFS_DIR="/mnt/wordpress"

# Atualizar pacotes
sudo yum update -y

# Instalar o Docker e dependências da Amazon
sudo yum install -y docker amazon-efs-utils

# Iniciar o Docker
sudo systemctl enable docker
sudo systemctl start docker

# Instalar o Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" \
    -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Criar diretório do EFS e montar com TLS
sudo mkdir -p ${EFS_DIR}
sudo mount -t efs -o tls ${EFS_ID}:/ ${EFS_DIR}

# Criar arquivo docker-compose.yml
cat > /home/ec2-user/docker-compose.yml <<EOF
version: '3.8'
services:
  wordpress:
    image: wordpress:latest
    container_name: wordpress
    restart: always
    ports:
      - "80:80"
    environment:
      WORDPRESS_DB_HOST: ${RDS_HOST}:${RDS_PORT}
      WORDPRESS_DB_NAME: ${DB_NAME}
      WORDPRESS_DB_USER: ${DB_USER}
      WORDPRESS_DB_PASSWORD: ${DB_PASSWORD}
    volumes:
      - ${EFS_DIR}:/var/www/html
EOF

cd /home/ec2-user
sudo docker-compose up -d
