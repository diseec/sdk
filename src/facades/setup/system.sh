#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get system dependencies from package.json
fac_set_get_system_deps() {
    local pkg_json="$KIT_DIR/package.json"
    
    # Extract systemDependencies array using grep, sed, and tr
    # This finds the line with "systemDependencies", then extracts the array content
    sed -n '/"systemDependencies"/,/]/p' "$pkg_json" | \
    grep -o '"[^"]*"' | \
    sed 's/"//g' | \
    grep -v "systemDependencies" | \
    grep -v '^\s*$'
}

# Detect Linux distribution
fac_set_detect_distro() {
    if [ -f /etc/alpine-release ]; then
        echo "alpine"
    elif [ -f /etc/debian_version ] || [ -f /etc/lsb-release ]; then
        echo "ubuntu"
    elif command -v apk >/dev/null 2>&1; then
        echo "alpine"
    elif command -v apt-get >/dev/null 2>&1; then
        echo "ubuntu"
    else
        echo "unknown"
    fi
}

# Check if running as root/sudo
fac_set_check_privileges() {
    if [ "$EUID" -ne 0 ]; then
        echo -e "${YELLOW}Warning: Not running as root. You may need sudo for package installation.${NC}"
        SUDO_CMD="sudo"
    else
        SUDO_CMD=""
    fi
}

# Check if a command exists
fac_set_command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check system dependencies function
fac_set_check_system_dependencies() {
    # echo -e "${BLUE}=== System Dependencies Check ===${NC}"
    
    # local distro=$(fac_set_detect_distro)
    # echo -e "Detected OS: ${YELLOW}$distro${NC}"
    
    # Get dependencies from package.json
    local deps=()
    while IFS= read -r dep; do
        deps+=("$dep")
    done < <(fac_set_get_system_deps)
    
    if [ ${#deps[@]} -eq 0 ]; then
        echo -e "${YELLOW}No system dependencies defined in package.json${NC}"
        return 0
    fi
    
    local missing_deps=()
    local missing_count=0

    # message "Kit system dependencies"

    for dep in "${deps[@]}"; do
        if ! fac_set_command_exists "$dep"; then
            # echo -e "${RED}✗${NC} $dep (missing)"
            missing_deps+=("$dep")
            ((missing_count++))
        # else
        #     echo -e "${GREEN}✔${NC} $dep"
        fi
    done
    
    if [ $missing_count -eq 0 ]; then
        message 32 "✔" "All system dependencies are installed!"
        return 0
    else
        message 31 "✗" "$missing_count missing dependencies found: ${missing_deps[*]}"
        return 1
    fi
}

# Package manager utilities
fac_set_run_package_manager() {
    local cmd="$1"
    eval "$SUDO_CMD $cmd"
    return $?
}

fac_set_install_package() {
    local pkg="$1"
    local distro=$(fac_set_detect_distro)
    
    if [ "$distro" = "alpine" ]; then
        fac_set_run_package_manager "apk add --no-cache $pkg"
    elif [ "$distro" = "ubuntu" ]; then
        fac_set_run_package_manager "apt-get install -y $pkg"
    else
        return 1
    fi
}

fac_set_update_package_list() {
    local distro=$(fac_set_detect_distro)
    if [ "$distro" = "ubuntu" ]; then
        fac_set_run_package_manager "apt-get update"
    fi
    return 0
}

# Custom installer functions
fac_set_install_git() {
    fac_set_install_package "git"
}

fac_set_install_curl() {
    fac_set_install_package "curl"
}

fac_set_install_bash() {
    fac_set_install_package "bash"
}

fac_set_install_docker() {
    local distro=$(fac_set_detect_distro)
    if [ "$distro" = "alpine" ]; then
        fac_set_install_package "docker"
    elif [ "$distro" = "ubuntu" ]; then
        fac_set_install_package "docker.io"
    else
        return 1
    fi
}

fac_set_install_nodejs() {
    fac_set_install_package "nodejs"
}

fac_set_install_npm() {
    fac_set_install_package "npm"
}

fac_set_install_yq() {
    fac_set_install_package "yq"
}

fac_set_install_yarn() {
    if fac_set_command_exists npm; then
        _npm install -g yarn
    else
        echo -e "${RED}npm is required to install yarn${NC}"
        return 1
    fi
}

fac_set_install_gh() {
    # Custom GitHub cli_main installation using the same logic as Dockerfile
    local arch=$(uname -m)
    local arch_tag
    
    if [ "$arch" = "x86_64" ]; then
        arch_tag="linux_amd64"
    elif [ "$arch" = "aarch64" ]; then
        arch_tag="linux_arm64"
    else
        echo -e "${RED}Unsupported architecture: $arch${NC}"
        return 1
    fi
    
    local version="2.47.0"
    local url="https://github.com/cli/cli/releases/download/v${version}/gh_${version}_${arch_tag}.tar.gz"
    
    echo -e "${BLUE}Installing GitHub cli_main from binary...${NC}"
    
    mkdir -p /tmp/gh && \
    cd /tmp/gh && \
    wget "$url" && \
    tar -xzf "gh_${version}_${arch_tag}.tar.gz" && \
    $SUDO_CMD mv gh_*/bin/gh /usr/local/bin/ && \
    $SUDO_CMD chmod +x /usr/local/bin/gh && \
    cd / && \
    rm -rf /tmp/gh
    
    return $?
}

fac_set_install_openssl() {
    fac_set_install_package "openssl"
}

fac_set_install_git_lfs() {
    fac_set_install_package "git-lfs"
}

# Get installer function for a dependency
fac_set_get_installer() {
    local dep="$1"
    local installer_fn="fac_set_install_$(echo "$dep" | tr '-' '_')"
    
    # Check if installer function exists
    if declare -F "$installer_fn" >/dev/null; then
        echo "$installer_fn"
    else
        echo ""
    fi
}

# Install a single dependency
fac_set_install_dependency() {
    local dep="$1"
    local installer=$(fac_set_get_installer "$dep")
    
    if [ -n "$installer" ]; then
        echo -e "${BLUE}Installing $dep...${NC}"
        if $installer; then
            echo -e "${GREEN}✔ $dep installed${NC}"
            return 0
        else
            echo -e "${RED}✗ Failed to install $dep${NC}"
            return 1
        fi
    else
        echo -e "${YELLOW}No custom installer for $dep, trying package manager...${NC}"
        if fac_set_install_package "$dep"; then
            echo -e "${GREEN}✔ $dep installed${NC}"
            return 0
        else
            echo -e "${RED}✗ Failed to install $dep${NC}"
            return 1
        fi
    fi
}

# Main installation function
fac_set_install_system_dependencies() {
    set -e
    # echo -e "${BLUE}=== Installing System Dependencies ===${NC}"
    
    local distro=$(fac_set_detect_distro)
    # echo -e "Detected OS: ${YELLOW}$distro${NC}"
    
    if [ "$distro" = "unknown" ]; then
        echo -e "${RED}Error: Unsupported Linux distribution${NC}"
        echo "Supported: Alpine Linux, Ubuntu/Debian"
        return 1
    fi
    
    fac_set_check_privileges
    
    # Get dependencies from package.json
    local deps=()
    while IFS= read -r dep; do
        deps+=("$dep")
    done < <(fac_set_get_system_deps)
    
    if [ ${#deps[@]} -eq 0 ]; then
        echo -e "${YELLOW}No system dependencies defined in package.json${NC}"
        return 0
    fi
    
    # Find missing dependencies
    local missing_deps=()
    for dep in "${deps[@]}"; do
        if ! fac_set_command_exists "$dep"; then
            missing_deps+=("$dep")
        fi
    done
    
    if [ ${#missing_deps[@]} -eq 0 ]; then
        echo -e "${GREEN}✔ All dependencies already installed${NC}"
        return 0
    fi
    
    # echo -e "${BLUE}Missing dependencies: ${missing_deps[*]}${NC}"
    
    # Update package list first
    fac_set_update_package_list
    
    # Install missing dependencies
    local all_success=true
    for dep in "${missing_deps[@]}"; do
        if ! fac_set_install_dependency "$dep"; then
            all_success=false
        fi
    done
    
    if $all_success; then
        message 32 "✔" "All system dependencies installed successfully!"
        return 0
    else
        message 31 "E" "Some dependencies failed to install"
        return 1
    fi
}
