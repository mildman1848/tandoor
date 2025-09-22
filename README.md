# LinuxServer.io Container Template Standards

**🇩🇪 Deutsche Version:** [README.de.md](README.de.md)

This repository provides standardized templates and patterns for creating secure, production-ready Docker containers based on LinuxServer.io standards with comprehensive security hardening.

## 🎯 Purpose

Create consistent, secure, and maintainable container images for all Mildman1848 projects following industry best practices and LinuxServer.io standards.

## 🏗️ Architecture

- **Base:** LinuxServer.io Alpine Baseimage with S6 Overlay v3
- **Security:** Comprehensive Docker security hardening
- **Multi-Platform:** OCI Manifest Lists (AMD64, ARM64)
- **CI/CD:** Automated GitHub Actions workflows
- **Scanning:** Comprehensive security scans (Trivy + CodeQL)

## 📁 Template Structure

```
template/
├── CLAUDE.md                    # Claude Code guidance and standards
├── README.md                    # This file (English)
├── README.de.md                 # German documentation
├── templates/                   # Template files for new projects
│   ├── Dockerfile.template      # Generalized Dockerfile
│   ├── Makefile.template        # Build system template
│   ├── docker-compose.template.yml         # Service orchestration
│   ├── docker-compose.override.template.yml # Security hardening
│   ├── docker-compose.production.template.yml # Production config
│   ├── .env.template           # Environment variables template
│   └── root/etc/s6-overlay/s6-rc.d/        # S6 service templates
├── .github/workflows/           # CI/CD workflow templates
│   ├── ci.template.yml
│   ├── docker-publish.template.yml
│   ├── security.template.yml
│   ├── codeql.template.yml
│   └── upstream-monitor.template.yml
├── docs/                        # Documentation
│   ├── SECURITY.md             # Security standards
│   ├── DEVELOPMENT.md          # Development guidelines
│   └── DEPLOYMENT.md           # Deployment standards
└── examples/                    # Example implementations
    ├── webapp-example/
    ├── daemon-example/
    └── database-example/
```

## 🚀 Quick Start

### Creating a New Project

1. **Copy Template Structure:**
   ```bash
   cp -r template/ my-new-project/
   cd my-new-project/
   ```

2. **Customize Templates:**
   ```bash
   # Replace template variables with your application specifics
   find templates/ -type f -exec sed -i 's/${APPLICATION_NAME}/myapp/g' {} \;
   find templates/ -type f -exec sed -i 's/${APPLICATION_DESCRIPTION}/My Application/g' {} \;
   # ... continue with other variables
   ```

3. **Generate Project Files:**
   ```bash
   # Copy customized templates to project root
   cp templates/Dockerfile.template ./Dockerfile
   cp templates/Makefile.template ./Makefile
   cp templates/docker-compose.template.yml ./docker-compose.yml
   # ... continue with other files
   ```

4. **Initialize Project:**
   ```bash
   make setup              # Creates .env and generates secrets
   make build              # Build Docker image
   make test               # Run tests
   ```

## 🔒 Security Standards

All projects must implement:

### Container Security
- ✅ Non-root execution (user `abc`, UID 911)
- ✅ Capability dropping (ALL dropped, minimal added)
- ✅ Security hardening (`no-new-privileges`, AppArmor, Seccomp)
- ✅ Resource limits (CPU, memory, PIDs)
- ✅ tmpfs mounts for temporary data

### Secret Management
- ✅ LinuxServer.io FILE__ prefix secrets
- ✅ 512-bit JWT secrets minimum
- ✅ 256-bit API keys minimum
- ✅ Automatic rotation capabilities

### Vulnerability Management
- ✅ Zero CRITICAL vulnerabilities in production
- ✅ Weekly automated security scans
- ✅ Monthly dependency reviews
- ✅ Automated security patch notifications

## 🛠️ Build System Standards

### Required Make Targets

```bash
make help                    # Show available targets
make setup                   # Complete initial setup
make build                   # Single-platform build
make build-manifest          # Multi-arch build with OCI manifests
make test                    # Comprehensive container tests
make security-scan           # Trivy + CodeQL scans
make validate               # Dockerfile linting
make secrets-generate        # Generate secure secrets
make start                  # Start container
make stop                   # Stop container
```

### Environment Configuration

All projects use standardized `.env` structure:

```bash
# === Container Configuration ===
PUID=1000
PGID=1000
TZ=Europe/Berlin
UMASK=022

# === Application Configuration ===
APPLICATION_MODE=default
EXTERNAL_PORT=8080
APPLICATION_LOG_LEVEL=INFO

# === Security Configuration ===
# Use FILE__ prefix for secrets
FILE__APPLICATION_PASSWORD=/run/secrets/app_password
```

## 🔄 CI/CD Pipeline Standards

### Required Workflows

1. **CI Pipeline** (`ci.yml`)
   - Dockerfile linting
   - Multi-platform builds
   - Integration tests
   - Security scans

2. **Docker Publish** (`docker-publish.yml`)
   - Multi-arch builds with OCI manifests
   - LinuxServer.io style architecture tags
   - GHCR and Docker Hub publishing
   - SBOM generation

3. **Security Scanning** (`security.yml`)
   - Daily vulnerability scans
   - CodeQL static analysis
   - Secret detection
   - Docker Bench Security

4. **Upstream Monitoring** (`upstream-monitor.yml`)
   - Dependency update detection
   - Security advisory monitoring
   - Automated issue creation

## 📋 Development Guidelines

### Project Initialization Checklist

- [ ] Copy and customize templates
- [ ] Run `make setup` for initial configuration
- [ ] Update `PUID`/`PGID` to match host user
- [ ] Create bilingual documentation (English/German)
- [ ] Configure GitHub repository secrets
- [ ] Test build and deployment pipeline

### Code Quality Requirements

- **Dockerfile:** Pass hadolint validation
- **Security:** Zero CRITICAL vulnerabilities
- **Testing:** All integration tests pass
- **Documentation:** Complete and up-to-date

### Testing Standards

```bash
# Pre-commit validation
make validate           # Dockerfile linting
make build             # Image build verification
make test              # Integration tests
make security-scan     # Security validation
```

## 🎯 Quality Assurance

### Security Metrics

- **Zero CRITICAL** vulnerabilities in production
- **< 5 HIGH** vulnerabilities per image
- **< 24h** mean time to patch (MTTP)
- **100%** scan coverage

### Release Process

1. ✅ All tests pass
2. ✅ Security scans clean
3. ✅ Documentation updated
4. ✅ Multi-arch manifests created
5. ✅ Registry upload successful
6. ✅ Release notes generated

## 📚 Documentation Standards

### Required Documentation

1. **Bilingual README** (English/German)
2. **Security architecture** documentation
3. **API documentation** (if applicable)
4. **Deployment guide**
5. **Troubleshooting guide**

### Cross-Reference Format

```markdown
🇩🇪 **Deutsche Version:** [README.de.md](README.de.md)
🇺🇸 **English Version:** [README.md](README.md)
```

## 🔗 Important Sources

### LinuxServer.io Standards
- **Documentation:** https://docs.linuxserver.io/
- **Baseimage:** https://github.com/linuxserver/docker-baseimage-alpine
- **S6 Overlay:** https://github.com/just-containers/s6-overlay
- **🔄 Update Check:** Monthly review for new baseimage versions

### Docker Security
- **Official Security:** https://docs.docker.com/engine/security/
- **CIS Benchmark:** https://www.cisecurity.org/benchmark/docker
- **NIST Guidelines:** https://csrc.nist.gov/publications/detail/sp/800-190/final
- **🔄 Update Check:** Quarterly review for new security guidelines

### Security Tools
- **Trivy:** https://trivy.dev/
- **CodeQL:** https://docs.github.com/en/code-security/codeql-cli
- **Hadolint:** https://github.com/hadolint/hadolint
- **🔄 Update Check:** Monthly review for tool updates

## 🆘 Support

### Getting Help
- **Issues:** Create GitHub issue for bugs or feature requests
- **Security:** security@mildman1848.dev for security-related issues
- **Documentation:** Check docs/ directory for detailed guides

### Contributing
1. Fork the repository
2. Create feature branch
3. Follow development guidelines
4. Submit pull request with tests

## 📄 License

This template is provided under the MIT License. See [LICENSE](LICENSE) for details.

---

**Last Updated:** 2025-09-22
**Next Review:** 2025-10-22
**Version:** 1.0.0-template

*For questions about this template or improvement suggestions, please create an issue in the template repository.*