#!/bin/bash
# Docker test script for luoking-box Debian package
# This script runs the test-install.sh in a Docker container

set -e

echo "Building luoking-box Debian package and testing installation/removal..."
echo ""

# Check if Docker is available
if ! command -v docker >/dev/null 2>&1; then
    echo "错误: Docker 未安装或不可用"
    echo "请先安装 Docker: https://www.docker.com/products/docker-desktop"
    exit 1
fi

# Run build and test in Docker container
echo "Running build and installation/removal tests in Docker..."
docker run --rm \
    --platform linux/amd64 \
    -v "$(pwd):/workspace" \
    -w /workspace \
    ubuntu:22.04 \
    bash -c "
        export DEBIAN_FRONTEND=noninteractive
        apt-get update -qq >/dev/null 2>&1
        # Install dependencies for building and testing
        apt-get install -y -qq dpkg-dev dpkg apt-utils >/dev/null 2>&1
        # Build the package
        echo 'Step 1: Building package...'
        chmod +x script/build-deb.sh script/test-install.sh
        ./script/build-deb.sh
        echo ''
        # Run the test script
        echo 'Step 2: Running installation/removal tests...'
        ./script/test-install.sh
    "

echo ""
echo "测试完成！"

