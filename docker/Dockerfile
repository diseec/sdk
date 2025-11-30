FROM node:20-bullseye-slim

ENV IS_IN_SDK_CONTAINER=true

# Build argument for SDK name with default value
ARG D_SDK_NAME=sdk
ARG D_CONT_CTX_DIR="/ctx"

# Install base dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    bash coreutils curl jq git openssl git-lfs wget dnsutils traceroute bc \
    && rm -rf /var/lib/apt/lists/*

# Install yq
RUN ARCH=$(uname -m) && \
    if [ "$ARCH" = "x86_64" ]; then \
    YQ_ARCH="amd64"; \
    elif [ "$ARCH" = "aarch64" ]; then \
    YQ_ARCH="arm64"; \
    else \
    echo "Unsupported architecture: $ARCH" && exit 1; \
    fi && \
    wget -qO /usr/local/bin/yq "https://github.com/mikefarah/yq/releases/latest/download/yq_linux_${YQ_ARCH}" && \
    chmod +x /usr/local/bin/yq

WORKDIR /${D_SDK_NAME}

# Install GitHub cli_ctx using prebuilt binary for the current architecture
RUN ARCH=$(uname -m) && \
    if [ "$ARCH" = "x86_64" ]; then \
    ARCH_TAG="linux_amd64"; \
    elif [ "$ARCH" = "aarch64" ]; then \
    ARCH_TAG="linux_arm64"; \
    else \
    echo "Unsupported architecture: $ARCH" && exit 1; \
    fi && \
    mkdir -p /tmp/gh && \
    cd /tmp/gh && \
    GH_VERSION="2.47.0" && \
    wget "https://github.com/cli/cli/releases/download/v${GH_VERSION}/gh_${GH_VERSION}_${ARCH_TAG}.tar.gz" && \
    tar -xzf "gh_${GH_VERSION}_${ARCH_TAG}.tar.gz" && \
    mv gh_*/bin/gh /usr/local/bin/ && \
    chmod +x /usr/local/bin/gh && \
    cd / && \
    rm -rf /tmp/gh

RUN npm install -g prettier

COPY . .

RUN npm install -g /${D_SDK_NAME}

COPY docker/.bashrc /root/.bashrc
COPY docker/entrypoints /entrypoints
RUN chmod +x /entrypoints/*.sh
# COPY entrypoint.sh /entrypoint.sh
# RUN chmod +x /entrypoint.sh
# ENTRYPOINT ["/entrypoint.sh"]

RUN mkdir -p ${D_CONT_CTX_DIR}
WORKDIR ${D_CONT_CTX_DIR}

CMD ["D", "--help"]