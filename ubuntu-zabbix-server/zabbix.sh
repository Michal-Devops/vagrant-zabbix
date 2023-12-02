#!/bin/bash

# Instalacja repozytorium Zabbix
wget https://repo.zabbix.com/zabbix/6.4/ubuntu/pool/main/z/zabbix-release/zabbix-release_6.4-1+ubuntu20.04_all.deb
dpkg -i zabbix-release_6.4-1+ubuntu20.04_all.deb
apt update

# Instalacja serwera Zabbix, frontendu, agenta
apt install -y zabbix-server-pgsql zabbix-frontend-php php7.4-pgsql zabbix-nginx-conf zabbix-sql-scripts zabbix-agent

# Konfiguracja bazy danych Postgres
sudo -u postgres createuser --pwprompt zabbix
sudo -u postgres createdb -O zabbix zabbix

# Import schematu i danych początkowych
zcat /usr/share/zabbix-sql-scripts/postgresql/server.sql.gz | sudo -u zabbix psql zabbix

# Konfiguracja Zabbix server
sed -i 's/# DBPassword=/DBPassword=password/' /etc/zabbix/zabbix_server.conf

# Konfiguracja PHP dla frontendu Zabbix
sed -i 's/# listen 80;/listen 8080;/' /etc/zabbix/nginx.conf
sed -i 's/# server_name example.com;/server_name zabbixvm;/' /etc/zabbix/nginx.conf

# Uruchomienie serwera Zabbix i agenta
systemctl restart zabbix-server zabbix-agent nginx php7.4-fpm
systemctl enable zabbix-server zabbix-agent nginx php7.4-fpm
