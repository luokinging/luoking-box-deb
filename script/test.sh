#!/bin/bash
# Main test entry point
# Detects environment and runs tests accordingly

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Check if we can use native debian tools
can_use_native() {
    command -v dpkg-deb >/dev/null 2>&1 && \
    command -v dpkg >/dev/null 2>&1 && \
    [ -f /etc/debian_version ] 2>/dev/null
}

# Check if Docker is available
has_docker() {
    command -v docker >/dev/null 2>&1 && \
    docker info >/dev/null 2>&1
}

# Build package
build_package() {
    echo -e "${YELLOW}Building package...${NC}"
    
    if can_use_native; then
        "$SCRIPT_DIR/build-deb.sh" || {
            echo -e "${RED}Failed to build package${NC}"
            return 1
        }
    elif has_docker; then
        "$SCRIPT_DIR/build-docker.sh" || {
            echo -e "${RED}Failed to build package${NC}"
            return 1
        }
    else
        echo -e "${RED}Error: Cannot build package - no dpkg-deb or Docker available${NC}"
        return 1
    fi
    
    DEB_FILE=$(find "$PROJECT_DIR/build" -name "*.deb" 2>/dev/null | head -1)
    if [ -z "$DEB_FILE" ]; then
        echo -e "${RED}Error: No deb file found after build${NC}"
        return 1
    fi
    
    echo -e "${GREEN}✓ Package built: $(basename "$DEB_FILE")${NC}"
    return 0
}

# Install package (native)
install_package_native() {
    local deb_file="$1"
    echo -e "${YELLOW}Installing package...${NC}"
    
    sudo dpkg -i "$deb_file" || {
        echo -e "${YELLOW}Installing dependencies...${NC}"
        sudo apt-get install -f -y -qq >/dev/null 2>&1
    }
    
    echo -e "${GREEN}✓ Package installed${NC}"
}

# Run tests in Docker
run_tests_docker() {
    local deb_file="$1"
    echo -e "${YELLOW}Running tests in Docker...${NC}"
    
    docker run --rm \
        --platform linux/amd64 \
        -v "$PROJECT_DIR:/workspace" \
        -w /workspace \
        ubuntu:22.04 \
        bash -c "
            set -e
            export DEBIAN_FRONTEND=noninteractive
            
            # Install dependencies
            apt-get update -qq >/dev/null 2>&1
            apt-get install -y -qq dpkg python3 bash systemd iproute2 >/dev/null 2>&1
            
            # Install package
            dpkg -i build/*.deb || apt-get install -f -y -qq >/dev/null 2>&1
            
            # Verify installation
            [ -f /usr/bin/luoking-box ] || { echo 'Error: luoking-box not installed'; exit 1; }
            [ -f /etc/profile.d/luoking-box.sh ] || { echo 'Error: shell integration not installed'; exit 1; }
            
            # Run tests
            chmod +x test/*.sh
            bash test/run-all.sh
        "
}

# Run tests natively
run_tests_native() {
    echo -e "${YELLOW}Running tests natively...${NC}"
    
    # Verify installation
    if [ ! -f /usr/bin/luoking-box ]; then
        echo -e "${RED}Error: luoking-box not installed${NC}"
        return 1
    fi
    
    if [ ! -f /etc/profile.d/luoking-box.sh ]; then
        echo -e "${RED}Error: shell integration not installed${NC}"
        return 1
    fi
    
    # Run tests
    chmod +x "$PROJECT_DIR/test"/*.sh
    bash "$PROJECT_DIR/test/run-all.sh"
}

# Main execution
main() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}  luoking-box Test Suite${NC}"
    echo -e "${BLUE}========================================${NC}\n"
    
    # Build package
    if ! build_package; then
        exit 1
    fi
    
    DEB_FILE=$(find "$PROJECT_DIR/build" -name "*.deb" 2>/dev/null | head -1)
    
    # Determine test environment
    if can_use_native; then
        echo -e "${GREEN}Using native Debian environment${NC}\n"
        install_package_native "$DEB_FILE"
        run_tests_native
    elif has_docker; then
        echo -e "${GREEN}Using Docker environment${NC}\n"
        run_tests_docker "$DEB_FILE"
    else
        echo -e "${RED}Error: Cannot run tests${NC}"
        echo -e "${RED}  - No dpkg-deb available (not a Debian system)${NC}"
        echo -e "${RED}  - Docker not available${NC}"
        echo -e "\n${YELLOW}Please install Docker to run tests:${NC}"
        echo -e "  https://www.docker.com/products/docker-desktop"
        exit 1
    fi
}

main

