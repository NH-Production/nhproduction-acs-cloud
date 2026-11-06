# Existing VPS read-only audit checklist

Run only read-only commands during the audit. Do not paste passwords, private keys, tokens, full environment files or secret configuration values into chat.

Suggested commands:
```bash
hostnamectl
uptime
free -h
swapon --show
df -hT
ps aux --sort=-%mem | head -15
systemctl --type=service --state=running
systemctl --failed
ss -lntup
nginx -v
mongod --version
mariadb --version
go version
du -sh /var/www/gacs-dashboard /var/lib/mongodb /var/lib/mysql 2>/dev/null
systemctl status genieacs-cwmp genieacs-fs genieacs-nbi genieacs-ui --no-pager
```

Record OS/kernel, CPU, RAM/swap, disk, running services, listening ports, GenieACS versions/status, MongoDB/MariaDB health and current resource utilization. Redact public IPs if desired.

The audit must identify port conflicts before any proposed ingress allocation is activated. Historical outputs are not a substitute for a fresh audit.
