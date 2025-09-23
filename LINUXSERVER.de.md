# LinuxServer.io Compliance Leitfaden

> 🇩🇪 **Deutsche Version** | 📖 **[English Version](LINUXSERVER.md)**

Dieses Dokument beschreibt, wie dieses Tandoor Recipes Docker Image vollständig mit LinuxServer.io Standards und Best Practices konform ist.

## ✅ Implementierte LinuxServer.io Standards

### S6 Overlay v3
- **✅ Vollständige S6 v3 Implementierung**
- **✅ Ordnungsgemäße Service-Abhängigkeiten**
- **✅ Standard-Init-Prozess**
- **✅ Django-spezifische Service-Kette**

### FILE__ Prefix Secrets
- **✅ Vollständige FILE__ Umgebungsvariablen-Unterstützung**
- **✅ Automatische Secret-Verarbeitung**
- **✅ Rückwärtskompatibilität mit Legacy-Secrets**
- **✅ Pfad-Validierung und -Bereinigung**

### Docker Mods Unterstützung
- **✅ DOCKER_MODS Umgebungsvariable**
- **✅ Unterstützung mehrerer Mods (Pipe-getrennt)**
- **✅ Standard-Mod-Installationsprozess**

### Custom Scripts & Services
- **✅ /custom-cont-init.d Unterstützung**
- **✅ /custom-services.d Unterstützung**
- **✅ Ordnungsgemäße Ausführungsreihenfolge**

### Benutzerverwaltung
- **✅ PUID/PGID Unterstützung**
- **✅ abc Benutzer (UID 911)**
- **✅ Dynamische Benutzer-ID-Änderungen**

### UMASK Unterstützung
- **✅ UMASK Umgebungsvariable**
- **✅ Standard UMASK=022**
- **✅ Angewandt auf alle Dateioperationen**

### Container Branding
- **✅ Custom Branding-Datei-Implementierung**
- **✅ LSIO_FIRST_PARTY=false gesetzt**
- **✅ Klare Unterscheidung von offiziellen LinuxServer.io Containern**
- **✅ Custom ASCII Art für "Mildman1848"**
- **✅ Ordnungsgemäße Support-Kanal-Verweise**

### OCI Manifest Lists & Multi-Architecture Pipeline
- **✅ OCI Image Manifest Specification v1.1.0 Konformität**
- **✅ LinuxServer.io Pipeline-Standards-Implementierung**
- **✅ Architektur-spezifische Tags (amd64-latest, arm64-latest)**
- **✅ Native Multi-Plattform-Builds (keine Emulation)**
- **✅ Matrix-basierte GitHub Actions Builds**
- **✅ Digest-Management und Artefakt-Sharing**

## 🏗️ Service-Struktur

### S6 Service-Kette
```
init-branding → init-secrets → init-tandoor-config → tandoor
```

### Service-Details

**init-branding**
- Custom Mildman1848 ASCII Art Anzeige
- Versionsinformations-Ausgabe
- Support-Kanal-Verweise

**init-secrets**
- FILE__ Prefix Umgebungsvariablen-Verarbeitung
- Docker Secrets Rückwärtskompatibilität
- Pfad-Validierung für Sicherheit

**init-tandoor-config**
- Django Konfiguration Setup
- Datenbankverbindungs-Validierung
- Statische Datei-Verzeichnis-Erstellung
- SECRET_KEY Generierung falls nicht bereitgestellt

**tandoor**
- Gunicorn WSGI Server Startup
- Django Migrationen
- Statische Datei-Sammlung
- Non-root Ausführung (Benutzer abc)

## 🔐 Sicherheits-Implementierung

### LinuxServer.io Sicherheitsstandards
- **✅ Non-root Ausführung**
- **✅ Capability Dropping**
- **✅ SecComp Profile**
- **✅ AppArmor Integration**
- **✅ Read-only Root-Filesystem-Unterstützung**

### Erweiterte Sicherheitsfeatures
- **✅ no-new-privileges Sicherheitsoption**
- **✅ Minimaler Capability-Set (CHOWN, DAC_OVERRIDE, FOWNER, SETGID, SETUID)**
- **✅ tmpfs Mounts für temporäre Daten**
- **✅ Ressourcenlimits (CPU, Speicher, PIDs)**

## 🔧 Umgebungsvariablen

### Standard LinuxServer.io Variablen
| Variable | Standard | Zweck |
|----------|----------|-------|
| `PUID` | `1000` | Benutzer-ID für Dateieigentum |
| `PGID` | `1000` | Gruppen-ID für Dateieigentum |
| `TZ` | `Etc/UTC` | Zeitzonenkonfiguration |
| `UMASK` | `022` | Dateierstellungsmaske |

### Tandoor-spezifische Variablen
| Variable | Standard | Zweck |
|----------|----------|-------|
| `SECRET_KEY` | | Django Secret Key |
| `DEBUG` | `False` | Django Debug-Modus |
| `ALLOWED_HOSTS` | `*` | Django erlaubte Hosts |
| `POSTGRES_HOST` | `db_recipes` | Datenbank-Hostname |
| `POSTGRES_DB` | `djangodb` | Datenbankname |
| `POSTGRES_USER` | `djangouser` | Datenbank-Benutzername |
| `POSTGRES_PASSWORD` | | Datenbank-Passwort |

### FILE__ Prefix Unterstützung
```bash
# Empfohlenes Secret-Management
FILE__SECRET_KEY=/run/secrets/tandoor_secret_key
FILE__POSTGRES_PASSWORD=/run/secrets/tandoor_postgres_password
FILE__POSTGRES_USER=/run/secrets/tandoor_postgres_user
```

## 📁 Volume-Struktur

### Standard LinuxServer.io Volumes
- `/config` - Anwendungskonfiguration und Logs
- `/app/mediafiles` - Benutzer-hochgeladene Inhalte
- `/app/staticfiles` - Anwendungs-statische Dateien

### Dateiberechtigungen
- Konfigurationsdateien: `640` (Besitzer lesen/schreiben, Gruppe lesen)
- Verzeichnisse: `750` (Besitzer lesen/schreiben/ausführen, Gruppe lesen/ausführen)
- Statische Dateien: `644` (Besitzer lesen/schreiben, Gruppe/andere lesen)

## 🐳 Container Labels

### OCI Standard Labels
```dockerfile
LABEL org.opencontainers.image.title="Tandoor Recipes"
LABEL org.opencontainers.image.description="Self-hosted recipe management server based on LinuxServer.io Alpine with S6 Overlay"
LABEL org.opencontainers.image.authors="mildman1848"
LABEL org.opencontainers.image.vendor="mildman1848"
LABEL org.opencontainers.image.licenses="AGPL-3.0"
LABEL org.opencontainers.image.source="https://github.com/mildman1848/tandoor"
```

### LinuxServer.io Kompatible Labels
```dockerfile
LABEL build_version="mildman1848 version:- ${VERSION} Build-date:- ${BUILD_DATE}"
LABEL maintainer="mildman1848"
```

## 🚀 CI/CD Pipeline

### GitHub Actions Integration
- **✅ Matrix-Builds für mehrere Architekturen**
- **✅ OCI Manifest List Erstellung**
- **✅ Security-Scanning (Trivy + CodeQL)**
- **✅ Dockerfile-Validierung (Hadolint)**
- **✅ SBOM-Generierung**

### Build-Prozess
```bash
# Multi-Architektur-Build
make build-manifest

# OCI-Konformitäts-Validierung
make validate-manifest

# Security-Scanning
make security-scan
```

## 📊 Health Checks

### Prozess-basierter Health Check
```dockerfile
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=5 \
    CMD ps aux | grep -v grep | grep "gunicorn" || exit 1
```

### Vorteile
- **Sicherheit**: Keine Authentifizierung erforderlich
- **Zuverlässigkeit**: Direkte Prozessüberwachung
- **Performance**: Schnelle Ausführung
- **Kompatibilität**: Funktioniert mit allen Deployment-Szenarien

## 🔗 Konformitäts-Verifizierung

### Automatisierte Tests
- **✅ S6 Service Startup-Validierung**
- **✅ FILE__ Prefix Secret-Verarbeitung**
- **✅ PUID/PGID Funktionalität**
- **✅ UMASK Anwendung**
- **✅ Docker Mods Unterstützung**

### Manuelle Verifizierungs-Befehle
```bash
# S6 Services prüfen
docker exec tandoor s6-rc -a list

# Benutzer-ID verifizieren
docker exec tandoor id abc

# Dateiberechtigungen prüfen
docker exec tandoor ls -la /config

# Umgebungsverarbeitung validieren
docker exec tandoor env | grep -E "(PUID|PGID|TZ|UMASK)"
```

## 📋 Unterschiede zu Standard LinuxServer.io

### Anpassungen
1. **Custom Branding**: Mildman1848 ASCII Art anstatt LinuxServer.io
2. **Erweiterte Sicherheit**: Zusätzliche Härtung über Standard hinaus
3. **Anwendungsspezifisch**: Django/Python Optimierungen
4. **Multi-Container**: PostgreSQL Datenbankintegration

### Beibehaltene Kompatibilität
- **✅ Alle LinuxServer.io Umgebungsvariablen**
- **✅ Alle LinuxServer.io Volume-Strukturen**
- **✅ Alle LinuxServer.io Service-Pattern**
- **✅ Alle LinuxServer.io Sicherheitsfeatures**

## 🆘 Support

Für LinuxServer.io Konformitätsprobleme:
- **Repository**: [mildman1848/tandoor](https://github.com/mildman1848/tandoor)
- **Issues**: [GitHub Issues](https://github.com/mildman1848/tandoor/issues)
- **Dokumentation**: Dieser Leitfaden und README-Dateien

**Hinweis**: Dies ist KEIN offizieller LinuxServer.io Container. Für offiziellen LinuxServer.io Support besuchen Sie [linuxserver.io](https://www.linuxserver.io/).

---

**Erstellt von Mildman1848** | Nach LinuxServer.io Standards