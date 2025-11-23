#!/bin/bash
# Test installation functionality

source "$(dirname "$0")/test-common.sh"

DEB_FILE="${1:-/playground/luoking-box_1.0.0_amd64.deb}"

run_tests() {
    init_test_suite "Installation Test"
    
    # Check if deb file exists
    if [ ! -f "$DEB_FILE" ]; then
        test_fail "DEB file exists" "File not found: $DEB_FILE"
        print_test_summary
        return 1
    fi
    test_pass "DEB file exists: $DEB_FILE"
    
    # Output results for parent script
    get_test_results
    
    # Install package
    if apt install -y "$DEB_FILE" >/dev/null 2>&1; then
        test_pass "Package installation"
    elif dpkg -i "$DEB_FILE" >/dev/null 2>&1 && apt-get install -f -y >/dev/null 2>&1; then
        test_pass "Package installation (with dependency fix)"
    else
        test_fail "Package installation" "Installation failed"
        print_test_summary
        return 1
    fi
    
    # Verify installation
    [ -f /usr/bin/luoking-box ] && test_pass "luoking-box binary exists" || test_fail "luoking-box binary exists"
    [ -f /etc/profile.d/luoking-box.sh ] && test_pass "Shell integration script exists" || test_fail "Shell integration script exists"
    [ -f /etc/luoking-box/config.json ] && test_pass "Main config file exists" || test_fail "Main config file exists"
    [ -d /etc/luoking-box/sing-box-config ] && test_pass "Config directory exists" || test_fail "Config directory exists"
    
    print_test_summary
    get_test_results
    return $?
}

run_tests

