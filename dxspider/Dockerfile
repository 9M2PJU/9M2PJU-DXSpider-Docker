FROM ghcr.io/ubuntu:22.04

ARG SPIDER_GIT_REPOSITORY=git://scm.dxcluster.org/scm/spider
# SPIDER_VERSION can be "mojo" or "master"
ARG SPIDER_VERSION=mojo

ARG SPIDER_INSTALL_DIR=${SPIDER_INSTALL_DIR:-/spider}
ARG SPIDER_USERNAME=${SPIDER_USERNAME:-sysop}
ARG SPIDER_UID=${SPIDER_UID:-1000}

RUN apt-get update \
    && apt-get install -y \
    gcc \
    git \
    make \
    libncurses-dev \
    perl \
    nano \
    netcat \
    perl-modules-5.34 \
    libmysqlclient-dev \
    ttyd \
    wget \
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
    && adduser --disabled-password --uid ${SPIDER_UID} --home ${SPIDER_INSTALL_DIR} ${SPIDER_USERNAME} \
    && git config --global --add safe.directory ${SPIDER_INSTALL_DIR} \
    && git clone -b ${SPIDER_VERSION} ${SPIDER_GIT_REPOSITORY} ${SPIDER_INSTALL_DIR} \
    && mkdir -p ${SPIDER_INSTALL_DIR}/local ${SPIDER_INSTALL_DIR}/local_cmd ${SPIDER_INSTALL_DIR}/local_data \
    && find ${SPIDER_INSTALL_DIR}/. -type d -exec chmod 2775 {} \; \
    && find ${SPIDER_INSTALL_DIR}/. -type f -name '*.pl' -exec chmod 775 {} \; \
    && (cd ${SPIDER_INSTALL_DIR}/src && make) \
    && apt-get remove --purge -y \
        gcc \
        make \
        libncurses-dev \
        perl-modules-5.34 \
    && apt-get autoremove -y && apt-get clean && rm -rf /var/lib/apt/lists/*

# Copy connection node files - cleanup
RUN rm -rf /spider/connect/*

# Copy node connection files over
COPY ./connect /spider/connect/

# Copy Message of the day file motd
COPY motd ${SPIDER_INSTALL_DIR}/data

# Copy Startup script
COPY startup ${SPIDER_INSTALL_DIR}/scripts

# Copy crontab
COPY crontab ${SPIDER_INSTALL_DIR}/local_cmd

# Permissions for spider 
RUN chown -R ${SPIDER_USERNAME}:${SPIDER_USERNAME} ${SPIDER_INSTALL_DIR}/.

USER ${SPIDER_UID}

# COPY entrypoint.sh file
COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/bin/sh", "/entrypoint.sh"]
