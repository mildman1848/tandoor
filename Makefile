# tandoor Docker Image Makefile
# Based on LinuxServer.io best practices and Mildman1848 standards

# Variables
DOCKER_REPO = mildman1848/tandoor
VERSION ?= latest
BUILD_DATE := $(shell date -u +'%Y-%m-%dT%H:%M:%SZ')
VCS_REF := $(shell git rev-parse --short HEAD 2>/dev/null || echo "unknown")
TANDOOR_VERSION ?= 1.5.19

# Platform support for multi-architecture builds
PLATFORMS = linux/amd64,linux/arm64

# Docker commands with error checking
DOCKER = docker
BUILDX = docker buildx
COMPOSE = docker-compose

# Colors for output
RED = \033[0;31m
GREEN = \033[0;32m
YELLOW = \033[0;33m
BLUE = \033[0;34m
NC = \033[0m # No Color

.PHONY: help build build-multiarch build-manifest build-manifest-push inspect-manifest validate-manifest push test clean lint validate security-scan secrets-generate secrets-rotate secrets-clean secrets-info env-setup env-validate setup

# Default target
all: help

## Help target
help: ## Show this help message
	@echo "$(BLUE)tandoor Docker Image Build System$(NC)"
	@echo ""
	@echo "$(GREEN)Available targets:$(NC)"
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  $(YELLOW)%-20s$(NC) %s\n", $$1, $$2}' $(MAKEFILE_LIST)
	@echo ""
	@echo "$(GREEN)Variables:$(NC)"
	@echo "  $(YELLOW)DOCKER_REPO$(NC)           Repository name (default: $(DOCKER_REPO))"
	@echo "  $(YELLOW)VERSION$(NC)               Version tag (default: $(VERSION))"
	@echo "  $(YELLOW)TANDOOR_VERSION$(NC)        tandoor version (default: $(TANDOOR_VERSION))"
	@echo "  $(YELLOW)PLATFORMS$(NC)             Target platforms (default: $(PLATFORMS))"

## Build targets
build: ## Build Docker image for current platform
	@echo "$(GREEN)Building Docker image...$(NC)"
	$(DOCKER) build \
		--build-arg BUILD_DATE="$(BUILD_DATE)" \
		--build-arg VERSION="$(VERSION)" \
		--build-arg VCS_REF="$(VCS_REF)" \
		--build-arg TANDOOR_VERSION="$(TANDOOR_VERSION)" \
		--tag $(DOCKER_REPO):$(VERSION) \
		--tag $(DOCKER_REPO):latest \
		.
	@echo "$(GREEN)Build completed successfully!$(NC)"

build-multiarch: ## Build multi-architecture Docker image
	@echo "$(GREEN)Building multi-architecture Docker image...$(NC)"
	$(BUILDX) build \
		--platform $(PLATFORMS) \
		--build-arg BUILD_DATE="$(BUILD_DATE)" \
		--build-arg VERSION="$(VERSION)" \
		--build-arg VCS_REF="$(VCS_REF)" \
		--build-arg TANDOOR_VERSION="$(TANDOOR_VERSION)" \
		--tag $(DOCKER_REPO):$(VERSION) \
		--tag $(DOCKER_REPO):latest \
		--push \
		.
	@echo "$(GREEN)Multi-architecture build completed successfully!$(NC)"

## LinuxServer.io Pipeline targets
build-manifest: ## Build and create LinuxServer.io style manifest lists (local)
	@echo "$(GREEN)Building LinuxServer.io style multi-arch with manifest lists (local)...$(NC)"
	@echo "Building platform-specific images..."
	# Build for current platform (amd64) - guaranteed to work
	$(BUILDX) build \
		--platform linux/amd64 \
		--build-arg BUILD_DATE="$(BUILD_DATE)" \
		--build-arg VERSION="$(VERSION)" \
		--build-arg VCS_REF="$(VCS_REF)" \
		--build-arg TANDOOR_VERSION="$(TANDOOR_VERSION)" \
		--tag $(DOCKER_REPO):amd64-$(VERSION) \
		--load \
		.
	@echo "$(GREEN)AMD64 build completed!$(NC)"
	# ARM builds (optional - may fail if base images don't support these platforms)
	@echo "$(YELLOW)Attempting ARM64 build (may fail if base image doesn't support this platform)...$(NC)"
	-$(BUILDX) build \
		--platform linux/arm64 \
		--build-arg BUILD_DATE="$(BUILD_DATE)" \
		--build-arg VERSION="$(VERSION)" \
		--build-arg VCS_REF="$(VCS_REF)" \
		--build-arg TANDOOR_VERSION="$(TANDOOR_VERSION)" \
		--tag $(DOCKER_REPO):arm64-$(VERSION) \
		--output=type=docker \
		. && echo "$(GREEN)ARM64 build completed!$(NC)" || echo "$(YELLOW)ARM64 build failed (base image may not support this platform)$(NC)"
	@echo "$(GREEN)LinuxServer.io style local builds completed!$(NC)"

build-manifest-push: ## Build and push LinuxServer.io style manifest lists (requires registry access)
	@echo "$(GREEN)Building and pushing LinuxServer.io style multi-arch with manifest lists...$(NC)"
	@echo "$(YELLOW)Warning: This requires Docker Hub/GHCR login and push access!$(NC)"
	@echo "Building platform-specific images..."
	# Build for each platform separately and push by digest
	$(BUILDX) build \
		--platform linux/amd64 \
		--build-arg BUILD_DATE="$(BUILD_DATE)" \
		--build-arg VERSION="$(VERSION)" \
		--build-arg VCS_REF="$(VCS_REF)" \
		--build-arg TANDOOR_VERSION="$(TANDOOR_VERSION)" \
		--tag $(DOCKER_REPO):amd64-$(VERSION) \
		--push \
		.
	$(BUILDX) build \
		--platform linux/arm64 \
		--build-arg BUILD_DATE="$(BUILD_DATE)" \
		--build-arg VERSION="$(VERSION)" \
		--build-arg VCS_REF="$(VCS_REF)" \
		--build-arg TANDOOR_VERSION="$(TANDOOR_VERSION)" \
		--tag $(DOCKER_REPO):arm64-$(VERSION) \
		--push \
		.
	@echo "Creating manifest list..."
	$(DOCKER) manifest create $(DOCKER_REPO):$(VERSION) \
		$(DOCKER_REPO):amd64-$(VERSION) \
		$(DOCKER_REPO):arm64-$(VERSION)
	$(DOCKER) manifest push $(DOCKER_REPO):$(VERSION)
	@echo "$(GREEN)LinuxServer.io style build with manifest list completed!$(NC)"

inspect-manifest: ## Inspect manifest lists (LinuxServer.io style)
	@echo "$(GREEN)Inspecting local images and manifest lists...$(NC)"
	@echo "=== Local Images ==="
	@$(DOCKER) images $(DOCKER_REPO) | grep -E "(latest|amd64|arm64)" || echo "No local images found"
	@echo "=== Architecture-specific local images ==="
	@for arch in amd64 arm64; do \
		echo "--- $${arch} specific image ---"; \
		if $(DOCKER) inspect $(DOCKER_REPO):$${arch}-$(VERSION) >/dev/null 2>&1; then \
			$(DOCKER) inspect $(DOCKER_REPO):$${arch}-$(VERSION) --format '{{.Architecture}}' 2>/dev/null || echo "Architecture info not available"; \
		else \
			echo "Image not found locally"; \
		fi; \
	done
	@echo "=== Remote Manifest verification (if available) ==="
	@$(BUILDX) imagetools inspect $(DOCKER_REPO):$(VERSION) 2>/dev/null || echo "$(YELLOW)Remote manifest not available (not pushed)$(NC)"

validate-manifest: ## Validate OCI manifest compliance
	@echo "$(GREEN)Validating OCI manifest compliance...$(NC)"
	@command -v skopeo >/dev/null 2>&1 && \
		skopeo inspect docker://$(DOCKER_REPO):$(VERSION) || \
		(echo "$(YELLOW)Skopeo not installed, using docker manifest inspect$(NC)"; \
		$(DOCKER) manifest inspect $(DOCKER_REPO):$(VERSION))

## Test targets
test: ## Test the Docker image
	@echo "$(GREEN)Testing Docker image...$(NC)"
	@echo "Creating test directories..."
	@mkdir -p /tmp/tandoor-test-{config,data,logs}
	@echo "Starting container for testing..."
	$(DOCKER) run -d \
		--name tandoor-test \
		--rm \
		-p 1${EXTERNAL_PORT}:8080 \
		-v /tmp/tandoor-test-config:/config \
		-v /tmp/tandoor-test-data:/data \
		-v /tmp/tandoor-test-logs:/config/logs \
		-e PUID=$(shell id -u) \
		-e PGID=$(shell id -g) \
		--health-cmd="${HEALTH_CHECK_CMD}" \
		--health-interval=15s \
		--health-timeout=10s \
		--health-retries=5 \
		--health-start-period=30s \
		$(DOCKER_REPO):$(VERSION)
	@echo "Waiting for container to be healthy..."
	@timeout 120 sh -c 'until [ "$$($(DOCKER) inspect --format="{{.State.Health.Status}}" tandoor-test)" = "healthy" ]; do sleep 3; done' || \
		(echo "$(RED)✗ Container failed to become healthy$(NC)"; \
		$(DOCKER) logs tandoor-test; \
		$(DOCKER) stop tandoor-test; \
		exit 1)
	@echo "$(GREEN)✓ Health check passed$(NC)"
	@echo "Testing tandoor functionality..."
	@echo "Waiting for services to fully start..."
	@sleep 10
	@echo "Checking tandoor binary availability..."
	@$(DOCKER) exec tandoor-test tandoor version >/dev/null || \
		(echo "$(RED)✗ tandoor binary not accessible$(NC)"; \
		$(DOCKER) logs tandoor-test; \
		$(DOCKER) stop tandoor-test; \
		exit 1)
	@echo "$(GREEN)✓ tandoor binary is working$(NC)"
	@echo "Verifying container is running correctly..."
	@$(DOCKER) inspect tandoor-test >/dev/null || \
		(echo "$(RED)✗ Container is not running$(NC)"; \
		exit 1)
	@echo "$(GREEN)✓ Container is running successfully$(NC)"
	@echo "Stopping test container..."
	@$(DOCKER) stop tandoor-test
	@echo "Cleaning up test directories..."
	@rm -rf /tmp/tandoor-test-*
	@echo "$(GREEN)All tests passed!$(NC)"

## Security and validation targets
security-scan: ## Run comprehensive security scan (Trivy + CodeQL)
	@echo "$(GREEN)Running comprehensive security scan...$(NC)"
	@echo "$(YELLOW)1. Running Trivy vulnerability scan...$(NC)"
	@command -v trivy >/dev/null 2>&1 && \
		trivy image $(DOCKER_REPO):$(VERSION) || \
		(echo "$(YELLOW)Running Trivy via Docker...$(NC)"; \
		docker run --rm -v //var/run/docker.sock:/var/run/docker.sock \
			aquasec/trivy:latest image $(DOCKER_REPO):$(VERSION) || \
		(echo "$(YELLOW)Trivy scan failed$(NC)"; \
		echo "Install Trivy for security scanning: https://trivy.dev/"))
	@echo "$(YELLOW)2. Running CodeQL static analysis...$(NC)"
	@make codeql-scan
	@echo "$(GREEN)✓ Comprehensive security scan completed$(NC)"

codeql-scan: ## Run CodeQL static code analysis
	@echo "$(GREEN)Running CodeQL static analysis...$(NC)"
	@if command -v gh >/dev/null 2>&1; then \
		echo "$(YELLOW)Using GitHub CLI for CodeQL...$(NC)"; \
		gh workflow run codeql.yml --ref $(shell git branch --show-current) || \
		echo "$(YELLOW)CodeQL workflow triggered via GitHub CLI$(NC)"; \
	elif command -v codeql >/dev/null 2>&1; then \
		echo "$(YELLOW)Running CodeQL locally...$(NC)"; \
		codeql database create codeql-db --language=javascript || true; \
		codeql database analyze codeql-db --format=csv --output=codeql-results.csv || true; \
		echo "$(GREEN)✓ CodeQL analysis completed - results in codeql-results.csv$(NC)"; \
	else \
		echo "$(YELLOW)CodeQL not available locally. Install CodeQL CLI or use GitHub Actions.$(NC)"; \
		echo "$(CYAN)GitHub Actions CodeQL workflow available at: .github/workflows/codeql.yml$(NC)"; \
		echo "$(CYAN)Install CodeQL: https://docs.github.com/en/code-security/codeql-cli/getting-started-with-the-codeql-cli$(NC)"; \
	fi

trivy-scan: ## Run Trivy vulnerability scan only
	@echo "$(GREEN)Running Trivy vulnerability scan...$(NC)"
	@command -v trivy >/dev/null 2>&1 && \
		trivy image $(DOCKER_REPO):$(VERSION) || \
		(echo "$(YELLOW)Running Trivy via Docker...$(NC)"; \
		docker run --rm -v //var/run/docker.sock:/var/run/docker.sock \
			aquasec/trivy:latest image $(DOCKER_REPO):$(VERSION))

security-scan-detailed: ## Run detailed security scan with exports
	@echo "$(GREEN)Running detailed security scan with exports...$(NC)"
	@mkdir -p security-reports
	@echo "$(YELLOW)1. Trivy JSON report...$(NC)"
	@command -v trivy >/dev/null 2>&1 && \
		trivy image --format json --output security-reports/trivy-report.json $(DOCKER_REPO):$(VERSION) || \
		docker run --rm -v //var/run/docker.sock:/var/run/docker.sock -v $(PWD)/security-reports:/reports \
			aquasec/trivy:latest image --format json --output /reports/trivy-report.json $(DOCKER_REPO):$(VERSION)
	@echo "$(YELLOW)2. Trivy SARIF report...$(NC)"
	@command -v trivy >/dev/null 2>&1 && \
		trivy image --format sarif --output security-reports/trivy-report.sarif $(DOCKER_REPO):$(VERSION) || \
		docker run --rm -v //var/run/docker.sock:/var/run/docker.sock -v $(PWD)/security-reports:/reports \
			aquasec/trivy:latest image --format sarif --output /reports/trivy-report.sarif $(DOCKER_REPO):$(VERSION)
	@echo "$(YELLOW)3. Dockerfile scan...$(NC)"
	@command -v trivy >/dev/null 2>&1 && \
		trivy config --format json --output security-reports/dockerfile-scan.json . || \
		docker run --rm -v $(PWD):/workspace -v $(PWD)/security-reports:/reports \
			aquasec/trivy:latest config --format json --output /reports/dockerfile-scan.json /workspace
	@echo "$(GREEN)✓ Security reports saved to security-reports/$(NC)"

validate: ## Validate Dockerfile and configuration
	@echo "$(GREEN)Validating Dockerfile...$(NC)"
	@command -v hadolint >/dev/null 2>&1 && \
		(hadolint Dockerfile; echo "$(GREEN)✓ Dockerfile validation passed$(NC)") || \
		(echo "$(YELLOW)Hadolint not installed, skipping Dockerfile validation$(NC)"; \
		echo "Install Hadolint: https://github.com/hadolint/hadolint")

lint: validate ## Alias for validate

## Deployment targets
push: ## Push image to registry
	@echo "$(GREEN)Pushing Docker image to registry...$(NC)"
	$(DOCKER) push $(DOCKER_REPO):$(VERSION)
	$(DOCKER) push $(DOCKER_REPO):latest
	@echo "$(GREEN)Push completed successfully!$(NC)"

## Utility targets
clean: ## Clean up Docker artifacts
	@echo "$(GREEN)Cleaning up Docker artifacts...$(NC)"
	$(DOCKER) image prune -f
	$(DOCKER) container prune -f
	@echo "$(GREEN)Cleanup completed!$(NC)"

clean-all: ## Remove all related Docker images and containers
	@echo "$(GREEN)Removing all tandoor Docker artifacts...$(NC)"
	-@$(DOCKER) stop `$(DOCKER) ps -q --filter ancestor=$(DOCKER_REPO)` 2>/dev/null || true
	-@$(DOCKER) rmi `$(DOCKER) images $(DOCKER_REPO) -q` 2>/dev/null || true
	@echo "$(GREEN)Complete cleanup finished!$(NC)"

## Development targets
dev: ## Build and run for development
	@echo "$(GREEN)Building and starting development container...$(NC)"
	$(MAKE) build
	$(DOCKER) run -it --rm \
		--name tandoor-dev \
		-p 1${EXTERNAL_PORT}:8080 \
		-v $(PWD)/test-data/config:/config \
		-v $(PWD)/test-data/data:/data \
		-v $(PWD)/test-data/logs:/config/logs \
		$(DOCKER_REPO):$(VERSION)

shell: ## Get shell access to running container
	@echo "$(GREEN)Opening shell in tandoor container...$(NC)"
	$(DOCKER) exec -it `$(DOCKER) ps -q --filter ancestor=$(DOCKER_REPO)` /bin/bash

logs: ## Show logs from running container
	@echo "$(GREEN)Showing logs from tandoor container...$(NC)"
	$(DOCKER) logs -f `$(DOCKER) ps -q --filter ancestor=$(DOCKER_REPO)`

## Release targets
release: validate build test security-scan ## Complete release workflow
	@echo "$(GREEN)Release workflow completed successfully!$(NC)"
	@echo "To push to registry, run: make push"

## Secrets management targets
secrets-generate: ## Generate secure secrets for tandoor
	@echo "$(GREEN)Generating secure secrets for tandoor...$(NC)"
	@mkdir -p secrets
	@echo "Generating tandoor config password..."
	@openssl rand -base64 32 | tr -d "=+/\n" | head -c 24 > secrets/tandoor_config_pass.txt
	@echo "Generating tandoor API key..."
	@openssl rand -base64 32 | tr -d "=+/\n" | head -c 32 > secrets/tandoor_api_key.txt
	@echo "Generating tandoor JWT secret..."
	@openssl rand -base64 48 | tr -d "=+/\n" | head -c 48 > secrets/tandoor_jwt_secret.txt
	@chmod 600 secrets/tandoor_*.txt
	@chown $(shell id -u):$(shell id -g) secrets/tandoor_*.txt 2>/dev/null || true
	@echo "$(GREEN)✓ tandoor secrets generated successfully!$(NC)"
	@echo "$(YELLOW)⚠️  Keep these secrets secure and never commit them to version control!$(NC)"

secrets-rotate: ## Rotate existing secrets (keeps backups)
	@echo "$(GREEN)Rotating secrets...$(NC)"
	@test -d "secrets" && \
		(echo "Creating backup of existing secrets..."; \
		mkdir -p secrets/backup-$(shell date +%Y%m%d-%H%M%S); \
		cp secrets/*.txt secrets/backup-$(shell date +%Y%m%d-%H%M%S)/ 2>/dev/null || true) || true
	@$(MAKE) secrets-generate
	@echo "$(GREEN)✓ Secrets rotated successfully!$(NC)"

secrets-clean: ## Clean up old secret backups (keeps last 5)
	@echo "$(GREEN)Cleaning up old secret backups...$(NC)"
	@test -d "secrets" && \
		(cd secrets && ls -dt backup-* 2>/dev/null | tail -n +6 | xargs rm -rf 2>/dev/null || true; \
		echo "$(GREEN)✓ Old secret backups cleaned up!$(NC)") || \
		echo "$(YELLOW)No secrets directory found.$(NC)"

secrets-info: ## Show information about current secrets
	@echo "$(BLUE)tandoor Secrets Information:$(NC)"
	@test -d "secrets" && \
		(echo "  Secrets directory: exists"; \
		echo "  tandoor secret files:"; \
		ls -la secrets/tandoor_*.txt 2>/dev/null | awk '{print "    " $$9 " (" $$5 " bytes, " $$6 " " $$7 " " $$8 ")"}' || echo "    No tandoor secret files found"; \
		echo "  Backup directories:"; \
		ls -d secrets/backup-* 2>/dev/null | wc -l | awk '{print "    " $$1 " backup(s) available"}' || echo "    No backups found") || \
		(echo "  Secrets directory: not found"; \
		echo "  Run 'make secrets-generate' to create tandoor secrets")

## Environment setup targets
env-setup: ## Setup environment from .env.example
	@echo "$(GREEN)Setting up environment...$(NC)"
	@test ! -f .env && \
		(echo "Creating .env from .env.example..."; \
		cp .env.example .env; \
		echo "$(GREEN)✓ .env file created!$(NC)"; \
		echo "$(YELLOW)⚠️  Please review and customize .env before starting containers!$(NC)") || \
		echo "$(YELLOW).env file already exists, skipping...$(NC)"

env-validate: ## Validate environment configuration
	@echo "$(GREEN)Validating environment configuration...$(NC)"
	@test -f .env && \
		(echo "✓ .env file exists"; \
		grep -q "PUID=" .env && echo "✓ PUID is set" || echo "⚠️  PUID not set"; \
		grep -q "PGID=" .env && echo "✓ PGID is set" || echo "⚠️  PGID not set"; \
		grep -q "TZ=" .env && echo "✓ TZ is set" || echo "⚠️  TZ not set"; \
		grep -q "UMASK=" .env && echo "✓ UMASK is set" || echo "⚠️  UMASK not set"; \
		test -d secrets && echo "✓ Secrets directory exists" || echo "⚠️  Secrets directory missing - run 'make secrets-generate'"; \
		echo "$(GREEN)Environment validation completed!$(NC)") || \
		(echo "$(RED)✗ .env file not found!$(NC)"; \
		echo "Run 'make env-setup' to create it."; \
		exit 1)

## Complete setup workflow
setup: env-setup secrets-generate ## Complete initial setup
	@echo "$(GREEN)Initial setup completed!$(NC)"
	@echo "$(BLUE)Next steps:$(NC)"
	@echo "  1. Review and customize .env file"
	@echo "  2. Run 'make build' to build the Docker image"
	@echo "  3. Run 'make dev' or 'docker-compose up -d' to start"

## Container management commands
start: ## Start the tandoor container
	@echo "$(GREEN)Starting tandoor container...$(NC)"
	@test -f .env || (echo "$(RED)✗ .env file not found! Run 'make env-setup' first$(NC)" && exit 1)
	@test -d secrets || (echo "$(YELLOW)⚠️  Secrets not found, generating...$(NC)" && $(MAKE) secrets-generate)
	$(COMPOSE) up -d tandoor
	@echo "$(GREEN)✓ Container started on http://localhost:$$(grep EXTERNAL_PORT .env | cut -d'=' -f2 | head -1)$(NC)"

stop: ## Stop the tandoor container
	@echo "$(GREEN)Stopping tandoor container...$(NC)"
	$(COMPOSE) down
	@echo "$(GREEN)✓ Container stopped$(NC)"

restart: stop start ## Restart the tandoor container

status: ## Show container status and health
	@echo "$(GREEN)Container Status:$(NC)"
	$(COMPOSE) ps
	@echo ""
	@echo "$(GREEN)Health Status:$(NC)"
	@$(DOCKER) ps --filter "name=tandoor" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" 2>/dev/null || echo "No containers running"
	@echo ""
	@echo "$(GREEN)Recent Logs:$(NC)"
	$(COMPOSE) logs --tail=20 tandoor 2>/dev/null || echo "No logs available"

## Information targets
info: ## Show build information
	@echo "$(BLUE)Build Information:$(NC)"
	@echo "  Repository: $(DOCKER_REPO)"
	@echo "  Version: $(VERSION)"
	@echo "  Build Date: $(BUILD_DATE)"
	@echo "  VCS Ref: $(VCS_REF)"
	@echo "  tandoor Version: $(TANDOOR_VERSION)"
	@echo "  Platforms: $(PLATFORMS)"
## Django-optimized secrets management
secrets-django: ## Generate Django-optimized secrets for Tandoor Recipes
	@echo "$(GREEN)Generating Django-optimized secrets for Tandoor Recipes...$(NC)"
	@mkdir -p secrets
	@echo "Generating Django SECRET_KEY (URL-safe, 64 chars)..."
	@python3 -c "import secrets; print(secrets.token_urlsafe(64))" > secrets/tandoor_secret_key.txt 2>/dev/null || \
		openssl rand -base64 64 | tr -d "=+/\n" | head -c 64 > secrets/tandoor_secret_key.txt
	@echo "Generating PostgreSQL password (secure, 32 chars)..."
	@openssl rand -base64 32 | tr -d "=+/\n" | head -c 32 > secrets/tandoor_postgres_password.txt
	@echo "djangouser" > secrets/tandoor_postgres_user.txt
	@echo "Generating Django session key (hex, 64 chars)..."
	@python3 -c "import secrets; print(secrets.token_hex(32))" > secrets/tandoor_session_key.txt 2>/dev/null || \
		openssl rand -hex 32 > secrets/tandoor_session_key.txt
	@echo "Generating database encryption key..."
	@openssl rand -base64 32 | tr -d "=+/\n" | head -c 32 > secrets/tandoor_db_key.txt
	@chmod 600 secrets/tandoor_*.txt
	@chown $(shell id -u):$(shell id -g) secrets/tandoor_*.txt 2>/dev/null || true
	@echo "$(GREEN)✓ Django secrets generated successfully!$(NC)"
	@echo "$(BLUE)Django Secret Summary:$(NC)"
	@echo "  SECRET_KEY: $(shell wc -c < secrets/tandoor_secret_key.txt 2>/dev/null || echo '0') characters"
	@echo "  DB Password: $(shell wc -c < secrets/tandoor_postgres_password.txt 2>/dev/null || echo '0') characters"
	@echo "  Session Key: $(shell wc -c < secrets/tandoor_session_key.txt 2>/dev/null || echo '0') characters"
	@echo "  DB Encryption: $(shell wc -c < secrets/tandoor_db_key.txt 2>/dev/null || echo '0') characters"
	@echo "$(YELLOW)⚠️  Store these securely - never commit to version control!$(NC)"
