#!/bin/bash
# Common test utilities and functions

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test counters
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_TOTAL=0
TEST_SUITE_NAME=""

# Initialize test suite
init_test_suite() {
    TEST_SUITE_NAME="$1"
    TESTS_PASSED=0
    TESTS_FAILED=0
    TESTS_TOTAL=0
    echo -e "\n${BLUE}=== $TEST_SUITE_NAME ===${NC}"
}

# Test case function
test_case() {
    local test_name="$1"
    local test_command="$2"
    local expected_pattern="${3:-}"
    local should_fail="${4:-false}"
    
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
    echo -n "  Test $TESTS_TOTAL: $test_name ... "
    
    if [ "$should_fail" = "true" ]; then
        # Test should fail
        if eval "$test_command" >/dev/null 2>&1; then
            echo -e "${RED}FAILED${NC} (expected failure but succeeded)"
            TESTS_FAILED=$((TESTS_FAILED + 1))
            return 1
        else
            echo -e "${GREEN}PASSED${NC}"
            TESTS_PASSED=$((TESTS_PASSED + 1))
            return 0
        fi
    else
        # Test should succeed
        local output
        output=$(eval "$test_command" 2>&1) || {
            echo -e "${RED}FAILED${NC} (command failed)"
            echo "    Output: $output" | head -3
            TESTS_FAILED=$((TESTS_FAILED + 1))
            return 1
        }
        
        if [ -n "$expected_pattern" ]; then
            if echo "$output" | grep -qE "$expected_pattern"; then
                echo -e "${GREEN}PASSED${NC}"
                TESTS_PASSED=$((TESTS_PASSED + 1))
                return 0
            else
                echo -e "${RED}FAILED${NC} (pattern mismatch)"
                echo "    Expected: $expected_pattern"
                echo "    Got: $output" | head -3
                TESTS_FAILED=$((TESTS_FAILED + 1))
                return 1
            fi
        else
            echo -e "${GREEN}PASSED${NC}"
            TESTS_PASSED=$((TESTS_PASSED + 1))
            return 0
        fi
    fi
}

# Print test suite summary
print_test_summary() {
    echo -e "\n${BLUE}=== $TEST_SUITE_NAME Summary ===${NC}"
    echo -e "Total:  $TESTS_TOTAL"
    echo -e "${GREEN}Passed: $TESTS_PASSED${NC}"
    if [ $TESTS_FAILED -gt 0 ]; then
        echo -e "${RED}Failed: $TESTS_FAILED${NC}"
    else
        echo -e "Failed: $TESTS_FAILED"
    fi
    
    # Output results in a parseable format for parent script
    echo "TEST_RESULTS: TOTAL=$TESTS_TOTAL PASSED=$TESTS_PASSED FAILED=$TESTS_FAILED"
    
    if [ $TESTS_FAILED -eq 0 ]; then
        return 0
    else
        return 1
    fi
}

# Setup test config
setup_test_config() {
    # Use project root test-env directory
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local project_dir="$(cd "$script_dir/.." && pwd)"
    local test_config_dir="${1:-$project_dir/test-env}"
    mkdir -p "$test_config_dir/etc/luoking-box/sing-box-config"
    mkdir -p "$test_config_dir/var/lib/luoking-box"
    
    # Create test config with mixed inbound
    cat > "$test_config_dir/etc/luoking-box/sing-box-config/default.json" << 'EOF'
{
    "inbounds": [
        {
            "type": "mixed",
            "listen": "127.0.0.1",
            "listen_port": 8890
        }
    ]
}
EOF
    
    echo '{"active_config": "default"}' > "$test_config_dir/etc/luoking-box/config.json"
    chmod 600 "$test_config_dir/etc/luoking-box/config.json" "$test_config_dir/etc/luoking-box/sing-box-config/default.json" 2>/dev/null || true
    
    echo "$test_config_dir"
}

# Cleanup test config
cleanup_test_config() {
    local test_config_dir="$1"
    [ -n "$test_config_dir" ] && rm -rf "$test_config_dir" 2>/dev/null || true
}

