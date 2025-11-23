#!/bin/bash
# Test version command

source "$(dirname "$0")/test-common.sh"

run_tests() {
    init_test_suite "Version Command Test"
    
    # Test -v flag
    VERSION_OUTPUT=$(/usr/bin/luoking-box -v 2>&1)
    if echo "$VERSION_OUTPUT" | grep -qE "luoking-box version [0-9]+\.[0-9]+\.[0-9]+"; then
        test_pass "Version command (-v)"
    else
        test_fail "Version command (-v)" "Output: $VERSION_OUTPUT"
    fi
    
    # Test --version flag
    VERSION_OUTPUT=$(/usr/bin/luoking-box --version 2>&1)
    if echo "$VERSION_OUTPUT" | grep -qE "luoking-box version [0-9]+\.[0-9]+\.[0-9]+"; then
        test_pass "Version command (--version)"
    else
        test_fail "Version command (--version)" "Output: $VERSION_OUTPUT"
    fi
    
    # Verify version is not "unknown"
    VERSION=$(/usr/bin/luoking-box -v 2>&1 | awk '{print $3}')
    if [ "$VERSION" != "unknown" ] && [ -n "$VERSION" ]; then
        test_pass "Version is valid (not unknown)"
    else
        test_fail "Version is valid (not unknown)" "Version: $VERSION"
    fi
    
    print_test_summary
    get_test_results
    return $?
}

run_tests

