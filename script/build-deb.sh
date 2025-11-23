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
# Use cp -R with --preserve=all to maintain permissions, but strip extended attributes
cp -R "$DEBIAN_DIR" "$BUILD_DIR/${PACKAGE_NAME}_${VERSION}"

# Remove macOS extended attributes if present (they can cause issues in deb packages)
if command -v xattr >/dev/null 2>&1; then
    find "$BUILD_DIR/${PACKAGE_NAME}_${VERSION}" -exec xattr -c {} \; 2>/dev/null || true
fi

# Ensure proper file permissions for DEBIAN scripts
chmod 755 "$BUILD_DIR/${PACKAGE_NAME}_${VERSION}/DEBIAN/postinst" 2>/dev/null || true
chmod 755 "$BUILD_DIR/${PACKAGE_NAME}_${VERSION}/DEBIAN/postrm" 2>/dev/null || true
chmod 755 "$BUILD_DIR/${PACKAGE_NAME}_${VERSION}/DEBIAN/prerm" 2>/dev/null || true
chmod 644 "$BUILD_DIR/${PACKAGE_NAME}_${VERSION}/DEBIAN/control" 2>/dev/null || true
chmod 644 "$BUILD_DIR/${PACKAGE_NAME}_${VERSION}/DEBIAN/conffiles" 2>/dev/null || true

# Calculate installed size
INSTALLED_SIZE=$(du -sk "$BUILD_DIR/${PACKAGE_NAME}_${VERSION}" | cut -f1)

# Update control file with installed size
sed -i.bak "s/^Installed-Size:.*/Installed-Size: ${INSTALLED_SIZE}/" "$BUILD_DIR/${PACKAGE_NAME}_${VERSION}/DEBIAN/control" 2>/dev/null || true
rm -f "$BUILD_DIR/${PACKAGE_NAME}_${VERSION}/DEBIAN/control.bak"

# Validate debian structure before building
if [ ! -f "$BUILD_DIR/${PACKAGE_NAME}_${VERSION}/DEBIAN/control" ]; then
    echo "Error: DEBIAN/control file not found!" >&2
    exit 1
fi

# Build the package
dpkg-deb --build "$BUILD_DIR/${PACKAGE_NAME}_${VERSION}" "$BUILD_DIR/${PACKAGE_NAME}_${VERSION}_${ARCH}.deb"

# Verify the package was built correctly
if [ ! -f "$BUILD_DIR/${PACKAGE_NAME}_${VERSION}_${ARCH}.deb" ]; then
    echo "Error: Package build failed!" >&2
    exit 1
fi

# Validate package integrity
if command -v dpkg-deb >/dev/null 2>&1; then
    if ! dpkg-deb -I "$BUILD_DIR/${PACKAGE_NAME}_${VERSION}_${ARCH}.deb" >/dev/null 2>&1; then
        echo "Error: Package validation failed!" >&2
        exit 1
    fi
fi

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

