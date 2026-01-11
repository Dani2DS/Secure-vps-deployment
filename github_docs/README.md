# 🔐 Secure VPS Deployment - Linux Server Hardening Project

![Security](https://img.shields.io/badge/Security-Hardened-green)
![Ubuntu](https://img.shields.io/badge/Ubuntu-24.04%20LTS-orange)
![Python](https://img.shields.io/badge/Python-3.12-blue)
![Nginx](https://img.shields.io/badge/Nginx-SSL%2FTLS%201.3-brightgreen)
![License](https://img.shields.io/badge/License-MIT-yellow)

## 📋 Overview

This project demonstrates the complete deployment and hardening of a Linux VPS server, implementing enterprise-grade security measures. The server hosts a Python-based web application with automated scheduling, protected by multiple security layers.

**This is a practical implementation of concepts learned from:**
- 🎓 **Cybersecurity Essentials** - Defense in depth, network security fundamentals
- 🏴‍☠️ **TryHackMe Pre-Security** - Linux fundamentals, networking basics
- 💻 **Foundations of Programming** - Scripting and automation
- 🐍 **Python for Everyone** - Application development and API integration

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        INTERNET                              │
│                      (Attackers/Bots)                        │
└─────────────────────────┬───────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────┐
│  LAYER 1: Cloud Provider Firewall                           │
│  ✅ Only ports 22, 80, 443 exposed                          │
└─────────────────────────┬───────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────┐
│  LAYER 2: UFW (Uncomplicated Firewall)                      │
│  ✅ Default deny incoming, allow outgoing                   │
└─────────────────────────┬───────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────┐
│  LAYER 3: Fail2Ban IPS                                      │
│  ✅ SSH protection (3 attempts → ban)                       │
│  ✅ Nginx auth protection                                    │
│  ✅ Recidive jail (repeat offenders → 1 week ban)           │
│  ✅ Exponential ban scaling (1h → 24h → days → 1 year max)  │
└─────────────────────────┬───────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────┐
│  LAYER 4: SSH Hardening                                     │
│  ✅ Root login disabled                                      │
│  ✅ Password authentication disabled                         │
│  ✅ Ed25519 SSH keys only                                    │
│  ✅ MaxAuthTries: 3                                          │
└─────────────────────────┬───────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────┐
│  LAYER 5: Nginx + SSL/TLS                                   │
│  ✅ Let's Encrypt certificate (auto-renewal)                │
│  ✅ TLS 1.3 + AES-256-GCM                                   │
│  ✅ Security headers (X-Frame, X-XSS, etc.)                 │
│  ✅ HTTP Basic Authentication                                │
└─────────────────────────┬───────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────┐
│  LAYER 6: Application Security                              │
│  ✅ Non-root user with sudo                                  │
│  ✅ Python virtual environment                               │
│  ✅ Secrets in .env file (chmod 640)                        │
│  ✅ Sensitive paths blocked                                  │
└─────────────────────────────────────────────────────────────┘
```

---

## 🛡️ Security Implementations

### 1. Firewall Configuration (UFW)

```bash
# Default policies
ufw default deny incoming
ufw default allow outgoing

# Allow only necessary services
ufw allow 22/tcp   # SSH
ufw allow 80/tcp   # HTTP (redirects to HTTPS)
ufw allow 443/tcp  # HTTPS

ufw enable
```

### 2. SSH Hardening

Key configurations in `/etc/ssh/sshd_config`:

```bash
PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes
MaxAuthTries 3
LoginGraceTime 60
PermitEmptyPasswords no
```

### 3. Fail2Ban Configuration

**Escalating ban system for repeat offenders:**

```ini
[DEFAULT]
bantime = 1h
findtime = 10m
maxretry = 5

# Exponential increase for repeat offenders
bantime.increment = true
bantime.factor = 24
bantime.maxtime = 52w  # Maximum 1 year ban

[sshd]
enabled = true
port = 22
maxretry = 3
bantime = 1h

[nginx-auth]
enabled = true
port = 80,443
maxretry = 5
bantime = 1h

[recidive]
enabled = true
bantime = 1w
findtime = 1d
maxretry = 3
```

### 4. Nginx Security Headers

```nginx
# Security headers
add_header X-Frame-Options "SAMEORIGIN" always;
add_header X-Content-Type-Options "nosniff" always;
add_header X-XSS-Protection "1; mode=block" always;
add_header Referrer-Policy "strict-origin-when-cross-origin" always;

# Block sensitive paths
location ~ /(.env|.git|data|backup|logs|config) {
    deny all;
    return 404;
}
```

### 5. SSL/TLS Configuration

- **Protocol:** TLS 1.3
- **Cipher:** TLS_AES_256_GCM_SHA384
- **Certificate:** Let's Encrypt (auto-renewal via Certbot)
- **HSTS:** Enabled

---

## 📊 Real Attack Data

Within **2 hours** of deployment, the server detected and blocked multiple brute-force attempts:

| Attacker IP | Attempts | Usernames Tried |
|-------------|----------|-----------------|
| 188.166.21.229 | 6 | admin, mysql, user |
| 146.190.30.46 | 5 | ubuntu, guest, postgres |
| 188.166.46.159 | 2 | Various |
| 171.243.150.190 | 2 | Various |

**Why they failed:**
- ❌ Username "root" → Login disabled
- ❌ Password authentication → Disabled (SSH keys only)
- ❌ Multiple attempts → Banned by fail2ban
- ✅ Our user exists but requires private key stored locally

---

## 🐍 Python Application

### Features
- Automated API data fetching
- HTML report generation
- Scheduled execution via cron (3x daily)
- Robust error handling and logging
- Environment-based configuration

### Project Structure

```
/var/www/app/
├── app/
│   └── monitor.py          # Main application
├── data/                   # Data storage
├── output/                 # Generated reports (web-accessible)
├── logs/                   # Application logs
├── backup/                 # Automatic backups
├── scripts/                # Maintenance scripts
├── venv/                   # Python virtual environment
├── .env                    # Secrets (chmod 640)
└── requirements.txt        # Dependencies
```

### Cron Automation

```bash
# Runs at 3:00 AM, 10:00 AM, and 3:00 PM (local timezone)
0 3,10,15 * * * /usr/bin/flock -n /tmp/app.lock /var/www/app/run_script.sh
```

---

## 🔧 Setup Guide

### Prerequisites
- Ubuntu 24.04 LTS VPS
- Domain name pointing to server IP
- SSH key pair generated locally

### Quick Start

```bash
# 1. Update system
apt update && apt upgrade -y

# 2. Create non-root user
adduser appuser
usermod -aG sudo appuser

# 3. Configure SSH keys
# (copy public key to ~/.ssh/authorized_keys)

# 4. Harden SSH
nano /etc/ssh/sshd_config
systemctl restart ssh

# 5. Configure firewall
apt install ufw -y
ufw default deny incoming
ufw default allow outgoing
ufw allow 22/tcp
ufw allow 80/tcp
ufw allow 443/tcp
ufw enable

# 6. Install fail2ban
apt install fail2ban -y
# (configure jails)

# 7. Install web stack
apt install nginx python3 python3-pip python3-venv certbot python3-certbot-nginx -y

# 8. Deploy application
# (see detailed guide)

# 9. Obtain SSL certificate
certbot --nginx -d yourdomain.com

# 10. Verify security
ufw status
fail2ban-client status
nginx -t
```

---

## 📚 Learning Outcomes

### Cybersecurity Essentials
- ✅ Defense in Depth implementation
- ✅ Network segmentation concepts
- ✅ Principle of least privilege
- ✅ Security logging and monitoring

### TryHackMe Pre-Security
- ✅ Linux command line proficiency
- ✅ User and permission management
- ✅ Service configuration
- ✅ Network fundamentals (ports, protocols)

### Foundations of Programming
- ✅ Bash scripting for automation
- ✅ Configuration file management
- ✅ Cron job scheduling
- ✅ Log analysis

### Python for Everyone
- ✅ API integration
- ✅ File handling (JSON, HTML)
- ✅ Environment variables
- ✅ Virtual environments
- ✅ Error handling and logging

---

## 🛠️ Useful Commands

```bash
# Check banned IPs
sudo fail2ban-client status sshd

# View failed login attempts
sudo grep "Failed password" /var/log/auth.log | tail -20

# Check firewall status
sudo ufw status verbose

# View application logs
tail -f /var/www/app/logs/run.log

# Test SSL certificate
echo | openssl s_client -connect yourdomain.com:443 2>/dev/null | grep -E "Protocol|Cipher"

# Verify Nginx configuration
sudo nginx -t

# Check security headers
curl -sI https://yourdomain.com | grep -E "X-Frame|X-Content|X-XSS|Referrer"
```

---

## 📈 Security Checklist

- [x] Non-root user created
- [x] SSH root login disabled
- [x] SSH password authentication disabled
- [x] SSH keys configured (Ed25519)
- [x] UFW firewall enabled
- [x] Fail2ban protecting SSH
- [x] Fail2ban protecting web auth
- [x] Recidive jail for repeat offenders
- [x] SSL/TLS 1.3 enabled
- [x] Security headers configured
- [x] Sensitive paths blocked
- [x] Secrets in protected .env file
- [x] Automated certificate renewal
- [x] Log monitoring configured

---

## 🚨 Disclaimer

This project is for **educational purposes only**. The configurations shown are based on a real deployment but all sensitive information (IPs, domains, credentials) has been anonymized.

Always adapt security measures to your specific requirements and threat model.

---

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 🤝 Acknowledgments

- [TryHackMe](https://tryhackme.com) - Security training platform
- [Let's Encrypt](https://letsencrypt.org) - Free SSL certificates
- [Fail2Ban](https://www.fail2ban.org) - Intrusion prevention
- [Nginx](https://nginx.org) - Web server

---

**Made with 🔐 by [Your Name]**

*Practicing cybersecurity one server at a time.*
