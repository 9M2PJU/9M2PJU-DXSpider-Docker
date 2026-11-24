# =============================================================================
#  9M2PJU DXSpider Docker — Alpine-based DX Cluster container
#  Image version: 2.7.0-9M2PJU
#
#  Packages DXSpider (https://github.com/EA3CV/dxspider) in a hardened
#  Alpine container with a ttyd web console for remote administration.
#  The cluster runs as a non-root sysop user; root is only used during
#  entrypoint to fix bind-mount permissions.
# =============================================================================

FROM alpine:3.23

# --- Build arguments (override with --build-arg) ---
ARG SPIDER_INSTALL_DIR=/spider
ARG SPIDER_USERNAME=sysop
ARG SPIDER_UID=1000
# DXSpider git branch: "mojo" (recommended, active development) or "master"
ARG SPIDER_VERSION=mojo
# Pin DXSpider to a specific commit SHA for reproducible builds.
# This prevents supply-chain surprises from a moving branch HEAD.
# Override with --build-arg SPIDER_GIT_REF=<sha> to bump.
# Current mojo HEAD as of 2026-11-24 (v1.57 build 933):
ARG SPIDER_GIT_REF=b9bc2369df47cfc8aee3c740e3dd42178605e9d3

# --- OCI image labels (consumed by registries like GHCR) ---
LABEL org.opencontainers.image.title="9M2PJU DXSpider Docker" \
      org.opencontainers.image.description="High-performance DXSpider Amateur Radio Cluster in a container" \
      org.opencontainers.image.authors="9M2PJU" \
      org.opencontainers.image.source="https://github.com/9M2PJU/9M2PJU-DXSpider-Docker" \
      org.opencontainers.image.licenses="GPL-3.0" \
      org.opencontainers.image.version="2.7.0" \
      org.opencontainers.image.url="https://hamradio.my"

# --- Persist build args as runtime env (consumed by entrypoint.sh) ---
ENV SPIDER_INSTALL_DIR=${SPIDER_INSTALL_DIR}
ENV SPIDER_USERNAME=${SPIDER_USERNAME}
ENV SPIDER_UID=${SPIDER_UID}

# --- Default cluster configuration ---
# These are overridden at runtime via .env / docker -e flags.
# Defaults use a generic placeholder node (N0CALL-2).
ENV CLUSTER_CALLSIGN=N0CALL-2
ENV CLUSTER_SYSOP_CALLSIGN=9M2PJU
ENV CLUSTER_SYSOP_NAME="DXSpider Sysop"
ENV CLUSTER_QTH="DXSpider Node"
ENV CLUSTER_LOCATOR=JO01aa
ENV CLUSTER_PORT=7300
ENV CLUSTER_SYSOP_PORT=8080
# Set to "yes" at runtime to force-regenerate DXVars.pm and Listeners.pm
ENV OVERWRITE_CONFIG=no

WORKDIR ${SPIDER_INSTALL_DIR}

# =============================================================================
#  Layer 1: Install runtime + build dependencies, clone DXSpider, clean up
# =============================================================================
RUN apk add --no-cache \
    # --- Shell / utilities ---
    bash \
    git \
    nano \
    netcat-openbsd \
    wget \
    # --- Init / privilege drop ---
    tini \
    su-exec \
    # --- Perl runtime modules (from Alpine packages, no CPAN needed) ---
    # NOTE: perl-db_file is installed separately below — it is not packaged
    # for all architectures (e.g., linux/386, ppc64le, s390x).
    perl-digest-sha1 \
    perl-io-socket-ssl \
    perl-net-telnet \
    perl-timedate \
    perl-yaml-libyaml \
    perl-test-simple \
    perl-curses \
    perl-mojolicious \
    perl-math-round \
    perl-json \
    # --- Database drivers ---
    # perl-dbd-mysql  → optional MariaDB backend for spot logging
    # perl-dbd-sqlite → required for the user database (DXUser.pm) even
    #                   in flat-file mode (default storage)
    perl-dbd-mysql \
    perl-dbd-sqlite \
    perl-dbi \
    # --- Additional Perl modules used by DXSpider Mojo features ---
    perl-archive-zip \
    perl-authen-sasl \
    perl-date-calc \
    perl-date-manip \
    perl-ev \
    perl-file-copy-recursive \
    perl-html-parser \
    perl-io-socket-inet6 \
    perl-io-tty \
    perl-json-xs \
    perl-libwww \
    perl-list-moreutils \
    perl-lwp-protocol-https \
    perl-mailtools \
    perl-net-cidr-lite \
    perl-net-mqtt-simple \
    perl-net-smtp-ssl \
    # --- Berkeley DB runtime (needed by DB_File, installed below) ---
    db \
    # --- MariaDB client (for optional DB backend connectivity) ---
    mysql-client \
    # --- Web console (ttyd serves a web-based terminal) ---
    ttyd \
    && apk add --no-cache --virtual .build-deps \
    gcc \
    make \
    musl-dev \
    ncurses-dev \
    perl-app-cpanminus \
    perl-dev \
    mysql-dev \
    db-dev \
    # --- Install DB_File ---
    # perl-db_file is available as an Alpine package on amd64/arm64/arm/v7/arm/v6
    # but NOT on 386/ppc64le/s390x. Try the Alpine package first (fast), then
    # fall back to building from CPAN (works everywhere, just slower).
    && (apk add --no-cache perl-db_file 2>/dev/null || cpanm --notest DB_File) \
    # Install CPAN modules not available as Alpine packages.
    # Data::Structure::Util is a C extension (hence the build deps above).
    # --notest skips the test suite (test deps aren't installed on musl).
    && cpanm --notest --no-wget Data::Structure::Util LWP::Parallel::UserAgent Email::Sender \
    # Verify full EA3CV/DXSpider Mojo Perl dependency inventory at build time
    && perl -e 'for my $m (qw(EV Mojolicious JSON JSON::XS Data::Structure::Util Math::Round Net::CIDR::Lite DBI DBD::SQLite Date::Parse HTML::Parser IO::Socket::INET6 Archive::Zip Curses Mail::Internet Digest::SHA LWP::UserAgent LWP::Parallel::UserAgent DB_File IO::Pty Authen::SASL Net::SMTP::SSL Email::Sender)) { eval "require $m; 1" or die "Missing required Perl module: $m\n"; } Mojolicious->VERSION(7.26);' \
    # --- Create the non-root sysop user ---
    && adduser -D -u ${SPIDER_UID} -h ${SPIDER_INSTALL_DIR} ${SPIDER_USERNAME} \
    # --- Clone DXSpider at the pinned commit ---
    # --no-checkout avoids checking out the default branch tip before
    # we pin to the specific SHA via git checkout.
    && git config --global --add safe.directory ${SPIDER_INSTALL_DIR} \
    && git clone --no-checkout -b ${SPIDER_VERSION} https://github.com/EA3CV/dxspider ${SPIDER_INSTALL_DIR} \
    && cd ${SPIDER_INSTALL_DIR} \
    && git checkout ${SPIDER_GIT_REF} \
    && git rev-parse --short HEAD > ${SPIDER_INSTALL_DIR}/.version \
    # --- Create runtime directories ---
    && mkdir -p ${SPIDER_INSTALL_DIR}/local ${SPIDER_INSTALL_DIR}/local_cmd ${SPIDER_INSTALL_DIR}/local_data \
    # --- Set ownership and permissions ---
    # 2775 = setgid on directories (new files inherit group=sysop)
    # 775  = rwxrwxr-x on .pl scripts (sysop group can edit)
    && chown -R ${SPIDER_USERNAME}:${SPIDER_USERNAME} ${SPIDER_INSTALL_DIR} \
    && find ${SPIDER_INSTALL_DIR} -type d -exec chmod 2775 {} \; \
    && find ${SPIDER_INSTALL_DIR} -type f -name '*.pl' -exec chmod 775 {} \; \
    # --- Remove build-only packages to shrink the image ---
    && apk del .build-deps \
    && rm -rf /root/.cpanm /var/cache/apk/*

# =============================================================================
#  Layer 2: Copy default configuration files into the image
#
#  These are FALLBACK DEFAULTS only. When running via docker compose (or
#  docker run with -v bind mounts), the host files override these copies
#  at runtime. This means:
#    - Rebuilding the image does NOT change your configuration
#    - Your host files (connect/, local_cmd/, startup, motd, etc.) are
#      always the source of truth
#    - These COPYs only matter for standalone `docker run` without mounts
# =============================================================================
COPY ./connect ${SPIDER_INSTALL_DIR}/connect/
COPY motd ${SPIDER_INSTALL_DIR}/data/
COPY startup ${SPIDER_INSTALL_DIR}/scripts/
COPY local_cmd/crontab ${SPIDER_INSTALL_DIR}/local_cmd/crontab
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# =============================================================================
#  Healthcheck: verify the cluster is listening on the telnet port.
#  Uses the CLUSTER_PORT env var (defaults to 7300).
# =============================================================================
HEALTHCHECK --interval=30s --timeout=10s --start-period=20s --retries=3 \
  CMD nc -z localhost "${CLUSTER_PORT:-7300}" || exit 1

# =============================================================================
#  Entrypoint: tini reaps zombies and forwards signals to entrypoint.sh,
#  which fixes volume permissions, generates config, then drops to sysop.
# =============================================================================
ENTRYPOINT ["/sbin/tini", "--", "/entrypoint.sh"]
