#!/bin/bash
# Test script for luoking-box Debian package installation and removal
# This script runs in Docker container to verify installation and cleanup

set -e

PACKAGE_NAME="luoking-box"
PACKAGE_FILE="build/luoking-box_1.0.0_amd64.deb"
ERRORS=0
WARNINGS=0

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Helper functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
    ERRORS=$((ERRORS + 1))
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
    WARNINGS=$((WARNINGS + 1))
}

check_file_exists() {
    if [ -f "$1" ]; then
        log_info "✓ File exists: $1"
        return 0
    else
        log_error "✗ File missing: $1"
        return 1
    fi
}

check_dir_exists() {
    if [ -d "$1" ]; then
        log_info "✓ Directory exists: $1"
        return 0
    else
        log_error "✗ Directory missing: $1"
        return 1
    fi
}

check_file_not_exists() {
    if [ ! -e "$1" ]; then
        log_info "✓ File/directory removed: $1"
        return 0
    else
        log_error "✗ File/directory still exists: $1"
        return 1
    fi
}

check_service_status() {
    # Skip systemctl check in Docker environment
    if ! command -v systemctl >/dev/null 2>&1 || ! systemctl >/dev/null 2>&1; then
        log_info "✓ Skipping service status check (systemctl not available in Docker)"
        return 0
    fi
    if systemctl is-enabled "$1" >/dev/null 2>&1; then
        log_warn "Service $1 is enabled (expected disabled by default)"
    else
        log_info "✓ Service $1 is disabled (as expected)"
    fi
}

echo "=========================================="
echo "luoking-box Package Installation Test"
echo "=========================================="
echo ""

# Step 1: Build the package
log_info "Step 1: Building package..."
if [ ! -f "$PACKAGE_FILE" ]; then
    log_info "Package not found, building..."
    ./script/build-deb.sh
fi

if [ ! -f "$PACKAGE_FILE" ]; then
    log_error "Failed to build package"
    exit 1
fi
log_info "✓ Package built successfully: $PACKAGE_FILE"
echo ""

# Step 2: Install the package
log_info "Step 2: Installing package..."
apt-get update -qq >/dev/null 2>&1
if ! apt-get install -y -qq ./"$PACKAGE_FILE" 2>&1; then
    log_error "Failed to install package, trying with verbose output..."
    apt-get install -y ./"$PACKAGE_FILE" || {
        log_error "Installation failed"
        exit 1
    }
fi
log_info "✓ Package installed successfully"
echo ""

# Step 3: Verify installation
log_info "Step 3: Verifying installation..."

# Check executable files
check_file_exists "/usr/bin/sing-box"
check_file_exists "/usr/bin/luoking-box-wrapper"

# Check systemd service file
check_file_exists "/lib/systemd/system/luoking-box.service"

# Check configuration files
check_file_exists "/etc/luoking-box/config.json"
check_file_exists "/etc/luoking-box/config.json.example"
check_file_exists "/etc/luoking-box/sing-box-config/default.json"

# Check directories
check_dir_exists "/etc/luoking-box"
check_dir_exists "/etc/luoking-box/sing-box-config"
check_dir_exists "/var/log/luoking-box"

# Check file permissions
if [ -f "/etc/luoking-box/config.json" ]; then
    PERMS=$(stat -c "%a" /etc/luoking-box/config.json 2>/dev/null || stat -f "%OLp" /etc/luoking-box/config.json 2>/dev/null)
    if [ "$PERMS" = "600" ]; then
        log_info "✓ config.json has correct permissions (600)"
    else
        log_warn "config.json permissions are $PERMS (expected 600)"
    fi
fi

# Check service status
check_service_status "luoking-box.service"

# Check package is registered
if dpkg -l | grep -q "^ii.*$PACKAGE_NAME"; then
    log_info "✓ Package is registered in dpkg database"
else
    log_error "Package not found in dpkg database"
fi

# Check wrapper script functionality (basic syntax check)
if bash -n /usr/bin/luoking-box-wrapper 2>/dev/null; then
    log_info "✓ wrapper script syntax is valid"
else
    log_error "wrapper script has syntax errors"
fi

# Check config.json format
if command -v python3 >/dev/null 2>&1; then
    if python3 -m json.tool /etc/luoking-box/config.json >/dev/null 2>&1; then
        log_info "✓ config.json is valid JSON"
    else
        log_error "config.json is not valid JSON"
    fi
fi

echo ""
log_info "Installation verification complete"
echo ""

# Step 4: Test remove (should keep config files)
log_info "Step 4: Testing 'remove' (should keep config files)..."
dpkg -r "$PACKAGE_NAME" >/dev/null 2>&1 || {
    log_error "Failed to remove package"
    exit 1
}
log_info "✓ Package removed successfully"

# Verify config files still exist after remove
check_file_exists "/etc/luoking-box/config.json"
check_file_exists "/etc/luoking-box/config.json.example"
check_file_exists "/etc/luoking-box/sing-box-config/default.json"
check_dir_exists "/etc/luoking-box"
check_dir_exists "/var/log/luoking-box"

# Verify package files are removed
check_file_not_exists "/usr/bin/luoking-box-wrapper"
check_file_not_exists "/usr/bin/sing-box"
check_file_not_exists "/lib/systemd/system/luoking-box.service"

# Verify package is not in dpkg database
if dpkg -l | grep -q "^rc.*$PACKAGE_NAME"; then
    log_info "✓ Package is in 'rc' state (removed but config remains)"
else
    log_warn "Package state after remove is unexpected"
fi

echo ""
log_info "Remove verification complete"
echo ""

# Step 5: Reinstall for purge test
log_info "Step 5: Reinstalling package for purge test..."
apt-get install -y -qq ./"$PACKAGE_FILE" >/dev/null 2>&1 || {
    log_error "Failed to reinstall package"
    exit 1
}
log_info "✓ Package reinstalled"
echo ""

# Step 6: Test purge (should remove everything)
log_info "Step 6: Testing 'purge' (should remove everything including configs)..."
dpkg -P "$PACKAGE_NAME" >/dev/null 2>&1 || {
    log_error "Failed to purge package"
    exit 1
}
log_info "✓ Package purged successfully"

# Verify all files are removed
check_file_not_exists "/usr/bin/luoking-box-wrapper"
check_file_not_exists "/usr/bin/sing-box"
check_file_not_exists "/lib/systemd/system/luoking-box.service"
check_file_not_exists "/etc/luoking-box/config.json"
check_file_not_exists "/etc/luoking-box/config.json.example"
check_file_not_exists "/etc/luoking-box/sing-box-config/default.json"
check_file_not_exists "/etc/luoking-box"
check_file_not_exists "/var/log/luoking-box"

# Verify package is completely removed from dpkg database
if ! dpkg -l | grep -q "$PACKAGE_NAME"; then
    log_info "✓ Package completely removed from dpkg database"
else
    log_error "Package still exists in dpkg database"
fi

echo ""
log_info "Purge verification complete"
echo ""

# Final summary
echo "=========================================="
echo "Test Summary"
echo "=========================================="
if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo -e "${GREEN}✓ All tests passed!${NC}"
    exit 0
elif [ $ERRORS -eq 0 ]; then
    echo -e "${YELLOW}⚠ Tests passed with $WARNINGS warning(s)${NC}"
    exit 0
else
    echo -e "${RED}✗ Tests failed with $ERRORS error(s) and $WARNINGS warning(s)${NC}"
    exit 1
fi

