#!/bin/bash

# Cores para feedback
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# 1. Verificação de Ambiente (Painéis)
if [ -d "/etc/cloudpanel" ] || [ -d "/usr/local/psa" ]; then
    echo -e "${YELLOW}Detectado painel de controle (CloudPanel/Plesk).${NC}"
    echo -e "O script não configurará o Nginx automaticamente para evitar conflitos."
    HAS_PANEL=true
else
    HAS_PANEL=false
fi

# 2. Coleta de Informações (Valores Escolhidos)
read -p "Link da API (ex: api.dominio.com): " evolution
echo ""
read -p "Deseja instalar/atualizar o MinIO? (s/n): " install_minio

if [ "$install_minio" == "s" ]; then
  read -p "Subdomínio para o Console MinIO (ex: s3.dominio.com): " minio_domain
  read -p "Usuário MinIO (admin): " minio_user
  minio_user=${minio_user:-admin}
  read -p "Senha MinIO (mín. 8 caracteres): " minio_password
  echo ""
fi

# 3. Gestão de Pastas e Atualização
if [ -d "evolution-api" ]; then
    echo -e "${YELLOW}Atualizando instalação existente...${NC}"
    cd evolution-api
    # Backup preventivo do .env
    cp .env .env.bak
else
    echo -e "${GREEN}Nova instalação...${NC}"
    git clone https://github.com/EvolutionAPI/evolution-api.git
    cd evolution-api
    # Gerar API KEY inicial apenas se for novo
    echo "AUTHENTICATION_API_KEY=$(openssl rand -hex 16)" > .env
fi

# 4. Definição de Portas (Faremos fixas para facilitar o mapeamento no painel)
# Você pode alterar essas portas se já estiverem em uso
api_port=8080
pg_port=5433
redis_port=6380
minio_port=9000
minio_console_port=9001

# 5. Configuração do .env (Adição/Update do MinIO)
if [ "$install_minio" == "s" ]; then
    # Remove configurações de S3 anteriores para evitar duplicidade
    sed -i '/S3_/d' .env
    cat >> .env << EOL
S3_ENABLED=true
S3_ACCESS_KEY=$minio_user
S3_SECRET_KEY=$minio_password
S3_BUCKET=evolution
S3_PORT=$minio_port
S3_ENDPOINT=evolution_minio
S3_REGION=us-east-1
S3_USE_SSL=false
EOL
fi

# 6. Docker Compose (Mantendo volumes para não perder dados)
cat > docker-compose.yml << EOL
version: '3.8'
services:
  api:
    container_name: evolution_api
    image: evoapicloud/evolution-api:latest
    restart: always
    ports: ["$api_port:$api_port"]
    networks: [evolution-net]
    env_file: [.env]
    depends_on: [evolution_postgres, evolution_redis]

  evolution_postgres:
    container_name: evolution_postgres
    image: postgres:16
    restart: always
    environment:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: p8KkRN1EKeCbrou6
      POSTGRES_DB: evolution_db
    ports: ["$pg_port:5432"]
    volumes: [pg_data:/var/lib/postgresql/data]
    networks: [evolution-net]

  evolution_redis:
    container_name: evolution_redis
    image: redis:alpine
    restart: always
    ports: ["$redis_port:6379"]
    networks: [evolution-net]
EOL

if [ "$install_minio" == "s" ]; then
  cat >> docker-compose.yml << EOL
  evolution_minio:
    container_name: evolution_minio
    image: minio/minio
    restart: always
    ports: ["$minio_port:9000", "$minio_console_port:9001"]
    environment:
      MINIO_ROOT_USER: $minio_user
      MINIO_ROOT_PASSWORD: $minio_password
    volumes: [minio_data:/data]
    networks: [evolution-net]
    command: server /data --console-address ":9001"
EOL
fi

echo "networks: { evolution-net: { driver: bridge } }
volumes: { pg_data: {}, minio_data: {} }" >> docker-compose.yml

# 7. Start
docker-compose pull
docker-compose up -d

# 8. Instruções Finais (O "Pulo do Gato")
echo -e "\n${GREEN}==================================================${NC}"
echo -e "${GREEN} INSTALAÇÃO/ATUALIZAÇÃO CONCLUÍDA! ${NC}"
echo -e "${GREEN}==================================================${NC}"

if [ "$HAS_PANEL" = true ]; then
    echo -e "${YELLOW}COMO VOCÊ USA PAINEL (PLESK/CLOUD_PANEL):${NC}"
    echo -e "1. Crie os sites/subdomínios: $evolution e $minio_domain no seu painel."
    echo -e "2. No Reverse Proxy (ou Vhost), aponte:"
    echo -e "   - $evolution -> http://127.0.0.1:$api_port"
    echo -e "   - $minio_domain -> http://127.0.0.1:$minio_console_port"
    echo -e "3. Habilite o SSL (Let's Encrypt) diretamente pelo seu painel."
else
    echo -e "${YELLOW}DICA: Como você não tem painel, use o Nginx nativo para expor as portas.$NC"
    echo -e "A API está rodando internamente na porta $api_port"
fi

if [ "$install_minio" == "s" ]; then
    echo -e "\n${GREEN}DADOS DO MINIO:${NC}"
    echo -e "User: $minio_user"
    echo -e "Pass: $minio_password"
    echo -e "Acesse via: http://IP_DO_SERVIDOR:$minio_console_port (ou via Proxy se configurado)"
fi