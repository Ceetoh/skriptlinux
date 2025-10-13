#!/bin/bash
# Skript kontrollib apache2 olemasolu ja paigaldab vajadusel

if [ "$EUID" -ne 0 ]; then
    echo "Seda skripti peab käivitama root kasutajana!"
    exit 1
fi

APACHE2=$(dpkg-query -W -f='${Status}' apache2 2>/dev/null | grep -c 'ok installed')

if [ $APACHE2 -eq 0 ]; then
    echo "Paigaldame apache2..."
    apt update
    apt install -y apache2
    echo "Apache on paigaldatud."
    systemctl start apache2
    systemctl status apache2
elif [ $APACHE2 -eq 1 ]; then
    echo "apache2 on juba paigaldatud."
    systemctl start apache2
    systemctl status apache2
fi
