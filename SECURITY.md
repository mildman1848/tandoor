# Security Policy

> 🇬🇧 **English Version** | 📖 **[Deutsche Version](SECURITY.de.md)**

This document outlines the security policies, practices, and vulnerability reporting procedures for the Tandoor Recipes Docker image.

## 🔒 Security Overview

This container implements comprehensive security hardening based on LinuxServer.io standards with additional enhancements for production environments.

### Security Architecture

- **Base Security**: LinuxServer.io Alpine 3.22 with S6 Overlay v3
- **Application Security**: Django/Python security best practices
- **Container Security**: Enhanced hardening with capability dropping
- **Network Security**: Configurable network isolation
- **Data Security**: Encrypted secrets management

## 🛡️ Security Features

### Container Security Hardening

#### Standard Security Features
- ✅ **Non-root execution** - All processes run as user `abc` (UID 911)
- ✅ **Capability dropping** - All capabilities dropped, minimal set added back
- ✅ **No new privileges** - Prevents privilege escalation
- ✅ **Read-only root filesystem** - Where possible
- ✅ **SecComp profiles** - System call filtering
- ✅ **AppArmor integration** - Additional access control

#### Enhanced Security Options
```yaml
# Automatic security hardening (docker-compose.override.yml)
security_opt:
  - no-new-privileges:true
  - apparmor=docker-default
cap_drop:
  - ALL
cap_add:
  - CHOWN
  - DAC_OVERRIDE
  - FOWNER
  - SETGID
  - SETUID
```

#### Resource Limits
```yaml
deploy:
  resources:
    limits:
      cpus: '2.0'
      memory: 1G
      pids: 200
```

### Secret Management

#### FILE__ Prefix Secrets (Recommended)
Secure secret management using LinuxServer.io FILE__ prefix standard:

```bash
# Environment variables pointing to secret files
FILE__SECRET_KEY=/run/secrets/tandoor_secret_key
FILE__POSTGRES_PASSWORD=/run/secrets/tandoor_postgres_password
FILE__POSTGRES_USER=/run/secrets/tandoor_postgres_user
```

#### Docker Secrets Integration
```yaml
secrets:
  tandoor_secret_key:
    file: ./secrets/tandoor_secret_key.txt
  tandoor_postgres_password:
    file: ./secrets/tandoor_postgres_password.txt
services:
  tandoor:
    secrets:
      - tandoor_secret_key
      - tandoor_postgres_password
```

#### Secret Generation
The project includes automatic secure secret generation:

```bash
# Generate secure secrets
make secrets-generate

# View secret status
make secrets-info

# Rotate secrets
make secrets-rotate
```

**Secret Specifications:**
- **Django SECRET_KEY**: 512-bit cryptographically secure random string
- **Database passwords**: 256-bit secure random strings
- **API keys**: 256-bit secure tokens
- **Storage**: Proper file permissions (600) and ownership

### Network Security

#### Port Binding
```yaml
# Secure localhost-only binding (recommended)
ports:
  - "127.0.0.1:8080:8080"

# Alternative: specific interface binding
ports:
  - "192.168.1.100:8080:8080"
```

#### Network Isolation
```yaml
# Custom bridge network for service isolation
networks:
  tandoor-network:
    driver: bridge
    ipam:
      config:
        - subnet: 172.20.0.0/16
```

### Application Security

#### Django Security Settings
- ✅ **DEBUG=False** in production
- ✅ **Secure cookie settings** (HTTPS only)
- ✅ **CSRF protection** enabled
- ✅ **Content Security Policy** headers
- ✅ **XSS protection** headers
- ✅ **Clickjacking protection**

#### Database Security
- ✅ **Encrypted connections** to PostgreSQL
- ✅ **Credential isolation** using secrets
- ✅ **Database user privileges** minimal required permissions
- ✅ **Connection pooling** with secure configurations

## 🔍 Vulnerability Management

### Security Scanning

The project includes comprehensive security scanning:

```bash
# Run all security scans
make security-scan

# Individual scan tools
make trivy-scan          # Container vulnerability scanning
make codeql-scan         # Static code analysis
```

#### Automated Scanning
- **GitHub Actions**: Automated security scans on every push
- **Trivy**: Container and filesystem vulnerability detection
- **CodeQL**: Static code analysis for security issues
- **Hadolint**: Dockerfile security best practices

#### Vulnerability Response
- **Critical**: Immediate patching within 24 hours
- **High**: Patching within 7 days
- **Medium**: Regular maintenance cycle (monthly)
- **Low**: Next major version

### Security Monitoring

#### Health Checks
```dockerfile
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=5 \
    CMD ps aux | grep -v grep | grep "gunicorn" || exit 1
```

#### Logging
- **Security events**: Authentication, authorization failures
- **Application logs**: Error tracking and monitoring
- **Container logs**: System-level security events
- **Audit logs**: File access and permission changes

## 🚨 Vulnerability Reporting

### Supported Versions

We provide security updates for the following versions:

| Version | Supported          |
| ------- | ------------------ |
| 1.5.x   | ✅ Yes            |
| 1.4.x   | ⚠️ Limited        |
| < 1.4   | ❌ No             |

### Reporting a Vulnerability

**For security vulnerabilities, please DO NOT open a public issue.**

#### Preferred Method: Private Security Advisory
1. Go to the [Security tab](https://github.com/mildman1848/tandoor/security) of this repository
2. Click "Report a vulnerability"
3. Fill out the security advisory form with detailed information

#### Alternative Method: Email
Send vulnerability reports to: **security@mildman1848.dev**

#### What to Include
- **Description**: Clear description of the vulnerability
- **Impact**: Potential security impact and affected components
- **Reproduction**: Step-by-step instructions to reproduce
- **Environment**: Container version, configuration details
- **Suggested Fix**: If you have ideas for remediation

#### Response Timeline
- **Acknowledgment**: Within 48 hours
- **Initial Assessment**: Within 7 days
- **Status Updates**: Weekly until resolved
- **Resolution**: Target 30 days for critical issues

### Security Advisory Process

1. **Report Received**: Security team acknowledges receipt
2. **Vulnerability Assessment**: Impact and severity evaluation
3. **Fix Development**: Patch development and testing
4. **Coordinated Disclosure**: Public advisory after fix is available
5. **Security Update**: New container image with fix released

## 🔐 Security Best Practices

### Deployment Security

#### Production Configuration
```yaml
# Use production security configuration
docker-compose -f docker-compose.yml -f docker-compose.production.yml up -d
```

#### Environment Hardening
- ✅ Use specific image tags, not `latest`
- ✅ Implement network segmentation
- ✅ Enable audit logging
- ✅ Regular security updates
- ✅ Monitor container behavior

#### Access Control
- ✅ **Principle of least privilege**: Minimal required permissions
- ✅ **Role-based access**: Django user roles and permissions
- ✅ **Strong authentication**: Complex passwords and 2FA where possible
- ✅ **Regular access review**: Periodic user and permission audits

### Secrets Management Best Practices

1. **Never commit secrets** to version control
2. **Use FILE__ prefix** for Docker secrets
3. **Rotate secrets regularly** (90-day cycle recommended)
4. **Monitor secret access** and usage
5. **Backup secrets securely** with encryption

### Database Security

1. **Use dedicated database user** with minimal privileges
2. **Enable connection encryption** (SSL/TLS)
3. **Regular database backups** with encryption
4. **Database access monitoring**
5. **Keep PostgreSQL updated** to latest secure version

## 📋 Security Checklist

### Before Deployment
- [ ] Review and customize `.env` configuration
- [ ] Generate secure secrets with `make secrets-generate`
- [ ] Configure network security (port binding, firewall)
- [ ] Enable production security hardening
- [ ] Set up monitoring and alerting
- [ ] Review user access and permissions

### Regular Maintenance
- [ ] Update container images monthly
- [ ] Rotate secrets quarterly
- [ ] Review access logs monthly
- [ ] Update dependencies regularly
- [ ] Perform security scans weekly
- [ ] Backup configurations and data

### Incident Response
- [ ] Monitor security alerts
- [ ] Have incident response plan
- [ ] Know how to isolate compromised containers
- [ ] Maintain forensic logging
- [ ] Test disaster recovery procedures

## 🔗 Security Resources

### Documentation
- [LinuxServer.io Security](https://www.linuxserver.io/blog/2019-09-14-customizing-our-containers)
- [Django Security](https://docs.djangoproject.com/en/stable/topics/security/)
- [Docker Security](https://docs.docker.com/engine/security/)
- [OWASP Container Security](https://owasp.org/www-project-docker-top-10/)

### Tools
- [Trivy](https://trivy.dev/) - Vulnerability scanner
- [Docker Bench](https://github.com/docker/docker-bench-security) - Security auditing
- [Hadolint](https://github.com/hadolint/hadolint) - Dockerfile linting

### Community
- [Tandoor Security Discussions](https://github.com/mildman1848/tandoor/discussions/categories/security)
- [LinuxServer.io Discord](https://discord.gg/YWrKVTn)

## 📜 Compliance

### Standards Compliance
- ✅ **CIS Docker Benchmark**: Container security guidelines
- ✅ **NIST Cybersecurity Framework**: Security controls implementation
- ✅ **OWASP Top 10**: Web application security risks mitigation
- ✅ **LinuxServer.io Standards**: Container best practices

### Licensing
This security policy is released under the same AGPL-3.0 license as the project.

---

**Last Updated**: September 2025
**Next Review**: December 2025

For questions about this security policy, please open a [discussion](https://github.com/mildman1848/tandoor/discussions) or contact the maintainers.