# 🚀 Evolution API + MinIO S3: Auto-Instalador Inteligente

Este script Bash automatiza o processo de instalação e atualização da **Evolution API**, permitindo a configuração opcional do **MinIO (S3)** para armazenamento de ficheiros. Foi desenhado para ser seguro tanto em servidores "puros" quanto em ambientes gerenciados por painéis (Plesk, CloudPanel, etc.).

## ✨ Funcionalidades

* **Instalação Híbrida:** Deteta se já existe uma instalação e realiza a atualização das imagens sem apagar dados.
* **Token Único:** Gera automaticamente uma `AUTHENTICATION_API_KEY` segura e exclusiva na primeira instalação.
* **MinIO (S3) Opcional:** Configura o armazenamento S3 com subdomínio e console administrativo próprios.
* **Preservação de Dados:** Utiliza volumes Docker para garantir que bases de dados e instâncias não sejam perdidas.
* **Segurança de Proxy:** Não interfere com o Nginx nativo do servidor, evitando conflitos com painéis de controlo.

---

## 🛠️ Pré-requisitos

1.  **DNS Configurado:**
    * `api.oseudominio.com` -> IP do Servidor
    * `s3.oseudominio.com` -> IP do Servidor (se optar pelo MinIO)
2.  **Ambiente:** Servidor Ubuntu/Debian com Docker e Docker Compose instalados.

---

## 🚀 Como Utilizar

Ligue-se ao seu servidor via SSH e execute os seguintes comandos:

```bash
git clone https://github.com/launcherandco/evolution-api.git
chmod +x evolution.sh
./evolution.sh
