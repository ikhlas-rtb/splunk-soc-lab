# ============================================================
# Splunk SOC Lab — Makefile
# Run this on VM1 (Splunk Server): 192.168.225.10
# Usage: make <target>
# ============================================================

SPLUNK_BIN     := /opt/splunk/bin/splunk
SPLUNK_USER    := splunk
SPLUNK_AUTH    := admin:$(SPLUNK_PASS)  # Set via: export SPLUNK_PASS=yourpassword
UF_HOST        := 192.168.225.20
KALI_HOST      := 192.168.225.30
SSH_USER       := rikhlas

.PHONY: help start stop restart status attack attack-ssh attack-scan attack-ddos attack-web clean logs

# ── Default target ───────────────────────────────────────────
help:
	@echo ""
	@echo "  Splunk SOC Lab — Available Commands"
	@echo "  ─────────────────────────────────────────────"
	@echo "  make start        → Start Splunk + enable UF on VM2"
	@echo "  make stop         → Stop Splunk"
	@echo "  make restart      → Restart Splunk"
	@echo "  make status       → Show Splunk + UF status"
	@echo "  make attack       → Run ALL attack simulations from Kali"
	@echo "  make attack-ssh   → SSH Brute Force only"
	@echo "  make attack-scan  → Port Scan only"
	@echo "  make attack-ddos  → SYN Flood DDoS only"
	@echo "  make attack-web   → Web attacks (Nikto + SQLmap)"
	@echo "  make logs         → Tail Splunk search logs"
	@echo "  make clean        → Remove temp files"
	@echo ""

# ── Splunk lifecycle ─────────────────────────────────────────
start:
	@echo "[*] Starting Splunk..."
	sudo -u $(SPLUNK_USER) $(SPLUNK_BIN) start
	@echo "[*] Opening firewall ports..."
	sudo ufw allow 8000/tcp
	sudo ufw allow 9997/tcp
	@echo "[+] Splunk started → http://192.168.225.10:8000"

stop:
	@echo "[*] Stopping Splunk..."
	sudo -u $(SPLUNK_USER) $(SPLUNK_BIN) stop

restart:
	@echo "[*] Restarting Splunk..."
	sudo -u $(SPLUNK_USER) $(SPLUNK_BIN) restart

status:
	@echo "=== VM1 — Splunk Server ==="
	sudo -u $(SPLUNK_USER) $(SPLUNK_BIN) status
	@echo ""
	@echo "=== VM2 — Universal Forwarder ==="
	ssh $(SSH_USER)@$(UF_HOST) "sudo /opt/splunkforwarder/bin/splunk status"

# ── Attack simulations (runs scripts on Kali via SSH) ────────
attack:
	@echo "[*] Launching ALL attack simulations from Kali ($(KALI_HOST))..."
	ssh $(SSH_USER)@$(KALI_HOST) "bash ~/attack-sim.sh all"

attack-ssh:
	ssh $(SSH_USER)@$(KALI_HOST) "bash ~/attack-sim.sh ssh"

attack-scan:
	ssh $(SSH_USER)@$(KALI_HOST) "bash ~/attack-sim.sh scan"

attack-ddos:
	ssh $(SSH_USER)@$(KALI_HOST) "bash ~/attack-sim.sh ddos"

attack-web:
	ssh $(SSH_USER)@$(KALI_HOST) "bash ~/attack-sim.sh web"

# ── Logs ─────────────────────────────────────────────────────
logs:
	tail -f /opt/splunk/var/log/splunk/splunkd.log

# ── Cleanup ──────────────────────────────────────────────────
clean:
	rm -f /tmp/attack-*.log
	@echo "[+] Cleaned up temp files"
