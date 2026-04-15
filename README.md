# Splunk SOC Lab

A home lab simulating a Security Operations Center (SOC) using Splunk, built for cybersecurity portfolio purposes.

## Architecture

```
┌─────────────────────────────────────────────────┐
│           VMware Host-Only Network              │
│              192.168.225.0/24                   │
│                                                 │
│  ┌──────────────┐    ┌──────────────┐           │
│  │   VM1        │    │   VM2        │           │
│  │ Ubuntu 22.04 │◄───│ Ubuntu 22.04 │           │
│  │ Splunk 10.x  │    │ Splunk UF   │           │
│  │ .225.10      │    │ .225.20      │           │
│  └──────────────┘    └──────┬───────┘           │
│                             │ logs              │
│  ┌──────────────┐           │                   │
│  │   VM3        │───────────┘                   │
│  │ Kali Linux   │  attacks                      │
│  │ .225.30      │                               │
│  └──────────────┘                               │
└─────────────────────────────────────────────────┘
```

## Detection Rules (MITRE ATT&CK)

| # | Alert | Technique | Trigger |
|---|-------|-----------|---------|
| 1 | SSH Brute Force | T1110.001 | >5 failed logins/60s |
| 2 | Port Scan | T1046 | >15 unique ports/60s |
| 3 | Sudo Escalation | T1548.003 | >3 auth failures |
| 4 | New User Created | T1136.001 | `useradd` detected |
| 5 | Outbound Traffic | T1041 | High volume transfer |
| 6 | SYN Flood DDoS | T1498.001 | >1000 SYN packets/min |

## Quick Start

```bash
# On VM1 — start everything
make start

# From VM1 — launch all attack simulations
make attack

# Individual attacks
make attack-ssh     # SSH Brute Force
make attack-scan    # Port Scan
make attack-ddos    # SYN Flood
make attack-web     # Web attacks (requires setup-web-target.sh)
```

## Setup

### VM1 — Splunk Server
```bash
bash scripts/install-splunk.sh
```

### VM2 — Log Source + Universal Forwarder
```bash
bash scripts/install-forwarder.sh
bash scripts/setup-web-target.sh   # Optional: adds DVWA for web attacks
```

### Telegram Alerts
```bash
# 1. Create bot via @BotFather, get TOKEN
# 2. Get chat ID via @userinfobot
# 3. Edit scripts/telegram-alert.py — set TOKEN and CHAT_ID
# 4. Deploy to Splunk:
bash scripts/setup-telegram-splunk.sh
# 5. Test:
python3 /opt/splunk/etc/apps/telegram_alert/bin/telegram-alert.py --test
```

## Attack Simulations

All attacks run from Kali (VM3) using `scripts/attack-sim.sh`:

| Attack | Tool | MITRE |
|--------|------|-------|
| SSH Brute Force | Hydra | T1110.001 |
| Port Scan | Nmap | T1046 |
| SYN Flood | hping3 | T1498.001 |
| Web Scan | Nikto | T1190 |
| SQL Injection | SQLmap | T1190 |

## Project Structure

```
splunk-soc-lab/
├── Makefile                          # Lab automation
├── scripts/
│   ├── install-splunk.sh             # VM1 setup
│   ├── install-forwarder.sh          # VM2 setup
│   ├── attack-sim.sh                 # All attack simulations
│   ├── telegram-alert.py             # Telegram notification script
│   ├── setup-telegram-splunk.sh      # Deploy Telegram into Splunk
│   └── setup-web-target.sh           # Install DVWA on VM2
├── configs/
│   └── splunk/
│       └── detection-rules.spl       # All 6 SPL detection queries
├── dashboards/
│   └── soc-overview.xml              # Splunk dashboard XML
├── docs/
│   ├── Blueprint.md
│   └── Report.md
└── logs/
    └── samples/
```

## Author

**Ikhlas Retbi** — Networks & Telecom Engineer  
Portfolio: [github.com/ikhlas-rtb](https://github.com/ikhlas-rtb)
