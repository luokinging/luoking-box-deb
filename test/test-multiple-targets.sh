#!/bin/bash
# Test multiple targets functionality

source "$(dirname "$0")/test-common.sh"

run_tests() {
    init_test_suite "Multiple Targets"
    
    # Setup test config
    TEST_DIR=$(setup_test_config)
    export CONFIG_FILE="$TEST_DIR/etc/luoking-box/config.json"
    export CONFIG_DIR="$TEST_DIR/etc/luoking-box/sing-box-config"
    export PROXY_STATE_DIR="$TEST_DIR/var/lib/luoking-box"
    
    # Test enable multiple targets
    rm -f "$PROXY_STATE_DIR/session_proxy" "$PROXY_STATE_DIR/docker_proxy"
    bash -c "export CONFIG_FILE='$CONFIG_FILE' CONFIG_DIR='$CONFIG_DIR' PROXY_STATE_DIR='$PROXY_STATE_DIR'; /usr/bin/luoking-box enable session docker" >/dev/null 2>&1 || true
    
    test_case "enable session docker creates session state" \
        "[ -f '$PROXY_STATE_DIR/session_proxy' ]" \
        ""
    
    test_case "enable session docker creates docker state" \
        "[ -f '$PROXY_STATE_DIR/docker_proxy' ]" \
        ""
    
    # Test clear multiple targets
    test_case "clear session docker removes both states" \
        "bash -c \"export CONFIG_FILE='$CONFIG_FILE' CONFIG_DIR='$CONFIG_DIR' PROXY_STATE_DIR='$PROXY_STATE_DIR'; /usr/bin/luoking-box clear session docker\" >/dev/null 2>&1; \
        [ ! -f '$PROXY_STATE_DIR/session_proxy' ] && [ ! -f '$PROXY_STATE_DIR/docker_proxy' ]" \
        ""
    
    cleanup_test_config "$TEST_DIR"
    print_test_summary
}

run_tests

