#!/bin/bash


sudo pacman -Syu --noconfirm

# php mariadb e o apache em si
sudo pacman -S --noconfirm apache php php-apache mariadb mariadb-clients wget unzip

# inicia o apache, cria as pastas necessárias e da permissão
sudo systemctl start httpd
sudo systemctl enable httpd
sudo mkdir -p /srv/http
sudo chown -R http:http /srv/http
sudo chmod -R 755 /srv/http

# configura o PHP para rodar no servidor
echo 'LoadModule php_module modules/libphp.so' | sudo tee -a /etc/httpd/conf/httpd.conf
echo 'AddHandler php-script php' | sudo tee -a /etc/httpd/conf/httpd.conf
echo 'Include conf/extra/php_module.conf' | sudo tee -a /etc/httpd/conf/httpd.conf
sudo sed -i 's/index.html/index.php index.html/' /etc/httpd/conf/httpd.conf

# Configura Apache MPM para não rodar mais de um modulo (aparentemente é o que vem por padrão quando é instalado)
sudo sed -i 's/^#LoadModule mpm_prefork_module/LoadModule mpm_prefork_module/' /etc/httpd/conf/httpd.conf
sudo sed -i 's/^LoadModule mpm_event_module/#LoadModule mpm_event_module/' /etc/httpd/conf/httpd.conf

# setta um host
echo 'ServerName 127.0.0.1' | sudo tee -a /etc/httpd/conf/httpd.conf

# habilita a extensão mysqli
if ! grep -q "^extension=mysqli" /etc/php/php.ini; then
    echo "extension=mysqli" | sudo tee -a /etc/php/php.ini
fi

# fecha e abre o httpd para recarregar as configurações
sudo systemctl restart httpd

# configuração padrão do mariadb
sudo mysql_install_db --user=mysql --basedir=/usr --datadir=/var/lib/mysql
sudo systemctl start mariadb
sudo systemctl enable mariadb

# instalação segura automatica
sudo mysql_secure_installation <<EOF

y
password
password
y
y
y
y
EOF

# cria um usuário e senha para o wordpress
sudo mysql -u root -ppassword <<EOF
CREATE DATABASE wordpress;
GRANT ALL PRIVILEGES ON wordpress.* TO 'wpuser'@'localhost' IDENTIFIED BY 'wppassword';
FLUSH PRIVILEGES;
EXIT;
EOF

# baixa o wordpress, descompacta e joga as configurações nos servidor
wget https://wordpress.org/latest.zip -P /tmp
unzip /tmp/latest.zip -d /tmp
sudo mv /tmp/wordpress /srv/http/wordpress
sudo chown -R http:http /srv/http/wordpress

sudo cp /srv/http/wordpress/wp-config-sample.php /srv/http/wordpress/wp-config.php
sudo sed -i "s/database_name_here/wordpress/" /srv/http/wordpress/wp-config.php
sudo sed -i "s/username_here/wpuser/" /srv/http/wordpress/wp-config.php
sudo sed -i "s/password_here/wppassword/" /srv/http/wordpress/wp-config.php

# da permissão para o servidor conseguir encontrar os arquivos
sudo chown -R http:http /srv/http/wordpress
sudo find /srv/http/wordpress/ -type d -exec chmod 750 {} \;
sudo find /srv/http/wordpress/ -type f -exec chmod 640 {} \;

# novamente o servidor é reiniciado para recarregar as configurações
sudo systemctl restart httpd

echo "acesse http://127.0.0.1/wordpress para verificar se a instalação foi feita com sucesso"
