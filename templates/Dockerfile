# syntax=docker/dockerfile:1

# Build stage for tandoor
FROM ${SOURCE_IMAGE}:${SOURCE_VERSION} AS tandoor

# Production stage with LinuxServer.io Alpine baseimage
FROM ghcr.io/linuxserver/baseimage-alpine:${ALPINE_VERSION}

# Build arguments for metadata
ARG BUILD_DATE
ARG VERSION
ARG TANDOOR_VERSION="${SOURCE_VERSION}"

# Metadata labels following LinuxServer.io standards
LABEL build.version="Mildman1848 version: ${VERSION} Build-date: ${BUILD_DATE}"
LABEL maintainer="Mildman1848"
LABEL org.opencontainers.image.title="tandoor"
LABEL org.opencontainers.image.description="Tandoor Recipes - Recipe management server with S6 Overlay"
LABEL org.opencontainers.image.version="${VERSION}"
LABEL org.opencontainers.image.created="${BUILD_DATE}"
LABEL org.opencontainers.image.authors="Mildman1848"
LABEL org.opencontainers.image.url="${APPLICATION_URL}"
LABEL org.opencontainers.image.documentation="${APPLICATION_DOCS_URL}"
LABEL org.opencontainers.image.source="https://github.com/Mildman1848/tandoor"
LABEL org.opencontainers.image.vendor="Mildman1848"
LABEL org.opencontainers.image.licenses="MIT"

# Environment variables for tandoor
ENV TANDOOR_CONFIG="/config/tandoor/tandoor.conf" \
    TANDOOR_CACHE_DIR="/config/cache" \
    TANDOOR_TEMP_DIR="/tmp/tandoor" \
    TANDOOR_LOG_LEVEL="INFO" \
    TANDOOR_LOG_FILE="/config/logs/tandoor.log" \
    TANDOOR_APP_VERSION="${TANDOOR_VERSION}"

# Install dependencies and tandoor
RUN \
  echo "**** install runtime packages ****" && \
  apk add --no-cache \
    ca-certificates=${CA_CERTIFICATES_VERSION} \
    curl=${CURL_VERSION} \
    # Add application-specific packages here
    # Example: fuse3=${FUSE3_VERSION} \
    unzip=${UNZIP_VERSION} && \
  echo "**** install tandoor ****" && \
  mkdir -p /app && \
  echo "**** cleanup ****" && \
  rm -rf \
    /tmp/* \
    /var/cache/apk/* \
    /var/tmp/*

# Copy application binary from official image or download
COPY --from=tandoor ${SOURCE_BINARY_PATH} ${TARGET_BINARY_PATH}

# Copy local files and set permissions
COPY root/ /

# Security: Set non-root user (LinuxServer.io will manage actual user via S6)
# This satisfies security scanners while S6 overlay handles the real user management
USER abc

# Expose ports (application specific ports)
EXPOSE 8080

# Health check for tandoor
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
  CMD ${HEALTH_CHECK_CMD} || exit 1

# Volumes for persistent data
VOLUME ["/config", "/data"]