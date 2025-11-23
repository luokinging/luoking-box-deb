#!/bin/bash
# Verify deb package integrity
# Usage: ./script/verify-deb.sh <path-to-deb-file>

set -e

DEB_FILE="${1:-}"

if [ -z "$DEB_FILE" ]; then
    echo "Usage: $0 <path-to-deb-file>"
    exit 1
fi

if [ ! -f "$DEB_FILE" ]; then
    echo "Error: File not found: $DEB_FILE"
    exit 1
fi

echo "Verifying deb package: $DEB_FILE"
echo ""

# Check file size
FILE_SIZE=$(stat -f%z "$DEB_FILE" 2>/dev/null || stat -c%s "$DEB_FILE" 2>/dev/null)
echo "File size: $FILE_SIZE bytes ($(numfmt --to=iec-i --suffix=B $FILE_SIZE 2>/dev/null || echo "N/A"))"

# Check file type
echo "File type:"
file "$DEB_FILE"
echo ""

# Check if it's a valid deb package
if command -v dpkg-deb >/dev/null 2>&1; then
    echo "Checking package structure..."
    if dpkg-deb -I "$DEB_FILE" >/dev/null 2>&1; then
        echo "✓ Package structure is valid"
        echo ""
        echo "Package information:"
        dpkg-deb -I "$DEB_FILE"
        echo ""
        echo "Package contents:"
        dpkg-deb -c "$DEB_FILE" | head -20
        echo "..."
    else
        echo "✗ ERROR: Invalid package structure!"
        echo ""
        echo "Trying to extract and inspect..."
        TEMP_DIR=$(mktemp -d)
        trap "rm -rf $TEMP_DIR" EXIT
        
        # Try to extract
        if ar -x "$DEB_FILE" -C "$TEMP_DIR" 2>&1; then
            echo "Extracted archive members:"
            ls -lh "$TEMP_DIR"
        else
            echo "Failed to extract archive"
        fi
        exit 1
    fi
else
    echo "Warning: dpkg-deb not found, skipping detailed validation"
    echo "Trying basic ar archive check..."
    if ar -t "$DEB_FILE" >/dev/null 2>&1; then
        echo "✓ Basic archive structure OK"
        echo "Archive members:"
        ar -t "$DEB_FILE"
    else
        echo "✗ ERROR: Not a valid ar archive!"
        exit 1
    fi
fi

echo ""
echo "✓ Package verification completed successfully"

