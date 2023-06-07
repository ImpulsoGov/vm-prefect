#!/usr/bin/bash

# exportar variáveis
set -o allexport
env | grep PREFECT - | unset -
. "$PWD/.env"
set +o allexport

# Remove instalações antigas
systemctl stop prefect-agent.service prefect-server.service
systemctl disable prefect-agent.service prefect-server.service
lsof -t -i :4200 | xargs kill -9
rm -r /home/prefect/*

# atualiza repositórios e pacotes
apt update -yqq && apt upgrade -yqq


# instala dependências
apt install -yqq --reinstall python3-apt apt-transport-https
apt install -yqq python3-venv wget ufw nginx apache2-utils bzip2 rsync \
    openssl uidmap build-essential libssl-dev libffi-dev certbot \
    python3-certbot-nginx libffi-dev software-properties-common fail2ban \
    ca-certificates curl gnupg lsb-release dbus-user-session apache2-utils
wget https://bootstrap.pypa.io/get-pip.py
python3 get-pip.py
rm ./get-pip.py
pip3 install --force-reinstall "pyopenssl==23.0.0" "cryptography==39.0.1"


# configurar usuário com privilégios administrativos
user_exists=$(getent passwd prefect)
if [ -z "$user_exists" ] 
then
  adduser --disabled-password prefect
fi
echo "prefect:${PREFECT_SENHA_SISTEMA}" | chpasswd 
usermod -aG sudo prefect


# instala e configura docker
apt-get remove docker docker-engine docker.io containerd runc
mkdir -p /etc/apt/keyrings
chmod 0755 /etc/apt/keyrings
# ATENCAO!: cheque a chave correta para a distribuição em questão em
# https://docs.docker.com/get-docker/
curl -fsSL https://download.docker.com/linux/debian/gpg \
  | gpg --batch --yes --dearmor -o /etc/apt/keyrings/docker.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
  $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
chmod a+r /etc/apt/keyrings/docker.gpg
apt-get update -yqq
apt-get install -y docker-ce docker-ce-cli containerd.io \
  docker-buildx-plugin docker-compose-plugin
groupadd docker &
usermod -aG docker prefect
docker context use default
systemctl enable docker.service
systemctl enable containerd.service
systemctl start docker.service
systemctl start containerd.service


# configurar acesso via SSH
ufw allow OpenSSH
rsync --archive --chown=prefect:prefect ~/.ssh /home/prefect


# mover arquivos
cp .env /home/prefect/.env
cp docker-prune.service /etc/systemd/system/
cp docker-prune.timer /etc/systemd/system/
cp prefect-agent.service /etc/systemd/system/prefect-agent.service
cp prefect-server.service /etc/systemd/system/prefect-server.service
cp agent-start.sh /home/prefect/agent-start.sh
cp server-start.sh /home/prefect/server-start.sh
chmod +x /home/prefect/agent-start.sh
chmod +x /home/prefect/server-start.sh
chown prefect:prefect /home/prefect/agent-start.sh
chown prefect:prefect /home/prefect/server-start.sh
chown prefect:prefect /home/prefect/.env


# instalar prefect
install_prefect() {
  cd /home/prefect/ || exit;
  python3 -m venv .venv;
  . /home/prefect/.venv/bin/activate;
  /home/prefect/.venv/bin/pip install prefect;
  deactivate;
}
echo "Inicializando ambiente virtual e instalando prefect..."
su -u prefect -c "$(typeset -f install_prefect); install_prefect"
echo "Ambiente virtual com prefect instalado com sucesso!"
envsubst < profiles.toml.template > /home/prefect/.prefect/profiles.toml
chown prefect:prefect /home/prefect/*


# configurar nginx e certificados SSL
mkdir ./backups && mkdir ./backups/nginx \
  && mkdir ./backups/nginx/sites-available
mv /etc/nginx/sites-available/* ./backups/nginx/sites-available/
envsubst '$PREFECT_DOMINIO' < nginx.conf.template > /etc/nginx/nginx.conf
ufw allow http
ufw allow https
ufw allow 'Nginx Full'
nginx -s reload

htpasswd \
  -b -c /etc/apache2/.htpasswd "$PREFECT_API_USUARIO" "$PREFECT_API_SENHA"
certbot -n --nginx -d "$PREFECT_DOMINIO" -m "$PREFECT_ADM_EMAIL" \
  --redirect --agree-tos
certbot install --cert-name "$PREFECT_DOMINIO"
nginx -s reload
systemctl reload nginx


# habilitar serviços
systemctl daemon-reload
systemctl enable docker-prune.timer
systemctl enable prefect-server.service
systemctl enable prefect-agent.service
systemctl start docker-prune.timer
systemctl start prefect-server.service
systemctl start prefect-agent.service
ufw --force enable


# informar a conclusão do script
echo "Rotina de configuração finalizada com sucesso!"
exit 0
