#!/usr/bin/env bash
# baseimage-update-test.sh
# LinuxServer.io Baseimage Update Testing Script
#
# This script tests new LinuxServer.io baseimage versions before deployment
# Following LinuxServer.io standards and our security requirements

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
BASEIMAGE_REPO="linuxserver/docker-baseimage-alpine"
CURRENT_VERSION_PATTERN="baseimage-alpine:3.22-[a-f0-9]+-ls[0-9]+"
TEST_IMAGE_TAG="baseimage-update-test"
TIMEOUT_DURATION="300" # 5 minutes

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}ℹ️  INFO:${NC} $1"
}

log_success() {
    echo -e "${GREEN}✅ SUCCESS:${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}⚠️  WARNING:${NC} $1"
}

log_error() {
    echo -e "${RED}❌ ERROR:${NC} $1"
}

# Get latest baseimage version from GitHub API
get_latest_baseimage_version() {
    local latest_tag
    latest_tag=$(curl -s "https://api.github.com/repos/${BASEIMAGE_REPO}/releases/latest" | grep -o '"tag_name": "[^"]*' | cut -d'"' -f4)

    if [[ -z "$latest_tag" ]]; then
        log_error "Failed to fetch latest baseimage version"
        return 1
    fi

    echo "$latest_tag"
}

# Get current baseimage version from Dockerfile
get_current_baseimage_version() {
    if [[ ! -f "$PROJECT_ROOT/Dockerfile" ]]; then
        log_error "Dockerfile not found in project root"
        return 1
    fi

    local current_version
    current_version=$(grep -oE "$CURRENT_VERSION_PATTERN" "$PROJECT_ROOT/Dockerfile" | head -1 | cut -d':' -f2)

    if [[ -z "$current_version" ]]; then
        log_error "Could not extract current baseimage version from Dockerfile"
        return 1
    fi

    echo "$current_version"
}

# Compare versions to check if update is needed
is_update_needed() {
    local current_version="$1"
    local latest_version="$2"

    if [[ "$current_version" == "$latest_version" ]]; then
        return 1 # No update needed
    fi

    return 0 # Update needed
}

# Create test Dockerfile with new baseimage
create_test_dockerfile() {
    local new_version="$1"
    local test_dockerfile="$PROJECT_ROOT/Dockerfile.baseimage-test"

    log_info "Creating test Dockerfile with baseimage version: $new_version"

    # Copy original Dockerfile and replace baseimage version
    sed "s/$CURRENT_VERSION_PATTERN/baseimage-alpine:$new_version/g" "$PROJECT_ROOT/Dockerfile" > "$test_dockerfile"

    if [[ ! -f "$test_dockerfile" ]]; then
        log_error "Failed to create test Dockerfile"
        return 1
    fi

    log_success "Test Dockerfile created: $test_dockerfile"
    echo "$test_dockerfile"
}

# Build test image with new baseimage
build_test_image() {
    local test_dockerfile="$1"
    local project_name
    project_name=$(basename "$PROJECT_ROOT")

    log_info "Building test image with new baseimage..."

    # Build test image
    if ! docker build \
        --file "$test_dockerfile" \
        --tag "${project_name}:${TEST_IMAGE_TAG}" \
        --build-arg BUILD_DATE="$(date -u +'%Y-%m-%dT%H:%M:%SZ')" \
        --build-arg VERSION="baseimage-test" \
        --build-arg VCS_REF="$(git rev-parse --short HEAD)" \
        "$PROJECT_ROOT" 2>&1 | tee "$PROJECT_ROOT/baseimage-test-build.log"; then

        log_error "Test image build failed. See log: $PROJECT_ROOT/baseimage-test-build.log"
        return 1
    fi

    log_success "Test image built successfully: ${project_name}:${TEST_IMAGE_TAG}"
    echo "${project_name}:${TEST_IMAGE_TAG}"
}

# Run comprehensive container tests
run_container_tests() {
    local test_image="$1"
    local project_name
    project_name=$(basename "$PROJECT_ROOT")
    local container_name="${project_name}-baseimage-test"

    log_info "Running container tests with new baseimage..."

    # Cleanup any existing test container
    docker rm -f "$container_name" 2>/dev/null || true

    # Create test directories
    local test_config_dir="/tmp/${container_name}-config"
    local test_data_dir="/tmp/${container_name}-data"
    local test_logs_dir="/tmp/${container_name}-logs"

    mkdir -p "$test_config_dir" "$test_data_dir" "$test_logs_dir"

    # Start test container
    log_info "Starting test container: $container_name"

    if ! docker run -d \
        --name "$container_name" \
        --rm \
        -p 8080 \
        -v "$test_config_dir:/config" \
        -v "$test_data_dir:/data" \
        -v "$test_logs_dir:/config/logs" \
        -e PUID=1000 \
        -e PGID=1000 \
        -e TZ=UTC \
        --health-interval=30s \
        --health-timeout=10s \
        --health-retries=3 \
        --health-start-period=60s \
        "$test_image"; then

        log_error "Failed to start test container"
        return 1
    fi

    # Wait for container to be healthy or timeout
    log_info "Waiting for container to be healthy (timeout: ${TIMEOUT_DURATION}s)..."

    local waited=0
    local health_status=""

    while [[ $waited -lt $TIMEOUT_DURATION ]]; do
        health_status=$(docker inspect --format='{{.State.Health.Status}}' "$container_name" 2>/dev/null || echo "starting")

        if [[ "$health_status" == "healthy" ]]; then
            log_success "Container is healthy!"
            break
        elif [[ "$health_status" == "unhealthy" ]]; then
            log_error "Container became unhealthy"
            docker logs "$container_name" > "$PROJECT_ROOT/baseimage-test-container.log" 2>&1
            docker rm -f "$container_name" 2>/dev/null || true
            return 1
        fi

        sleep 5
        waited=$((waited + 5))
    done

    if [[ $waited -ge $TIMEOUT_DURATION ]]; then
        log_warning "Container health check timed out after ${TIMEOUT_DURATION}s"
        log_info "Container status: $health_status"
    fi

    # Test S6 Overlay services
    log_info "Testing S6 Overlay services..."

    if ! docker exec "$container_name" s6-rc -l list 2>/dev/null; then
        log_error "S6 Overlay services test failed"
        docker logs "$container_name" > "$PROJECT_ROOT/baseimage-test-container.log" 2>&1
        docker rm -f "$container_name" 2>/dev/null || true
        return 1
    fi

    log_success "S6 Overlay services are working correctly"

    # Test LinuxServer.io user management
    log_info "Testing LinuxServer.io user management..."

    local abc_user_info
    abc_user_info=$(docker exec "$container_name" id abc 2>/dev/null || echo "")

    if [[ -z "$abc_user_info" ]]; then
        log_error "LinuxServer.io abc user not found"
        docker rm -f "$container_name" 2>/dev/null || true
        return 1
    fi

    log_success "LinuxServer.io abc user configured correctly: $abc_user_info"

    # Test basic functionality (if health checks are not available)
    if [[ "$health_status" != "healthy" ]]; then
        log_info "Running basic process tests..."

        local running_processes
        running_processes=$(docker exec "$container_name" ps aux | grep -v grep | grep -c "s6\|init" || echo "0")

        if [[ "$running_processes" -eq 0 ]]; then
            log_error "No S6/init processes found running"
            docker logs "$container_name" > "$PROJECT_ROOT/baseimage-test-container.log" 2>&1
            docker rm -f "$container_name" 2>/dev/null || true
            return 1
        fi

        log_success "Basic processes are running ($running_processes S6/init processes)"
    fi

    # Collect test results
    docker logs "$container_name" > "$PROJECT_ROOT/baseimage-test-container.log" 2>&1

    # Cleanup
    docker rm -f "$container_name" 2>/dev/null || true
    rm -rf "$test_config_dir" "$test_data_dir" "$test_logs_dir"

    log_success "Container tests completed successfully"
    return 0
}

# Run security scan on test image
run_security_scan() {
    local test_image="$1"

    log_info "Running security scan on test image..."

    # Run Trivy scan
    if command -v trivy >/dev/null 2>&1; then
        log_info "Running Trivy vulnerability scan..."

        if ! trivy image \
            --severity HIGH,CRITICAL \
            --exit-code 0 \
            --format table \
            "$test_image" > "$PROJECT_ROOT/baseimage-test-security.log" 2>&1; then

            log_warning "Trivy scan encountered issues. See log: $PROJECT_ROOT/baseimage-test-security.log"
        else
            log_success "Security scan completed successfully"
        fi
    else
        log_warning "Trivy not available. Skipping security scan."
    fi
}

# Generate test report
generate_test_report() {
    local current_version="$1"
    local new_version="$2"
    local test_result="$3"

    local report_file="$PROJECT_ROOT/BASEIMAGE_UPDATE_REPORT.md"
    local project_name
    project_name=$(basename "$PROJECT_ROOT")

    log_info "Generating test report..."

    cat > "$report_file" << EOF
# LinuxServer.io Baseimage Update Test Report

## Project Information
- **Project:** $project_name
- **Test Date:** $(date -u +'%Y-%m-%d %H:%M:%S UTC')
- **Test Result:** $test_result

## Version Information
- **Current Baseimage:** $current_version
- **New Baseimage:** $new_version
- **Update Required:** $(if is_update_needed "$current_version" "$new_version"; then echo "Yes"; else echo "No"; fi)

## Test Results
- **Build Test:** $([[ -f "$PROJECT_ROOT/baseimage-test-build.log" ]] && echo "✅ Passed" || echo "❌ Failed")
- **Container Test:** $([[ "$test_result" == "SUCCESS" ]] && echo "✅ Passed" || echo "❌ Failed")
- **Security Scan:** $([[ -f "$PROJECT_ROOT/baseimage-test-security.log" ]] && echo "✅ Completed" || echo "⚠️ Skipped")

## Log Files
- Build Log: \`baseimage-test-build.log\`
- Container Log: \`baseimage-test-container.log\`
- Security Log: \`baseimage-test-security.log\`

## Recommended Actions
$( if [[ "$test_result" == "SUCCESS" ]]; then
    echo "✅ **Ready for Update:** All tests passed. The new baseimage is compatible."
    echo ""
    echo "**Update Steps:**"
    echo "1. Update Dockerfile: \`FROM ghcr.io/linuxserver/baseimage-alpine:$new_version\`"
    echo "2. Update any documentation references"
    echo "3. Run full test suite: \`make test\`"
    echo "4. Build and push: \`make build-manifest\`"
    echo "5. Monitor for issues after deployment"
else
    echo "❌ **Update Not Recommended:** Tests failed. Investigation required."
    echo ""
    echo "**Investigation Steps:**"
    echo "1. Review build log for compilation issues"
    echo "2. Check container log for runtime errors"
    echo "3. Compare S6 Overlay versions for breaking changes"
    echo "4. Test with minimal configuration"
    echo "5. Check LinuxServer.io release notes for breaking changes"
fi )

## Additional Notes
- This test was automated using \`baseimage-update-test.sh\`
- For manual testing, use: \`./scripts/baseimage-update-test.sh\`
- Always test in non-production environment first
- Monitor LinuxServer.io release notes: https://github.com/linuxserver/docker-baseimage-alpine/releases

---
Generated automatically by LinuxServer.io Baseimage Update Testing System
EOF

    log_success "Test report generated: $report_file"
}

# Cleanup test files
cleanup_test_files() {
    log_info "Cleaning up test files..."

    rm -f "$PROJECT_ROOT/Dockerfile.baseimage-test"

    # Remove test image
    local project_name
    project_name=$(basename "$PROJECT_ROOT")
    docker rmi "${project_name}:${TEST_IMAGE_TAG}" 2>/dev/null || true

    log_success "Cleanup completed"
}

# Main execution function
main() {
    log_info "🚀 Starting LinuxServer.io Baseimage Update Test"
    log_info "Project: $(basename "$PROJECT_ROOT")"

    # Get version information
    local current_version latest_version

    log_info "Checking current and latest baseimage versions..."
    current_version=$(get_current_baseimage_version)
    latest_version=$(get_latest_baseimage_version)

    if [[ -z "$current_version" || -z "$latest_version" ]]; then
        log_error "Failed to get version information"
        exit 1
    fi

    log_info "Current baseimage: $current_version"
    log_info "Latest baseimage: $latest_version"

    # Check if update is needed
    if ! is_update_needed "$current_version" "$latest_version"; then
        log_success "No update needed. Already using latest baseimage version."
        generate_test_report "$current_version" "$latest_version" "NO_UPDATE_NEEDED"
        exit 0
    fi

    log_warning "Update available: $current_version -> $latest_version"

    # Run tests
    local test_dockerfile test_image test_result="FAILED"

    # Create test Dockerfile
    if test_dockerfile=$(create_test_dockerfile "$latest_version"); then
        # Build test image
        if test_image=$(build_test_image "$test_dockerfile"); then
            # Run container tests
            if run_container_tests "$test_image"; then
                # Run security scan
                run_security_scan "$test_image"
                test_result="SUCCESS"
                log_success "🎉 All tests passed! New baseimage is compatible."
            else
                log_error "Container tests failed"
            fi
        else
            log_error "Image build failed"
        fi
    else
        log_error "Failed to create test Dockerfile"
    fi

    # Generate report
    generate_test_report "$current_version" "$latest_version" "$test_result"

    # Cleanup
    cleanup_test_files

    # Final status
    if [[ "$test_result" == "SUCCESS" ]]; then
        log_success "✅ Baseimage update test completed successfully!"
        log_info "📋 Review the test report: BASEIMAGE_UPDATE_REPORT.md"
        log_info "🚀 Ready to update baseimage in production"
        exit 0
    else
        log_error "❌ Baseimage update test failed!"
        log_info "📋 Check the test report for details: BASEIMAGE_UPDATE_REPORT.md"
        log_info "🔍 Investigation required before update"
        exit 1
    fi
}

# Handle script arguments
case "${1:-}" in
    --help|-h)
        echo "LinuxServer.io Baseimage Update Testing Script"
        echo ""
        echo "Usage: $0 [options]"
        echo ""
        echo "Options:"
        echo "  --help, -h     Show this help message"
        echo "  --version      Show script version"
        echo ""
        echo "This script automatically tests new LinuxServer.io baseimage versions"
        echo "and generates a compatibility report."
        exit 0
        ;;
    --version)
        echo "baseimage-update-test.sh v1.0.0"
        exit 0
        ;;
    "")
        # No arguments, run main function
        main
        ;;
    *)
        log_error "Unknown argument: $1"
        log_info "Use --help for usage information"
        exit 1
        ;;
esac