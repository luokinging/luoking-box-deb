#!/bin/bash
# Test Docker proxy functionality

source "$(dirname "$0")/test-common.sh"

run_tests() {
    init_test_suite "Docker Proxy"
    
    # Setup test config
    TEST_DIR=$(setup_test_config)
    export CONFIG_FILE="$TEST_DIR/etc/luoking-box/config.json"
    export CONFIG_DIR="$TEST_DIR/etc/luoking-box/sing-box-config"
    export PROXY_STATE_DIR="$TEST_DIR/var/lib/luoking-box"
    
    # Mock sudo for testing (create test docker config dir)
    DOCKER_TEST_DIR="$TEST_DIR/etc/systemd/system/docker.service.d"
    mkdir -p "$DOCKER_TEST_DIR"
    
    # Test enable docker (will create state file even if sudo fails)
    bash -c "export CONFIG_FILE='$CONFIG_FILE' CONFIG_DIR='$CONFIG_DIR' PROXY_STATE_DIR='$PROXY_STATE_DIR'; /usr/bin/luoking-box enable docker" >/dev/null 2>&1 || true
    
    test_case "enable docker creates state file" \
        "[ -f '$PROXY_STATE_DIR/docker_proxy' ]" \
        ""
    
    # Test clear docker
    test_case "clear docker removes state file" \
        "bash -c \"export CONFIG_FILE='$CONFIG_FILE' CONFIG_DIR='$CONFIG_DIR' PROXY_STATE_DIR='$PROXY_STATE_DIR'; /usr/bin/luoking-box clear docker\" >/dev/null 2>&1; [ ! -f '$PROXY_STATE_DIR/docker_proxy' ]" \
        ""
    
    cleanup_test_config "$TEST_DIR"
    print_test_summary
}

run_tests

