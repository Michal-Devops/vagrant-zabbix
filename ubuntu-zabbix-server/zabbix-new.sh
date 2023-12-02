#!/bin/bash

# Aktualizacja systemu
sudo apt update
sudo apt upgrade -y

# Instalacja PostgreSQL
sudo apt install -y postgresql postgresql-contrib

# Uruchomienie i włączenie PostgreSQL
sudo systemctl start postgresql
sudo systemctl enable postgresql

# Tworzenie użytkownika i bazy danych dla Zabbix
sudo -u postgres psql -c "CREATE USER zabbix WITH PASSWORD 'password';"
sudo -u postgres psql -c "CREATE DATABASE zabbix OWNER zabbix;"

# Instalacja repozytorium Zabbix
wget https://repo.zabbix.com/zabbix/6.4/ubuntu/pool/main/z/zabbix-release/zabbix-release_6.4-1+ubuntu20.04_all.deb
dpkg -i zabbix-release_6.4-1+ubuntu20.04_all.deb
sudo apt update

# Instalacja serwera Zabbix, frontendu, agenta
sudo apt install -y zabbix-server-pgsql zabbix-frontend-php php7.4-pgsql zabbix-nginx-conf zabbix-sql-scripts zabbix-agent

# Import schematu i danych początkowych do bazy danych Zabbix
sudo zcat /usr/share/doc/zabbix-sql-scripts/postgresql/server.sql.gz | sudo -u zabbix psql zabbix

# Konfiguracja Zabbix server
sudo sed -i 's/# DBPassword=/DBPassword=twoje_hasło/' /etc/zabbix/zabbix_server.conf
sudo sed -i "s/# DBHost=localhost/DBHost=localhost/" /etc/zabbix/zabbix_server.conf

# Konfiguracja PHP dla frontendu Zabbix
sudo sed -i 's/# listen 80;/listen 8080;/' /etc/zabbix/nginx.conf
sudo sed -i 's/# server_name example.com;/server_name zabbixvm;/' /etc/zabbix/nginx.conf

# Uruchomienie serwera Zabbix i agenta
sudo systemctl restart zabbix-server zabbix-agent nginx php7.4-fpm
sudo systemctl enable zabbix-server zabbix-agent nginx php7.4-fpm
