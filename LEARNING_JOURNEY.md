# 🎓 Learning Journey

## Overview

This document chronicles my learning journey through foundational cybersecurity and programming courses, culminating in a practical server hardening project.

---

## 📚 Courses Completed

### 1. 🛡️ Cybersecurity Essentials

**Key Concepts Learned:**

| Concept | Description | Applied In Project |
|---------|-------------|-------------------|
| Defense in Depth | Multiple security layers | 10 security layers implemented |
| Principle of Least Privilege | Minimal necessary permissions | Non-root user + sudo |
| CIA Triad | Confidentiality, Integrity, Availability | SSL encryption, file permissions, uptime |
| Risk Assessment | Identifying and mitigating threats | fail2ban, firewall rules |
| Security Controls | Preventive, Detective, Corrective | UFW, logs, auto-banning |

**Practical Application:**
```
Internet → Cloud Firewall → UFW → Fail2Ban → SSH Hardening → Application
         (Layer 1)       (L2)    (L3)         (L4)           (L5-6)
```

---

### 2. 🏴‍☠️ TryHackMe Pre-Security

**Linux Fundamentals Applied:**

```bash
# User Management
adduser appuser                    # Create user
usermod -aG sudo appuser           # Grant sudo access
groups appuser                     # Verify groups

# File Permissions
chmod 640 /path/to/.env            # Restrict secret file
chown root:appuser /path/to/.env   # Set ownership
ls -la /path/to/                   # Verify permissions

# Service Management
systemctl status nginx             # Check service
systemctl restart ssh              # Restart service
systemctl enable fail2ban          # Enable on boot

# Process Management
ps aux | grep python               # Find processes
top                                # System monitor
htop                               # Interactive monitor
```

**Networking Concepts Applied:**

| Concept | Understanding | Implementation |
|---------|---------------|----------------|
| TCP/IP | How data travels | Firewall rules  port |
| Ports | Service endpoints | 22 (SSH), 80 (HTTP), 443 (HTTPS) |
| DNS | Domain resolution | Configured A record |
| TLS/SSL | Encrypted communication | Let's Encrypt certificate |

---

### 3. 💻 Foundations of Programming

**Bash Scripting:**

```bash
#!/usr/bin/env bash
# Example: Automated execution script

set -euo pipefail  # Strict mode

BASE="/var/www/app"
cd "$BASE"

# Activate virtual environment
source "$BASE/venv/bin/activate"

# Log execution
echo "===== $(date -Is) START =====" >> "$BASE/logs/run.log"

# Run application
python3 "$BASE/app/monitor.py" >> "$BASE/logs/run.log" 2>&1

echo "===== $(date -Is) END =====" >> "$BASE/logs/run.log"
```

**Cron Scheduling:**

```bash
# Crontab syntax: minute hour day month weekday command
# ┌───────────── minute (0 - 59)
# │ ┌───────────── hour (0 - 23)
# │ │ ┌───────────── day of month (1 - 31)
# │ │ │ ┌───────────── month (1 - 12)
# │ │ │ │ ┌───────────── day of week (0 - 6)
# │ │ │ │ │
# * * * * * command

# My implementation: Run at 3am, 10am, 3pm daily
0 3,10,15 * * * /usr/bin/flock -n /tmp/app.lock /path/to/script.sh
```

---

### 4. 🐍 Python for Everyone

**Concepts Applied:**

```python
# Environment Variables (Security)
import os
from dotenv import load_dotenv

load_dotenv('/path/to/.env')
API_KEY = os.getenv('API_KEY')

# Never hardcode secrets!
# ❌ API_KEY = "abc123secret"
# ✅ API_KEY = os.getenv('API_KEY')
```

```python
# API Integration
import requests
import json

def fetch_data(endpoint, params):
    """Fetch data from API with error handling."""
    try:
        response = requests.get(
            endpoint,
            params=params,
            timeout=30
        )
        response.raise_for_status()
        return response.json()
    except requests.RequestException as e:
        logger.error(f"API Error: {e}")
        return None
```

```python
# Logging Best Practices
import logging
from datetime import datetime

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s | %(levelname)s | %(message)s',
    handlers=[
        logging.FileHandler(f'logs/app_{datetime.now():%Y-%m-%d}.log'),
        logging.StreamHandler()
    ]
)

logger = logging.getLogger(__name__)
logger.info("Application started")
```

```python
# File Handling
import json

# Read JSON
with open('data/database.json', 'r', encoding='utf-8') as f:
    data = json.load(f)

# Write JSON (atomic - prevents corruption)
import tempfile
import shutil

def save_atomic(filepath, data):
    """Save file atomically to prevent corruption."""
    temp_fd, temp_path = tempfile.mkstemp()
    try:
        with os.fdopen(temp_fd, 'w', encoding='utf-8') as f:
            json.dump(data, f, ensure_ascii=False, indent=2)
        shutil.move(temp_path, filepath)
    except Exception:
        os.unlink(temp_path)
        raise
```

---

## 🧠 Key Takeaways

### Security Mindset

1. **Trust Nothing** - Validate all inputs, assume breach
2. **Defense in Depth** - Multiple layers, not single points of failure
3. **Least Privilege** - Only grant necessary permissions
4. **Log Everything** - You can't detect what you don't monitor
5. **Automate Security** - Humans make mistakes, scripts don't sleep

### Practical Skills Gained

| Skill | Before | After |
|-------|--------|-------|
| Linux CLI | Basic commands | Service management, user administration |
| Networking | Conceptual | Firewall rules, port management |
| Python | Syntax | Full application deployment |
| Security | Theoretical | Hands-on hardening |
| Troubleshooting | Google everything | Systematic log analysis |

---

## 📊 Project Metrics

### Security Effectiveness

Within **2 hours** of deployment:

- **15+ brute-force attacks** detected
- **4 unique attacker IPs** banned
- **0 successful unauthorized access**

### Attack Patterns Observed

```
Timeline of attacks on a fresh server:
├── 00:00 - Server deployed
├── 00:48 - First SSH brute-force attempt (banned)
├── 01:05 - Second attacker joins
├── 01:11 - Third attacker
├── 02:00 - 6 IPs banned, system secure
└── Ongoing - Continuous automated attacks blocked
```

### Common Attack Usernames

```
Most attempted usernames (first 24 hours):
1. root          (blocked - login disabled)
2. admin         (blocked - doesn't exist)
3. ubuntu        (blocked - doesn't exist)
4. postgres      (blocked - doesn't exist)
5. mysql         (blocked - doesn't exist)
6. test          (blocked - doesn't exist)
7. guest         (blocked - doesn't exist)
8. administrator (blocked - doesn't exist)
```

---

## 🔮 Future Learning Goals

- [ ] Web Application Firewall (ModSecurity)
- [ ] Container security (Docker hardening)
- [ ] Infrastructure as Code (Terraform/Ansible)
- [ ] SIEM implementation
- [ ] Penetration testing (offensive security)
- [ ] Cloud security (AWS/Azure)

---

## 💡 Advice for Beginners

1. **Start with Linux** - Everything runs on it
2. **Build real projects** - Theory is useless without practice
3. **Embrace failure** - Broken servers teach more than tutorials
4. **Document everything** - Future you will thank present you
5. **Stay curious** - Security evolves daily

---

## 🔗 Resources That Helped

### Courses
- [TryHackMe](https://tryhackme.com) - Interactive security labs
- [Cybersecurity Essentials](https://www.netacad.com) - Cisco Networking Academy
- [Python for Everybody](https://www.py4e.com) - Dr. Charles Severance

### Documentation
- [Ubuntu Server Guide](https://ubuntu.com/server/docs)
- [Nginx Documentation](https://nginx.org/en/docs/)
- [Fail2Ban Wiki](https://www.fail2ban.org/wiki/)
- [Let's Encrypt](https://letsencrypt.org/docs/)

### Communities
- [r/linuxadmin](https://reddit.com/r/linuxadmin)
- [r/netsec](https://reddit.com/r/netsec)
- [Server Fault](https://serverfault.com)

---

*"The best way to learn security is to secure something."*
