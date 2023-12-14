#!/bin/bash

# Step 1: Install Zabbix repository
sudo wget https://repo.zabbix.com/zabbix/6.3/ubuntu/pool/main/z/zabbix-release/zabbix-release_6.3-3%2Bubuntu22.04_all.deb
sudo dpkg -i zabbix-release_6.3-3+ubuntu22.04_all.deb
sudo apt update

# Step 2: Install Zabbix server and other components
sudo apt install -y zabbix-server-mysql zabbix-frontend-php zabbix-apache-conf zabbix-sql-scripts zabbix-agent 

# Step 3: Install MySQL server
sudo apt-get install -y mysql-server
sudo systemctl start mysql
sudo systemctl enable mysql

# Step 4: Create initial Zabbix database and user
sudo mysql -e "create database zabbix character set utf8mb4 collate utf8mb4_bin;"
sudo mysql -e "create user zabbix@localhost identified by 'zabbixPasword';"
sudo mysql -e "grant all privileges on zabbix.* to zabbix@localhost;"
sudo mysql -e "set global log_bin_trust_function_creators = 1;"



# Step 5: Import initial schema and data for Zabbix
echo "[client]" > /home/vagrant/.my.cnf
echo "user=zabbix" >> /home/vagrant/.my.cnf
echo "password=zabbixPassword" >> /home/vagrant/.my.cnf
chmod 600 /home/vagrant/.my.cnf


sudo zcat /usr/share/zabbix-sql-scripts/mysql/server.sql.gz | mysql --default-character-set=utf8mb4 -uzabbix -p'password' zabbix

# Step 6: Disable log_bin_trust_function_creators option
sudo mysql -e "set global log_bin_trust_function_creators = 0;"

# Step 7: Configure the database for Zabbix server
sudo sed -i 's/^# DBPassword=.*/DBPassword=zabbixPassword/' /etc/zabbix/zabbix_server.conf

# Step 8: Start Zabbix server and agent processes
sudo systemctl restart zabbix-server zabbix-agent apache2
sudo systemctl enable zabbix-server zabbix-agent apache2
