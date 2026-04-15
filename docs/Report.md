# SOC Lab Report

**Author:** Ikhlas Retbi  
**Date:** April 2026  
**Project:** splunk-soc-lab  

---

## Executive Summary

This report documents the design, implementation, and validation of a home Security Operations Center (SOC) lab. The lab simulates real-world attack scenarios and demonstrates detection capabilities using Splunk SIEM.

**Result:** 5 out of 6 detection rules successfully triggered and alerted during simulated attacks.

---

## Environment

| VM | Role | OS | IP | RAM |
|----|------|----|----|-----|
| VM1 | Splunk SIEM | Ubuntu 22.04 | 192.168.225.10 | 2GB |
| VM2 | Target + Log Source | Ubuntu 22.04 | 192.168.225.20 | 2GB |
| VM3 | Attacker | Kali Linux 2024 | 192.168.225.30 | 2GB |

---

## Detection Results

### Rule 1 — SSH Brute Force (T1110.001) ✅
- **Tool:** Hydra with rockyou.txt wordlist
- **Result:** 8+ failed logins/min detected from 192.168.225.30
- **Alert:** Fired within 60 seconds of attack start
- **Evidence:** `Failed password for root from 192.168.225.30`

### Rule 2 — Port Scan (T1046) ✅
- **Tool:** Nmap SYN scan (-sS) against ports 1-1000
- **Result:** 1000 unique destination ports detected in 60 seconds
- **Alert:** Fired immediately
- **Evidence:** iptables PORT_SCAN entries in syslog

### Rule 3 — Sudo/Auth Failure (T1548.003) ✅
- **Tool:** Manual `su` + failed sudo attempts
- **Result:** 64 root authentication failures detected
- **Alert:** Fired after threshold of 3 exceeded
- **Evidence:** `authentication failure` in auth.log

### Rule 4 — New User Created (T1136.001) ✅
- **Tool:** `useradd hacker` command on VM2
- **Result:** New user creation detected in real-time
- **Alert:** Fired immediately
- **Evidence:** `new user: name=hacker` in auth.log

### Rule 5 — Unusual Outbound Traffic (T1041) ⚠️
- **Status:** Partial — rule created but limited by lack of NetFlow
- **Limitation:** Ubuntu syslog does not include bytes_out field without additional agent
- **Mitigation:** Would deploy Zeek or Suricata in a production environment

### Rule 6 — SYN Flood DDoS (T1498.001) ✅
- **Tool:** hping3 --flood
- **Result:** >1000 SYN packets/min from 192.168.225.30
- **Alert:** Fires based on iptables log volume
- **Evidence:** Flood of PORT_SCAN entries in syslog

---

## Telegram Alerting

Real-time notifications deployed via custom Splunk alert action script (`telegram-alert.py`). When any detection rule fires, a formatted Telegram message is sent including:
- Alert name and MITRE technique
- Source IP of attacker
- Timestamp
- Link to Splunk for investigation

---

## Key Findings

1. **SSH brute force is easily detectable** with auth.log monitoring — threshold of 5 attempts/60s is effective
2. **iptables logging is essential** for port scan and DDoS detection on Linux targets
3. **Splunk UF is lightweight** — minimal impact on VM2 performance during attacks
4. **Real-time alerting** via Telegram bridges the gap between detection and response

---

## Lessons Learned

- LVM disk management is critical — Splunk requires minimum 5GB free space
- VMware adapter configuration must be verified (APIPA indicates DHCP failure)
- Ubuntu 22.04 disables root SSH login by default — affects brute force simulation methodology
- `rex` field extraction is necessary when Splunk CIM fields are not auto-extracted

---

## Next Steps

- [ ] Add Zeek for NetFlow-based traffic analysis
- [ ] Integrate GoPhish for phishing simulation
- [ ] Build MITRE ATT&CK coverage heatmap in Splunk dashboard
- [ ] Add Metasploit exploitation with reverse shell detection
- [ ] Implement automated incident response playbooks

---

## Tools Used

| Tool | Version | Purpose |
|------|---------|---------|
| Splunk Enterprise | 10.2.2 | SIEM |
| Splunk UF | 10.2.2 | Log forwarding |
| Hydra | 9.5 | SSH brute force |
| Nmap | 7.94 | Port scanning |
| hping3 | 3.0.0 | SYN flood |
| Nikto | 2.x | Web scanning |
| VMware Workstation | Pro 17 | Hypervisor |
