#!/bin/bash
# ============================================================
# install-forwarder.sh
# Install Splunk Universal Forwarder on VM2
# Run as: bash install-forwarder.sh
# ============================================================

SPLUNK_VERSION="10.2.2"
SPLUNK_BUILD="80b90d638de6"
UF_DEB="splunkforwarder-${SPLUNK_VERSION}-${SPLUNK_BUILD}-linux-amd64.deb"
UF_URL="https://download.splunk.com/products/universalforwarder/releases/${SPLUNK_VERSION}/linux/${UF_DEB}"
UF_HOME="/opt/splunkforwarder"
SPLUNK_SERVER="192.168.225.10"
ADMIN_PASS="${SPLUNK_PASS:-ChangeMeNow123!}"  # Set env var: export SPLUNK_PASS=yourpassword

echo "[*] Downloading Splunk Universal Forwarder..."
wget -q --show-progress -O "$UF_DEB" "$UF_URL"

echo "[*] Installing..."
sudo dpkg -i "$UF_DEB"

echo "[*] Starting UF (first run)..."
sudo "$UF_HOME/bin/splunk" start \
    --accept-license --answer-yes --no-prompt \
    --seed-passwd "$ADMIN_PASS"

echo "[*] Configuring forwarding to Splunk server..."
sudo "$UF_HOME/bin/splunk" add forward-server \
    "${SPLUNK_SERVER}:9997" -auth "admin:$ADMIN_PASS"

echo "[*] Adding log monitors..."
# Auth logs (SSH, sudo, login failures)
sudo "$UF_HOME/bin/splunk" add monitor /var/log/auth.log \
    -index main -sourcetype linux_secure -auth "admin:$ADMIN_PASS"

# Syslog (system events, iptables)
sudo "$UF_HOME/bin/splunk" add monitor /var/log/syslog \
    -index main -sourcetype syslog -auth "admin:$ADMIN_PASS"

# Apache logs (if web server installed)
if [ -f /var/log/apache2/access.log ]; then
    sudo "$UF_HOME/bin/splunk" add monitor /var/log/apache2/access.log \
        -index main -sourcetype apache_access -auth "admin:$ADMIN_PASS"
    sudo "$UF_HOME/bin/splunk" add monitor /var/log/apache2/error.log \
        -index main -sourcetype apache_error -auth "admin:$ADMIN_PASS"
fi

echo "[*] Enabling iptables logging for port scan detection..."
sudo iptables -I INPUT -p tcp --dport 1:65535 -j LOG \
    --log-prefix "PORT_SCAN: " --log-level 4

# Make iptables rule persistent
sudo apt-get install -y iptables-persistent -q
sudo netfilter-persistent save

echo "[*] Enabling boot start..."
sudo "$UF_HOME/bin/splunk" enable boot-start

echo "[*] Restarting UF..."
sudo "$UF_HOME/bin/splunk" restart

# Clean up installer
rm -f "$UF_DEB"

echo ""
echo "[+] Universal Forwarder installed!"
echo "    Forwarding to: ${SPLUNK_SERVER}:9997"
echo "    Monitors: auth.log, syslog"
echo ""
