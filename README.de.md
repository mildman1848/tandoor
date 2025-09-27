# Tandoor Recipes Docker Image

> 🇩🇪 **Deutsche Version** | 📖 **[English Version](README.md)**

![Build Status](https://github.com/mildman1848/tandoor/workflows/CI/badge.svg)
![Docker Pulls](https://img.shields.io/docker/pulls/mildman1848/tandoor)
![Docker Image Size](https://img.shields.io/docker/image-size/mildman1848/tandoor/latest)
![License](https://img.shields.io/github/license/mildman1848/tandoor)
![Version](https://img.shields.io/badge/version-2.2.6-blue)

🐳 **[Docker Hub: mildman1848/tandoor](https://hub.docker.com/r/mildman1848/tandoor)**

Ein production-ready Docker-Image für [Tandoor Recipes](https://github.com/TandoorRecipes/recipes) basierend auf dem LinuxServer.io Alpine Baseimage mit erweiterten Security-Features, automatischer Secret-Verwaltung, vollständiger LinuxServer.io Compliance und CI/CD-Integration.

## 🚀 Features

- ✅ **LinuxServer.io Alpine Baseimage 3.22** - Optimiert und sicher
- ✅ **S6 Overlay v3** - Professionelles Process Management
- ✅ **Vollständige LinuxServer.io Compliance** - FILE__ Secrets, Docker Mods, Custom Scripts
- ✅ **Enhanced Security Hardening** - Non-root execution, capability dropping, secure permissions
- ✅ **OCI Manifest Lists** - Echte Multi-Architecture Unterstützung nach OCI Standard
- ✅ **LinuxServer.io Pipeline** - Architecture-specific Tags + Manifest Lists
- ✅ **Multi-Platform Support** - AMD64, ARM64 mit nativer Performance
- ✅ **Advanced Health Checks** - Automatische Überwachung mit Failover
- ✅ **Robust Secret Management** - 512-bit JWT, 256-bit API Keys, sichere Rotation
- ✅ **Automated Build System** - Make + GitHub Actions CI/CD mit Manifest Validation
- ✅ **Environment Validation** - Umfassende Konfigurationsprüfung
- ✅ **Security Scanning** - Integrierte Vulnerability-Scans mit Trivy + CodeQL
- ✅ **OCI Compliance** - Standard-konforme Container Labels und Manifest Structure
- ✅ **Django/Python Support** - Virtual Environments, PostgreSQL Integration, Gunicorn WSGI
- ✅ **Multi-Container Setup** - Integrierte PostgreSQL Datenbank mit Health Check Dependencies

## 🚀 Quick Start

### Automatisiertes Setup (Empfohlen)

```bash
# Repository klonen
git clone https://github.com/mildman1848/tandoor.git
cd tandoor

# Komplettes Setup (Environment + Secrets)
make setup

# Container starten
docker-compose up -d
```

### Mit Docker Compose (Manuell)

```bash
# Repository klonen
git clone https://github.com/mildman1848/tandoor.git
cd tandoor

# Environment Template kopieren
cp .env.example .env

# Konfiguration bearbeiten
nano .env

# Tandoor Recipes mit PostgreSQL starten
docker-compose up -d

# Logs anzeigen
docker-compose logs -f
```

**🌐 Zugang:** http://localhost:8080

## 🐳 Docker Verwendung

### Quick Start

```bash
# Image herunterladen
docker pull mildman1848/tandoor:latest

# Mit PostgreSQL ausführen (docker-compose empfohlen)
docker run -d \
  --name tandoor \
  -p 8080:8080 \
  -v ./config:/config \
  -v ./mediafiles:/app/mediafiles \
  -v ./staticfiles:/app/staticfiles \
  -e SECRET_KEY="ihr-secret-key" \
  -e POSTGRES_PASSWORD="ihr-db-passwort" \
  mildman1848/tandoor:latest
```

### Docker Compose (Empfohlen)

```yaml
---
services:
  tandoor:
    image: mildman1848/tandoor:latest
    container_name: tandoor
    ports:
      - "127.0.0.1:8080:8080"
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Europe/Berlin
      - SECRET_KEY=ihr-secret-key
      - POSTGRES_HOST=db_recipes
      - POSTGRES_DB=djangodb
      - POSTGRES_USER=djangouser
      - POSTGRES_PASSWORD=ihr-db-passwort
    volumes:
      - ./config:/config
      - ./mediafiles:/app/mediafiles
      - ./staticfiles:/app/staticfiles
    depends_on:
      db_recipes:
        condition: service_healthy
    restart: unless-stopped

  db_recipes:
    image: postgres:16-alpine
    container_name: tandoor_db
    environment:
      - POSTGRES_DB=djangodb
      - POSTGRES_USER=djangouser
      - POSTGRES_PASSWORD=ihr-db-passwort
    volumes:
      - ./db:/var/lib/postgresql/data
    restart: unless-stopped
```

## 🔧 Konfiguration

### Umgebungsvariablen

| Variable | Standard | Beschreibung |
|----------|----------|--------------|
| `PUID` | `1000` | Benutzer-ID für Dateiberechtigungen |
| `PGID` | `1000` | Gruppen-ID für Dateiberechtigungen |
| `TZ` | `Etc/UTC` | Zeitzone |
| `SECRET_KEY` | | Django Secret Key (erforderlich) |
| `DEBUG` | `False` | Django Debug-Modus |
| `ALLOWED_HOSTS` | `*` | Django erlaubte Hosts |
| `POSTGRES_HOST` | `db_recipes` | PostgreSQL Hostname |
| `POSTGRES_DB` | `djangodb` | PostgreSQL Datenbankname |
| `POSTGRES_USER` | `djangouser` | PostgreSQL Benutzername |
| `POSTGRES_PASSWORD` | | PostgreSQL Passwort (erforderlich) |
| `GUNICORN_WORKERS` | `2` | Anzahl Gunicorn Worker |
| `GUNICORN_TIMEOUT` | `120` | Gunicorn Timeout in Sekunden |

### Volumes

| Pfad | Beschreibung |
|------|--------------|
| `/config` | Konfiguration und Logs |
| `/app/mediafiles` | Hochgeladene Media-Dateien (Rezepte, Bilder) |
| `/app/staticfiles` | Statische Dateien (CSS, JS, etc.) |

### Ports

| Port | Beschreibung |
|------|--------------|
| `8080` | Tandoor Recipes Web-Interface |

## 🔒 Security Features

### Enhanced Security Hardening

```yaml
# Automatische Security-Härtung (docker-compose.override.yml)
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
deploy:
  resources:
    limits:
      cpus: '2.0'
      memory: 1G
      pids: 200
```

### Secret-Management

**FILE__ Prefix Secrets (Empfohlen):**
```bash
# Umgebungsvariablen
FILE__SECRET_KEY=/run/secrets/tandoor_secret_key
FILE__POSTGRES_PASSWORD=/run/secrets/tandoor_postgres_password
```

**Docker Secrets:**
```yaml
secrets:
  tandoor_secret_key:
    file: ./secrets/tandoor_secret_key.txt
  tandoor_postgres_password:
    file: ./secrets/tandoor_postgres_password.txt
```

## 🏗️ Architektur

- **Base Image:** LinuxServer.io Alpine 3.22 mit S6 Overlay v3
- **Anwendung:** Tandoor Recipes 1.5.19 mit Django/Python
- **Datenbank:** PostgreSQL 16 Alpine
- **Web Server:** Gunicorn WSGI mit Nginx
- **Process Management:** S6 Overlay für professionelles Service Management
- **Security:** Enhanced Container Hardening mit Capability Dropping

### S6 Services

- `init-branding` - Custom Mildman1848 Branding
- `init-secrets` - FILE__ Prefix Secret Processing
- `init-tandoor-config` - Django Konfiguration und Setup
- `tandoor` - Haupt Gunicorn WSGI Application Server

## 🔧 Entwicklung

### Build aus Quellcode

```bash
# Repository klonen
git clone https://github.com/mildman1848/tandoor.git
cd tandoor

# Image bauen
make build

# Tests ausführen
make test

# Development Container starten
make dev
```

### Verfügbare Make-Befehle

```bash
make setup                  # Komplettes Initial Setup
make build                  # Docker Image bauen
make build-manifest         # Multi-Architecture Image bauen
make test                   # Umfassende Tests ausführen
make dev                    # Development Container starten
make security-scan          # Security-Scans durchführen
make start                  # Production Container starten
make stop                   # Container stoppen
make logs                   # Logs anzeigen
make shell                  # Container Shell-Zugang
```

## 📊 Multi-Platform Support

### OCI Manifest Lists

```bash
# Architecture-spezifische Downloads
docker pull mildman1848/tandoor:amd64-latest
docker pull mildman1848/tandoor:arm64-latest

# Automatische Platform-Auswahl
docker pull mildman1848/tandoor:latest
```

### Build-Prozess

```bash
# LinuxServer.io Pipeline Compliance
make build-manifest          # Manifest Lists erstellen
make inspect-manifest        # Manifest Struktur inspizieren
make validate-manifest       # OCI Compliance validieren
```

## 🚨 Problembehebung

### Häufige Probleme

**Container startet nicht:**
- Logs prüfen: `docker-compose logs tandoor`
- Umgebungsvariablen verifizieren
- PostgreSQL Health Status prüfen: `docker-compose ps`

**Datenbankverbindungsprobleme:**
- `POSTGRES_*` Umgebungsvariablen prüfen
- Database Container Health prüfen: `docker-compose ps db_recipes`
- Database Logs überprüfen: `docker-compose logs db_recipes`

**Berechtigungsfehler:**
- `PUID`/`PGID` in `.env` mit Ihrem Benutzer abgleichen
- Besitz korrigieren: `sudo chown -R $USER:$USER ./config ./mediafiles`

**Port-Konflikte:**
- `EXTERNAL_PORT` in `.env` ändern
- Port-Verwendung prüfen: `netstat -tlnp | grep :8080`

### Debug-Modus

```bash
# Debug-Logging aktivieren
echo "DEBUG=True" >> .env
echo "LOG_LEVEL=debug" >> .env
docker-compose restart
```

## 📋 Anforderungen

- Docker 20.10+
- Docker Compose 2.0+
- 2GB RAM mindestens
- 1GB freier Festplattenspeicher

## 🤝 Mitwirkung

1. Repository forken
2. Feature-Branch erstellen
3. Änderungen durchführen
4. Tests ausführen: `make test`
5. Pull Request einreichen

## 📄 Lizenz

Dieses Projekt steht unter der AGPL-3.0 Lizenz - siehe [LICENSE](LICENSE) Datei für Details.

## 🔗 Links

- **Tandoor Recipes:** https://github.com/TandoorRecipes/recipes
- **Dokumentation:** https://docs.tandoor.dev/
- **Docker Hub:** https://hub.docker.com/r/mildman1848/tandoor
- **LinuxServer.io:** https://www.linuxserver.io/
- **Support:** [Issues](https://github.com/mildman1848/tandoor/issues)

---

**Erstellt mit ❤️ von Mildman1848** | Basierend auf LinuxServer.io Standards