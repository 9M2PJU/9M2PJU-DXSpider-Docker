FROM alpine:3.20

# ARG SPIDER_GIT_REPOSITORY=git://scm.dxcluster.org/scm/spider
ARG SPIDER_GIT_REPOSITORY=https://github.com/9M2PJU/dxspider.git
# SPIDER_VERSION can be "mojo" or "master"
ARG SPIDER_VERSION=mojo

ARG SPIDER_INSTALL_DIR=${SPIDER_INSTALL_DIR:-/spider}
ARG SPIDER_USERNAME=${SPIDER_USERNAME:-sysop}
ARG SPIDER_UID=${SPIDER_UID:-1000}


RUN apk update \
    && apk add \
    gcc \
    git \ 
    make \
    musl-dev \
    ncurses-dev \
    perl-app-cpanminus \
    perl-dev \
    nano \
    netcat-openbsd \
    perl-db_file \
    perl-dev \
    perl-digest-sha1 \
    perl-io-socket-ssl \
    perl-net-telnet \ 
    perl-timedate \
    perl-yaml-libyaml \
    perl-test-simple \ 
    perl-curses \ 
    perl-app-cpanminus \
    perl-mojolicious \
    perl-math-round \
    perl-json \
    mysql-client \
    mysql-dev \
    perl-dbd-mysql \ 
    perl-dbi musl \ 
    perl-net-cidr-lite \
    make \
    musl-dev \
    ncurses-dev \
    mysql-dev \
    gcc \
    ttyd \
    wget \
    && cpanm --no-wget Data::Structure::Util \
    && adduser -D -u ${SPIDER_UID} -h ${SPIDER_INSTALL_DIR} ${SPIDER_USERNAME} \
    && git config --global --add safe.directory ${SPIDER_INSTALL_DIR} \
    && git clone -b ${SPIDER_VERSION} ${SPIDER_GIT_REPOSITORY} ${SPIDER_INSTALL_DIR} \
    && mkdir -p ${SPIDER_INSTALL_DIR}/local ${SPIDER_INSTALL_DIR}/local_cmd ${SPIDER_INSTALL_DIR}/local_data \
    && find ${SPIDER_INSTALL_DIR}/. -type d -exec chmod 2775 {} \; \ 
    && find ${SPIDER_INSTALL_DIR}/. -type f -name '*.pl' -exec chmod 775 {} \; \
    && (cd ${SPIDER_INSTALL_DIR}/src && make) \
    && apk del --purge \
    gcc \
    make \
    musl-dev \
    ncurses-dev \
    perl-app-cpanminus \
    perl-dev \
    && rm -rf /var/cache/apk/*


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

# Set permissions on the mounted volumes
RUN chmod -R a+rwx /spider

# COPY entrypoint.sh file
COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/bin/sh", "/entrypoint.sh"]
