# Multi-stage build for Tandoor Recipes based on LinuxServer.io Alpine
FROM ghcr.io/linuxserver/baseimage-alpine:3.22

# Build arguments
ARG BUILD_DATE
ARG VERSION
ARG VCS_REF
ARG TANDOOR_VERSION="1.5.19"
ARG PROJECT_VERSION="1.5.19-automation.1"

# Environment variables
ENV PYTHONUNBUFFERED=1 \
    DOCKER=true \
    HOME="/config" \
    TANDOOR_VERSION=${TANDOOR_VERSION} \
    PROJECT_VERSION=${PROJECT_VERSION}

# OCI Labels for LinuxServer.io compatibility
LABEL build_version="mildman1848 version:- ${VERSION} Build-date:- ${BUILD_DATE}"
LABEL maintainer="mildman1848"
LABEL org.opencontainers.image.title="Tandoor Recipes"
LABEL org.opencontainers.image.description="Self-hosted recipe management server based on LinuxServer.io Alpine with S6 Overlay"
LABEL org.opencontainers.image.authors="mildman1848"
LABEL org.opencontainers.image.vendor="mildman1848"
LABEL org.opencontainers.image.licenses="AGPL-3.0"
LABEL org.opencontainers.image.version=${VERSION}
LABEL org.opencontainers.image.revision=${VCS_REF}
LABEL org.opencontainers.image.created=${BUILD_DATE}
LABEL org.opencontainers.image.source="https://github.com/mildman1848/tandoor"
LABEL org.opencontainers.image.url="https://hub.docker.com/r/mildman1848/tandoor"
LABEL org.opencontainers.image.documentation="https://github.com/mildman1848/tandoor"

# Create application directory
RUN mkdir -p /app && chown abc:abc /app
WORKDIR /app

# Install build and runtime packages, build Python deps, then cleanup
RUN \
    echo "**** install build packages ****" && \
    apk add --no-cache --virtual .build-deps \
        gcc \
        musl-dev \
        postgresql-dev \
        zlib-dev \
        jpeg-dev \
        libwebp-dev \
        openssl-dev \
        libffi-dev \
        cargo \
        openldap-dev \
        python3-dev \
        xmlsec-dev \
        build-base \
        g++ \
        curl \
        rust && \
    echo "**** install runtime packages ****" && \
    apk add --no-cache \
        python3 \
        py3-pip \
        py3-setuptools \
        py3-wheel \
        postgresql-libs \
        postgresql-client \
        gettext \
        zlib \
        libjpeg \
        libwebp \
        libxml2-dev \
        libxslt-dev \
        openldap \
        git \
        libgcc \
        libstdc++ \
        nginx \
        tini \
        envsubst \
        nodejs \
        npm \
        xmlsec && \
    echo "**** create symbolic link for python ****" && \
    ln -sf /usr/bin/python3 /usr/bin/python && \
    echo "**** download Tandoor Recipes ****" && \
    curl -o /tmp/tandoor.tar.gz -L \
        "https://github.com/TandoorRecipes/recipes/archive/refs/tags/${TANDOOR_VERSION}.tar.gz" && \
    tar xf /tmp/tandoor.tar.gz -C /app --strip-components=1 && \
    echo "**** install Python dependencies ****" && \
    sed -i '/# Development/,$d' /app/requirements.txt && \
    python -m venv /app/venv && \
    /app/venv/bin/python -m pip install --upgrade pip && \
    /app/venv/bin/pip install wheel==0.45.1 && \
    /app/venv/bin/pip install setuptools_rust==1.10.2 && \
    /app/venv/bin/pip install -r /app/requirements.txt --no-cache-dir && \
    echo "**** configure nginx ****" && \
    rm -rf /etc/nginx/http.d && \
    ln -s /app/http.d /etc/nginx/http.d && \
    ln -sf /dev/stdout /var/log/nginx/access.log && \
    ln -sf /dev/stderr /var/log/nginx/error.log && \
    echo "**** collect version information ****" && \
    /app/venv/bin/python /app/version.py && \
    echo "**** cleanup ****" && \
    find /app -type d -name ".git" -exec rm -rf {} + && \
    apk del .build-deps && \
    rm -rf \
        /tmp/* \
        /root/.cache \
        /root/.cargo

# Copy S6 service files
COPY root/ /

# Ports and volumes
EXPOSE 8080
VOLUME ["/config", "/app/mediafiles", "/app/staticfiles"]

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=5 \
    CMD ps aux | grep -v grep | grep "gunicorn" || exit 1

# Use S6 Overlay as entrypoint
ENTRYPOINT ["/init"]