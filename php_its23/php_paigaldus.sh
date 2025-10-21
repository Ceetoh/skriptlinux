#!/bin/bash

set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

PHP=$(dpkg-query -W -f='${Status}\n' php7.0 2>/dev/null | grep -c 'ok installed' || true)

have_pkg() { apt-cache show "$1" >/dev/null 2>&1; }
have_php70_repo() {
  have_pkg php7.0 && have_pkg libapache2-mod-php7.0 && have_pkg php7.0-mysql
}

add_repo_debian_sury() {
  apt-get update -y >/dev/null
  apt-get install -y apt-transport-https ca-certificates curl lsb-release gnupg >/dev/null
  curl -fsSL https://packages.sury.org/php/apt.gpg | gpg --dearmor -o /usr/share/keyrings/sury-php.gpg
  echo "deb [signed-by=/usr/share/keyrings/sury-php.gpg] https://packages.sury.org/php/ $(lsb_release -sc) main" \
    > /etc/apt/sources.list.d/php.list
  apt-get update -y >/dev/null
}

add_repo_ubuntu_ondrej() {
  apt-get update -y >/dev/null
  apt-get install -y software-properties-common >/dev/null
  add-apt-repository -y ppa:ondrej/php >/dev/null
  apt-get update -y >/dev/null
}

ensure_repo() {
  if have_php70_repo; then return 0; fi
  if grep -qi debian /etc/os-release; then
    add_repo_debian_sury
  elif grep -qi ubuntu /etc/os-release; then
    add_repo_ubuntu_ondrej
  fi
  have_php70_repo || return 1
}

if [ "$PHP" -eq 0 ]; then
  echo "Paigaldame php ja vajalikud lisad"

  if ! ensure_repo; then
    echo "VIGA: php7.0 paketid (php7.0, libapache2-mod-php7.0, php7.0-mysql) ei ole sinu varamutes."
    echo "Lisa kursuse juhendi repo ja käivita skript uuesti."
    exit 1
  fi

  apt-get install -y php7.0 libapache2-mod-php7.0 php7.0-mysql
  echo "php on paigaldatud"

elif [ "$PHP" -eq 1 ]; then
  echo "php on juba paigaldatud"
  which php || true
fi

if systemctl list-unit-files | grep -q '^apache2.service'; then
  a2enmod php7.0 >/dev/null 2>&1 || true
  if [ -f /etc/apache2/mods-enabled/dir.conf ]; then
    sed -i 's/DirectoryIndex .*/DirectoryIndex index.php index.html index.cgi index.pl index.xhtml index.htm/' \
      /etc/apache2/mods-enabled/dir.conf
  fi
  systemctl restart apache2
fi

which php || true
php -v | head -n 1 || true

if [ -d /var/www/html ]; then
  echo "<?php phpinfo(); ?>" > /var/www/html/info.php
fi

exit 0
