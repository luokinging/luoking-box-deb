#!/bin/bash
# Test session proxy functionality

source "$(dirname "$0")/test-common.sh"

run_tests() {
    init_test_suite "Session Proxy"
    
    # Setup test config
    TEST_DIR=$(setup_test_config)
    export CONFIG_FILE="$TEST_DIR/etc/luoking-box/config.json"
    export CONFIG_DIR="$TEST_DIR/etc/luoking-box/sing-box-config"
    export PROXY_STATE_DIR="$TEST_DIR/var/lib/luoking-box"
    
    # Test enable session
    PROXY_OUTPUT=$(bash -c "export CONFIG_FILE='$CONFIG_FILE' CONFIG_DIR='$CONFIG_DIR' PROXY_STATE_DIR='$PROXY_STATE_DIR'; /usr/bin/luoking-box enable session" 2>&1 || echo "")
    PROXY_URL=$(echo "$PROXY_OUTPUT" | grep -E '^http://[0-9.]+:[0-9]+$' | head -1 || echo "")
    
    test_case "enable session outputs URL" \
        "[ -n '$PROXY_URL' ]" \
        ""
    
    test_case "enable session creates state file" \
        "[ -f '$PROXY_STATE_DIR/session_proxy' ]" \
        ""
    
    if [ -f "$PROXY_STATE_DIR/session_proxy" ] && [ -n "$PROXY_URL" ]; then
        test_case "state file contains correct URL" \
            "[ \"\$(cat '$PROXY_STATE_DIR/session_proxy')\" = '$PROXY_URL' ]" \
            ""
    else
        test_case "state file contains correct URL" \
            "false" \
            ""
    fi
    
    # Test clear session
    test_case "clear session removes state file" \
        "bash -c \"export CONFIG_FILE='$CONFIG_FILE' CONFIG_DIR='$CONFIG_DIR' PROXY_STATE_DIR='$PROXY_STATE_DIR'; /usr/bin/luoking-box clear session\" >/dev/null 2>&1; [ ! -f '$PROXY_STATE_DIR/session_proxy' ]" \
        ""
    
    cleanup_test_config "$TEST_DIR"
    print_test_summary
}

run_tests

