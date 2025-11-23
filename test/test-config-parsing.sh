#!/bin/bash
# Test configuration parsing

source "$(dirname "$0")/test-common.sh"

run_tests() {
    init_test_suite "Config Parsing"
    
    # Setup test config
    TEST_DIR=$(setup_test_config)
    export CONFIG_FILE="$TEST_DIR/etc/luoking-box/config.json"
    export CONFIG_DIR="$TEST_DIR/etc/luoking-box/sing-box-config"
    export PROXY_STATE_DIR="$TEST_DIR/var/lib/luoking-box"
    
    # Test extract mixed proxy config
    PROXY_OUTPUT=$(bash -c "export CONFIG_FILE='$CONFIG_FILE' CONFIG_DIR='$CONFIG_DIR' PROXY_STATE_DIR='$PROXY_STATE_DIR'; /usr/bin/luoking-box enable session" 2>&1 || echo "")
    PROXY_URL=$(echo "$PROXY_OUTPUT" | grep -E '^http://[0-9.]+:[0-9]+$' | head -1 || echo "")
    
    test_case "extract mixed proxy config" \
        "[ -n '$PROXY_URL' ] && echo '$PROXY_URL' | grep -qE '^http://127.0.0.1:8890$'" \
        ""
    
    # Test with invalid config
    echo '{"active_config": "nonexistent"}' > "$TEST_DIR/etc/luoking-box/config.json"
    test_case "invalid config file fails" \
        "bash -c \"export CONFIG_FILE='$TEST_DIR/etc/luoking-box/config.json' CONFIG_DIR='$CONFIG_DIR' PROXY_STATE_DIR='$PROXY_STATE_DIR'; /usr/bin/luoking-box enable session\" 2>&1 | grep -q 'not found'" \
        "" \
        true
    
    # Restore valid config
    echo '{"active_config": "default"}' > "$TEST_DIR/etc/luoking-box/config.json"
    
    # Test missing config file
    test_case "missing config file fails" \
        "bash -c \"export CONFIG_FILE='/nonexistent/config.json' CONFIG_DIR='$CONFIG_DIR' PROXY_STATE_DIR='$PROXY_STATE_DIR'; /usr/bin/luoking-box enable session\" 2>&1 | grep -q 'not found'" \
        "" \
        true
    
    cleanup_test_config "$TEST_DIR"
    print_test_summary
}

run_tests

