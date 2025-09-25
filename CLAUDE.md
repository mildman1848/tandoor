# CLAUDE.md - LinuxServer.io Container Template Standards

Diese Datei definiert standardisierte Richtlinien für Claude Code (claude.ai/code) zur Erstellung von Container-Images basierend auf LinuxServer.io Standards mit umfassender Sicherheitshärtung.

## 🎯 Template-Übersicht

Dieses Template standardisiert die Erstellung von benutzerdefinierten Docker-Images basierend auf LinuxServer.io Alpine Baseimages, nach 2024 LinuxServer.io Pipeline-Standards.

**Kern-Technologien:**
- **Base:** LinuxServer.io Alpine 3.22+ mit S6 Overlay v3
- **Architektur:** OCI Manifest Lists mit nativem Multi-Platform Support (AMD64, ARM64)
- **Sicherheit:** Erweiterte Container-Härtung, Capability-Management, Secrets-Verwaltung
- **Compliance:** Vollständige LinuxServer.io Standard-Konformität (FILE__ Secrets, Docker Mods, Custom Scripts)
- **Pipeline:** 2024 LinuxServer.io Pipeline-Standards mit architekturspezifischen Tags

## 📚 Dokumentationsanforderungen

**Sprach-Richtlinie:** Alle Projekte müssen zweisprachige Dokumentation (Englisch/Deutsch) mit Querverweisen pflegen:
- `README.md` / `README.de.md`
- `LINUXSERVER.md` / `LINUXSERVER.de.md` (optional)
- `SECURITY.md` / `SECURITY.de.md` (optional)

**Querverweis-Format:**
```markdown
🇩🇪 **Deutsche Version:** [README.de.md](README.de.md)
🇺🇸 **English Version:** [README.md](README.md)
```

## 🔒 Sicherheitsarchitektur-Standards

### Verpflichtende Docker Security-Implementierung

**Quelle:** [Docker Security Best Practices](https://docs.docker.com/engine/security/)
**Aktualisierungscheck:** Monatliche Überprüfung der offiziellen Docker-Sicherheitsdokumentation

Alle Projekte implementieren umfassende Docker-Sicherheitsbestpraktiken:

**Automatische Sicherheitshärtung (docker-compose.override.yml):**
```yaml
# VERPFLICHTEND für alle Projekte
security_opt:
  - no-new-privileges:true
  - apparmor=docker-default
  - seccomp=./security/seccomp-profile.json
cap_drop:
  - ALL
cap_add:
  - SETGID      # Benutzerumschaltung (LinuxServer.io Anforderung)
  - SETUID      # Benutzerumschaltung (LinuxServer.io Anforderung)
  - CHOWN       # Dateiberechtigungen
  - DAC_OVERRIDE  # Dateizugriff (minimal)
deploy:
  resources:
    limits:
      cpus: '2.0'
      memory: 1G
      pids: 200
ports:
  - "127.0.0.1:${EXTERNAL_PORT}:${APPLICATION_PORT}"  # Localhost-only Binding (KRITISCH für Security)
tmpfs:
  - /tmp:noexec,nosuid,size=50M
  - /var/tmp:noexec,nosuid,size=50M
```

**Produktions-Sicherheit (docker-compose.production.yml):**
```yaml
# Maximale Sicherheit für Produktionsumgebungen
read_only: true
tmpfs:
  - /tmp:noexec,nosuid,size=50M,mode=1777
  - /run:noexec,nosuid,size=50M,mode=755
volumes:
  - ./config:/config:ro  # Read-only wo möglich
networks:
  - name: ${APPLICATION_NAME}_network
    driver: bridge
    internal: false
```

**Container-Härtung (Dockerfile Standards):**
```dockerfile
# VERPFLICHTEND für alle Dockerfiles
USER abc
EXPOSE ${APPLICATION_PORT}
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=5 \
  CMD ${APPLICATION_SPECIFIC_HEALTH_CHECKS}
WORKDIR /app
```

**Capability-Management (Erforderlich):**
```yaml
# docker-compose.override.yml
cap_drop:
  - ALL
cap_add:
  - SETGID    # Benutzerumschaltung
  - SETUID    # Benutzerumschaltung
  - CHOWN     # Dateiberechtigungen
  - DAC_OVERRIDE  # Dateizugriff (minimal)
```

### Secret-Management (LinuxServer.io Standard)

**Quelle:** [LinuxServer.io Secrets Dokumentation](https://github.com/linuxserver/docker-baseimage-alpine)

**Bevorzugte Methode - FILE__ Prefix:**
```bash
# Umgebungsvariablen
FILE__APP_PASSWORD=/run/secrets/app_password
FILE__APP_API_KEY=/run/secrets/app_api_key
FILE__APP_JWT_SECRET=/run/secrets/app_jwt_secret
```

**Service-Implementierung:**
```bash
# init-secrets Service Template
#!/usr/bin/with-contenv bash

# Verarbeitet FILE__ prefixe Secrets (LinuxServer.io Standard)
for VAR in $(env | grep '^FILE__' | cut -d= -f1); do
    FILE_PATH=$(env | grep "^${VAR}=" | cut -d= -f2-)

    if [[ -f "${FILE_PATH}" && -r "${FILE_PATH}" ]]; then
        VAR_NAME=${VAR#FILE__}
        VAR_VALUE=$(cat "${FILE_PATH}")
        export "${VAR_NAME}=${VAR_VALUE}"
        echo "✓ Secret geladen: ${VAR_NAME}"
    fi
done
```

**Secret-Generierung-Standards:**
```bash
# Mindest-Sicherheitsanforderungen
JWT_SECRET=$(openssl rand -base64 48)     # 512-bit JWT Secrets
API_KEY=$(openssl rand -base64 32)        # 256-bit API Keys
DB_PASSWORD=$(openssl rand -base64 24)    # 192-bit DB Passwords
SESSION_SECRET=$(openssl rand -base64 32) # 256-bit Session Secrets
```

## 🔧 Build und Development-Standards

### Essential Make Commands (Standardisiert für alle Projekte)

**Quelle:** [LinuxServer.io Build Standards](https://github.com/linuxserver/pipeline-templates)
**Aktualisierungscheck:** Monatliche Überprüfung der LinuxServer.io Pipeline-Updates

```bash
# Setup and Initial Configuration
make setup                    # Complete initial setup (creates .env + generates secrets)
make env-setup               # Create .env from .env.example template
make secrets-generate        # Generate secure secrets (512-bit JWT, 256-bit API keys)

# Build and Test (Enhanced with OCI Manifest Lists)
make build                   # Build Docker image for current platform
make build-multiarch         # Build multi-architecture image (Legacy)
make build-manifest          # LinuxServer.io style Manifest Lists (Recommended)
make inspect-manifest        # Inspect manifest lists (Multi-arch details)
make validate-manifest       # Validate OCI manifest compliance
make test                    # Run comprehensive container tests with health checks
make validate               # Validate Dockerfile with hadolint
make security-scan          # Run comprehensive security scan (Trivy + CodeQL)
make trivy-scan              # Run Trivy vulnerability scan only
make codeql-scan             # Run CodeQL static code analysis
make security-scan-detailed  # Run detailed security scan with exports

# LinuxServer.io Baseimage Management (2025-09-25)
make baseimage-check        # Check for LinuxServer.io baseimage updates
make baseimage-test         # Test new LinuxServer.io baseimage version
make baseimage-update       # Update to latest LinuxServer.io baseimage

# Container Management (Improved)
make start                  # Start container using docker-compose
make stop                   # Stop running containers
make restart                # Stop and restart containers
make status                 # Show container status and health
make logs                   # Show container logs
make shell                  # Get shell access to running container

# Development
make dev                    # Build and run development container

# Environment Management (Enhanced)
make env-validate           # Validate .env configuration (enhanced checks)
make secrets-info           # Show current secrets status with details
make secrets-rotate         # Rotate secrets (with backup and stronger encryption)
make secrets-clean          # Clean up old secret backups
```

### Docker Compose Operations (Standardisiert)

```bash
# Standard operations
docker-compose up -d                         # Start in detached mode
docker-compose up -d ${APPLICATION_NAME}     # Start only main service
docker-compose logs -f                       # Follow logs
```

## 🏗️ Architecture Overview (LinuxServer.io S6 Overlay)

### S6 Overlay Services Structure (Template-Standard)

**⚠️ KRITISCH: S6 Service Bundle Konfiguration**

**Häufiger Fehler:** Services starten nicht, weil sie nicht im S6 User Bundle enthalten sind.

**Lösung:** IMMER sicherstellen, dass der Hauptservice in der User-Bundle-Konfiguration enthalten ist:
```
root/etc/s6-overlay/s6-rc.d/user/contents.d/{APPLICATION_NAME}
```

**Debugging:** Wenn Services nicht starten, prüfen Sie:
1. Service ist in `user/contents.d/` enthalten
2. Dependencies sind korrekt definiert
3. Service-Scripts sind ausführbar

Alle Container verwenden S6 Overlay v3 mit folgender Service-Abhängigkeitskette:

```
init-branding → init-mods-package-install → init-custom-files → init-secrets → init-{app}-config → {app}
```

**Service-Locations:** `root/etc/s6-overlay/s6-rc.d/`

**Standard-Services (Template):**
- `init-branding`: Mildman1848 ASCII Art Branding (standardisiert)
- `init-secrets`: Enhanced FILE__ prefix processing mit Pfad-Validierung
- `init-{app}-config`: Anwendungsspezifische Konfiguration und Validierung
- `{app}`: Haupt-Anwendungsservice mit Health Check Integration

**Standard-Implementierung (Recent Best Practices):**
- ✅ **chmod Permission Fixes**: Sichere Fallback-Methoden für Berechtigungen
- ✅ **Enhanced FILE__ Secret Processing**: Pfad-Sanitization und Validierung
- ✅ **Error Handling**: Verbesserte Fehlerbehandlung in allen Services
- ✅ **Configuration Validation**: Automatische Konfigurations-Validierung
- ✅ **Health Check Integration**: Process-basierte Health Checks ohne Authentication
- ✅ **Logging Optimization**: Reduzierte unnecessary Warnings

### Security Architecture (Erweitert)

**Container Security (Erweiterte Standards):**
- Non-root execution (user `abc`, UID 911)
- Security hardening mit `no-new-privileges`
- Capability dropping (ALL dropped, minimal added)
- Read-only where possible mit tmpfs mounts

**Secret Management (Enhanced Standards):**
- **Preferred:** LinuxServer.io FILE__ prefix secrets mit path validation
- **Encryption:** 512-bit JWT secrets, 256-bit API keys
- **Legacy:** Docker Swarm secrets support (backward compatible)
- **Generated secrets:** JWT, API keys, database credentials, session secrets
- **Security:** Automatic backup, rotation, and cleanup capabilities

**Vulnerability Management (2024/2025 Standards):**
- **Trivy Scanning:** Container und filesystem vulnerability detection
- **CodeQL Analysis:** Static code analysis für security issues
- **npm Security:** Comprehensive package vulnerability patches
- **Advanced Nested Fixes:** Intelligent replacement system für vulnerable nested dependencies
- **Production Status:** Zero CRITICAL vulnerabilities, minimal remaining risk
- **Automation:** GitHub Actions integration für continuous security scanning

### OCI Manifest Lists & LinuxServer.io Pipeline (2024 Standards)

**Multi-Architecture Implementation (Template-Standard):**
- **OCI Compliance:** Full OCI Image Manifest Specification v1.1.0 support
- **LinuxServer.io Style:** Architecture-specific tags + Manifest Lists
- **Native Builds:** No emulation - true platform-specific images
- **GitHub Actions:** Matrix-based builds mit digest management

**Architecture Tags (LinuxServer.io Standard-Template):**
```bash
# Architecture-specific pulls
docker pull mildman1848/${APPLICATION_NAME}:amd64-latest
docker pull mildman1848/${APPLICATION_NAME}:arm64-latest

# Automatic platform selection
docker pull mildman1848/${APPLICATION_NAME}:latest
```

**Build Process (Template-Standard):**
```bash
# LinuxServer.io Pipeline compliance
make build-manifest          # Create manifest lists with arch tags
make inspect-manifest        # Inspect OCI manifest structure
make validate-manifest       # Validate OCI compliance
```

## 🔄 Development Workflow (Standardisiert)

### Setting Up Development Environment

1. **Initial Setup:**
   ```bash
   make setup              # Creates .env and generates secrets
   ```

2. **Environment Customization:**
   - Edit `.env` file for local paths and settings
   - Ensure `PUID`/`PGID` match your user: `id -u && id -g`

3. **Development Container:**
   ```bash
   make dev               # Builds and runs with development volumes
   ```

### Making Changes (Template-Standard)

**For S6 Services:** Edit files in `root/etc/s6-overlay/s6-rc.d/`
**For Build Process:** Modify `Dockerfile` and `Makefile`
**For Configuration:** Update `.env.example` and `docker-compose.yml`

**Testing Changes (Enhanced mit Manifest Support):**
```bash
make validate           # Dockerfile linting with hadolint
make build             # Build new image for current platform
make build-manifest    # Build LinuxServer.io style multi-arch with manifest lists
make inspect-manifest  # Inspect manifest structure and platform details
make validate-manifest # Validate OCI manifest compliance
make test              # Run comprehensive integration tests
make security-scan     # Comprehensive security validation (Trivy + CodeQL)
make trivy-scan        # Trivy vulnerability scanning only
make codeql-scan       # CodeQL static code analysis
make status            # Check container health and status
```

**Application-Specific Testing Process (Template-Anpassung):**
Die `make test` Kommando führt umfassende Validierung durch:
1. **Container Startup** - Creates test directories and starts container with proper volumes
2. **Health Check** - Validates application process is running with `ps aux | grep ${APPLICATION_NAME}`
3. **Binary Test** - Verifies `${APPLICATION_NAME} --version` command works inside container
4. **Container Verification** - Confirms container is healthy and running
5. **Cleanup** - Automatically stops container and removes test directories

**⚠️ CRITICAL PUSH WORKFLOW REQUIREMENTS (Template-Standard):**
Before pushing changes to GitHub, ALWAYS follow this sequence:
1. **Build Image:** `make build` - Verify image builds successfully
2. **Test Container:** `make test` - Ensure application starts and interface is accessible
3. **Only push if:** Both build and test complete successfully with clean logs
4. **Never push** broken or non-functional versions to repository

### CI/CD Integration (Template-Standard)

**GitHub Actions Workflows:** (`.github/workflows-template/`)
- `ci.template.yml`: Automated testing and validation
- `docker-publish.template.yml`: Enhanced OCI manifest lists mit LinuxServer.io pipeline standards
- `security.template.yml`: Security scanning and SBOM generation
- `codeql.template.yml`: CodeQL static code analysis für JavaScript/TypeScript
- `upstream-monitor.template.yml`: Automated upstream dependency monitoring mit issue creation
- `release.template.yml`: Automated release management mit docker publishing trigger

**Enhanced Docker Publish Workflow (Template-Features):**
- **Matrix Builds:** Separate jobs for each platform (amd64, arm64)
- **Digest Management:** Platform images pushed by digest mit artifact sharing
- **Manifest Creation:** OCI-compliant manifest lists mit architecture-specific tags
- **LinuxServer.io Style:** Architecture tags (`amd64-latest`, `arm64-latest`)
- **Validation:** Manifest structure inspection and OCI compliance verification

**Upstream Monitoring Workflow (Template-Standard):**
- **Schedule:** Monday and Thursday at 6 AM UTC
- **Application Monitoring:** GitHub API release tracking mit automated issue creation
- **Base Image Monitoring:** LinuxServer.io baseimage-alpine 3.22 series tracking
- **Security Assessment:** Prioritizes security-related updates
- **Semi-Automated:** Creates GitHub issues for manual review and action

## 🛠️ Common Development Patterns (Template-Standards)

### Adding New Environment Variables

1. Add to `.env.template` mit documentation
2. Reference in `docker-compose.template.yml` environment section
3. Handle in relevant S6 service script
4. Update both README.md and README.de.md if user-facing (maintain bilingual documentation)

### Modifying Container Startup

- Main application logic: `root/etc/s6-overlay/s6-rc.d/{app}/run`
- Configuration setup: `root/etc/s6-overlay/s6-rc.d/init-{app}-config/up`
- Secret processing: `root/etc/s6-overlay/s6-rc.d/init-secrets/up`

### Security Best Practices (Template-Requirements)

**⚠️ KRITISCHE Sicherheitseinstellungen:**
1. **Host Binding:** PORT auf 127.0.0.1 beschränken (`HOST=127.0.0.1`)
2. **Authentication:** NO_AUTH=false als Standard (nie deaktivieren in Produktion)
3. **S6 Service Bundle:** Hauptservice MUSS in `user/contents.d/` enthalten sein

- All secrets should use FILE__ prefix when possible
- Validate input parameters in S6 scripts
- Use `s6-setuidgid abc` for non-root execution
- Set proper file permissions (750 for config, 600 for secrets)

## 🚨 Troubleshooting (Comprehensive Template Guide)

### Common Issues (Standard Solutions)

**Permission errors:**
- Check PUID/PGID in `.env` - should match your user (`id -u && id -g`)
- Verify directory ownership: `sudo chown -R $USER:$USER ./config ./data`
- Use secure fallback methods in S6 services

**Port conflicts:**
- Modify EXTERNAL_PORT in `.env` (default varies by application)
- Check if port is already in use: `netstat -tlnp | grep :PORT`
- Use `docker-compose down` before changing ports

**Secret errors:**
- Run `make secrets-generate` to create initial secrets
- Check `make secrets-info` für current secrets status
- Verify FILE__ prefix paths exist and are readable
- Enhanced validation mit path sanitization

**Health check failures:**
- Check application startup logs: `make logs`
- Verify configuration files are properly created
- Use process-based health checks avoiding authentication requirements
- Extended health check intervals (30s start period, 15s interval, 5 retries)

**Container startup issues:**
- Validate environment variables: `make env-validate`
- Check S6 service dependency chain
- Review init services logs für configuration errors
- Application-specific startup validation

**Docker workflow failures:**
- Verify GHCR_TOKEN permissions (write:packages, read:packages)
- Check GitHub Actions secrets configuration
- Review workflow syntax and matrix configurations
- Proper error handling in cleanup steps

**Build failures:**
- Run `make validate` für Dockerfile linting
- Check for conflicting environment variables
- Verify base image availability and versions
- Review multi-platform build compatibility

**Debug Mode (Template-Standard):**
```bash
# Enable debug logging
echo "LOG_LEVEL=debug" >> .env
echo "DEBUG_MODE=true" >> .env
make restart
```

## 📄 File Structure (Template-Standard)

```
${APPLICATION_NAME}/
├── Dockerfile                 # Multi-stage container build (von .template erstellt)
├── Makefile                   # Build und development automation (von .template erstellt)
├── docker-compose.yml         # Service orchestration mit secrets (von .template erstellt)
├── .env                       # Configuration (von .env.template erstellt)
├── root/                      # Container filesystem overlay
│   └── etc/s6-overlay/s6-rc.d/  # S6 service definitions
├── .github/workflows/         # CI/CD automation (von workflows-template erstellt)
├── docs/                      # Documentation
│   ├── README.md             # English documentation
│   ├── README.de.md          # German documentation
│   └── SECURITY.md           # Security documentation
└── config/                   # Runtime configuration (created by make setup)
    ├── cache/               # Application cache
    └── logs/               # Application logs
```

## 🚀 Template-Verwendung (Schritt-für-Schritt)

### Neues Projekt erstellen

1. **Template klonen:**
   ```bash
   git clone https://github.com/mildman1848/template.git myapp
   cd myapp
   ```

2. **Template-Variablen ersetzen:**
   ```bash
   find . -type f -name "*.template*" -exec sed -i 's/${APPLICATION_NAME}/myapp/g' {} \;
   find . -type f -name "*.template*" -exec sed -i 's/${APPLICATION_NAME_UPPER}/MYAPP/g' {} \;
   find . -type f -name "*.template*" -exec sed -i 's/${APPLICATION_DESCRIPTION}/My Application/g' {} \;
   find . -type f -name "*.template*" -exec sed -i 's/${DEFAULT_VERSION}/1.0.0/g' {} \;
   find . -type f -name "*.template*" -exec sed -i 's/${DEFAULT_PORT}/8080/g' {} \;
   find . -type f -name "*.template*" -exec sed -i 's/${APPLICATION_PORT}/8080/g' {} \;
   find . -type f -name "*.template*" -exec sed -i 's/${DEFAULT_MODE}/server/g' {} \;
   find . -type f -name "*.template*" -exec sed -i 's/${UPSTREAM_REPO}/upstream\/repo/g' {} \;
   ```

3. **Template-Dateien umbenennen:**
   ```bash
   for file in $(find . -name "*.template*"); do
     mv "$file" "${file//.template/}"
   done
   ```

4. **Projekt initialisieren:**
   ```bash
   make setup
   make build
   make test
   ```

### Vollständige Template-Variable Referenz

**Standard-Variablen (erforderlich):**
- `${APPLICATION_NAME}` - Name der Anwendung (z.B. "myapp")
- `${APPLICATION_NAME_UPPER}` - Großbuchstaben-Name (z.B. "MYAPP")
- `${APPLICATION_DESCRIPTION}` - Beschreibung der Anwendung
- `${DEFAULT_VERSION}` - Standard-Anwendungsversion
- `${DEFAULT_PORT}` - Standard-Port
- `${APPLICATION_PORT}` - Interner Anwendungsport
- `${DEFAULT_MODE}` - Standard-Betriebsmodus
- `${UPSTREAM_REPO}` - Upstream Repository (z.B. "org/repo")

**Anwendungsspezifische Variablen (anpassen):**
- `${APPLICATION_SPECIFIC_HEALTH_CHECKS}` - Anwendungsspezifische Health Checks
- `${APPLICATION_SPECIFIC_SERVICE_TESTS}` - Anwendungsspezifische Service-Tests
- `${APPLICATION_SPECIFIC_SECURITY_CHECKS}` - Anwendungsspezifische Security Checks
- `${APPLICATION_SPECIFIC_VALIDATION}` - Anwendungsspezifische Validierung

## 📊 Wartungsplan (Template-Aktualisierung)

### Monatliche Aufgaben

- [ ] LinuxServer.io Baseimage-Updates prüfen
- [ ] Security-Tools Updates (Trivy, CodeQL, Hadolint)
- [ ] GitHub Actions Versionen aktualisieren
- [ ] Docker Security Best Practices Review

### Quartalsweise Aufgaben

- [ ] Security Best Practices Updates
- [ ] CI/CD Pipeline Optimierung
- [ ] Performance Benchmarks durchführen
- [ ] Dokumentations-Review

## 📖 Referenzen und Aktualisierungsrichtlinien

### Primäre Quellen (Monatlich überwachen)

**LinuxServer.io:**
- **Dokumentation:** https://docs.linuxserver.io/
- **Baseimage Repository:** https://github.com/linuxserver/docker-baseimage-alpine
- **S6 Overlay:** https://github.com/just-containers/s6-overlay
- **Pipeline Standards:** https://github.com/linuxserver/pipeline-templates

**Docker & Container Security:**
- **Docker Security:** https://docs.docker.com/engine/security/
- **OCI Standards:** https://github.com/opencontainers/image-spec
- **GitHub Actions:** https://docs.github.com/en/actions

### Security Tools (Monatlich auf Updates prüfen)

**Scanning Tools:**
- **Trivy:** https://trivy.dev/
- **CodeQL:** https://docs.github.com/en/code-security/codeql-cli
- **Hadolint:** https://github.com/hadolint/hadolint
- **TruffleHog:** https://github.com/trufflesecurity/trufflehog

### Compliance Standards (Quartalsweise überwachen)

**Security Frameworks:**
- **NIST Container Security:** https://csrc.nist.gov/publications/detail/sp/800-190/final
- **CIS Docker Benchmark:** https://www.cisecurity.org/benchmark/docker
- **OWASP Container Security:** https://cheatsheetseries.owasp.org/cheatsheets/Docker_Security_Cheat_Sheet.html

## ⚠️ KRITISCHE VERSION-MANAGEMENT ERKENNTNISSE (2025-09-24)

### VERPFLICHTENDE UPSTREAM-VERSION-PRÜFUNG

**🚨 CRITICAL LESSON: Verwendung veralteter Versionen führt zu tagelangen Debugging-Zyklen**

Das Tandoor-Projekt verwendete Version 1.5.19 (veraltet), während die aktuelle Version 2.2.4 ist. Dies führte zu:
- 2 Tage verschwendete Debugging-Zeit
- Komplexe webpack-loader Probleme, die in der aktuellen Version gar nicht existieren
- Unnötige workarounds für bereits gelöste Probleme

**NEUE VERPFLICHTENDE REGEL:**
```bash
# VOR JEDEM PROJEKT-START - IMMER AKTUELLE VERSION PRÜFEN
make version-check    # Muss implementiert werden in allen Projekten
```

### Automatisierte Version-Validierung (VERPFLICHTEND)

**Alle Projekte MÜSSEN folgende Prüfungen haben:**

1. **GitHub Release API Check:**
   ```bash
   CURRENT_VERSION=$(curl -s https://api.github.com/repos/${UPSTREAM_REPO}/releases/latest | jq -r '.tag_name')
   LOCAL_VERSION=${APPLICATION_VERSION}
   if [[ "$CURRENT_VERSION" != "$LOCAL_VERSION" ]]; then
     echo "⚠️ WARNING: Using outdated version $LOCAL_VERSION, latest is $CURRENT_VERSION"
     echo "Consider updating before proceeding"
   fi
   ```

2. **Pre-Build Version Check:**
   ```makefile
   version-check:
   	@echo "Checking upstream version..."
   	@LATEST=$$(curl -s https://api.github.com/repos/${UPSTREAM_REPO}/releases/latest | jq -r '.tag_name'); \
   	if [ "$$LATEST" != "${APPLICATION_VERSION}" ]; then \
   		echo "⚠️  OUTDATED: Using ${APPLICATION_VERSION}, latest is $$LATEST"; \
   		echo "Update recommended before building"; \
   	else \
   		echo "✅ Using latest version: ${APPLICATION_VERSION}"; \
   	fi
   ```

3. **Makefile Integration:**
   ```makefile
   build: version-check
   	# Build continues only after version check
   ```

## 🔄 Tandoor Version Migration (2.2.4) - Lessons Learned

### ERFOLGREICHE MIGRATION VON 1.5.19 → 2.2.4

**✅ FUNDAMENTAL ARCHITECTURE CHANGES IDENTIFIED:**

Das Tandoor-Projekt durchlief massive Architektur-Änderungen zwischen Versionen:

**Django Database Migration Issues:**
- ✅ **Fehlende Migrations:** `python manage.py migrate` war nicht im Startup-Prozess enthalten
- ✅ **Database Wait Logic:** Implementiert pg_isready-basierte Wartelogik für PostgreSQL
- ✅ **218 Migrations erfolgreich:** Vollständige Datenbank-Schema-Initialisierung
- ✅ **Error Handling:** Robuste Fehlerbehandlung für DB-Verbindungsprobleme

**Django Static Files & Vue.js Integration:**
- ✅ **collectstatic Fix:** `python manage.py collectstatic --noinput --clear` hinzugefügt
- ✅ **webpack-stats.json:** Vollständige Vue.js Bundle-Unterstützung erstellt
- ✅ **442 Static Files:** Korrekte Asset-Sammlung und -bereitstellung
- ✅ **JavaScript Bundle Support:** recipe_search_view, recipe_view, recipe_edit, etc.

**Container Environment & Secrets:**
- ✅ **Environment Variable Loading:** Direkte Variablen als Workaround für S6-Probleme
- ✅ **DEBUG Mode:** Aktiviert für Debugging (DEBUG=1 in docker-compose.yml)
- ✅ **Secret Loading:** FILE__ prefix + fallback zu direkten Werten
- ✅ **Django Settings:** Korrekte DJANGO_SETTINGS_MODULE Konfiguration

**S6 Overlay Service-Struktur Vervollständigt:**
- ✅ **Fehlende Standard-Services:** init-adduser, init-custom-files, init-mods-package-install
- ✅ **Service Dependencies:** Korrekte Abhängigkeitskette nach LinuxServer.io Standards
- ✅ **User Bundle Fix:** Alle Services in user/contents.d/ korrekt registriert
- ✅ **Service Types:** Alle auf 'oneshot' gesetzt für korrekte Initialisierung

### Django-Container Best Practices (Lessons Learned)

**⚠️ KRITISCHE DJANGO-ANFORDERUNGEN:**

1. **Database Migrations sind VERPFLICHTEND:**
   ```bash
   # In S6 Service (z.B. tandoor/run)
   echo "Migrating database..."
   s6-setuidgid abc /app/venv/bin/python manage.py migrate
   ```

2. **Database Wait Logic Essential:**
   ```bash
   # PostgreSQL readiness check
   while ! pg_isready --host=${POSTGRES_HOST} --port=${POSTGRES_PORT} --user=${POSTGRES_USER} -q; do
       echo "Waiting for database..."
       sleep 5
   done
   ```

3. **Static Files Collection Required:**
   ```bash
   # Django static files
   s6-setuidgid abc /app/venv/bin/python manage.py collectstatic --noinput --clear
   ```

4. **Vue.js/Webpack Integration for Modern Django:**
   ```bash
   # Comprehensive webpack-stats.json creation
   cat > /app/vue/webpack-stats.json << 'EOF'
   {
     "status": "done",
     "publicPath": "/static/vue/",
     "chunks": {
       "app": [{"name": "app.js", "publicPath": "/static/js/app.js"}],
       "recipe_search_view": [{"name": "recipe_search_view.js", "publicPath": "/static/js/recipe_search_view.js"}]
     }
   }
   EOF
   ```

### Container-Funktionalität Validierung (2025-09-24)

**✅ VOLLSTÄNDIGE FUNKTIONSPRÜFUNG BESTANDEN:**

- ✅ **Container Startup:** Sauberer Start ohne Fehler oder Service-Failures
- ✅ **S6 Services:** Alle 6 Services (init-branding → init-mods-package-install → init-custom-files → init-secrets → init-tandoor-config → tandoor) laufen korrekt
- ✅ **LinuxServer.io Branding:** Korrekte Anzeige mit Original Project Attribution
- ✅ **Database Connectivity:** PostgreSQL-Verbindung erfolgreich etabliert
- ✅ **Django Migrations:** 218 Migrations erfolgreich angewendet
- ✅ **Static Files:** 442 Dateien korrekt gesammelt und bereitgestellt
- ✅ **WebUI Accessibility:** HTTP 200/302 Responses, Login-Form korrekt angezeigt
- ✅ **Health Checks:** Container meldet "healthy" Status
- ✅ **Asset Loading:** CSS, JS, und Image-Assets laden korrekt
- ✅ **Django Settings:** Debug-Modus funktional, Konfiguration validiert

**Setup-Prozess Funktioniert:**
- ✅ **Fresh Installation:** Login-Seite wird korrekt angezeigt
- ✅ **User Workflow:** Setup-Prozess erreichbar für Ersteinrichtung
- ✅ **Asset Pipeline:** Vue.js-Integration funktional
- ✅ **Database Schema:** Vollständig initialisiert und bereit

### Performance & Optimierung

**Container Build Optimierungen:**
- ✅ **Multi-stage Build:** Effiziente Layer-Nutzung
- ✅ **Dependency Caching:** Verbesserte Build-Zeiten
- ✅ **Asset Generation:** Automated webpack-stats.json creation
- ✅ **Permission Management:** Korrekte abc:abc Ownership

**Runtime Optimierungen:**
- ✅ **Gunicorn Configuration:** 2 Workers, 120s Timeout
- ✅ **Static File Serving:** Effiziente Asset-Bereitstellung
- ✅ **Database Connection Pooling:** PostgreSQL-optimiert
- ✅ **Memory Management:** Angemessene Container-Limits

### Troubleshooting Guide (Django-spezifisch)

**Häufige Django-Container Probleme:**

1. **HTTP 500 auf WebUI → Migrations prüfen:**
   ```bash
   docker-compose logs tandoor | grep -i migration
   # Sollte "218 migrations applied" zeigen
   ```

2. **Asset Loading Failures → webpack-stats.json prüfen:**
   ```bash
   docker-compose exec tandoor cat /app/vue/webpack-stats.json
   # Sollte vollständige Bundle-Definition enthalten
   ```

3. **Database Connection Errors → Wait Logic prüfen:**
   ```bash
   docker-compose logs tandoor | grep -i "database"
   # Sollte "✓ Database is ready" zeigen
   ```

4. **Static Files 404 → collectstatic prüfen:**
   ```bash
   docker-compose logs tandoor | grep -i "static"
   # Sollte "442 static files" o.ä. zeigen
   ```

**Debug-Kommandos:**
```bash
# Django Debug Mode aktivieren
echo "DEBUG=1" >> .env
docker-compose restart tandoor

# Service Status prüfen
docker-compose exec tandoor s6-rc -u list

# Django Settings validieren
docker-compose exec tandoor /app/venv/bin/python manage.py check
```

---

## 🔧 CI/CD Workflow Standardisierung (2025-09-25)

### GitHub Actions Workflow Updates

**✅ KRITISCHE CI WORKFLOW FIXES:**

Das Tandoor-Projekt hatte spezifische CI-Workflow-Probleme, die behoben wurden:

**Docker Compose Installation Fix:**
- ✅ **Legacy v2.21.0 Problem:** Fehlgeschlagene Download-URLs in GitHub Actions
- ✅ **Solution:** Migration zu native Docker Compose Plugin
- ✅ **Implementation:** Alle `docker-compose` Befehle zu `docker compose` geändert
- ✅ **Result:** CI builds laufen jetzt zuverlässig

**DockerHub Manifest Dependency Elimination:**
- ✅ **Problem:** CI tests versuchten auf nicht-existierende DockerHub images zuzugreifen
- ✅ **Solution:** `IMAGE_TAG=test` environment variable für lokale Builds
- ✅ **Implementation:** Alle CI docker-compose tests verwenden lokal gebaute images
- ✅ **Result:** Keine Abhängigkeit mehr von externen Docker registries in CI

**Hadolint Configuration:**
- ✅ **DL3007 Warning:** `FROM ghcr.io/tandoorrecipes/recipes:latest` → `FROM ghcr.io/tandoorrecipes/recipes:2.2.5`
- ✅ **Ignore Directives:** LinuxServer.io spezifische Requirements ausgenommen
- ✅ **Result:** Saubere Hadolint validation ohne false positives

**Version Updates (2.2.4 → 2.2.5):**
- ✅ **Tandoor Recipes:** Updated zu latest stable version
- ✅ **Container Branding:** Version strings aktualisiert
- ✅ **CI References:** Alle Dockerfile und workflow references aligned

### Baseimage Testing Integration (2025-09-25)

**LinuxServer.io Baseimage Update System:**
- ✅ **Automated Testing Script:** `scripts/baseimage-update-test.sh` implementiert
- ✅ **Make Integration:** `make baseimage-check`, `make baseimage-test`, `make baseimage-update`
- ✅ **Version Detection:** API-basierte neueste Baseimage-Version Detection
- ✅ **Container Validation:** Comprehensive build and runtime tests
- ✅ **Security Scanning:** Trivy integration für baseimage updates
- ✅ **Rollback Support:** Automatisches Rollback bei failed tests

**CI Workflow Standardisierung (Alle Projekte):**
```yaml
# Standardized across audiobookshelf, rclone, tandoor
- name: Setup Docker Compose
  run: |
    sudo apt-get update
    sudo apt-get install -y docker-compose-plugin
    docker compose version

- name: Test docker-compose configuration
  run: |
    IMAGE_TAG=test docker compose config --quiet
    IMAGE_TAG=test docker compose up -d --wait
```

### .gitignore/.dockerignore Updates (2025-09-25)

**Enhanced Artifact Management:**
```gitignore
# Baseimage testing (2025-09-25)
BASEIMAGE_UPDATE_REPORT.md
baseimage-test-*.log
baseimage-test-*.json
```

**Benefits:**
- ✅ **Workflow Consistency:** Alle drei Projekte verwenden identische CI patterns
- ✅ **Reliability:** Eliminierte external dependency failures
- ✅ **Maintenance:** Automated baseimage update testing
- ✅ **Security:** Comprehensive vulnerability scanning in CI

---

**Letzte Aktualisierung:** 2025-09-25
**Nächste Review:** 2025-10-25
**Template Version:** 2.2.0
**Tandoor Status:** ✅ Vollständig Funktionsfähig mit CI/CD Standardisierung

*Für Fragen zu diesem Template oder Verbesserungsvorschläge, erstelle bitte ein Issue im Template-Repository.*