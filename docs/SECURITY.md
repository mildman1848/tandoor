# Security Standards und Best Practices

Dieses Dokument definiert die umfassenden Sicherheitsstandards für alle Mildman1848 Container-Projekte basierend auf aktuellen Docker Security Best Practices und LinuxServer.io Standards.

## 🔒 Überblick

Alle Container-Images müssen die folgenden Sicherheitsstandards erfüllen:
- **Zero Trust Ansatz** - Keine implizite Vertrauensstellung
- **Defense in Depth** - Mehrschichtige Sicherheit
- **Principle of Least Privilege** - Minimale notwendige Berechtigungen
- **Security by Design** - Sicherheit von Anfang an eingebaut

## 📋 Sicherheits-Checkliste

### Container-Sicherheit (Mandatory)

#### ✅ Non-Root Execution
```dockerfile
# Dockerfile
USER abc
```

```yaml
# docker-compose.yml
environment:
  - PUID=911
  - PGID=911
```

#### ✅ Capability Management
```yaml
# docker-compose.override.yml
cap_drop:
  - ALL
cap_add:
  - SETGID      # User switching (LinuxServer.io requirement)
  - SETUID      # User switching (LinuxServer.io requirement)
  - CHOWN       # File ownership management
  - DAC_OVERRIDE # File access (minimal)
```

#### ✅ Security Options
```yaml
security_opt:
  - no-new-privileges:true
  - apparmor=docker-default
  - seccomp=./security/seccomp-profile.json
```

#### ✅ Resource Limits
```yaml
deploy:
  resources:
    limits:
      cpus: '2.0'
      memory: 1G
      pids: 200
    reservations:
      cpus: '0.25'
      memory: 128M
```

#### ✅ Secure Temp Filesystems
```yaml
tmpfs:
  - /tmp:rw,noexec,nosuid,size=100m
  - /var/tmp:rw,noexec,nosuid,size=50m
  - /run:rw,noexec,nosuid,size=50m
```

### Secret Management (LinuxServer.io Standard)

#### ✅ FILE__ Prefix Support
```bash
# Environment Variable Definition
FILE__APPLICATION_PASSWORD=/run/secrets/app_password
FILE__APPLICATION_API_KEY=/run/secrets/app_api_key
FILE__APPLICATION_JWT_SECRET=/run/secrets/app_jwt_secret
```

#### ✅ S6 Service Implementation
```bash
#!/usr/bin/with-contenv bash
# Process FILE__ environment variables
for VAR in $(env | grep '^FILE__' | cut -d= -f1); do
    FILE_PATH=$(env | grep "^${VAR}=" | cut -d= -f2-)

    if [[ -f "${FILE_PATH}" && -r "${FILE_PATH}" ]]; then
        VAR_NAME=${VAR#FILE__}
        VAR_VALUE=$(cat "${FILE_PATH}")
        export "${VAR_NAME}=${VAR_VALUE}"
        echo "✓ Loaded secret: ${VAR_NAME}"
    fi
done
```

#### ✅ Secret Generation Standards
```bash
# Minimum Sicherheitsanforderungen
JWT_SECRET=$(openssl rand -base64 48)     # 512-bit JWT secrets
API_KEY=$(openssl rand -base64 32)        # 256-bit API keys
PASSWORD=$(openssl rand -base64 24)       # 192-bit passwords
```

#### ✅ Docker Secrets Support
```yaml
# docker-compose.yml
secrets:
  app_password:
    file: ./secrets/app_password.txt
  app_api_key:
    file: ./secrets/app_api_key.txt
```

### Network Security

#### ✅ Production Port Binding
```yaml
# docker-compose.production.yml
ports:
  - "127.0.0.1:${EXTERNAL_PORT}:${APPLICATION_PORT}"  # Localhost only
```

#### ✅ Custom Network Configuration
```yaml
networks:
  default:
    name: ${APPLICATION_NAME}_network
    driver: bridge
    driver_opts:
      com.docker.network.bridge.enable_icc: "false"
      com.docker.network.bridge.host_binding_ipv4: "127.0.0.1"
```

### File System Security

#### ✅ Read-Only Volumes
```yaml
# Production
volumes:
  - ./config:/config:ro,Z     # Read-only config
  - ./data:/data:rw,Z         # Read-write data only where needed
```

#### ✅ Secure File Permissions
```bash
# S6 Service Script
UMASK=${UMASK:-027}  # Restrictive permissions
umask "$UMASK"

# Set secure permissions
find /config -type d -exec chmod 750 {} \;
find /config -type f -exec chmod 640 {} \;
```

## 🛡️ Vulnerability Management

### Mandatory Scanning Pipeline

#### ✅ Trivy Container Scanning
```yaml
# .github/workflows/security.yml
- name: Run Trivy vulnerability scanner
  uses: aquasecurity/trivy-action@master
  with:
    image-ref: '${{ env.IMAGE_NAME }}:latest'
    format: 'sarif'
    output: 'trivy-results.sarif'
```

#### ✅ CodeQL Static Analysis
```yaml
- name: Initialize CodeQL
  uses: github/codeql-action/init@v3
  with:
    languages: 'javascript'
    queries: security-extended,quality
```

#### ✅ Secret Scanning
```yaml
- name: TruffleHog OSS
  uses: trufflesecurity/trufflehog@main
  with:
    path: ./
    extra_args: --debug --only-verified
```

### Security Standards Enforcement

#### ✅ Zero CRITICAL Vulnerabilities
- **Produktion:** Keine CRITICAL Vulnerabilities erlaubt
- **Development:** Maximum 5 HIGH Vulnerabilities
- **Monitoring:** Tägliche Scans aktiviert

#### ✅ SBOM Generation
```yaml
- name: Generate SBOM
  uses: anchore/sbom-action@v0
  with:
    path: ./
    format: spdx-json
```

## 🔍 Security Monitoring

### Automated Security Checks

#### ✅ Security Hardening Verification
```bash
# Verify non-root execution
USER_CHECK=$(docker exec container whoami)
if [ "$USER_CHECK" = "root" ]; then
    echo "SECURITY VIOLATION: Container running as root!"
    exit 1
fi

# Verify capabilities
docker exec container cat /proc/self/status | grep Cap

# Verify no-new-privileges
docker inspect container | jq '.[0].HostConfig.SecurityOpt'
```

#### ✅ Docker Bench Security
```bash
# Run Docker Bench for Security
git clone https://github.com/docker/docker-bench-security.git
cd docker-bench-security
sudo sh docker-bench-security.sh -c container_images
```

### Security Metrics

#### ✅ Required Metrics
- **CVE Count:** Anzahl Vulnerabilities nach Schweregrad
- **CVSS Score:** Durchschnittlicher CVSS Score
- **Patch Time:** Zeit bis zur Behebung von Vulnerabilities
- **Compliance Score:** Einhaltung der Security Standards

## 🚨 Incident Response

### Security Incident Workflow

#### 🔴 CRITICAL Vulnerabilities
1. **Sofort:** Container aus Produktion entfernen
2. **1 Stunde:** Security Team benachrichtigen
3. **4 Stunden:** Patch verfügbar oder Workaround implementiert
4. **24 Stunden:** Vollständige Behebung und Tests

#### 🟡 HIGH Vulnerabilities
1. **24 Stunden:** Assessment und Patch-Plan
2. **72 Stunden:** Patch implementiert und getestet
3. **1 Woche:** Deployment in Produktion

### Notification Channels

#### ✅ GitHub Security Tab
- SARIF Upload für alle Scans
- Automatische Issue-Erstellung
- Security Advisory Integration

#### ✅ Automated Alerts
```yaml
# Security notification workflow
notify-security-results:
  if: always() && (needs.container-security.result == 'failure')
  steps:
    - name: Notify on security issues
      run: |
        echo "⚠️ Security vulnerabilities detected!"
        # Add Slack/Discord/Email notifications here
```

## 📚 Security Documentation Requirements

### Mandatory Documentation

#### ✅ Security Architecture
- **Threat Model:** Identifizierte Bedrohungen und Mitigations
- **Security Controls:** Implementierte Sicherheitsmaßnahmen
- **Risk Assessment:** Bewertung verbleidender Risiken

#### ✅ Operational Security
- **Deployment Guidelines:** Sichere Deployment-Praktiken
- **Monitoring Setup:** Security Monitoring Konfiguration
- **Incident Procedures:** Schritt-für-Schritt Incident Response

#### ✅ Compliance Documentation
- **Audit Trail:** Nachvollziehbare Sicherheitsmaßnahmen
- **Compliance Mapping:** Zuordnung zu relevanten Standards
- **Certification Status:** Status von Security Zertifizierungen

## 🔄 Security Update Process

### Upstream Monitoring

#### ✅ Automated Dependency Monitoring
```yaml
# .github/workflows/upstream-monitor.yml
- name: Check Security Advisories
  run: |
    APP_ADVISORIES=$(curl -s "https://api.github.com/repos/app/repo/security-advisories")
    LSIO_ADVISORIES=$(curl -s "https://api.github.com/repos/linuxserver/docker-baseimage-alpine/security-advisories")
```

#### ✅ Update Prioritization
1. **Security Updates:** Höchste Priorität
2. **Critical Bugs:** Hohe Priorität
3. **Feature Updates:** Normale Priorität
4. **Documentation:** Niedrige Priorität

### Testing Requirements

#### ✅ Security Test Suite
```bash
# Mandatory security tests before deployment
make validate           # Dockerfile linting
make build             # Image build verification
make security-scan     # Comprehensive security scan
make test              # Functional testing
```

## 🎯 Security Goals und KPIs

### Quantitative Ziele

#### ✅ Vulnerability Metrics
- **Zero CRITICAL** in Production (100%)
- **< 5 HIGH** Vulnerabilities pro Image
- **< 24h** Mean Time To Patch (MTTP)
- **100%** Scan Coverage

#### ✅ Compliance Metrics
- **100%** Security Checklist Compliance
- **100%** Automated Scan Coverage
- **100%** Documentation Compliance
- **> 95%** Security Test Success Rate

### Continuous Improvement

#### ✅ Monthly Reviews
- Security Metrics Review
- Threat Model Updates
- Process Improvements
- Tool Evaluations

#### ✅ Quarterly Assessments
- External Security Audit
- Penetration Testing
- Compliance Review
- Training Updates

---

## 📖 Referenzen

### Primary Security Sources
- **Docker Security:** https://docs.docker.com/engine/security/
- **CIS Docker Benchmark:** https://www.cisecurity.org/benchmark/docker
- **NIST Container Security:** https://csrc.nist.gov/publications/detail/sp/800-190/final
- **OWASP Container Security:** https://cheatsheetseries.owasp.org/cheatsheets/Docker_Security_Cheat_Sheet.html

### LinuxServer.io Standards
- **Security Guidelines:** https://github.com/linuxserver/docker-baseimage-alpine/blob/master/README.md
- **S6 Overlay Security:** https://github.com/just-containers/s6-overlay/tree/v3-docs

### Security Tools
- **Trivy:** https://trivy.dev/
- **CodeQL:** https://docs.github.com/en/code-security/codeql-cli
- **Docker Bench:** https://github.com/docker/docker-bench-security
- **TruffleHog:** https://github.com/trufflesecurity/trufflehog

**Letzte Aktualisierung:** 2025-09-22
**Nächste Review:** 2025-10-22
**Version:** 1.0.0-security