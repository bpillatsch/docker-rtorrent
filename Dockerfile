FROM alpine:3.8

ARG OVERLAY_VERSION=1.21.7.0
ARG OVERLAY_ARCH=amd64

ARG UID=911
ARG GID=911

ENV S6_FIX_ATTRS_HIDDEN=1
ADD https://github.com/just-containers/s6-overlay/releases/download/v${OVERLAY_VERSION}/s6-overlay-${OVERLAY_ARCH}.tar.gz /tmp/
RUN gunzip -c /tmp/s6-overlay-${OVERLAY_ARCH}.tar.gz | tar -xf - -C / && \
  rm -rf /tmp/*

RUN apk add --no-cache --update rtorrent dtach && \
  adduser -D -u ${UID} -g ${GID} rtorrent && \
  mkdir -p /config/session /data/work /data/complete /log /socket && \
  chown -R rtorrent:rtorrent /config /data /log /socket

# Install Pyrocore and pyrotorque
# Pyrocore only installs to ~/bin and pyroadmin to ~/.pyroscope/rtorrent.d when invoked from update-to-head.sh
# Move ~/bin files and clean up ~/ directories
# bash required for #! and 'builtin cd' usage in scripts, also appears some of the rtorrent commands invoke bash instead of sh
ENV PYRO_CONFIG_DIR=/config/pyrocore
RUN apk add --no-cache --update -t build-deps build-base linux-headers python-dev git && \
  apk add --no-cache --update python bash && \
  mkdir -p /root/bin /root/.pyroscope/rtorrent.d && \
  git clone "https://github.com/pyroscope/pyrocore.git" /opt/pyrocore && \
  su -c "echo 'export PYRO_CONFIG_DIR=${PYRO_CONFIG_DIR}' >> ~/.profile" rtorrent && \
  /opt/pyrocore/update-to-head.sh && \
  /opt/pyrocore/bin/pip install -r /opt/pyrocore/requirements-torque.txt && \
  mv /root/bin/* /usr/local/bin/ && \
  chown -R rtorrent:rtorrent /config && \
  rm -rf /root/.cache /root/bin /root/.pyroscope && \
  apk del --purge build-deps

# Permissions will be fixed by s6-overlay fix-attrs.d at runtime
COPY /rootfs/ /

VOLUME ["/config", "/log", "/data", "/socket"]

ENTRYPOINT ["/init"]
