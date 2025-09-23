# Sicherheitsrichtlinie

> 🇩🇪 **Deutsche Version** | 📖 **[English Version](SECURITY.md)**

Dieses Dokument beschreibt die Sicherheitsrichtlinien, -praktiken und Verfahren zur Meldung von Sicherheitslücken für das Tandoor Recipes Docker Image.

## 🔒 Sicherheitsübersicht

Dieser Container implementiert umfassende Sicherheitshärtung basierend auf LinuxServer.io Standards mit zusätzlichen Verbesserungen für Produktionsumgebungen.

### Sicherheitsarchitektur

- **Basis-Sicherheit**: LinuxServer.io Alpine 3.22 mit S6 Overlay v3
- **Anwendungssicherheit**: Django/Python Sicherheits-Best-Practices
- **Container-Sicherheit**: Erweiterte Härtung mit Capability Dropping
- **Netzwerksicherheit**: Konfigurierbare Netzwerkisolation
- **Datensicherheit**: Verschlüsselte Secrets-Verwaltung

## 🛡️ Sicherheitsfeatures

### Container-Sicherheitshärtung

#### Standard-Sicherheitsfeatures
- ✅ **Non-root Ausführung** - Alle Prozesse laufen als Benutzer `abc` (UID 911)
- ✅ **Capability Dropping** - Alle Capabilities entfernt, minimaler Set wieder hinzugefügt
- ✅ **No new privileges** - Verhindert Privilege Escalation
- ✅ **Read-only Root-Dateisystem** - Wo möglich
- ✅ **SecComp Profile** - System Call Filterung
- ✅ **AppArmor Integration** - Zusätzliche Zugriffskontrolle

#### Erweiterte Sicherheitsoptionen
```yaml
# Automatische Sicherheitshärtung (docker-compose.override.yml)
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

#### Ressourcenlimits
```yaml
deploy:
  resources:
    limits:
      cpus: '2.0'
      memory: 1G
      pids: 200
```

### Secrets-Management

#### FILE__ Prefix Secrets (Empfohlen)
Sichere Secrets-Verwaltung mit LinuxServer.io FILE__ Prefix Standard:

```bash
# Umgebungsvariablen, die auf Secret-Dateien zeigen
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

#### Secret-Generierung
Das Projekt enthält automatische sichere Secret-Generierung:

```bash
# Sichere Secrets generieren
make secrets-generate

# Secret-Status anzeigen
make secrets-info

# Secrets rotieren
make secrets-rotate
```

**Secret-Spezifikationen:**
- **Django SECRET_KEY**: 512-bit kryptographisch sicherer zufälliger String
- **Datenbank-Passwörter**: 256-bit sichere zufällige Strings
- **API-Keys**: 256-bit sichere Token
- **Speicherung**: Ordnungsgemäße Dateiberechtigungen (600) und Eigentum

### Netzwerksicherheit

#### Port-Binding
```yaml
# Sichere Localhost-only Bindung (empfohlen)
ports:
  - "127.0.0.1:8080:8080"

# Alternative: spezifische Interface-Bindung
ports:
  - "192.168.1.100:8080:8080"
```

#### Netzwerkisolation
```yaml
# Benutzerdefiniertes Bridge-Netzwerk für Service-Isolation
networks:
  tandoor-network:
    driver: bridge
    ipam:
      config:
        - subnet: 172.20.0.0/16
```

### Anwendungssicherheit

#### Django Sicherheitseinstellungen
- ✅ **DEBUG=False** in Produktion
- ✅ **Sichere Cookie-Einstellungen** (nur HTTPS)
- ✅ **CSRF-Schutz** aktiviert
- ✅ **Content Security Policy** Header
- ✅ **XSS-Schutz** Header
- ✅ **Clickjacking-Schutz**

#### Datenbanksicherheit
- ✅ **Verschlüsselte Verbindungen** zu PostgreSQL
- ✅ **Credential-Isolation** mit Secrets
- ✅ **Datenbankbenutzer-Privilegien** minimal erforderliche Berechtigungen
- ✅ **Connection Pooling** mit sicheren Konfigurationen

## 🔍 Vulnerability Management

### Sicherheitsscanning

Das Projekt enthält umfassendes Sicherheitsscanning:

```bash
# Alle Sicherheitsscans ausführen
make security-scan

# Einzelne Scan-Tools
make trivy-scan          # Container-Vulnerability-Scanning
make codeql-scan         # Statische Code-Analyse
```

#### Automatisiertes Scanning
- **GitHub Actions**: Automatisierte Sicherheitsscans bei jedem Push
- **Trivy**: Container- und Dateisystem-Vulnerability-Erkennung
- **CodeQL**: Statische Code-Analyse für Sicherheitsprobleme
- **Hadolint**: Dockerfile-Sicherheits-Best-Practices

#### Vulnerability-Response
- **Critical**: Sofortige Behebung innerhalb von 24 Stunden
- **High**: Behebung innerhalb von 7 Tagen
- **Medium**: Regulärer Wartungszyklus (monatlich)
- **Low**: Nächste Hauptversion

### Sicherheitsmonitoring

#### Health Checks
```dockerfile
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=5 \
    CMD ps aux | grep -v grep | grep "gunicorn" || exit 1
```

#### Logging
- **Sicherheitsereignisse**: Authentifizierung, Autorisierungsfehler
- **Anwendungslogs**: Fehlererfassung und -überwachung
- **Container-Logs**: System-Level Sicherheitsereignisse
- **Audit-Logs**: Dateizugriff und Berechtigungsänderungen

## 🚨 Vulnerability-Meldung

### Unterstützte Versionen

Wir bieten Sicherheitsupdates für die folgenden Versionen:

| Version | Unterstützt        |
| ------- | ------------------ |
| 1.5.x   | ✅ Ja             |
| 1.4.x   | ⚠️ Begrenzt       |
| < 1.4   | ❌ Nein           |

### Meldung einer Sicherheitslücke

**Für Sicherheitslücken öffnen Sie bitte KEIN öffentliches Issue.**

#### Bevorzugte Methode: Private Security Advisory
1. Gehen Sie zum [Security-Tab](https://github.com/mildman1848/tandoor/security) dieses Repositories
2. Klicken Sie auf "Report a vulnerability"
3. Füllen Sie das Security Advisory Formular mit detaillierten Informationen aus

#### Alternative Methode: E-Mail
Senden Sie Vulnerability-Berichte an: **security@mildman1848.dev**

#### Was Sie einschließen sollten
- **Beschreibung**: Klare Beschreibung der Sicherheitslücke
- **Auswirkung**: Potenzielle Sicherheitsauswirkung und betroffene Komponenten
- **Reproduktion**: Schritt-für-Schritt-Anweisungen zur Reproduktion
- **Umgebung**: Container-Version, Konfigurationsdetails
- **Lösungsvorschlag**: Falls Sie Ideen zur Behebung haben

#### Response-Zeitplan
- **Bestätigung**: Innerhalb von 48 Stunden
- **Erste Bewertung**: Innerhalb von 7 Tagen
- **Status-Updates**: Wöchentlich bis zur Lösung
- **Lösung**: Ziel 30 Tage für kritische Probleme

### Security Advisory Prozess

1. **Bericht erhalten**: Security-Team bestätigt Erhalt
2. **Vulnerability-Bewertung**: Auswirkung und Schweregrad-Bewertung
3. **Fix-Entwicklung**: Patch-Entwicklung und -Test
4. **Koordinierte Offenlegung**: Öffentliche Bekanntgabe nach verfügbarem Fix
5. **Sicherheitsupdate**: Neues Container-Image mit Fix veröffentlicht

## 🔐 Sicherheits-Best-Practices

### Deployment-Sicherheit

#### Produktionskonfiguration
```yaml
# Produktions-Sicherheitskonfiguration verwenden
docker-compose -f docker-compose.yml -f docker-compose.production.yml up -d
```

#### Umgebungshärtung
- ✅ Spezifische Image-Tags verwenden, nicht `latest`
- ✅ Netzwerksegmentierung implementieren
- ✅ Audit-Logging aktivieren
- ✅ Regelmäßige Sicherheitsupdates
- ✅ Container-Verhalten überwachen

#### Zugriffskontrolle
- ✅ **Prinzip der geringsten Privilegien**: Minimal erforderliche Berechtigungen
- ✅ **Rollenbasierter Zugriff**: Django-Benutzerrollen und -Berechtigungen
- ✅ **Starke Authentifizierung**: Komplexe Passwörter und 2FA wo möglich
- ✅ **Regelmäßige Zugriffsprüfung**: Periodische Benutzer- und Berechtigungsaudits

### Secrets-Management Best Practices

1. **Niemals Secrets committen** in die Versionskontrolle
2. **FILE__ Prefix verwenden** für Docker Secrets
3. **Secrets regelmäßig rotieren** (90-Tage-Zyklus empfohlen)
4. **Secret-Zugriff überwachen** und Verwendung
5. **Secrets sicher sichern** mit Verschlüsselung

### Datenbanksicherheit

1. **Dedizierten Datenbankbenutzer verwenden** mit minimalen Privilegien
2. **Verbindungsverschlüsselung aktivieren** (SSL/TLS)
3. **Regelmäßige Datenbank-Backups** mit Verschlüsselung
4. **Datenbank-Zugriff überwachen**
5. **PostgreSQL aktuell halten** auf neueste sichere Version

## 📋 Sicherheits-Checkliste

### Vor Deployment
- [ ] `.env` Konfiguration überprüfen und anpassen
- [ ] Sichere Secrets mit `make secrets-generate` generieren
- [ ] Netzwerksicherheit konfigurieren (Port-Binding, Firewall)
- [ ] Produktions-Sicherheitshärtung aktivieren
- [ ] Monitoring und Alerting einrichten
- [ ] Benutzerzugriff und Berechtigungen überprüfen

### Regelmäßige Wartung
- [ ] Container-Images monatlich aktualisieren
- [ ] Secrets vierteljährlich rotieren
- [ ] Zugriffslogs monatlich überprüfen
- [ ] Dependencies regelmäßig aktualisieren
- [ ] Sicherheitsscans wöchentlich durchführen
- [ ] Konfigurationen und Daten sichern

### Incident Response
- [ ] Sicherheitswarnungen überwachen
- [ ] Incident Response Plan haben
- [ ] Wissen, wie kompromittierte Container isoliert werden
- [ ] Forensisches Logging aufrechterhalten
- [ ] Disaster Recovery Verfahren testen

## 🔗 Sicherheitsressourcen

### Dokumentation
- [LinuxServer.io Security](https://www.linuxserver.io/blog/2019-09-14-customizing-our-containers)
- [Django Security](https://docs.djangoproject.com/en/stable/topics/security/)
- [Docker Security](https://docs.docker.com/engine/security/)
- [OWASP Container Security](https://owasp.org/www-project-docker-top-10/)

### Tools
- [Trivy](https://trivy.dev/) - Vulnerability Scanner
- [Docker Bench](https://github.com/docker/docker-bench-security) - Security Auditing
- [Hadolint](https://github.com/hadolint/hadolint) - Dockerfile Linting

### Community
- [Tandoor Security Discussions](https://github.com/mildman1848/tandoor/discussions/categories/security)
- [LinuxServer.io Discord](https://discord.gg/YWrKVTn)

## 📜 Compliance

### Standards-Compliance
- ✅ **CIS Docker Benchmark**: Container-Sicherheitsrichtlinien
- ✅ **NIST Cybersecurity Framework**: Sicherheitskontroll-Implementierung
- ✅ **OWASP Top 10**: Webanwendungs-Sicherheitsrisiko-Mitigation
- ✅ **LinuxServer.io Standards**: Container-Best-Practices

### Lizenzierung
Diese Sicherheitsrichtlinie wird unter derselben AGPL-3.0 Lizenz wie das Projekt veröffentlicht.

---

**Zuletzt aktualisiert**: September 2025
**Nächste Überprüfung**: Dezember 2025

Für Fragen zu dieser Sicherheitsrichtlinie öffnen Sie bitte eine [Diskussion](https://github.com/mildman1848/tandoor/discussions) oder kontaktieren Sie die Maintainer.