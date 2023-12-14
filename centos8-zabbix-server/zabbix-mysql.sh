#!/bin/bash

# Disable SELinux and modify SELinux configuration to permissive
sudo setenforce 0 && sudo sed -i 's/^SELINUX=.*/SELINUX=permissive/g' /etc/selinux/config

# Install Zabbix repository
sudo rpm -Uvh https://repo.zabbix.com/zabbix/5.0/rhel/8/x86_64/zabbix-release-5.0-1.e18.noarch.rpm

# Clean DNF cache
sudo dnf clean all

# Install Zabbix server, web front, Apache config and agent
sudo dnf -y install zabbix-server-mysql zabbix-web-mysql zabbix-apache-conf zabbix-agent

# Install MariaDB server and enable/start the service
sudo dnf -y install mariadb-server && sudo systemctl start mariadb && sudo systemctl enable mariadb

# Set root password for MariaDB
sudo mysqladmin -u root password 'ZabbixPass'

# Create Zabbix database and user, set initial configurations
sudo mysql -u root -p'ZabbixPass' -e "create database zabbix character set utf8 collate utf8_bin;"
sudo mysql -u root -p'ZabbixPass' -e "grant all privileges on zabbix.* to zabbix@localhost identified by 'ZabbixPass';"
sudo mysql -uroot -p'ZabbixPass' zabbix -e "set global innodb_strict_mode='OFF';"

# Import initial schema and data for Zabbix
sudo zcat /usr/share/doc/zabbix-server-mysql*/create.sql.gz | sudo mysql -uzabbix -p'ZabbixPass' zabbix

# Reset the innodb_strict_mode setting
sudo mysql -uroot -p'ZabbixPass' zabbix -e "set global innodb_strict_mode='ON';"

# Update Zabbix server configuration with new database password
sudo sed -i '/^;\?DBPassword=/s/^;//;s/=.*/=ZabbixPass/' /etc/zabbix/zabbix_server.conf

# Restart Zabbix server and agent services
sudo systemctl restart zabbix-server zabbix-agent

# Enable Zabbix server and agent services to start on boot
sudo systemctl enable zabbix-server zabbix-agent

# Configure firewall for HTTP, HTTPS, and Zabbix ports
sudo firewall-cmd --add-service={http,https} --permanent
sudo firewall-cmd --add-port={10051/tcp,10050/tcp} --permanent
sudo firewall-cmd --reload

# Update PHP configuration for Zabbix
sudo sed -i '/php_value\[date\.timezone\]/s/^;\?//;s/.*=php_value[date.timezone]=Europe/Warsaw=' /etc/php-fpm.d/zabbix.conf

# Restart Apache and PHP-FPM services
sudo systemctl restart httpd php-fpm

# Enable Apache and PHP-FPM services to start on boot
sudo systemctl enable httpd php-fpm

# Run mysql_secure_installation at the end for additional security
#sudo mysql_secure_installation
