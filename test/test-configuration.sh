#!/bin/bash
# Test configuration functionality

source "$(dirname "$0")/test-common.sh"

CONFIG_FILE="${1:-/playground/config.json}"

run_tests() {
    init_test_suite "Configuration Test"
    
    # Check if config file exists
    if [ ! -f "$CONFIG_FILE" ]; then
        test_fail "Config file exists" "File not found: $CONFIG_FILE"
        print_test_summary
        return 1
    fi
    test_pass "Config file exists: $CONFIG_FILE"
    
    # Copy config file
    cp "$CONFIG_FILE" /etc/luoking-box/sing-box-config/default.json
    chmod 600 /etc/luoking-box/sing-box-config/default.json
    [ -f /etc/luoking-box/sing-box-config/default.json ] && test_pass "Config file copied" || test_fail "Config file copied"
    
    # Set active config
    echo '{"active_config": "default"}' > /etc/luoking-box/config.json
    chmod 600 /etc/luoking-box/config.json
    
    # Validate config syntax
    if /usr/bin/sing-box check -c /etc/luoking-box/sing-box-config/default.json >/dev/null 2>&1; then
        test_pass "Config syntax validation"
    else
        test_fail "Config syntax validation" "Config has syntax errors"
        print_test_summary
        return 1
    fi
    
    # Test config parsing (proxy extraction)
    PROXY_OUTPUT=$(/usr/bin/luoking-box enable session 2>&1)
    if echo "$PROXY_OUTPUT" | grep -qE '^http://127.0.0.1:[0-9]+$' || echo "$PROXY_OUTPUT" | grep -q "127.0.0.1:8890"; then
        test_pass "Config parsing (proxy extraction)"
    else
        test_fail "Config parsing (proxy extraction)" "Failed to extract proxy config"
    fi
    
    print_test_summary
    get_test_results
    return $?
}

run_tests

