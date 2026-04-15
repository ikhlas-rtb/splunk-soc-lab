#!/bin/bash
# ============================================================
# setup-telegram-splunk.sh
# Deploy Telegram alert action into Splunk
# Run on VM1 (Splunk Server) as: sudo bash setup-telegram-splunk.sh
# ============================================================

SPLUNK_HOME="/opt/splunk"
APP_DIR="$SPLUNK_HOME/etc/apps/telegram_alert"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "[*] Creating Telegram alert app directory..."
sudo mkdir -p "$APP_DIR/bin"
sudo mkdir -p "$APP_DIR/default"
sudo mkdir -p "$APP_DIR/metadata"

echo "[*] Copying alert script..."
sudo cp "$SCRIPT_DIR/telegram-alert.py" "$APP_DIR/bin/"
sudo chmod +x "$APP_DIR/bin/telegram-alert.py"

echo "[*] Writing app.conf..."
sudo tee "$APP_DIR/default/app.conf" > /dev/null << 'EOF'
[launcher]
author=SOC Lab
description=Telegram Alert Action for Splunk SOC Lab
version=1.0

[ui]
is_visible=false
label=Telegram Alert
EOF

echo "[*] Writing alert_actions.conf..."
sudo tee "$APP_DIR/default/alert_actions.conf" > /dev/null << 'EOF'
[telegram_alert]
label = Send Telegram Alert
description = Send alert notification via Telegram Bot
icon_path = telegram.png
is_custom = 1
payload_format = json

# Script to execute when alert fires
filename = telegram-alert.py
EOF

echo "[*] Writing transforms.conf for custom action..."
sudo tee "$APP_DIR/default/transforms.conf" > /dev/null << 'EOF'
# No transforms needed for this app
EOF

echo "[*] Setting ownership..."
sudo chown -R splunk:splunk "$APP_DIR"

echo "[*] Restarting Splunk to load app..."
sudo -u splunk "$SPLUNK_HOME/bin/splunk" restart

echo ""
echo "[+] Telegram alert app deployed!"
echo ""
echo "NEXT STEPS:"
echo "  1. Edit scripts/telegram-alert.py"
echo "  2. Set TELEGRAM_TOKEN and TELEGRAM_CHAT_ID"
echo "  3. Test: python3 $APP_DIR/bin/telegram-alert.py --test"
echo "  4. In Splunk UI: Edit each alert → Add Action → Run Script → telegram-alert.py"
echo ""
