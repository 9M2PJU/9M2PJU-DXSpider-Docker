# Multi-stage Dockerfile for DXSpider
# Stage 1: Build environment
# Stage 2: Runtime environment (smaller, no build tools)

# =============================================================================
# Stage 1: Builder
# =============================================================================
FROM alpine:3.20 AS builder

ARG SPIDER_GIT_REPOSITORY=git://scm.dxcluster.org/scm/spider
ARG SPIDER_VERSION=mojo
ARG SPIDER_INSTALL_DIR=/spider

# Install build dependencies
RUN apk update && apk add --no-cache \
    # Build tools
    gcc \
    git \
    make \
    musl-dev \
    ncurses-dev \
    perl-dev \
    mysql-dev \
    # Perl and cpanm for building modules
    perl \
    perl-app-cpanminus \
    # Runtime deps needed during build
    perl-db_file \
    perl-digest-sha1 \
    perl-io-socket-ssl \
    perl-net-telnet \
    perl-timedate \
    perl-yaml-libyaml \
    perl-curses \
    perl-mojolicious \
    perl-math-round \
    perl-json \
    perl-dbd-mysql \
    perl-dbi \
    perl-net-cidr-lite \
    perl-test-simple

# Install Perl modules that need compilation
RUN cpanm --no-wget --notest Data::Structure::Util

# Clone DXSpider repository
RUN git config --global --add safe.directory ${SPIDER_INSTALL_DIR} \
    && git clone -b ${SPIDER_VERSION} ${SPIDER_GIT_REPOSITORY} ${SPIDER_INSTALL_DIR}

# Create required directories
RUN mkdir -p ${SPIDER_INSTALL_DIR}/local \
             ${SPIDER_INSTALL_DIR}/local_cmd \
             ${SPIDER_INSTALL_DIR}/local_data

# Set permissions on directories and scripts
RUN find ${SPIDER_INSTALL_DIR}/. -type d -exec chmod 2775 {} \; \
    && find ${SPIDER_INSTALL_DIR}/. -type f -name '*.pl' -exec chmod 775 {} \;

# Compile native code
RUN cd ${SPIDER_INSTALL_DIR}/src && make

# =============================================================================
# Stage 2: Runtime
# =============================================================================
FROM alpine:3.20 AS runtime

# Labels for container metadata
LABEL org.opencontainers.image.title="DXSpider" \
      org.opencontainers.image.description="DX Cluster software for amateur radio operators" \
      org.opencontainers.image.source="https://github.com/9M2PJU/9M2PJU-DXSpider-Docker" \
      org.opencontainers.image.vendor="9M2PJU" \
      org.opencontainers.image.licenses="MIT"

ARG SPIDER_INSTALL_DIR=/spider
ARG SPIDER_USERNAME=sysop
ARG SPIDER_UID=1000

# Install only runtime dependencies (no build tools)
RUN apk update && apk add --no-cache \
    # Core Perl runtime
    perl \
    perl-db_file \
    perl-digest-sha1 \
    perl-io-socket-ssl \
    perl-net-telnet \
    perl-timedate \
    perl-yaml-libyaml \
    perl-curses \
    perl-mojolicious \
    perl-math-round \
    perl-json \
    perl-dbd-mysql \
    perl-dbi \
    perl-net-cidr-lite \
    perl-test-simple \
    # MySQL client for database connectivity
    mysql-client \
    # Network utilities
    netcat-openbsd \
    # Web terminal for sysop console
    ttyd \
    # Required for signal handling in entrypoint
    procps \
    && rm -rf /var/cache/apk/*

# Create sysop user
RUN adduser -D -u ${SPIDER_UID} -h ${SPIDER_INSTALL_DIR} ${SPIDER_USERNAME}

# Copy compiled DXSpider from builder stage
COPY --from=builder ${SPIDER_INSTALL_DIR} ${SPIDER_INSTALL_DIR}

# Copy Perl modules installed via cpanm
COPY --from=builder /usr/local/lib/perl5 /usr/local/lib/perl5
COPY --from=builder /usr/local/share/perl5 /usr/local/share/perl5

# Clean up default connect files and copy custom ones
RUN rm -rf ${SPIDER_INSTALL_DIR}/connect/*
COPY ./connect ${SPIDER_INSTALL_DIR}/connect/

# Copy configuration files
COPY motd ${SPIDER_INSTALL_DIR}/data/
COPY startup ${SPIDER_INSTALL_DIR}/scripts/
COPY crontab ${SPIDER_INSTALL_DIR}/local_cmd/

# Set ownership to sysop user
RUN chown -R ${SPIDER_USERNAME}:${SPIDER_USERNAME} ${SPIDER_INSTALL_DIR}

# Copy entrypoint script
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Switch to non-root user
USER ${SPIDER_UID}

# Health check will be defined in docker-compose.yml for flexibility
# Default ports: 7300 (telnet), 8050 (web console)
EXPOSE 7300 8050

ENTRYPOINT ["/bin/sh", "/entrypoint.sh"]
