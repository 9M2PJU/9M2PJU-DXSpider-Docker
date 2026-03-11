FROM alpine:3.23

ARG SPIDER_INSTALL_DIR=/spider
ARG SPIDER_USERNAME=sysop
ARG SPIDER_UID=1000

WORKDIR ${SPIDER_INSTALL_DIR}

# Install system dependencies and available perl-apk packages
RUN apk add --no-cache \
    bash \
    git \
    nano \
    netcat-openbsd \
    perl-db_file \
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
    perl-dbd-mysql \
    perl-dbi \
    perl-net-cidr-lite \
    perl-date-calc \
    perl-list-moreutils \
    mysql-client \
    ttyd \
    wget \
    tini \
    su-exec \
    && apk add --no-cache --virtual .build-deps \
    gcc \
    make \
    musl-dev \
    ncurses-dev \
    perl-app-cpanminus \
    perl-dev \
    mysql-dev \
# Install ONLY the modules not found in APK
    && cpanm --no-wget EV Date::Manip JSON::XS Data::Structure::Util \
    && cpanm Net::MQTT::Simple File::Copy::Recursive Authen::SASL \
    && adduser -D -u ${SPIDER_UID} -h ${SPIDER_INSTALL_DIR} ${SPIDER_USERNAME} \
    && git config --global --add safe.directory ${SPIDER_INSTALL_DIR} \
    && git clone -b mojo https://github.com/EA3CV/dxspider ${SPIDER_INSTALL_DIR} \
    && git rev-parse --short HEAD > ${SPIDER_INSTALL_DIR}/.version \
    && mkdir -p ${SPIDER_INSTALL_DIR}/local ${SPIDER_INSTALL_DIR}/local_cmd ${SPIDER_INSTALL_DIR}/local_data \
# Set permissions
    && chown -R ${SPIDER_USERNAME}:${SPIDER_USERNAME} ${SPIDER_INSTALL_DIR} \
    && find ${SPIDER_INSTALL_DIR} -type d -exec chmod 2775 {} \; \
    && find ${SPIDER_INSTALL_DIR} -type f -name '*.pl' -exec chmod 775 {} \; \
    && apk del .build-deps \
    && rm -rf /root/.cpanm /var/cache/apk/*

# Copy configuration files
COPY ./connect ${SPIDER_INSTALL_DIR}/connect/
COPY motd ${SPIDER_INSTALL_DIR}/data/
COPY startup ${SPIDER_INSTALL_DIR}/scripts/
COPY crontab ${SPIDER_INSTALL_DIR}/local_cmd/
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Start as root so entrypoint.sh can fix any volume permissions, 
# but the script will drop to the sysop user for the app.
ENTRYPOINT ["/sbin/tini", "--", "/entrypoint.sh"]
