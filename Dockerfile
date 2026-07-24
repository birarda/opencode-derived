FROM ghcr.io/anomalyco/opencode:latest

USER root

RUN apk add --no-cache \
    bash \
    build-base \
    ca-certificates \
    cargo \
    clippy \
    git \
    github-cli \
    openssh-client \
    pkgconf \
    rust \
    rustfmt \
    shadow \
    su-exec

ARG DEFAULT_UID=1000
ARG DEFAULT_GID=1000

RUN addgroup -g "${DEFAULT_GID}" opencode \
    && adduser -D -u "${DEFAULT_UID}" -G opencode \
        -h /home/opencode -s /bin/bash opencode \
    && mkdir -p \
        /workspace \
        /home/opencode/.config/opencode \
        /home/opencode/.local/share/opencode \
        /home/opencode/.cache \
        /home/opencode/.cargo \
        /home/opencode/.config/gh \
    && chown -R opencode:opencode /workspace /home/opencode

COPY --chmod=755 docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh

ENV HOME=/home/opencode \
    USER=opencode \
    LOGNAME=opencode \
    CARGO_HOME=/home/opencode/.cargo

WORKDIR /workspace

EXPOSE 4096

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]

CMD ["opencode", "serve", "--hostname", "0.0.0.0", "--port", "4096"]
