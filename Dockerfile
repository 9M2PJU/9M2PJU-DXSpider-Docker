# Dockerfile
FROM alpine:3.20

# Set environment variables (these can be overridden in docker-compose.yml)
ENV CLUSTER_CALLSIGN="MY1CALL-2"
ENV CLUSTER_SYSOP_NAME="Joe Bloggs"
ENV CLUSTER_SYSOP_CALLSIGN="MY1CALL"
ENV CLUSTER_LATITUDE="+51.5"
ENV CLUSTER_LONGITUDE="-0.13"
ENV CLUSTER_LOCATOR="IO91WM"
ENV CLUSTER_QTH='London, England'
ENV CLUSTER_SYSOP_EMAIL="joe@test.com"
ENV CLUSTER_SYSOP_BBS_ADDRESS="MY1CALL@MY1CALL-2.#1.CTY.CO"
ENV CLUSTER_PORT=7300

# Create the volume mount point (no need to mount here, docker-compose will handle it)
VOLUME /spider

# Expose the port
EXPOSE 7300
