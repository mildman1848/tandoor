# LinuxServer.io Compliance Guide

> 🇬🇧 **English Version** | 📖 **[Deutsche Version](LINUXSERVER.de.md)**

This document outlines how this Tandoor Recipes Docker image fully complies with LinuxServer.io standards and best practices.

## ✅ Implemented LinuxServer.io Standards

### S6 Overlay v3
- **✅ Complete S6 v3 implementation**
- **✅ Proper service dependencies**
- **✅ Standard init process**
- **✅ Django-specific service chain**

### FILE__ Prefix Secrets
- **✅ Full FILE__ environment variable support**
- **✅ Automatic secret processing**
- **✅ Backwards compatibility with legacy secrets**
- **✅ Path validation and sanitization**

### Docker Mods Support
- **✅ DOCKER_MODS environment variable**
- **✅ Multiple mod support (pipe-separated)**
- **✅ Standard mod installation process**

### Custom Scripts & Services
- **✅ /custom-cont-init.d support**
- **✅ /custom-services.d support**
- **✅ Proper execution order**

### User Management
- **✅ PUID/PGID support**
- **✅ abc user (UID 911)**
- **✅ Dynamic user ID changes**

### UMASK Support
- **✅ UMASK environment variable**
- **✅ Default UMASK=022**
- **✅ Applied to all file operations**

### Container Branding
- **✅ Custom branding file implementation**
- **✅ LSIO_FIRST_PARTY=false set**
- **✅ Clear distinction from official LinuxServer.io containers**
- **✅ Custom ASCII art for "Mildman1848"**
- **✅ Proper support channel references**

### OCI Manifest Lists & Multi-Architecture Pipeline
- **✅ OCI Image Manifest Specification v1.1.0 compliance**
- **✅ LinuxServer.io pipeline standards implementation**
- **✅ Architecture-specific tags (amd64-latest, arm64-latest)**
- **✅ Native multi-platform builds (no emulation)**
- **✅ Matrix-based GitHub Actions builds**
- **✅ Digest management and artifact sharing**

## 🏗️ Service Structure

### S6 Service Chain
```
init-branding → init-secrets → init-tandoor-config → tandoor
```

### Service Details

**init-branding**
- Custom Mildman1848 ASCII art display
- Version information output
- Support channel references

**init-secrets**
- FILE__ prefix environment variable processing
- Docker secrets backward compatibility
- Path validation for security

**init-tandoor-config**
- Django configuration setup
- Database connection validation
- Static file directory creation
- SECRET_KEY generation if not provided

**tandoor**
- Gunicorn WSGI server startup
- Django migrations
- Static file collection
- Non-root execution (user abc)

## 🔐 Security Implementation

### LinuxServer.io Security Standards
- **✅ Non-root execution**
- **✅ Capability dropping**
- **✅ SecComp profiles**
- **✅ AppArmor integration**
- **✅ Read-only root filesystem support**

### Enhanced Security Features
- **✅ no-new-privileges security option**
- **✅ Minimal capability set (CHOWN, DAC_OVERRIDE, FOWNER, SETGID, SETUID)**
- **✅ tmpfs mounts for temporary data**
- **✅ Resource limits (CPU, memory, PIDs)**

## 🔧 Environment Variables

### Standard LinuxServer.io Variables
| Variable | Default | Purpose |
|----------|---------|---------|
| `PUID` | `1000` | User ID for file ownership |
| `PGID` | `1000` | Group ID for file ownership |
| `TZ` | `Etc/UTC` | Timezone configuration |
| `UMASK` | `022` | File creation mask |

### Tandoor-Specific Variables
| Variable | Default | Purpose |
|----------|---------|---------|
| `SECRET_KEY` | | Django secret key |
| `DEBUG` | `False` | Django debug mode |
| `ALLOWED_HOSTS` | `*` | Django allowed hosts |
| `POSTGRES_HOST` | `db_recipes` | Database hostname |
| `POSTGRES_DB` | `djangodb` | Database name |
| `POSTGRES_USER` | `djangouser` | Database username |
| `POSTGRES_PASSWORD` | | Database password |

### FILE__ Prefix Support
```bash
# Recommended secret management
FILE__SECRET_KEY=/run/secrets/tandoor_secret_key
FILE__POSTGRES_PASSWORD=/run/secrets/tandoor_postgres_password
FILE__POSTGRES_USER=/run/secrets/tandoor_postgres_user
```

## 📁 Volume Structure

### Standard LinuxServer.io Volumes
- `/config` - Application configuration and logs
- `/app/mediafiles` - User uploaded content
- `/app/staticfiles` - Application static files

### File Permissions
- Configuration files: `640` (owner read/write, group read)
- Directories: `750` (owner read/write/execute, group read/execute)
- Static files: `644` (owner read/write, group/other read)

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

### LinuxServer.io Compatible Labels
```dockerfile
LABEL build_version="mildman1848 version:- ${VERSION} Build-date:- ${BUILD_DATE}"
LABEL maintainer="mildman1848"
```

## 🚀 CI/CD Pipeline

### GitHub Actions Integration
- **✅ Matrix builds for multiple architectures**
- **✅ OCI manifest list creation**
- **✅ Security scanning (Trivy + CodeQL)**
- **✅ Dockerfile validation (Hadolint)**
- **✅ SBOM generation**

### Build Process
```bash
# Multi-architecture build
make build-manifest

# OCI compliance validation
make validate-manifest

# Security scanning
make security-scan
```

## 📊 Health Checks

### Process-Based Health Check
```dockerfile
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=5 \
    CMD ps aux | grep -v grep | grep "gunicorn" || exit 1
```

### Benefits
- **Security**: No authentication required
- **Reliability**: Direct process monitoring
- **Performance**: Fast execution
- **Compatibility**: Works with all deployment scenarios

## 🔗 Compliance Verification

### Automated Testing
- **✅ S6 service startup validation**
- **✅ FILE__ prefix secret processing**
- **✅ PUID/PGID functionality**
- **✅ UMASK application**
- **✅ Docker Mods support**

### Manual Verification Commands
```bash
# Check S6 services
docker exec tandoor s6-rc -a list

# Verify user ID
docker exec tandoor id abc

# Check file permissions
docker exec tandoor ls -la /config

# Validate environment processing
docker exec tandoor env | grep -E "(PUID|PGID|TZ|UMASK)"
```

## 📋 Differences from Standard LinuxServer.io

### Customizations
1. **Custom Branding**: Mildman1848 ASCII art instead of LinuxServer.io
2. **Enhanced Security**: Additional hardening beyond standard
3. **Application-Specific**: Django/Python optimizations
4. **Multi-Container**: PostgreSQL database integration

### Maintained Compatibility
- **✅ All LinuxServer.io environment variables**
- **✅ All LinuxServer.io volume structures**
- **✅ All LinuxServer.io service patterns**
- **✅ All LinuxServer.io security features**

## 🆘 Support

For LinuxServer.io compliance issues:
- **Repository**: [mildman1848/tandoor](https://github.com/mildman1848/tandoor)
- **Issues**: [GitHub Issues](https://github.com/mildman1848/tandoor/issues)
- **Documentation**: This guide and README files

**Note**: This is NOT an official LinuxServer.io container. For official LinuxServer.io support, visit [linuxserver.io](https://www.linuxserver.io/).

---

**Maintained by Mildman1848** | Following LinuxServer.io Standards