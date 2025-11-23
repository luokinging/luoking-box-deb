#!/bin/bash
set -e

# Build script for luoking-box Debian package
# Usage: ./build-deb.sh

PACKAGE_NAME="luoking-box"
# Read version from control file, fallback to default if not found
VERSION=$(grep "^Version:" debian/DEBIAN/control 2>/dev/null | awk '{print $2}' || echo "1.0.0")
ARCH="amd64"
DEBIAN_DIR="debian"
BUILD_DIR="build"

echo "Building Debian package for luoking-box..."

# Clean previous build
if [ -d "$BUILD_DIR" ]; then
    rm -rf "$BUILD_DIR"
fi

# Create build directory
mkdir -p "$BUILD_DIR"

# Copy debian directory structure
cp -r "$DEBIAN_DIR" "$BUILD_DIR/${PACKAGE_NAME}_${VERSION}"

# Calculate installed size
INSTALLED_SIZE=$(du -sk "$BUILD_DIR/${PACKAGE_NAME}_${VERSION}" | cut -f1)

# Update control file with installed size
sed -i.bak "s/^Installed-Size:.*/Installed-Size: ${INSTALLED_SIZE}/" "$BUILD_DIR/${PACKAGE_NAME}_${VERSION}/DEBIAN/control" 2>/dev/null || true
rm -f "$BUILD_DIR/${PACKAGE_NAME}_${VERSION}/DEBIAN/control.bak"

# Build the package
dpkg-deb --build "$BUILD_DIR/${PACKAGE_NAME}_${VERSION}" "$BUILD_DIR/${PACKAGE_NAME}_${VERSION}_${ARCH}.deb"

# Clean up temporary build directory
rm -rf "$BUILD_DIR/${PACKAGE_NAME}_${VERSION}"

echo ""
echo "Package built successfully!"
echo "Location: $BUILD_DIR/${PACKAGE_NAME}_${VERSION}_${ARCH}.deb"
echo ""
echo "To install:"
echo "  sudo dpkg -i $BUILD_DIR/${PACKAGE_NAME}_${VERSION}_${ARCH}.deb"
echo ""
echo "To fix dependencies if needed:"
echo "  sudo apt-get install -f"

