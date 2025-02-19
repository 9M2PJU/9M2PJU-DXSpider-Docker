FROM alpine:latest

# ARGs for configuration
ARG SPIDER_GIT_REPOSITORY=git://scm.dxcluster.org/scm/spider
ARG SPIDER_VERSION=mojo
ARG SPIDER_INSTALL_DIR=${SPIDER_INSTALL_DIR:-/spider}
ARG SPIDER_USERNAME=${SPIDER_USERNAME:-sysop}
ARG SPIDER_UID=${SPIDER_UID:-1000}

# Install necessary packages and cpanm
RUN apk update && apk add --no-cache \
    gcc \
    git \
    make \
    ncurses-dev \
    perl \
    nano \
    netcat-openbsd \
    mariadb-dev \
    wget \
    curl \
    musl-dev \
    perl-dev \
    && curl -L https://cpanmin.us | perl - App::cpanminus \
    && cpanm --no-wget Data::Structure::Util \
    && cpanm --no-wget \
        DB_File \
        Digest::SHA1 \
        IO::Socket::SSL \
        Net::Telnet \
        Date::Calc \
        YAML::LibYAML \
        Test::Simple \
        Curses \
        App::cpanminus \
        Mojolicious \
        Math::Round \
        JSON \
        DBD::mysql \
        DBI \
        Net::CIDR::Lite \
    && apk del .build-deps

# Add user and set up git config
RUN adduser --disabled-password --uid ${SPIDER_UID} --home ${SPIDER_INSTALL_DIR} ${SPIDER_USERNAME} \
    && git config --global --add safe.directory ${SPIDER_INSTALL_DIR}

# Clone Spider repository and set up permissions
RUN git clone -b ${SPIDER_VERSION} ${SPIDER_GIT_REPOSITORY} ${SPIDER_INSTALL_DIR} \
    && mkdir -p ${SPIDER_INSTALL_DIR}/local ${SPIDER_INSTALL_DIR}/local_cmd ${SPIDER_INSTALL_DIR}/local_data \
    && find ${SPIDER_INSTALL_DIR}/. -type d -exec chmod 2775 {} \; \
    && find ${SPIDER_INSTALL_DIR}/. -type f -name '*.pl' -exec chmod 775 {} \; \
    && (cd ${SPIDER_INSTALL_DIR}/src && make)

# Clean up unnecessary packages and dependencies
RUN apk del \
        gcc \
        make \
        ncurses-dev \
        perl-dev \
    && rm -rf /var/cache/apk/*

# Install ttyd from GitHub
RUN curl -L https://github.com/tsl0922/ttyd/releases/download/1.6.1/ttyd_1.6.1_amd64.apk -o ttyd.apk \
    && apk add --no-cache --allow-untrusted ttyd.apk \
    && rm ttyd.apk

# Copy necessary files
COPY ./connect /spider/connect/
COPY motd ${SPIDER_INSTALL_DIR}/data
COPY startup ${SPIDER_INSTALL_DIR}/scripts
COPY crontab ${SPIDER_INSTALL_DIR}/local_cmd

# Set permissions for spider directory
RUN chown -R ${SPIDER_USERNAME}:${SPIDER_USERNAME} ${SPIDER_INSTALL_DIR}/.

# Set user for running the Spider application
USER ${SPIDER_UID}

# Copy entrypoint.sh file and set as entrypoint
COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/bin/sh", "/entrypoint.sh"]
