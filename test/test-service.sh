#!/bin/bash
# Test service functionality

source "$(dirname "$0")/test-common.sh"

run_tests() {
    init_test_suite "Service Test"
    
    # Start service
    if systemctl start luoking-box; then
        test_pass "Service start"
    else
        test_fail "Service start" "Failed to start service"
        print_test_summary
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
        print_test_summary
        return 1
    fi
    
    # Check process
    pgrep -f "sing-box run" >/dev/null && test_pass "sing-box process running" || test_fail "sing-box process running"
    
    # Check port listening
    if ss -tlnp 2>/dev/null | grep -q ":8890" || netstat -tlnp 2>/dev/null | grep -q ":8890"; then
        test_pass "Port 8890 listening"
    else
        test_fail "Port 8890 listening" "Port not listening"
    fi
    
    print_test_summary
    get_test_results
    return $?
}

run_tests

