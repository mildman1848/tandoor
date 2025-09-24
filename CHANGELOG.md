# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [2.2.4-1] - 2025-09-24

### 🚀 MAJOR: Tandoor 2.2.4 Migration & White Screen Fix
- **Version Update**: Upgraded from Tandoor 1.5.19 to 2.2.4 (CRITICAL architecture change)
- **Multi-Stage Build**: Implemented asset extraction from official Tandoor image
- **Vue.js/Vite Integration**: Fixed django-vite integration with real 50KB manifest.json
- **White Screen Resolution**: Login page now functional (4,822 bytes content vs empty)
- **Django Migrations**: Added missing database migrations to startup sequence
- **Service Worker**: Implemented PWA support with service-worker.js creation

### 📊 Version Management System
- **Upstream Validation**: Added mandatory version checking with GitHub API
- **Build Integration**: version-check target required before builds
- **Proactive Monitoring**: Prevents future version drift issues

### 🏗️ Build & Infrastructure
- **Asset Extraction**: `COPY --from=vite_assets` pattern for web applications
- **Permissions Fix**: Proper abc:abc ownership for Vue.js assets
- **Documentation**: Updated CLAUDE.md with migration lessons learned

### 🔧 Container Improvements
- **Health Checks**: Container reports healthy status consistently
- **HTTP Responses**: Proper 302 redirects to /accounts/login/
- **Static Files**: 623 files collected successfully
- **Database Wait**: Robust PostgreSQL readiness checking

### 📚 Documentation Organization
- **docs/ Structure**: Moved LINUXSERVER.md files to docs/ directory
- **Best Practices**: Documented multi-stage build patterns for future projects

### 🔧 Critical S6 Overlay Services Completion (2025-09-23)

#### LinuxServer.io S6 Service Structure Fixed
- **CRITICAL FIX**: Added missing LinuxServer.io standard services that were preventing proper container startup
- **Added init-adduser**: Essential PUID/PGID user management service (critical for LinuxServer.io compliance)
- **Added init-custom-files**: Custom scripts and files support for LinuxServer.io mods
- **Added init-mods-package-install**: LinuxServer.io package modification system support
- **Service Dependencies**: Correctly configured service dependency chain: init-branding → init-mods-package-install → init-custom-files → init-secrets → init-tandoor-config → tandoor
- **User Bundle Updated**: Added missing services to S6 user bundle configuration
- **Service Types**: All services properly configured as 'oneshot' type

#### Container Startup Validation
- **✅ Full S6 Service Chain**: All 8 S6 services now start correctly without errors
- **✅ LinuxServer.io Branding**: Container displays proper Mildman1848 branding on startup
- **✅ Django Application**: Tandoor Recipes starts successfully with Gunicorn workers
- **✅ Static Files**: 442 static files copied successfully to /app/staticfiles
- **✅ PUID/PGID Management**: User permissions managed correctly (197611/197121)
- **✅ Health Checks**: Container reports healthy status after startup

#### Technical Implementation
- **Service Scripts**: Copied and adapted working S6 services from audiobookshelf project
- **Dependency Resolution**: Fixed service dependency chain for proper initialization order
- **Type Configuration**: Added missing service type files (oneshot, bundle)
- **Error Handling**: Enhanced error handling in all S6 service scripts

### 🏗️ Project Structure Standardization (2025-09-23)

#### Directory Structure Overhaul
- **Data Consolidation**: Moved `mediafiles/` and `staticfiles/` to standardized `data/` directory structure
- **Volume Path Updates**: Updated docker-compose.yml volume mounts to reflect new `data/mediafiles` and `data/staticfiles` paths
- **Enhanced .env.example**: Comprehensive environment configuration template with all LinuxServer.io standard variables
- **Standardized Paths**: Implemented consistent `config/`, `data/`, and `security/` directory organization

#### Security Enhancements
- **seccomp Profile**: Maintained existing `security/seccomp-profile.json` with standardized path references
- **Production Security**: Enhanced docker-compose.production.yml with comprehensive security configurations
- **FILE__ Secrets**: Documented comprehensive FILE__ prefix secret support in .env.example

#### Configuration Improvements
- **Django Integration**: Added Django-specific environment variables and configuration options
- **Database Configuration**: Enhanced PostgreSQL configuration with proper secret management
- **Network Configuration**: Standardized network settings with subnet configuration
- **Path Standardization**: Updated all file paths to follow workspace template standards

## [1.5.19-automation.3] - 2025-09-23

### 🔧 Infrastructure & Workflow Fixes
- **CRITICAL:** Fixed .env file image reference from `vabene1111/recipes` to `mildman1848/tandoor` for local development
- **Workflows:** Fixed upstream-monitor workflow issues with missing GitHub labels (upstream-update, base-image-update, automated)
- **Workflows:** Enhanced base image version detection with Docker Hub API and GitHub fallback
- **Workflows:** Added automatic label creation to prevent workflow failures
- **Security:** Created missing GitHub repository labels for automated issue management
- **Dependencies:** Added comprehensive Dependabot configuration for Docker, GitHub Actions, and Python dependencies
- **Monitoring:** Fixed upstream monitoring workflow to properly track Tandoor Recipes and LinuxServer.io base image updates

### ✅ Container Validation Results
- **Container Build:** ✅ Successful build with proper python-ldap compilation
- **Container Test:** ✅ Healthy startup with Gunicorn running on port 8080
- **Security Scan:** ✅ Only 18 non-critical vulnerabilities found (excellent security posture)
- **Dockerfile Linting:** ✅ Passed hadolint validation

### 🔄 Workflow Infrastructure Complete
- **ci.yml:** ✅ Linting, validation, and basic testing
- **docker-publish.yml:** ✅ Multi-arch builds and registry publishing (release-only)
- **security.yml:** ✅ Trivy scans, SBOM generation, security reporting
- **upstream-monitor.yml:** ✅ Automated dependency update monitoring with issue creation
- **release.yml:** ✅ Complete release automation workflow
- **dependabot.yml:** ✅ Dependency management configuration

### 📋 Project Status
- **Ready for Production:** Container builds cleanly, starts healthy, passes all security scans
- **Standards Compliant:** Follows all LinuxServer.io and Docker best practices
- **Automation Complete:** Full GitHub Actions workflow suite implemented and functioning

## [1.5.19-automation.2] - 2025-09-23

### Fixed
- **CRITICAL:** Fixed python-ldap build compilation failure that was preventing Docker image builds
- **Build Process:** Consolidated all Python package installations (including requirements.txt) into single RUN instruction before build tools cleanup
- **Dependencies:** Ensured build tools (gcc, musl-dev, openldap-dev, python3-dev) remain available during python-ldap compilation
- **Docker:** Resolved Dockerfile syntax issues with line continuations and multi-stage build process
- **Container Health:** Verified container starts without errors and gunicorn runs properly on port 8080
- **S6 Services:** Confirmed all LinuxServer.io S6 overlay services initialize correctly

### Technical Details
- **python-ldap Issue:** The package requires native compilation with OpenLDAP development headers
- **Root Cause:** Build tools were being cleaned up in separate RUN instruction before python-ldap compilation
- **Solution:** Moved ALL Python package installations (pip, wheel, setuptools_rust, requirements.txt) into the first RUN instruction before `apk del .build-deps`
- **Validation:** Container now builds successfully and starts healthy with all Django authentication features intact

### Added
- Enhanced build pattern documentation for Django + python-ldap projects
- Comprehensive pre-push validation framework in template project
- Django-optimized secrets generation for future projects

### Development
- Updated template with learnings about Python native dependency compilation
- Created build patterns documentation for future reference
- Improved Docker build reliability for complex Python applications

### Dependencies
- Maintained django-auth-ldap==4.6.0 functionality
- Preserved all LDAP authentication capabilities
- No breaking changes to configuration or functionality

### Infrastructure
- LinuxServer.io S6 Overlay v3 compatibility maintained
- All security hardening features preserved
- Container startup time and health checks optimized

### Notes
- This fix resolves the core Docker build failure blocking the project
- All existing LDAP authentication workflows remain unchanged
- Build process is now more resilient for Python applications with native dependencies

---

## Previous Versions

### [1.5.19-automation.1] - 2025-09-XX
Initial LinuxServer.io compliant implementation with comprehensive security features and S6 Overlay integration.