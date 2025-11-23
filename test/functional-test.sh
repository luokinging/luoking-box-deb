#!/bin/bash
# Functional test script for luoking-box
# This script tests the complete functionality of luoking-box installation and usage

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test counters
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_TOTAL=0

# Configuration
DEB_FILE="${1:-/playground/luoking-box_1.0.0_amd64.deb}"
CONFIG_FILE="${2:-/playground/config.json}"
TEST_DIR="/playground/luoking-box-test"

# Test result tracking
test_pass() {
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "${GREEN}✓${NC} $1"
}

test_fail() {
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} $1"
    if [ -n "$2" ]; then
        echo -e "  ${RED}Error: $2${NC}"
    fi
}

print_header() {
    echo -e "\n${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}\n"
}

print_summary() {
    echo -e "\n${BLUE}========================================${NC}"
    echo -e "${BLUE}Test Summary${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo -e "Total tests:  $TESTS_TOTAL"
    echo -e "${GREEN}Passed:      $TESTS_PASSED${NC}"
    if [ $TESTS_FAILED -gt 0 ]; then
        echo -e "${RED}Failed:      $TESTS_FAILED${NC}"
        return 1
    else
        echo -e "Failed:      $TESTS_FAILED"
        return 0
    fi
}

# Cleanup function
cleanup() {
    echo -e "\n${YELLOW}Cleaning up...${NC}"
    
    # Stop service if running
    systemctl stop luoking-box 2>/dev/null || true
    systemctl disable luoking-box 2>/dev/null || true
    
    # Clear proxy
    if command -v luoking-box >/dev/null 2>&1; then
        source /etc/profile.d/luoking-box.sh 2>/dev/null || true
        luoking-box clear session docker 2>/dev/null || true
    fi
    
    # Uninstall package
    dpkg -P luoking-box 2>/dev/null || true
    
    # Remove test directory
    rm -rf "$TEST_DIR" 2>/dev/null || true
    
    echo -e "${GREEN}Cleanup completed${NC}"
}

# Setup test environment
setup_test_env() {
    print_header "Setting up test environment"
    
    mkdir -p "$TEST_DIR"
    
    # Check if deb file exists
    if [ ! -f "$DEB_FILE" ]; then
        test_fail "DEB file exists" "File not found: $DEB_FILE"
        return 1
    fi
    test_pass "DEB file exists: $DEB_FILE"
    
    # Check if config file exists
    if [ ! -f "$CONFIG_FILE" ]; then
        test_fail "Config file exists" "File not found: $CONFIG_FILE"
        return 1
    fi
    test_pass "Config file exists: $CONFIG_FILE"
    
    return 0
}

# Test installation
test_installation() {
    print_header "Testing Installation"
    
    # Install package
    if apt install -y "$DEB_FILE" 2>&1 | grep -q "Setting up luoking-box"; then
        test_pass "Package installation"
    elif dpkg -i "$DEB_FILE" 2>&1 && apt-get install -f -y >/dev/null 2>&1; then
        test_pass "Package installation (with dependency fix)"
    else
        test_fail "Package installation" "Installation failed"
        return 1
    fi
    
    # Verify installation
    if [ -f /usr/bin/luoking-box ]; then
        test_pass "luoking-box binary exists"
    else
        test_fail "luoking-box binary exists" "Binary not found"
        return 1
    fi
    
    if [ -f /etc/profile.d/luoking-box.sh ]; then
        test_pass "Shell integration script exists"
    else
        test_fail "Shell integration script exists" "Script not found"
    fi
    
    if [ -f /etc/luoking-box/config.json ]; then
        test_pass "Main config file exists"
    else
        test_fail "Main config file exists" "Config not found"
    fi
    
    if [ -d /etc/luoking-box/sing-box-config ]; then
        test_pass "Config directory exists"
    else
        test_fail "Config directory exists" "Directory not found"
    fi
    
    return 0
}

# Test configuration
test_configuration() {
    print_header "Testing Configuration"
    
    # Copy config file
    cp "$CONFIG_FILE" /etc/luoking-box/sing-box-config/default.json
    chmod 600 /etc/luoking-box/sing-box-config/default.json
    
    if [ -f /etc/luoking-box/sing-box-config/default.json ]; then
        test_pass "Config file copied"
    else
        test_fail "Config file copied" "Copy failed"
        return 1
    fi
    
    # Set active config
    echo '{"active_config": "default"}' > /etc/luoking-box/config.json
    chmod 600 /etc/luoking-box/config.json
    
    # Validate config syntax
    if /usr/bin/sing-box check -c /etc/luoking-box/sing-box-config/default.json >/dev/null 2>&1; then
        test_pass "Config syntax validation"
    else
        test_fail "Config syntax validation" "Config has syntax errors"
        return 1
    fi
    
    # Test config parsing
    if /usr/bin/luoking-box enable session 2>&1 | grep -qE '^http://127.0.0.1:[0-9]+$'; then
        test_pass "Config parsing (proxy extraction)"
    else
        test_fail "Config parsing (proxy extraction)" "Failed to extract proxy config"
    fi
    
    return 0
}

# Test service
test_service() {
    print_header "Testing Service"
    
    # Start service
    if systemctl start luoking-box; then
        test_pass "Service start"
    else
        test_fail "Service start" "Failed to start service"
        return 1
    fi
    
    # Wait for service to stabilize
    sleep 2
    
    # Check service status
    if systemctl is-active --quiet luoking-box; then
        test_pass "Service is active"
    else
        test_fail "Service is active" "Service not running"
        systemctl status luoking-box --no-pager | head -10
        return 1
    fi
    
    # Check process
    if pgrep -f "sing-box run" >/dev/null; then
        test_pass "sing-box process running"
    else
        test_fail "sing-box process running" "Process not found"
    fi
    
    # Check port listening
    if ss -tlnp 2>/dev/null | grep -q ":8890" || netstat -tlnp 2>/dev/null | grep -q ":8890"; then
        test_pass "Port 8890 listening"
    else
        test_fail "Port 8890 listening" "Port not listening"
    fi
    
    return 0
}

# Test proxy functionality
test_proxy() {
    print_header "Testing Proxy Functionality"
    
    # Test without proxy (should timeout)
    if timeout 3 curl -v www.google.com >/dev/null 2>&1; then
        test_fail "Direct connection timeout" "Connection succeeded (unexpected)"
    else
        test_pass "Direct connection timeout (expected)"
    fi
    
    # Enable proxy
    source /etc/profile.d/luoking-box.sh 2>/dev/null || true
    if luoking-box enable session >/dev/null 2>&1; then
        test_pass "Enable session proxy"
    else
        test_fail "Enable session proxy" "Failed to enable proxy"
        return 1
    fi
    
    # Test with proxy
    export http_proxy=http://127.0.0.1:8890
    export https_proxy=http://127.0.0.1:8890
    
    if timeout 3 curl -v --proxy http://127.0.0.1:8890 www.google.com >/dev/null 2>&1; then
        test_pass "Proxy connection successful"
    else
        test_fail "Proxy connection successful" "Proxy connection failed"
    fi
    
    # Clear proxy
    if luoking-box clear session >/dev/null 2>&1; then
        test_pass "Clear session proxy"
    else
        test_fail "Clear session proxy" "Failed to clear proxy"
    fi
    
    return 0
}

# Main execution
main() {
    print_header "luoking-box Functional Test Suite"
    
    # Setup
    if ! setup_test_env; then
        echo -e "${RED}Setup failed, aborting tests${NC}"
        exit 1
    fi
    
    # Run tests
    test_installation || exit 1
    test_configuration || exit 1
    test_service || exit 1
    test_proxy || exit 1
    
    # Print summary
    if print_summary; then
        echo -e "\n${GREEN}All tests passed!${NC}"
        exit 0
    else
        echo -e "\n${RED}Some tests failed${NC}"
        exit 1
    fi
}

# Trap cleanup on exit
trap cleanup EXIT

# Run main
main

