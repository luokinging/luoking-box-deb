#!/bin/bash
# Test shell integration functionality

source "$(dirname "$0")/test-common.sh"

run_tests() {
    init_test_suite "Shell Integration"
    
    # Source shell integration
    source /etc/profile.d/luoking-box.sh 2>/dev/null || {
        echo -e "${YELLOW}  Warning: Shell integration not available, skipping tests${NC}"
        return 0
    }
    
    # Test that luoking-box function exists
    test_case "shell function exists" \
        "type luoking-box | grep -q 'function'" \
        ""
    
    # Setup test config
    TEST_DIR=$(setup_test_config)
    export CONFIG_FILE="$TEST_DIR/etc/luoking-box/config.json"
    export CONFIG_DIR="$TEST_DIR/etc/luoking-box/sing-box-config"
    export PROXY_STATE_DIR="$TEST_DIR/var/lib/luoking-box"
    
    # Test enable session through shell function
    unset http_proxy https_proxy HTTP_PROXY HTTPS_PROXY all_proxy ALL_PROXY
    bash -c "export CONFIG_FILE='$CONFIG_FILE' CONFIG_DIR='$CONFIG_DIR' PROXY_STATE_DIR='$PROXY_STATE_DIR'; source /etc/profile.d/luoking-box.sh; luoking-box enable session" >/dev/null 2>&1
    
    test_case "shell function sets env vars" \
        "bash -c \"export CONFIG_FILE='$CONFIG_FILE' CONFIG_DIR='$CONFIG_DIR' PROXY_STATE_DIR='$PROXY_STATE_DIR'; source /etc/profile.d/luoking-box.sh; unset http_proxy HTTP_PROXY; luoking-box enable session >/dev/null 2>&1; [ -n \\\"\\\$http_proxy\\\" ] && [ -n \\\"\\\$HTTP_PROXY\\\" ]\"" \
        ""
    
    # Test clear session through shell function
    test_case "shell function unsets env vars" \
        "bash -c \"export CONFIG_FILE='$CONFIG_FILE' CONFIG_DIR='$CONFIG_DIR' PROXY_STATE_DIR='$PROXY_STATE_DIR'; source /etc/profile.d/luoking-box.sh; export http_proxy='test' HTTP_PROXY='test'; luoking-box clear session >/dev/null 2>&1; [ -z \\\"\\\$http_proxy\\\" ] && [ -z \\\"\\\$HTTP_PROXY\\\" ]\"" \
        ""
    
    # Test enable multiple targets through shell function
    test_case "shell function enable multiple targets" \
        "bash -c \"export CONFIG_FILE='$CONFIG_FILE' CONFIG_DIR='$CONFIG_DIR' PROXY_STATE_DIR='$PROXY_STATE_DIR'; source /etc/profile.d/luoking-box.sh; unset http_proxy HTTP_PROXY; luoking-box enable session docker >/dev/null 2>&1; [ -n \\\"\\\$http_proxy\\\" ]\"" \
        ""
    
    cleanup_test_config "$TEST_DIR"
    print_test_summary
}

run_tests

