# SOC Lab Blueprint

## Objective

Build a functional Security Operations Center (SOC) home lab to detect, analyze, and respond to simulated cyber attacks using open-source tools.

## Infrastructure

| Component | OS | Role | IP | RAM |
|-----------|-----|------|----|-----|
| VM1 | Ubuntu 22.04 | Splunk SIEM | 192.168.225.10 | 2GB |
| VM2 | Ubuntu 22.04 | Log Source + UF | 192.168.225.20 | 2GB |
| VM3 | Kali Linux 2024 | Attacker | 192.168.225.30 | 2GB |
| Host | Windows 11 | Hypervisor | 192.168.225.1 | — |

## Network Design

- **Hypervisor:** VMware Workstation Pro
- **Network:** VMnet1 (Host-only) — 192.168.225.0/24
- **VM Internet:** NAT via VMnet8 (ens33)
- **Lab Traffic:** Host-only VMnet1 (ens37)

## Detection Rules

### Rule 1 — SSH Brute Force (T1110.001)
```spl
index=main sourcetype=linux_secure "Failed password"
| rex "from (?P<src_ip>\d+\.\d+\.\d+\.\d+)"
| bin _time span=60s
| stats count by _time, src_ip
| where count > 5
```
**Logic:** More than 5 failed SSH logins from the same IP within 60 seconds.

### Rule 2 — Port Scan (T1046)
```spl
index=main sourcetype=syslog "PORT_SCAN"
| rex "SRC=(?P<src_ip>\d+\.\d+\.\d+\.\d+).*DPT=(?P<dest_port>\d+)"
| bin _time span=60s
| stats dc(dest_port) as unique_ports by _time, src_ip
| where unique_ports > 15
```
**Logic:** More than 15 unique destination ports hit in 60 seconds. Requires iptables LOG rule on VM2.

### Rule 3 — Sudo/Auth Failure (T1548.003)
```spl
index=main sourcetype=linux_secure ("authentication failure" OR "Failed password" OR "sudo")
| rex "user=(?P<user>\w+)"
| stats count by user, host
| where count > 3
```
**Logic:** Repeated authentication failures suggesting privilege escalation attempt.

### Rule 4 — New User Created (T1136.001)
```spl
index=main sourcetype=linux_secure "new user"
| rex "name=(?P<new_user>\w+)"
| table _time, host, new_user
```
**Logic:** Any new user account creation is flagged immediately.

### Rule 5 — Unusual Outbound Traffic (T1041)
```spl
index=main sourcetype=syslog
| stats sum(bytes_out) as total_bytes by src_ip
| where total_bytes > 10000000
```
**Logic:** Data exfiltration simulation. Requires NetFlow agent for full accuracy.

### Rule 6 — SYN Flood DDoS (T1498.001)
```spl
index=main sourcetype=syslog "PORT_SCAN"
| rex "SRC=(?P<src_ip>\d+\.\d+\.\d+\.\d+)"
| bin _time span=60s
| stats count by _time, src_ip
| where count > 1000
```
**Logic:** SYN flood generates thousands of iptables log entries per minute.

## Attack Scenarios

| Attack | Tool | Target | Expected Alert |
|--------|------|--------|----------------|
| SSH Brute Force | Hydra + rockyou.txt | VM2:22 | Rule 1 |
| Port Scan | Nmap SYN | VM2 | Rule 2 |
| SYN Flood | hping3 --flood | VM2 | Rule 6 |
| Privilege Escalation | manual sudo | VM2 | Rule 3 |
| User Creation | useradd | VM2 | Rule 4 |
| Web Scan | Nikto | VM2:80 | Apache logs |
| SQL Injection | SQLmap | VM2/dvwa | Apache logs |

## Log Sources

| Source | File | Sourcetype |
|--------|------|------------|
| SSH auth | /var/log/auth.log | linux_secure |
| System | /var/log/syslog | syslog |
| Apache | /var/log/apache2/access.log | apache_access |
| iptables | /var/log/syslog (kernel) | syslog |

## Alerting

Alerts are sent via:
1. **Splunk Triggered Alerts** — viewable in Splunk UI
2. **Telegram Bot** — real-time push notifications via `telegram-alert.py`

## Limitations

- Splunk Free License: 500MB/day indexed data limit
- No NetFlow: outbound traffic volume detection is approximate
- Lab-only: rules tuned for low-noise lab environment, would need tuning for production
