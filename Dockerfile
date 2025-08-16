FROM node:alpine

# Install base dependencies
RUN apk add --no-cache bash curl git git-lfs

# Install GitHub CLI using prebuilt binary for the current architecture
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

RUN npm install -g @diseec/devops

WORKDIR /app

ENV IS_IN_CONTAINER=true

COPY . .

CMD ["bash", "cli", "help"]