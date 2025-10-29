#!/usr/bin/env bash

set -euo pipefail

MYSQL_ROOT_PASSWORD="qwerty"
MYCNF="/root/.my.cnf"
MYSQL_KEY_ID="467B942D3A79BD29"

log() { echo -e "\n\033[1;32m==> $*\033[0m"; }
warn() { echo -e "\033[1;33m[WARN]\033[0m $*"; }
err() { echo -e "\033[1;31m[ERR]\033[0m $*" >&2; }

require_root() {
  if [ "$EUID" -ne 0 ]; then
    err "Palun käivita see skript root kasutajana!"
    exit 1
  fi
}

require_root

log "Kontrollin, kas MySQL on juba paigaldatud..."
if dpkg-query -W -f='${Status}' mysql-server 2>/dev/null | grep -q "ok installed"; then
  echo "mysql-server on juba paigaldatud!"
  mysql --version
  exit 0
fi

log "Paigaldan vajalikud tööriistad ja võtmed..."
apt-get update -y
apt-get install -y gnupg wget lsb-release ca-certificates apt-transport-https

if ! apt-key list | grep -q "$MYSQL_KEY_ID"; then
  log "Lisame MySQL repo võtme..."
  apt-key adv --keyserver keyserver.ubuntu.com --recv-keys "$MYSQL_KEY_ID" || true
  apt-key adv --keyserver pgp.mit.edu --recv-keys "$MYSQL_KEY_ID" || true
fi

log "Laen alla MySQL APT konfiguratsioonifaili..."
wget https://dev.mysql.com/get/mysql-apt-config_0.8.36-1_all.deb -O /tmp/mysql-apt-config.deb

log "Paigaldan MySQL APT konfiguratsioonifaili..."
DEBIAN_FRONTEND=noninteractive dpkg -i /tmp/mysql-apt-config.deb || true
apt-get update -y

log "Paigaldan MySQL serveri ja vajalikud lisad..."
DEBIAN_FRONTEND=noninteractive apt-get install -y mysql-server mysql-client

log "Loon MySQL konfiguratsioonifaili root kasutajale..."
cat > "$MYCNF" <<EOF
[client]
host = localhost
user = root
password = $MYSQL_ROOT_PASSWORD
EOF

chmod 600 "$MYCNF"

log "Kontrollin MySQL ühendust..."
if mysql -e "SELECT VERSION();" &>/dev/null; then
  log "MySQL server töötab korrektselt!"
else
  err "MySQL ei tööta korralikult — kontrolli teenust käsuga: systemctl status mysql"
  exit 1
fi

log "Paigaldus edukas!"
echo "MySQL root parool: $MYSQL_ROOT_PASSWORD"
