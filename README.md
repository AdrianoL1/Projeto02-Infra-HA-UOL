
# Infraestrutura de Alta disponibilidade e escalabilidade com AWS e WordPress

**Objetivo:** Implementar a plataforma WordPress na nuvem AWS garantindo escalabilidade e alta disponibilidade.

## Diagrama da Infraestrutura

![Diagrama](https://github.com/user-attachments/assets/c3d45565-ffcb-45bf-a6b1-5ca7f1fb3ddf)

## Índice

1. [Criar VPC e Subnets](#1-criar-vpc-e-subnets)
2. [Configurar Grupos de Segurança](#2-configurar-grupos-de-segurança)
    - 2.1 [Grupo de Segurança do Application Load Balancer](#21-grupo-de-segurança-do-application-load-balancer)
    - 2.2 [Grupo de Segurança da EC2](#22-grupo-de-segurança-da-ec2)
    - 2.3 [Grupo de Segurança do Relational Database Service](#23-grupo-de-segurança-do-rds)
    - 2.4 [Grupo de Segurança do Elastic File System](#24-grupo-de-segurança-do-efs)
3. [Criar o Relational Database Service (RDS)](#3-criar-o-relational-database-service-rds)
4. [Criar Target Groups (TG)](#4-criar-target-groups-tg)
5. [Criar Application Load Balancer (ALB)](#5-criar-application-load-balancer-alb)
6. [Criar Elastic File System (EFS)](#6-criar-elastic-file-system-efs)
7. [Criar Auto Scaling Group (ASG)](#7-criar-auto-scaling-group-asg)
    - 7.1 [Launch Template](#71-launch-template)
    - 7.2 [Auto Scaling Group](#72-auto-scaling-group)
8. [Resultado]()

## 1. Criar VPC e Subnets:
- No console AWS, acesse o serviço VPC e clique em **Criar VPC**
- Em **Configurações da VPC** clique em **VPC e muito mais**
- Em **Geração automática da etiqueta de nome** escolha um nome para sua VPC
- Para os recursos, deixe:

| Recurso                           | Configuração               |
|-----------------------------------|----------------------------|
| Bloco CIDR IPv4                   | 10.0.0.0/16                |
| Bloco CIDR IPv6                   | Nenhum bloco CIDR IPv6     |
| Locação                           | Padrão                     |
| Zonas de Disponibilidade (AZs)    | 2                          |
| Sub-redes Públicas                | 2                          |
| Sub-redes Privadas                | 4                          |
| Gateways NAT                      | 1 por AZ                   |
| Endpoints da VPC                  | Nenhuma                    |
| Opções de DNS                     | Habilitar nomes de host DNS, Habilitar resolução de DNS |

- Clique em **Criar VPC**

![Preview](https://github.com/user-attachments/assets/899cc275-7ae0-49cf-9950-41c876060e82)

## 2. Configurar Grupos de Segurança

**Para separar cada serviço com suas regras específicas, criaremos 4 Grupos de Segurança para nossa aplicação**

- No console da VPC vá em **Segurança** > **Grupos de Segurança** e clique em **Criar grupo de segurança**.

### 2.1 Grupo de Segurança do Application Load Balancer

- Nome do grupo de segurança: SG-ALB
- Descrição: Permite acesso a ALB
- VPC: VPC criada no passo 1


**Regras de Entrada**

| Tipo | Protocolo | Intervalo de Portas | Origem        |
|------|-----------|---------------------|---------------|
| HTTP | TCP       | 80                   | Qualquer IPV4 

**Regras de Saída**


| Tipo           | Protocolo | Intervalo de Portas | Destino   |
|----------------|-----------|---------------------|-----------|
| Todo o Tráfego | Tudo      | Tudo                | 0.0.0.0/0 |


### 2.2 Grupo de Segurança da EC2

- Nome do grupo de segurança: SG-EC2
- Descrição: Permite acesso a EC2
- VPC: VPC criada no passo 1

**Regras de Entrada**

| Tipo | Protocolo | Intervalo de Portas | Origem        |
|------|-----------|---------------------|---------------|
| HTTP | TCP       | 80                   | SG-ALB 

**Regras de Saída**


| Tipo           | Protocolo | Intervalo de Portas | Destino   |
|----------------|-----------|---------------------|-----------|
| Todo o Tráfego | Tudo      | Tudo                | 0.0.0.0/0 |

### 2.3 Grupo de Segurança do RDS

- Nome do grupo de segurança: SG-RDS
- Descrição: Permite acesso ao RDS
- VPC: VPC criada no passo 1

**Regras de Entrada**

| Tipo         | Protocolo | Intervalo de Portas | Origem        |
|--------------|-----------|--------------------|---------------|
| MYSQL/Aurora | TCP       | 3306               | SG-EC2 

**Regras de Saída**


| Tipo           | Protocolo | Intervalo de Portas | Destino   |
|----------------|-----------|---------------------|-----------|
| Todo o Tráfego | Tudo      | Tudo                | 0.0.0.0/0 |

### 2.4 Grupo de Segurança do EFS

- Nome do grupo de segurança: SG-EFS
- Descrição: Permite acesso ao EFS
- VPC: VPC criada no passo 1

**Regras de Entrada**

| Tipo | Protocolo | Intervalo de Portas | Origem        |
|------|-----------|---------------------|---------------|
| NFS  | TCP       | 2049                | SG-RDS 

**Regras de Saída**

| Tipo           | Protocolo | Intervalo de Portas | Destino   |
|----------------|-----------|---------------------|-----------|
| Todo o Tráfego | Tudo      | Tudo                | 0.0.0.0/0 |

## 3. Criar o Relational Database Service (RDS)

- No console AWS, acesse o serviço **RDS** e clique em **Criar banco de dados**
- Selecione **Criação padrão** e em **Opções de mecanismo** selecione **MySQL**.
- Para **Modelos**, escolha **Nível gratuito**.
- Em **Identificador da instância de banco de dados** dê um nome ao Recurso do RDS
- Para **Configurações de credenciais** escolha um nome para o **Nome do usuário principal** e uma senha para **Senha principal**
- Em **Configuração da instância**, selecione **db.t3.micro**.
- Para **Conectividade** mude as seguintes opções:

    | Nuvem privada virtual (VPC)          | Grupo de segurança de VPC (firewall) |
    |--------------------------------------|--------------------------------------|
    | Selecione a VPC criada anteriormente | SG-RDS                               | 

- Em **Configuração adicional** > **Opções de banco de dados** > **Nome do banco de dados inicial** dê um nome ao seu Banco de Dados
- Por fim, clique em **Criar banco de dados**
> [!IMPORTANT]
> Guarde suas credenciais em algum lugar, pois elas serão utilizadas nos próximos passos.

## 4. Criar Target Groups (TG)
- No console AWS, acesse o serviço **EC2** > **Grupos de Destino** e clique em **Criar grupo de destino**.
- Para **Escolha um tipo de destino** selecione **Instâncias**
- Em **Nome do grupo de destino** dê um nome ao seu grupo.
- **VPC**: Escolha a VPC criada anteriormente.
- Em **Configurações avançadas de verificação de integridade** vá até **Códigos de sucesso** e mude para **200-399**
- Clique em **Próximo** e **Criar grupo de destino**.

## 5. Criar Application Load Balancer (ALB)
- No console AWS, acesse o serviço **EC2** > **Load balancers** e clique em **Criar load balancer**.
- Selecione **_Application Load Balancer_**
- Escolha um nome para o seu ALB.
- Em **Mapeamento de rede** > **VPC** selecione a VPC criada anteriormente.
- Em **Zonas de disponibilidade e sub-redes** selecione as **duas AZs** e atribua uma **sub-rede pública** para cada uma.
- Para **Grupos de segurança** selecione **SG-ALB**.
- Em **Listeners e roteamento** > **Ação de roteamento** deixe **Encaminhar aos grupos de destino**.
- Para **Grupo de destino** selecione o TG criado anteriormente.
- Clique em **Criar load balancer**

## 6. Criar Elastic File System (EFS)
- No console AWS, acesse o serviço **EFS** e clique em **Criar sistema de arquivos**.
- Clique em **Personalizar**.
- Dê um nome ao EFS e clique em **Próximo**.
- Em **Acesso à rede** selecione a VPC criada anteriormente.
- Para **Destinos de montagem** verifique se há um em cada uma das AZs selecionadas, em **ID da sub-rede** selecione uma sub-rede privada para cada um e em **Grupos de segurança** deixe apenas **SG-EFS**
- Avance para **Revisar e criar** e clique em **Criar**

## 7. Criar Auto Scaling Group (ASG)
### 7.1 Launch Template
- No console AWS, vá para **EC2** > **Instâncias** > **Modelos de execução** e clique em **Criar modelo de execução**.
- Crie o modelo com as seguintes configurações: 

| Nome do modelo de execução    | AMI          | Tipo de instância | Par de chaves (login)                  | Firewall (grupos de segurança) |
|-----|--------------|-------------------|----------------------------------------| ---------------------------------------- |
| WP-Template | Amazon Linux | t2.micro          | Crie um novo ou selecione um existente | SG-EC2 |

- Clique em **Detalhes avançados** e no campo **Dados do usuário (opcional)**, cole o seguinte script:

```
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

```
- Clique em **Criar modelo de inicialização**.

> [!IMPORTANT]
> Não esqueça de substituir os valores das variáveis com as suas credenciais.

### 7.2 Auto Scaling Group
- No console do EC2, vá até **Auto Scaling** > **Grupos do Auto Scaling** e clique em **Criar um grupo do Auto Scaling**.
- Em **Nome** dê um nome para o seu grupo.
- Para **Modelo de execução** selecione o modelo criado no passo anterior.
- Clique em **Próximo**
- Em **Rede** selecione a VPC criada anteriormente e **todas sub-redes privadas disponiveis**
- Clique em **Próximo**
- Anexe o **Balanceador de carga** e o **Grupo de destino** criados anteriormente.
- Clique em **Próximo**
- Em **Configurar tamanho do grupo e ajuste de escala** utilize as seguintes configurações:

 | Tamanho do grupo          |  |
 |--------------------------------------|--|
 | Capacidade desejada | 2 |


 | Escalabilidade           |                            |
 |--------------------------------------|----------------------------|
 | Capacidade mínima desejada | 1                          | 
 | Capacidade máxima desejada | 4                          | 
 | Tipo de métrica | Média de utilização da CPU |
 | Valor de destino | 70                         |
 | Aquecimento da instância | 300                        |

- Avance para **Análise** e clique em **Criar grupo de auto scaling**

## 8. Resultado
Após alguns minutos, o Auto Scaling Group lançará as instâncias, com toda configuração feita.

- Vá até **EC2** > **Load Balancers**.
- Selecione o ALB criado anteriormente e copie o **DNS**.
- Cole o DNS em seu navegador (adicione o http://).

Você verá a tela de configuração inicial do WordPress.

![Pagina inicial WP](https://github.com/user-attachments/assets/0d3ff3ea-0155-41e0-a2c3-8e33cb2eb1ec)

Caso queira, podemos instalar e testar o WordPress, basta seguir as intruções na tela.

![Teste WP](https://github.com/user-attachments/assets/d1f1e210-ade3-405d-aa69-f25a5a5498ba)