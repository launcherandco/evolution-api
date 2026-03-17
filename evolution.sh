#!/bin/bash

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}Iniciando Instalador Evolution API (Atualizado para Docker v2)...${NC}"

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

api_port=8090
pg_port=5433
redis_port=6380
minio_port=9000
minio_console_port=9001

if [ -f ".env" ]; then
    echo -e "${YELLOW}-> Atualizando ambiente...${NC}"
    UNIQUE_TOKEN=$(grep AUTHENTICATION_API_KEY .env | cut -d'=' -f2)
else
    echo -e "${GREEN}-> Configuração limpa...${NC}"
    UNIQUE_TOKEN=$(openssl rand -hex 16 | tr '[:lower:]' '[:upper:]')
fi

# ==========================================
# 1. GERAÇÃO DO .ENV
# ==========================================
cat > .env << EOL
SERVER_TYPE=http
SERVER_PORT=$api_port
SERVER_URL=https://$evolution
AUTHENTICATION_API_KEY=$UNIQUE_TOKEN
AUTHENTICATION_EXPOSE_IN_FETCH_INSTANCES=true
LANGUAGE=pt-BR
LOG_LEVEL=ERROR,WARN,DEBUG,INFO,LOG,VERBOSE,DARK,WEBHOOKS
LOG_COLOR=true
LOG_BAILEYS=error

# Conexões padronizadas com hífen
DATABASE_PROVIDER=postgresql
DATABASE_CONNECTION_URI=postgresql://postgres:p8KkRN1EKeCbrou6@evolution-postgres:5432/evolution_db?schema=public
DATABASE_CONNECTION_CLIENT_NAME=evolution-exchange
DATABASE_SAVE_DATA_INSTANCE=true
DATABASE_SAVE_DATA_NEW_MESSAGE=true
DATABASE_SAVE_MESSAGE_UPDATE=true
DATABASE_SAVE_DATA_CONTACTS=true
DATABASE_SAVE_DATA_CHATS=true
DATABASE_SAVE_DATA_LABELS=true
DATABASE_SAVE_DATA_HISTORIC=true

CACHE_REDIS_ENABLED=true
CACHE_REDIS_URI=redis://evolution-redis:6379/2
CACHE_REDIS_PREFIX_KEY=evolution
CACHE_REDIS_SAVE_INSTANCES=false
CACHE_LOCAL_ENABLED=false

WEBHOOK_GLOBAL_ENABLED=true
WEBHOOK_GLOBAL_URL=''
WEBHOOK_GLOBAL_WEBHOOK_BY_EVENTS=true
WEBSOCKET_ENABLED=true
WEBSOCKET_GLOBAL_EVENTS=true
QRCODE_LIMIT=9999
QRCODE_COLOR='#175197'
DEL_INSTANCE=false
CONFIG_SESSION_PHONE_CLIENT=Evolution API
CONFIG_SESSION_PHONE_NAME=Chrome
EOL

if [ "$install_minio" == "s" ]; then
    cat >> .env << EOL

S3_ENABLED=true
S3_ACCESS_KEY=$minio_user
S3_SECRET_KEY=$minio_password
S3_BUCKET=evolution
S3_PORT=$minio_port
S3_ENDPOINT=evolution-minio
S3_REGION=us-east-1
S3_USE_SSL=false
S3_USE_PATH_STYLE=true
EOL
fi

# ==========================================
# 2. GERAÇÃO DO DOCKER-COMPOSE.YML
# ==========================================
cat > docker-compose.yml << EOL

services:
  evolution-api:
    container_name: evolution-api
    image: evoapicloud/evolution-api:latest
    restart: always
    ports:
      - "$api_port:$api_port"
    volumes:
      - evolution-instances:/evolution/instances
    networks:
      - evolution-net
    env_file:
      - .env
    depends_on:
      evolution-postgres:
        condition: service_healthy
      evolution-redis:
        condition: service_started

  evolution-postgres:
    container_name: evolution-postgres
    image: postgres:16
    restart: always
    environment:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: p8KkRN1EKeCbrou6
      POSTGRES_DB: evolution_db
    ports:
      - "$pg_port:5432"
    volumes:
      - pg-data:/var/lib/postgresql/data
    networks:
      - evolution-net
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 5s
      timeout: 5s
      retries: 5

  evolution-redis:
    container_name: evolution-redis
    image: redis:alpine
    restart: always
    ports:
      - "$redis_port:6379"
    networks:
      - evolution-net
EOL

if [ "$install_minio" == "s" ]; then
  cat >> docker-compose.yml << EOL

  evolution-minio:
    container_name: evolution-minio
    image: minio/minio
    restart: always
    ports:
      - "$minio_port:9000"
      - "$minio_console_port:9001"
    environment:
      MINIO_ROOT_USER: $minio_user
      MINIO_ROOT_PASSWORD: $minio_password
    volumes:
      - minio-data:/data
    networks:
      - evolution-net
    command: server /data --console-address ":9001"
EOL
fi

cat >> docker-compose.yml << EOL

networks:
  evolution-net:
    driver: bridge
    name: evolution-net

volumes:
  evolution-instances:
  pg-data:
EOL

if [ "$install_minio" == "s" ]; then
  echo "  minio-data:" >> docker-compose.yml
fi

# ==========================================
# 3. EXECUÇÃO
# ==========================================
docker compose pull
docker compose up -d

# Criação do Bucket corrigida (agora com hífen)
if [ "$install_minio" == "s" ]; then
    echo "Aguardando MinIO iniciar para criar o bucket..."
    sleep 10
    docker run --rm --network evolution-net \
      --entrypoint /bin/sh minio/mc -c "
      mc alias set local http://evolution-minio:9000 $minio_user $minio_password;
      mc mb local/evolution || true;
      mc anonymous set public local/evolution;
    "
    echo -e "${GREEN}Bucket 'evolution' configurado e público!${NC}"
fi

echo -e "\n${GREEN}==================================================${NC}"
echo -e "TOKEN ÚNICO: ${YELLOW}$UNIQUE_TOKEN${NC}"
echo -e "API: https://$evolution"
[ "$install_minio" == "s" ] && echo -e "MinIO: https://$minio_domain"
echo -e "${GREEN}==================================================${NC}"