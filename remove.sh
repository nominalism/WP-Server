#!/bin/bash

# Parar e Desabilitar os Serviços
sudo systemctl stop httpd
sudo systemctl disable httpd

sudo systemctl stop mariadb
sudo systemctl disable mariadb

# Remover os Pacotes Instalados
sudo pacman -Rns --noconfirm apache php php-apache mariadb mariadb-clients wget unzip

# Remover Arquivos de Configuração
sudo rm -rf /etc/httpd
sudo rm -rf /var/lib/mysql
sudo rm -rf /etc/mysql
sudo rm -rf /srv/http/wordpress


echo "Removido"

