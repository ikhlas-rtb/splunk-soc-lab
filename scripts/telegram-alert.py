#!/usr/bin/env python3
"""
telegram-alert.py — Splunk Custom Alert Action
Sends a Telegram message when a Splunk alert fires.

Setup:
  1. Create a Telegram bot via @BotFather → get TOKEN
  2. Get your chat ID via @userinfobot → get CHAT_ID
  3. Edit TOKEN and CHAT_ID below
  4. Deploy: copy this file to /opt/splunk/etc/apps/telegram_alert/bin/
  5. chmod +x telegram-alert.py

Splunk calls this script with alert data via stdin (JSON).
"""

import sys
import json
import urllib.request
import urllib.parse
import os
from datetime import datetime

# ── CONFIG — Edit these ───────────────────────────────────────
TELEGRAM_TOKEN  = os.environ.get("8527223663:AAEYrjBH0oqDkORSThwCC_u-WwyXOXMUx0c", "")   # From @BotFather
TELEGRAM_CHAT_ID = os.environ.get("6868427670", "")    # From @userinfobot
# ─────────────────────────────────────────────────────────────

SPLUNK_WEB_URL  = "http://192.168.225.10:8000"


def send_telegram(message: str) -> bool:
    """Send a message via Telegram Bot API."""
    url = f"https://api.telegram.org/bot{TELEGRAM_TOKEN}/sendMessage"
    payload = {
        "chat_id": TELEGRAM_CHAT_ID,
        "text": message,
        "parse_mode": "Markdown"
    }
    data = urllib.parse.urlencode(payload).encode("utf-8")
    try:
        req = urllib.request.Request(url, data=data, method="POST")
        with urllib.request.urlopen(req, timeout=10) as resp:
            return resp.status == 200
    except Exception as e:
        print(f"[ERROR] Telegram send failed: {e}", file=sys.stderr)
        return False


def format_alert(alert_data: dict) -> str:
    """Format alert data into a readable Telegram message."""
    alert_name  = alert_data.get("search_name", "Unknown Alert")
    trigger_time = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    result_count = alert_data.get("result_count", "N/A")
    results      = alert_data.get("result", {})

    # Extract key fields if present
    src_ip   = results.get("src_ip", results.get("host", "N/A"))
    count    = results.get("count", result_count)
    user     = results.get("user", "N/A")

    # Map alert name to MITRE technique
    mitre_map = {
        "SSH Brute Force Detection":          "T1110.001",
        "Port Scan Detection":                "T1046",
        "Sudo Privilege Escalation Detection": "T1548.003",
        "New User Account Detection":         "T1136.001",
        "Unusual Outbound Traffic Detection": "T1041",
        "SYN Flood Detection":               "T1498.001",
    }
    mitre = mitre_map.get(alert_name, "T????")

    message = (
        f"🚨 *SPLUNK SOC ALERT*\n"
        f"{'─' * 30}\n"
        f"*Alert:* `{alert_name}`\n"
        f"*MITRE:* `{mitre}`\n"
        f"*Time:* `{trigger_time}`\n"
        f"*Source IP:* `{src_ip}`\n"
        f"*Count:* `{count}`\n"
        f"*User:* `{user}`\n"
        f"{'─' * 30}\n"
        f"[🔍 View in Splunk]({SPLUNK_WEB_URL})"
    )
    return message


def main():
    # Splunk passes alert data via stdin as JSON
    try:
        raw = sys.stdin.read()
        alert_data = json.loads(raw) if raw.strip() else {}
    except json.JSONDecodeError:
        alert_data = {}

    # Also accept command-line test mode
    if len(sys.argv) > 1 and sys.argv[1] == "--test":
        alert_data = {
            "search_name": "SSH Brute Force Detection",
            "result_count": 12,
            "result": {
                "src_ip": "192.168.225.30",
                "count": "12",
                "user": "root"
            }
        }
        print("[TEST MODE] Sending test alert...")

    message = format_alert(alert_data)
    print(f"[*] Sending alert to Telegram...")
    print(f"[*] Message:\n{message}")

    success = send_telegram(message)
    if success:
        print("[+] Alert sent successfully!")
        sys.exit(0)
    else:
        print("[-] Failed to send alert", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
