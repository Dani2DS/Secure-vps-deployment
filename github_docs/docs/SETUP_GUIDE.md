# 🔧 Security Configuration Guide

> Complete step-by-step guide for hardening an Ubuntu 24.04 LTS server

---

## Table of Contents

1. [Initial Setup](#1-initial-setup)
2. [User Management](#2-user-management)
3. [SSH Hardening](#3-ssh-hardening)
4. [Firewall Configuration](#4-firewall-configuration)
5. [Fail2Ban Setup](#5-fail2ban-setup)
6. [Web Server (Nginx)](#6-web-server-nginx)
7. [SSL/TLS Certificates](#7-ssltls-certificates)
8. [Python Application Deployment](#8-python-application-deployment)
9. [Automation (Cron)](#9-automation-cron)
10. [Verification Checklist](#10-verification-checklist)

---

## 1. Initial Setup

### Update System

```bash
apt update
apt upgrade -y
apt install -y curl wget git nano htop
```

### Set Timezone

```bash
timedatectl set-timezone America/New_York  # Change to your timezone
timedatectl  # Verify
```

---

## 2. User Management

### Create Non-Root User

```bash
# Create user (you'll be prompted for password)
adduser appuser

# Grant sudo privileges
usermod -aG sudo appuser

# Verify
groups appuser
# Output: appuser : appuser sudo users
```

### Why Non-Root?

| Root | Non-Root + Sudo |
|------|-----------------|
| Full access always | Access on demand |
| No audit trail | Commands logged |
| One mistake = disaster | Errors contained |
| Easy target for attackers | Obscured username |

---

## 3. SSH Hardening

### Backup Original Config

```bash
cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup
```

### Edit SSH Configuration

```bash
nano /etc/ssh/sshd_config
```

**Required Changes:**

```bash
# Disable root login
PermitRootLogin no

# Disable password authentication (after setting up SSH keys!)
PasswordAuthentication no

# Enable public key authentication
PubkeyAuthentication yes

# Limit authentication attempts
MaxAuthTries 3

# Reduce login grace period
LoginGraceTime 60

# Disable empty passwords
PermitEmptyPasswords no
```

### Generate SSH Keys (On Your Local Machine)

```powershell
# Windows PowerShell
ssh-keygen -t ed25519 -C "yourname@yourmachine"

# View public key
cat ~/.ssh/id_ed25519.pub
```

### Copy Public Key to Server

```powershell
# From your local machine
type $env:USERPROFILE\.ssh\id_ed25519.pub | ssh appuser@SERVER_IP "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys"
```

### Test Connection Before Disabling Passwords

```powershell
# Open NEW terminal, keep old one open
ssh appuser@SERVER_IP

# If it works without password, proceed
# If not, DO NOT restart SSH!
```

### Apply Changes

```bash
systemctl restart ssh
```

---

## 4. Firewall Configuration

### Install and Configure UFW

```bash
# Install
apt install ufw -y

# Default policies
ufw default deny incoming
ufw default allow outgoing

# Allow necessary ports
ufw allow 22/tcp    # SSH
ufw allow 80/tcp    # HTTP
ufw allow 443/tcp   # HTTPS

# Enable firewall
ufw enable

# Verify
ufw status verbose
```

### Expected Output

```
Status: active

To                         Action      From
--                         ------      ----
22/tcp                     ALLOW       Anywhere
80/tcp                     ALLOW       Anywhere
443/tcp                    ALLOW       Anywhere
```

---

## 5. Fail2Ban Setup

### Install Fail2Ban

```bash
apt install fail2ban -y
```

### Create Local Configuration

```bash
nano /etc/fail2ban/jail.local
```

**Configuration:**

```ini
[DEFAULT]
bantime = 1h
findtime = 10m
maxretry = 5
ignoreip = 127.0.0.1/8

# Exponential ban increase for repeat offenders
bantime.increment = true
bantime.factor = 24
bantime.maxtime = 52w

[sshd]
enabled = true
port = 22
logpath = /var/log/auth.log
maxretry = 3
bantime = 1h

[nginx-auth]
enabled = true
port = 80,443
filter = nginx-auth
logpath = /var/log/nginx/*_access.log
maxretry = 5
bantime = 1h

[recidive]
enabled = true
logpath = /var/log/fail2ban.log
banaction = %(banaction_allports)s
bantime = 1w
findtime = 1d
maxretry = 3
```

### Create Nginx Auth Filter

```bash
nano /etc/fail2ban/filter.d/nginx-auth.conf
```

```ini
[Definition]
failregex = ^<HOST> -.*"(GET|POST).*" 401
ignoreregex =
```

### Start Fail2Ban

```bash
systemctl enable fail2ban
systemctl start fail2ban
fail2ban-client status
```

### Ban Time Escalation

| Offense | Duration |
|---------|----------|
| 1st | 1 hour |
| 2nd | 24 hours |
| 3rd | 24 days |
| 4th+ | Up to 1 year |
| Recidive (3+ in 1 day) | 1 week (all ports) |

---

## 6. Web Server (Nginx)

### Install Nginx

```bash
apt install nginx -y
systemctl enable nginx
systemctl status nginx
```

### Create Site Configuration

```bash
nano /etc/nginx/sites-available/myapp.conf
```

```nginx
server {
    listen 80;
    server_name yourdomain.com;

    root /var/www/myapp/output;
    index index.html;

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;

    # Basic authentication
    auth_basic "Restricted Access";
    auth_basic_user_file /etc/nginx/.htpasswd;

    location / {
        try_files $uri $uri/ /index.html;
    }

    # Block sensitive paths
    location ~ /(.env|.git|data|backup|logs|config) {
        deny all;
        return 404;
    }

    # Logs
    access_log /var/log/nginx/myapp_access.log;
    error_log /var/log/nginx/myapp_error.log;
}
```

### Create HTTP Authentication

```bash
apt install apache2-utils -y
htpasswd -cb /etc/nginx/.htpasswd "admin@example.com" 'YourSecurePassword'
chmod 640 /etc/nginx/.htpasswd
chown root:www-data /etc/nginx/.htpasswd
```

### Enable Site

```bash
ln -sf /etc/nginx/sites-available/myapp.conf /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default
nginx -t
systemctl reload nginx
```

---

## 7. SSL/TLS Certificates

### Install Certbot

```bash
apt install certbot python3-certbot-nginx -y
```

### Obtain Certificate

```bash
certbot --nginx -d yourdomain.com
```

### Verify Auto-Renewal

```bash
certbot renew --dry-run
```

### Check Certificate

```bash
echo | openssl s_client -connect yourdomain.com:443 2>/dev/null | grep -E "Protocol|Cipher"
```

**Expected Output:**

```
Protocol  : TLSv1.3
Cipher    : TLS_AES_256_GCM_SHA384
```

---

## 8. Python Application Deployment

### Create Directory Structure

```bash
mkdir -p /var/www/myapp/{app,config,data,logs,output,backup,scripts}
chown -R www-data:www-data /var/www/myapp
chmod -R 755 /var/www/myapp
```

### Create Virtual Environment

```bash
cd /var/www/myapp
python3 -m venv venv
chown -R appuser:appuser venv
source venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt
```

### Secure Environment File

```bash
nano /var/www/myapp/.env
```

```
API_KEY=your_secret_key_here
DATABASE_URL=your_connection_string
```

```bash
chmod 640 /var/www/myapp/.env
chown root:appuser /var/www/myapp/.env
```

### Configure Application to Use .env

```python
# In your Python app
from dotenv import load_dotenv
import os

load_dotenv('/var/www/myapp/.env')
API_KEY = os.getenv('API_KEY')
```

---

## 9. Automation (Cron)

### Create Execution Script

```bash
nano /var/www/myapp/run_app.sh
```

```bash
#!/usr/bin/env bash
set -euo pipefail

BASE="/var/www/myapp"
cd "$BASE"
source "$BASE/venv/bin/activate"

echo "===== $(date -Is) START =====" >> "$BASE/logs/run.log"
python3 "$BASE/app/main.py" >> "$BASE/logs/run.log" 2>&1
echo "===== $(date -Is) END =====" >> "$BASE/logs/run.log"
```

```bash
chmod +x /var/www/myapp/run_app.sh
```

### Configure Cron

```bash
sudo crontab -e
```

```cron
# Run at 3am, 10am, and 3pm daily
0 3,10,15 * * * /usr/bin/flock -n /tmp/myapp.lock /var/www/myapp/run_app.sh

# Generate security report every Monday at 8am
0 8 * * 1 /var/www/myapp/scripts/report_banned_ips.sh
```

---

## 10. Verification Checklist

### Run This Script to Verify Security

```bash
echo "=========================================="
echo "=== SECURITY VERIFICATION ==="
echo "=========================================="

echo "1. Non-root user:"
id appuser

echo ""
echo "2. SSH Configuration:"
grep -E "^PermitRootLogin|^PasswordAuthentication|^MaxAuthTries" /etc/ssh/sshd_config

echo ""
echo "3. Firewall:"
sudo ufw status

echo ""
echo "4. Fail2Ban:"
sudo fail2ban-client status

echo ""
echo "5. Nginx:"
sudo systemctl is-active nginx

echo ""
echo "6. SSL Certificate:"
sudo openssl x509 -in /etc/letsencrypt/live/yourdomain.com/cert.pem -noout -dates 2>/dev/null || echo "No certificate found"

echo ""
echo "7. Security Headers:"
curl -sI https://yourdomain.com 2>/dev/null | grep -E "X-Frame|X-Content|X-XSS|Referrer"

echo ""
echo "8. Open Ports:"
sudo ss -tlnp | grep LISTEN
```

### Expected Results

| Check | Expected |
|-------|----------|
| User exists | ✅ appuser with sudo |
| PermitRootLogin | ✅ no |
| PasswordAuthentication | ✅ no |
| UFW Status | ✅ active |
| Fail2Ban Jails | ✅ sshd, nginx-auth, recidive |
| Nginx | ✅ active |
| SSL Valid | ✅ notAfter in future |
| Security Headers | ✅ All 4 present |
| Open Ports | ✅ Only 22, 80, 443 |

---

## 🚨 Troubleshooting

### Can't Connect via SSH

1. Check if SSH is running: `systemctl status ssh`
2. Check firewall: `ufw status`
3. Clear known hosts: `ssh-keygen -R SERVER_IP`

### Fail2Ban Not Banning

1. Check jail status: `fail2ban-client status sshd`
2. Check logs: `tail -f /var/log/fail2ban.log`
3. Test regex: `fail2ban-regex /var/log/auth.log /etc/fail2ban/filter.d/sshd.conf`

### Nginx Returns 502

1. Check if app is running
2. Check permissions on socket/port
3. Review nginx error log: `tail /var/log/nginx/error.log`

### Certificate Issues

1. Check DNS: `ping yourdomain.com`
2. Check ports: `ufw status`
3. Retry: `certbot --nginx -d yourdomain.com`

---

*Security is a process, not a destination. Keep learning, keep hardening.*
