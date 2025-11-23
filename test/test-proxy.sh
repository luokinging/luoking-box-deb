#!/bin/bash
# Test proxy functionality

source "$(dirname "$0")/test-common.sh"

run_tests() {
    init_test_suite "Proxy Functionality Test"
    
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
        print_test_summary
        return 1
    fi
    
    # Verify proxy environment variables are set
    if [ -n "$http_proxy" ] && [ -n "$HTTP_PROXY" ]; then
        test_pass "Proxy environment variables set"
    else
        test_fail "Proxy environment variables set" "Variables not set"
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
    
    # Verify proxy environment variables are cleared
    if [ -z "$http_proxy" ] && [ -z "$HTTP_PROXY" ]; then
        test_pass "Proxy environment variables cleared"
    else
        test_fail "Proxy environment variables cleared" "Variables still set"
    fi
    
    print_test_summary
    get_test_results
    return $?
}

run_tests

