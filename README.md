# 🚀 Evolution API + MinIO S3: Auto-Instalador Inteligente

Este script Bash automatiza o processo de instalação e atualização da **Evolution API**, permitindo a configuração opcional do **MinIO (S3)** para armazenamento de ficheiros. Foi desenhado para ser seguro tanto em servidores limpos quanto em ambientes gerenciados por painéis (Plesk, CloudPanel, FastPanel, etc.).

## ✨ Funcionalidades

* **Instalação Híbrida:** Detecta se já existe uma instalação e realiza a atualização das imagens sem apagar seus dados.
* **Token Único:** Gera automaticamente uma `AUTHENTICATION_API_KEY` segura e exclusiva na primeira instalação.
* **MinIO (S3) Automatizado:** Configura o armazenamento S3, define credenciais e cria automaticamente o bucket público `evolution`.
* **Centralização no `.env`:** Todas as variáveis de ambiente (banco de dados, Redis, logs) são geradas em um `.env` completo, facilitando edições futuras.
* **Estabilidade e Healthchecks:** A API aguarda o PostgreSQL estar 100% pronto antes de tentar conectar, evitando erros no boot.
* **Segurança de Proxy:** Não interfere com o Nginx nativo do servidor, evitando conflitos com painéis de controle.

---

## 🛠️ Pré-requisitos

1.  **DNS Configurado:**
    * `api.seudominio.com` -> IP do Servidor
    * `s3.seudominio.com` -> IP do Servidor (se optar pelo MinIO)
2.  **Ambiente:** Servidor Ubuntu/Debian com Docker e Docker Compose instalados.

---

## 🚀 Como Utilizar

Ligue-se ao seu servidor via SSH e execute os seguintes comandos:

```bash
# 1. Clone o repositório
git clone https://github.com/launcherandco/evolution-api.git

# 2. Acesse a pasta
cd evolution-api

# 3. Dê permissão e execute o instalador
chmod +x evolution.sh
./evolution.sh
