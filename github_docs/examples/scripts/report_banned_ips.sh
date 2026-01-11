#!/bin/bash
# =============================================================================
# Banned IPs Report Script
# =============================================================================
#
# Generates a report of banned IPs for analysis and potential reporting
# to abuse databases like AbuseIPDB.
#
# Usage:
#   ./report_banned_ips.sh
#
# Schedule via cron (weekly report):
#   0 8 * * 1 /path/to/report_banned_ips.sh
#
# =============================================================================

set -euo pipefail

# Configuration
REPORT_DIR="/var/www/myapp/logs"
REPORT_FILE="${REPORT_DIR}/banned_ips_report_$(date +%Y%m%d).txt"
FAIL2BAN_LOG="/var/log/fail2ban.log"

# Ensure report directory exists
mkdir -p "$REPORT_DIR"

# =============================================================================
# Generate Report
# =============================================================================

{
    echo "======================================="
    echo "BANNED IPS SECURITY REPORT"
    echo "======================================="
    echo "Generated: $(date)"
    echo "Hostname: $(hostname)"
    echo "======================================="
    echo ""

    # Currently banned IPs
    echo "=== CURRENTLY BANNED IPS ==="
    echo ""
    
    for jail in $(sudo fail2ban-client status 2>/dev/null | grep "Jail list" | sed 's/.*://;s/,//g'); do
        echo "--- Jail: $jail ---"
        sudo fail2ban-client status "$jail" 2>/dev/null | grep -E "Currently banned|Banned IP" || echo "  No data available"
        echo ""
    done

    # Historical bans (last 7 days)
    echo "=== BAN HISTORY (Last 7 Days) ==="
    echo ""
    
    if [[ -f "$FAIL2BAN_LOG" ]]; then
        sudo grep "Ban " "$FAIL2BAN_LOG" 2>/dev/null | tail -100 || echo "No ban history found"
    else
        echo "Log file not found: $FAIL2BAN_LOG"
    fi
    echo ""

    # Repeat offenders (for reporting to abuse databases)
    echo "=== REPEAT OFFENDERS (Report These!) ==="
    echo ""
    echo "Count | IP Address"
    echo "------|----------------"
    
    if [[ -f "$FAIL2BAN_LOG" ]]; then
        sudo grep "Ban " "$FAIL2BAN_LOG" 2>/dev/null | \
            awk '{print $NF}' | \
            sort | \
            uniq -c | \
            sort -rn | \
            head -20 || echo "No repeat offenders found"
    else
        echo "Log file not found"
    fi
    echo ""

    # Attack timeline
    echo "=== ATTACK TIMELINE (Last 24 Hours) ==="
    echo ""
    
    if [[ -f "$FAIL2BAN_LOG" ]]; then
        sudo grep "Ban " "$FAIL2BAN_LOG" 2>/dev/null | \
            grep "$(date +%Y-%m-%d)" || echo "No attacks today"
    else
        echo "Log file not found"
    fi
    echo ""

    # Reporting links
    echo "=== USEFUL LINKS FOR REPORTING ==="
    echo ""
    echo "AbuseIPDB:    https://www.abuseipdb.com/report"
    echo "Spamhaus:     https://www.spamhaus.org/lookup/"
    echo "IPVoid:       https://www.ipvoid.com/"
    echo "VirusTotal:   https://www.virustotal.com/gui/home/search"
    echo ""
    echo "======================================="
    echo "END OF REPORT"
    echo "======================================="

} > "$REPORT_FILE"

echo "✅ Report generated: $REPORT_FILE"

# =============================================================================
# Optional: Send report via email
# =============================================================================
# Uncomment and configure if you have mail set up:
#
# RECIPIENT="admin@example.com"
# SUBJECT="[Security] Weekly Banned IPs Report - $(hostname)"
# 
# if command -v mail &> /dev/null; then
#     mail -s "$SUBJECT" "$RECIPIENT" < "$REPORT_FILE"
#     echo "📧 Report sent to $RECIPIENT"
# fi

# =============================================================================
# Optional: Cleanup old reports (keep last 30 days)
# =============================================================================

find "$REPORT_DIR" -name "banned_ips_report_*.txt" -mtime +30 -delete 2>/dev/null || true
