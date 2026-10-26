# Beeper Server (headless Beeper client: Client API, MCP, WebSocket events) + bbctl (self-hosted bridges)
# + Beeper CLI, in one container. Server and bridges connect OUT to Beeper: no inbound ports, no database.
#
# Beeper Server, bbctl and the CLI are downloaded at build time and verified against pinned checksums.
# They are Beeper's software and are not redistributed by this repository.
FROM debian:bookworm-slim

# https://api.beeper.com/desktop/update-feed.json?bundleID=com.automattic.beeper.server&platform=linux&channel=stable&arch=x64
ARG BEEPER_VERSION=4.3.229
ARG BEEPER_SHA512=No6Zfp+6OfxwN4ll6Yh95Cvaobc0VqxutlyeBa8GyJOvRvI13Mqvd1XIrC4F+63Rr4SDb3brWGPdvRJoau/dpA==
# https://github.com/beeper/bridge-manager/releases
ARG BBCTL_VERSION=v0.15.0
ARG BBCTL_SHA256=ff3091816429d41aeb51871445f8ccd77864ebe479a57a4b4a5981fd5051a73e
# https://github.com/beeper/cli/releases (sha256 from binaries.json in the npm package beeper-cli)
ARG BEEPER_CLI_VERSION=0.6.2
ARG BEEPER_CLI_SHA256=a881e1d2bc91e31218b251716644ec5f8d161d5ccb30e7eab66cf2ba6410511d

LABEL org.opencontainers.image.title="beeper-server" \
      org.opencontainers.image.description="Beeper Server + bbctl self-hosted bridges + Beeper CLI in one container" \
      org.opencontainers.image.source="https://github.com/aorizondo/beeper-server-docker" \
      org.opencontainers.image.licenses="MIT"

RUN apt-get update \
 && apt-get install -y --no-install-recommends ca-certificates curl libsecret-1-0 libglib2.0-0 \
 && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL -o /tmp/server.tgz "https://beeper-desktop.download.beeper.com/builds/beeper-server-${BEEPER_VERSION}-linux-x64.tar.gz" \
 && test "$(openssl dgst -sha512 -binary /tmp/server.tgz | base64 -w0)" = "$BEEPER_SHA512" \
 && mkdir -p /opt/beeper && tar -xzf /tmp/server.tgz -C /opt/beeper --strip-components=1 && rm /tmp/server.tgz \
 && ln -s /opt/beeper/beeper-server /usr/local/bin/beeper-server

RUN curl -fsSL -o /usr/local/bin/bbctl "https://github.com/beeper/bridge-manager/releases/download/${BBCTL_VERSION}/bbctl-linux-amd64" \
 && echo "${BBCTL_SHA256}  /usr/local/bin/bbctl" | sha256sum -c - \
 && chmod 0755 /usr/local/bin/bbctl

RUN curl -fsSL -o /tmp/cli.tgz "https://github.com/beeper/cli/releases/download/v${BEEPER_CLI_VERSION}/beeper-cli-${BEEPER_CLI_VERSION}-linux-x64.tar.gz" \
 && echo "${BEEPER_CLI_SHA256}  /tmp/cli.tgz" | sha256sum -c - \
 && mkdir -p /tmp/cli && tar -xzf /tmp/cli.tgz -C /tmp/cli --no-same-owner 2>/dev/null \
 && install -m 0755 /tmp/cli/bin/beeper /usr/local/bin/beeper && rm -rf /tmp/cli /tmp/cli.tgz

COPY start.sh /app/start.sh
COPY beeper-setup.sh /usr/local/bin/beeper-setup
RUN chmod 0755 /app/start.sh /usr/local/bin/beeper-setup

# All state (server database and keys, CLI login, bbctl login and bridge databases) lives in /data.
ENV HOME=/data XDG_CACHE_HOME=/data/cache BRIDGES=""
VOLUME /data
WORKDIR /data
EXPOSE 23373
CMD ["/app/start.sh"]
