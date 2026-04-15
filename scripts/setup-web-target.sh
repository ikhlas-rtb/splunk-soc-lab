#!/bin/bash
# ============================================================
# setup-web-target.sh
# Install Apache + DVWA (vulnerable web app) on VM2
# Run on VM2 as: sudo bash setup-web-target.sh
# ============================================================

echo "[*] Installing Apache + PHP + MySQL..."
sudo apt-get update -q
sudo apt-get install -y apache2 php php-mysqli php-gd libapache2-mod-php \
    mysql-server mysql-client git curl

echo "[*] Starting services..."
sudo systemctl enable apache2 mysql
sudo systemctl start apache2 mysql

echo "[*] Installing DVWA (Damn Vulnerable Web Application)..."
cd /var/www/html
sudo git clone https://github.com/digininja/DVWA.git dvwa
sudo cp /var/www/html/dvwa/config/config.inc.php.dist \
        /var/www/html/dvwa/config/config.inc.php

echo "[*] Configuring MySQL for DVWA..."
sudo mysql -e "CREATE DATABASE IF NOT EXISTS dvwa;"
sudo mysql -e "CREATE USER IF NOT EXISTS 'dvwa'@'localhost' IDENTIFIED BY 'p@ssw0rd';"
sudo mysql -e "GRANT ALL ON dvwa.* TO 'dvwa'@'localhost';"
sudo mysql -e "FLUSH PRIVILEGES;"

# Update DVWA config
sudo sed -i "s/\$_DVWA\[ 'db_password' \] = 'p@ssw0rd';/\$_DVWA[ 'db_password' ] = 'p@ssw0rd';/" \
    /var/www/html/dvwa/config/config.inc.php

echo "[*] Setting permissions..."
sudo chown -R www-data:www-data /var/www/html/dvwa
sudo chmod -R 755 /var/www/html/dvwa

echo "[*] Enabling Apache modules..."
sudo a2enmod rewrite
sudo systemctl restart apache2

echo "[*] Opening firewall for HTTP..."
sudo ufw allow 80/tcp

echo ""
echo "[+] Web target ready!"
echo "    DVWA: http://192.168.225.20/dvwa"
echo "    Login: admin / password"
echo "    Setup: http://192.168.225.20/dvwa/setup.php (click 'Create/Reset Database')"
echo ""
echo "Now run from Kali:"
echo "  nikto -h http://192.168.225.20/dvwa"
echo "  sqlmap -u 'http://192.168.225.20/dvwa/vulnerabilities/sqli/?id=1&Submit=Submit' --cookie='PHPSESSID=xxx;security=low' --dbs"
echo ""
