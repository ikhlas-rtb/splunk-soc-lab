#!/bin/bash
# ============================================================
# install-splunk.sh
# Install and configure Splunk Enterprise on VM1
# Run as: bash install-splunk.sh
# ============================================================

SPLUNK_VERSION="10.2.2"
SPLUNK_BUILD="80b90d638de6"
SPLUNK_DEB="splunk-${SPLUNK_VERSION}-${SPLUNK_BUILD}-linux-amd64.deb"
SPLUNK_URL="https://download.splunk.com/products/splunk/releases/${SPLUNK_VERSION}/linux/${SPLUNK_DEB}"
SPLUNK_HOME="/opt/splunk"
ADMIN_PASS="${SPLUNK_PASS:-ChangeMeNow123!}"  # Set env var: export SPLUNK_PASS=yourpassword

echo "[*] Extending LVM if needed..."
FREE=$(sudo vgdisplay 2>/dev/null | grep "Free" | awk '{print $5}')
if [ ! -z "$FREE" ] && [ "$FREE" -gt 0 ]; then
    sudo lvextend -l +100%FREE /dev/mapper/ubuntu--vg-ubuntu--lv 2>/dev/null
    sudo resize2fs /dev/mapper/ubuntu--vg-ubuntu--lv 2>/dev/null
fi

echo "[*] Downloading Splunk $SPLUNK_VERSION..."
wget -q --show-progress -O "$SPLUNK_DEB" "$SPLUNK_URL"

echo "[*] Installing..."
sudo dpkg -i "$SPLUNK_DEB"

echo "[*] Setting permissions..."
sudo chown -R splunk:splunk "$SPLUNK_HOME"

echo "[*] Starting Splunk (first run)..."
sudo -u splunk "$SPLUNK_HOME/bin/splunk" start \
    --accept-license --answer-yes --no-prompt \
    --seed-passwd "$ADMIN_PASS"

echo "[*] Lowering disk space threshold for lab..."
echo -e "\n[diskUsage]\nminFreeSpace = 2000" | \
    sudo -u splunk tee -a "$SPLUNK_HOME/etc/system/local/server.conf"

echo "[*] Enabling receiver on port 9997..."
sudo -u splunk "$SPLUNK_HOME/bin/splunk" enable listen 9997 \
    -auth "admin:$ADMIN_PASS"

echo "[*] Enabling boot start..."
sudo -u splunk "$SPLUNK_HOME/bin/splunk" enable boot-start -user splunk

echo "[*] Configuring UFW..."
sudo ufw allow 8000/tcp   # Splunk Web
sudo ufw allow 9997/tcp   # Forwarder input
sudo ufw allow 22/tcp     # SSH

echo "[*] Restarting Splunk..."
sudo -u splunk "$SPLUNK_HOME/bin/splunk" restart

# Clean up installer
rm -f "$SPLUNK_DEB"

echo ""
echo "[+] Splunk installed!"
echo "    Web UI:  http://192.168.225.10:8000"
echo "    Login:   admin / $ADMIN_PASS"
echo ""
