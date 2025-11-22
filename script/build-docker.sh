#!/bin/bash
# Build script using Docker (for macOS/Windows)
# Usage: ./build-docker.sh

set -e

echo "Building luoking-box Debian package using Docker..."
echo ""

# Check if Docker is available
if ! command -v docker >/dev/null 2>&1; then
    echo "错误: Docker 未安装或不可用"
    echo "请先安装 Docker: https://www.docker.com/products/docker-desktop"
    exit 1
fi

# Build using Ubuntu container
docker run --rm \
    -v "$(pwd):/workspace" \
    -w /workspace \
    ubuntu:22.04 \
    bash -c "
        apt-get update -qq && \
        apt-get install -y -qq dpkg-dev && \
        ./script/build-deb.sh
    "

echo ""
echo "构建完成！包文件位于 build/ 目录"

