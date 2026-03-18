# Changelog

English: [CHANGELOG.md](CHANGELOG.md)

Alle wichtigen Änderungen am Tandoor-Container werden in dieser Datei dokumentiert.

## Unveröffentlicht

- CI- und Security-Workflows auf die aktuelle Tandoor-Basisversion `2.3.0` vereinheitlicht statt veralteter `2.2.x`-Build-Argumente.
- Trivy-Workflows auf `aquasecurity/trivy-action@0.35.0` aktualisiert und SARIF-Uploads gegen fehlende Scan-Ausgaben abgesichert.
- Das veraltete Hadolint-Ziel für `Dockerfile.aarch64` entfernt, da der aktive CI- und Publish-Pfad ARM64 bereits über das zentrale Multi-Platform-Dockerfile baut.
- Den Maintenance-Workflow so angepasst, dass keine doppelten automatischen Security-Audit-Issues mehr entstehen, wenn bereits ein passendes Issue offen ist.
