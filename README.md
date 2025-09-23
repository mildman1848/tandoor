# Tandoor Recipes Docker Image

> 📖 **[Deutsche Version](README.de.md)** | 🇬🇧 **English Version**

![Build Status](https://github.com/mildman1848/tandoor/workflows/CI/badge.svg)
![Docker Pulls](https://img.shields.io/docker/pulls/mildman1848/tandoor)
![Docker Image Size](https://img.shields.io/docker/image-size/mildman1848/tandoor/latest)
![License](https://img.shields.io/github/license/mildman1848/tandoor)
![Version](https://img.shields.io/badge/version-1.5.19-blue)

🐳 **[Docker Hub: mildman1848/tandoor](https://hub.docker.com/r/mildman1848/tandoor)**

A production-ready Docker image for [Tandoor Recipes](https://github.com/TandoorRecipes/recipes) based on the LinuxServer.io Alpine baseimage with enhanced security features, automatic secret management, full LinuxServer.io compliance, and CI/CD integration.

## 🚀 Features

- ✅ **LinuxServer.io Alpine Baseimage 3.22** - Optimized and secure
- ✅ **S6 Overlay v3** - Professional process management
- ✅ **Full LinuxServer.io Compliance** - FILE__ secrets, Docker Mods, custom scripts
- ✅ **Enhanced Security Hardening** - Non-root execution, capability dropping, secure permissions
- ✅ **OCI Manifest Lists** - True multi-architecture support following OCI standard
- ✅ **LinuxServer.io Pipeline** - Architecture-specific tags + manifest lists
- ✅ **Multi-Platform Support** - AMD64, ARM64 with native performance
- ✅ **Advanced Health Checks** - Automatic monitoring with failover
- ✅ **Robust Secret Management** - 512-bit JWT, 256-bit API keys, secure rotation
- ✅ **Automated Build System** - Make + GitHub Actions CI/CD with manifest validation
- ✅ **Environment Validation** - Comprehensive configuration checks
- ✅ **Security Scanning** - Integrated vulnerability scans with Trivy + CodeQL
- ✅ **OCI Compliance** - Standard-compliant container labels and manifest structure
- ✅ **Django/Python Support** - Virtual environments, PostgreSQL integration, Gunicorn WSGI
- ✅ **Multi-Container Setup** - Integrated PostgreSQL database with health check dependencies

## 🚀 Quick Start

### Automated Setup (Recommended)

```bash
# Clone repository
git clone https://github.com/mildman1848/tandoor.git
cd tandoor

# Complete setup (environment + secrets)
make setup

# Start container
docker-compose up -d
```

### With Docker Compose (Manual)

```bash
# Clone repository
git clone https://github.com/mildman1848/tandoor.git
cd tandoor

# Copy environment template
cp .env.example .env

# Edit configuration
nano .env

# Start Tandoor Recipes with PostgreSQL
docker-compose up -d

# View logs
docker-compose logs -f
```

**🌐 Access:** http://localhost:8080

## 🐳 Docker Usage

### Quick Start

```bash
# Pull image
docker pull mildman1848/tandoor:latest

# Run with PostgreSQL (docker-compose recommended)
docker run -d \
  --name tandoor \
  -p 8080:8080 \
  -v ./config:/config \
  -v ./mediafiles:/app/mediafiles \
  -v ./staticfiles:/app/staticfiles \
  -e SECRET_KEY="your-secret-key" \
  -e POSTGRES_PASSWORD="your-db-password" \
  mildman1848/tandoor:latest
```

### Docker Compose (Recommended)

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
      - SECRET_KEY=your-secret-key
      - POSTGRES_HOST=db_recipes
      - POSTGRES_DB=djangodb
      - POSTGRES_USER=djangouser
      - POSTGRES_PASSWORD=your-db-password
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
      - POSTGRES_PASSWORD=your-db-password
    volumes:
      - ./db:/var/lib/postgresql/data
    restart: unless-stopped
```

## 🔧 Configuration

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `PUID` | `1000` | User ID for file permissions |
| `PGID` | `1000` | Group ID for file permissions |
| `TZ` | `Etc/UTC` | Timezone |
| `SECRET_KEY` | | Django secret key (required) |
| `DEBUG` | `False` | Django debug mode |
| `ALLOWED_HOSTS` | `*` | Django allowed hosts |
| `POSTGRES_HOST` | `db_recipes` | PostgreSQL hostname |
| `POSTGRES_DB` | `djangodb` | PostgreSQL database name |
| `POSTGRES_USER` | `djangouser` | PostgreSQL username |
| `POSTGRES_PASSWORD` | | PostgreSQL password (required) |
| `GUNICORN_WORKERS` | `2` | Number of Gunicorn workers |
| `GUNICORN_TIMEOUT` | `120` | Gunicorn timeout in seconds |

### Volumes

| Path | Description |
|------|-------------|
| `/config` | Configuration and logs |
| `/app/mediafiles` | Uploaded media files (recipes, images) |
| `/app/staticfiles` | Static files (CSS, JS, etc.) |

### Ports

| Port | Description |
|------|-------------|
| `8080` | Tandoor Recipes web interface |

## 🔒 Security Features

### Enhanced Security Hardening

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
deploy:
  resources:
    limits:
      cpus: '2.0'
      memory: 1G
      pids: 200
```

### Secret Management

**FILE__ Prefix Secrets (Recommended):**
```bash
# Environment variables
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

## 🏗️ Architecture

- **Base Image:** LinuxServer.io Alpine 3.22 with S6 Overlay v3
- **Application:** Tandoor Recipes 1.5.19 with Django/Python
- **Database:** PostgreSQL 16 Alpine
- **Web Server:** Gunicorn WSGI with Nginx
- **Process Management:** S6 Overlay for professional service management
- **Security:** Enhanced container hardening with capability dropping

### S6 Services

- `init-branding` - Custom Mildman1848 branding
- `init-secrets` - FILE__ prefix secret processing
- `init-tandoor-config` - Django configuration and setup
- `tandoor` - Main Gunicorn WSGI application server

## 🔧 Development

### Build from Source

```bash
# Clone repository
git clone https://github.com/mildman1848/tandoor.git
cd tandoor

# Build image
make build

# Run tests
make test

# Start development container
make dev
```

### Available Make Commands

```bash
make setup                  # Complete initial setup
make build                  # Build Docker image
make build-manifest         # Build multi-architecture image
make test                   # Run comprehensive tests
make dev                    # Start development container
make security-scan          # Run security scans
make start                  # Start production containers
make stop                   # Stop containers
make logs                   # View logs
make shell                  # Access container shell
```

## 📊 Multi-Platform Support

### OCI Manifest Lists

```bash
# Architecture-specific pulls
docker pull mildman1848/tandoor:amd64-latest
docker pull mildman1848/tandoor:arm64-latest

# Automatic platform selection
docker pull mildman1848/tandoor:latest
```

### Build Process

```bash
# LinuxServer.io Pipeline compliance
make build-manifest          # Create manifest lists
make inspect-manifest        # Inspect manifest structure
make validate-manifest       # Validate OCI compliance
```

## 🚨 Troubleshooting

### Common Issues

**Container won't start:**
- Check logs: `docker-compose logs tandoor`
- Verify environment variables are set
- Ensure PostgreSQL is healthy: `docker-compose ps`

**Database connection issues:**
- Verify `POSTGRES_*` environment variables
- Check database container health: `docker-compose ps db_recipes`
- Review database logs: `docker-compose logs db_recipes`

**Permission errors:**
- Check `PUID`/`PGID` in `.env` match your user
- Fix ownership: `sudo chown -R $USER:$USER ./config ./mediafiles`

**Port conflicts:**
- Change `EXTERNAL_PORT` in `.env`
- Check if port is in use: `netstat -tlnp | grep :8080`

### Debug Mode

```bash
# Enable debug logging
echo "DEBUG=True" >> .env
echo "LOG_LEVEL=debug" >> .env
docker-compose restart
```

## 📋 Requirements

- Docker 20.10+
- Docker Compose 2.0+
- 2GB RAM minimum
- 1GB free disk space

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run tests: `make test`
5. Submit a pull request

## 📄 License

This project is licensed under the AGPL-3.0 License - see the [LICENSE](LICENSE) file for details.

## 🔗 Links

- **Tandoor Recipes:** https://github.com/TandoorRecipes/recipes
- **Documentation:** https://docs.tandoor.dev/
- **Docker Hub:** https://hub.docker.com/r/mildman1848/tandoor
- **LinuxServer.io:** https://www.linuxserver.io/
- **Support:** [Issues](https://github.com/mildman1848/tandoor/issues)

---

**Built with ❤️ by Mildman1848** | Based on LinuxServer.io standards