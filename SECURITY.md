# Security Policy

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| main    | :white_check_mark: |
| older   | :x:                |

We recommend always using the latest version from the `main` branch.

## Reporting a Vulnerability

We take security seriously. If you discover a security vulnerability, please report it responsibly.

### How to Report

**DO NOT** open a public GitHub issue for security vulnerabilities.

Instead, please email: **9m2pju@hamradio.my**

Include:
- Description of the vulnerability
- Steps to reproduce
- Potential impact
- Suggested fix (if any)

### What to Expect

1. **Acknowledgment**: We'll acknowledge receipt within 48 hours
2. **Assessment**: We'll assess the vulnerability within 7 days
3. **Fix**: Critical issues will be addressed as soon as possible
4. **Disclosure**: We'll coordinate disclosure timing with you

### Scope

This security policy covers:
- Docker configuration files
- Shell scripts (entrypoint.sh, etc.)
- docker-compose.yml configuration
- Documentation that could lead to insecure configurations

For vulnerabilities in DXSpider itself, please contact the DXSpider project maintainers directly.

## Security Best Practices

### For Users

#### 1. Protect Your .env File

```bash
# Never commit .env to version control
# Use .env.example as a template
cp .env.example .env
chmod 600 .env
```

#### 2. Use Strong Passwords

```bash
# Generate strong passwords
openssl rand -base64 32

# Set in .env
CLUSTER_DB_PASS=<strong-random-password>
CLUSTER_DB_ROOT_PWD=<different-strong-password>
```

#### 3. Restrict Network Access

```yaml
# In docker-compose.yml, bind to specific interface
ports:
  - "127.0.0.1:7300:7300"  # Only localhost
  - "192.168.1.100:7300:7300"  # Specific IP
```

#### 4. Use a Reverse Proxy

For production, use a reverse proxy with TLS:

```nginx
# nginx example
server {
    listen 443 ssl;
    server_name cluster.example.com;

    ssl_certificate /path/to/cert.pem;
    ssl_certificate_key /path/to/key.pem;

    location / {
        proxy_pass http://localhost:8050;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}
```

#### 5. Keep Updated

```bash
# Pull latest changes
git pull origin main

# Rebuild container
docker compose down
docker compose up -d --build
```

#### 6. Monitor Logs

```bash
# Watch for suspicious activity
docker compose logs -f | grep -i "error\|warning\|failed"
```

### For Developers

#### Container Security

- **No privileged mode**: We removed `privileged: true`
- **Non-root user**: Container runs as UID 1000
- **Resource limits**: CPU and memory constraints applied
- **Read-only where possible**: Consider `:ro` for config volumes

#### Credential Handling

- **No command-line credentials**: Use files or environment variables
- **Secure file permissions**: `chmod 600` for sensitive files
- **Clean up on exit**: Remove temporary credential files

#### Network Security

- **Minimal exposed ports**: Only expose what's needed
- **Network isolation**: Use Docker networks
- **No hardcoded IPs**: Use environment variables

## Security Features

### Current Security Measures

| Feature | Status | Description |
|---------|--------|-------------|
| Non-privileged container | ✅ | No `privileged: true` |
| Non-root user | ✅ | Runs as UID 1000 |
| Credential file protection | ✅ | ttyd creds in file with 600 perms |
| Resource limits | ✅ | CPU and memory constraints |
| Health checks | ✅ | Detect unhealthy containers |
| Graceful shutdown | ✅ | Signal handling implemented |
| .gitignore | ✅ | Prevents committing secrets |

### Planned Security Improvements

| Feature | Status | Description |
|---------|--------|-------------|
| TLS for telnet | 🔄 Planned | stunnel integration |
| HTTPS for web console | 🔄 Planned | Let's Encrypt support |
| Rate limiting | 🔄 Planned | Prevent brute force |
| Audit logging | 🔄 Planned | Security event logging |

## Known Security Considerations

### 1. Telnet is Unencrypted

DXSpider uses telnet (port 7300) which is unencrypted. For sensitive deployments:
- Use VPN for remote access
- Restrict to local network
- Consider stunnel for TLS wrapping

### 2. Web Console Authentication

The ttyd web console uses basic authentication. For production:
- Use a reverse proxy with proper authentication
- Enable HTTPS
- Consider IP whitelisting

### 3. Database Credentials

If using MariaDB:
- Use strong, unique passwords
- Don't expose database port externally
- Regular backups with encryption

## Vulnerability Disclosure Timeline

| Day | Action |
|-----|--------|
| 0 | Vulnerability reported |
| 1-2 | Acknowledgment sent |
| 3-7 | Assessment completed |
| 8-14 | Fix developed and tested |
| 15-21 | Fix released |
| 22-30 | Public disclosure (coordinated) |

Timeline may vary based on severity and complexity.

## Contact

- Security issues: 9m2pju@hamradio.my
- General issues: GitHub Issues
- Website: https://hamradio.my

---

Thank you for helping keep this project secure! 73
