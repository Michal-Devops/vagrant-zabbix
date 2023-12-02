#!/bin/bash

# Aktualizacja systemu
sudo apt update
sudo apt upgrade -y

# Instalacja MySQL
sudo apt install -y mysql-server mysql-client

# Uruchomienie i włączenie MySQL
sudo systemctl start mysql
sudo systemctl enable mysql

# Tworzenie użytkownika i bazy danych dla Zabbix
sudo mysql -e "CREATE USER 'zabbix'@'localhost' IDENTIFIED BY 'admin';"
sudo mysql -e "CREATE DATABASE zabbix CHARACTER SET utf8mb4 COLLATE utf8mb4_bin;"
sudo mysql -e "GRANT ALL PRIVILEGES ON zabbix.* TO 'zabbix'@'localhost';"
sudo mysql -e "FLUSH PRIVILEGES;"

# Instalacja repozytorium Zabbix
wget https://repo.zabbix.com/zabbix/6.4/ubuntu/pool/main/z/zabbix-release/zabbix-release_6.4-1+ubuntu20.04_all.deb
dpkg -i zabbix-release_6.4-1+ubuntu20.04_all.deb
sudo apt update

# Instalacja serwera Zabbix, frontendu, agenta
sudo apt install -y zabbix-server-mysql zabbix-frontend-php zabbix-nginx-conf zabbix-sql-scripts zabbix-agent

# Import schematu i danych początkowych do bazy danych Zabbix
#zcat /usr/share/doc/zabbix-sql-scripts/mysql/create.sql.gz | mysql -u zabbix -p zabbix
sudo zcat /usr/share/zabbix-sql-scripts/mysql/server.sql.gz | mysql --default-character-set=utf8mb4 -u zabbix -p admin
# Konfiguracja Zabbix server
sudo sed -i 's/# DBPassword=/DBPassword=twoje_hasło/' /etc/zabbix/zabbix_server.conf
sudo sed -i "s/# DBHost=localhost/DBHost=localhost/" /etc/zabbix/zabbix_server.conf
sudo sed -i "s/# DBName=zabbix/DBName=zabbix/" /etc/zabbix/zabbix_server.conf
sudo sed -i "s/# DBUser=zabbix/DBUser=zabbix/" /etc/zabbix/zabbix_server.conf

# Konfiguracja PHP dla frontendu Zabbix
sudo sed -i 's/# php_value date.timezone Europe/Riga/php_value date.timezone Europe/Warsaw/' /etc/zabbix/nginx.conf
sudo sed -i 's/# listen 80;/listen 8080;/' /etc/zabbix/nginx.conf
sudo sed -i 's/# server_name example.com;/server_name zabbixvm;/' /etc/zabbix/nginx.conf

# Konfiguracja Nginx dla Zabbix
sudo ln -s /etc/zabbix/nginx.conf /etc/nginx/sites-enabled/zabbix.conf
sudo nginx -t && sudo systemctl restart nginx

# Uruchomienie serwera Zabbix i agenta
sudo systemctl restart zabbix-server zabbix-agent php7.4-fpm
sudo systemctl enable zabbix-server zabbix-agent nginx php7.4-fpm

