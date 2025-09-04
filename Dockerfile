FROM node:20-alpine

ENV IS_IN_SDK_CONTAINER=true

# Build argument for SDK name with default value
ARG SDK_NAME=sdk
ARG WORK_DIR_CONTAINER="/work"

# Install base dependencies
RUN apk add --no-cache bash coreutils curl yq jq git openssl git-lfs

WORKDIR /${SDK_NAME}

COPY . .

RUN npm install -g /${SDK_NAME}

# Install GitHub cli_main using prebuilt binary for the current architecture
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

# Install network diagnostic tools for internet facade
RUN apk add --no-cache wget iputils bind-tools traceroute bc

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]

RUN mkdir -p ${WORK_DIR_CONTAINER}
WORKDIR ${WORK_DIR_CONTAINER}

CMD ["D", "help"]