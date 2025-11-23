#!/bin/bash
# Main test runner - runs all functional tests

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/test-common.sh"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
DEB_FILE="${1:-/playground/luoking-box_1.0.0_amd64.deb}"
CONFIG_FILE="${2:-/playground/config.json}"

# Global counters
GLOBAL_PASSED=0
GLOBAL_FAILED=0
GLOBAL_TOTAL=0

# Run a test script and accumulate results
run_test_script() {
    local test_file="$1"
    local test_name=$(basename "$test_file" .sh)
    local test_args="${@:2}"
    
    echo -e "\n${YELLOW}Running $test_name...${NC}"
    
    # Run test and capture output
    local output
    output=$(bash "$test_file" $test_args 2>&1)
    local exit_code=$?
    
    # Display output
    echo "$output"
    
    # Parse results
    local result_line=$(echo "$output" | grep "^TOTAL=" | tail -1)
    if [ -n "$result_line" ]; then
        local total=$(echo "$result_line" | sed 's/.*TOTAL=\([0-9]*\).*/\1/')
        local passed=$(echo "$result_line" | sed 's/.*PASSED=\([0-9]*\).*/\1/')
        local failed=$(echo "$result_line" | sed 's/.*FAILED=\([0-9]*\).*/\1/')
        
        GLOBAL_TOTAL=$((GLOBAL_TOTAL + total))
        GLOBAL_PASSED=$((GLOBAL_PASSED + passed))
        GLOBAL_FAILED=$((GLOBAL_FAILED + failed))
    fi
    
    return $exit_code
}

# Cleanup function
cleanup() {
    echo -e "\n${YELLOW}Cleaning up...${NC}"
    
    # Stop service if running
    systemctl stop luoking-box 2>/dev/null || true
    systemctl disable luoking-box 2>/dev/null || true
    
    # Clear proxy
    if command -v luoking-box >/dev/null 2>&1; then
        source /etc/profile.d/luoking-box.sh 2>/dev/null || true
        luoking-box clear session docker 2>/dev/null || true
    fi
    
    # Uninstall package
    dpkg -P luoking-box 2>/dev/null || true
    
    echo -e "${GREEN}Cleanup completed${NC}"
}

# Main execution
main() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}  luoking-box Functional Test Suite${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo -e "DEB file: $DEB_FILE"
    echo -e "Config file: $CONFIG_FILE"
    
    # Trap cleanup on exit
    trap cleanup EXIT
    
    # Run all test suites
    run_test_script "$SCRIPT_DIR/test-installation.sh" "$DEB_FILE"
    run_test_script "$SCRIPT_DIR/test-configuration.sh" "$CONFIG_FILE"
    run_test_script "$SCRIPT_DIR/test-service.sh"
    run_test_script "$SCRIPT_DIR/test-proxy.sh"
    run_test_script "$SCRIPT_DIR/test-version.sh"
    
    # Print final summary
    echo -e "\n${BLUE}========================================${NC}"
    echo -e "${BLUE}  Final Test Summary${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo -e "Total tests:  $GLOBAL_TOTAL"
    echo -e "${GREEN}Passed:      $GLOBAL_PASSED${NC}"
    if [ $GLOBAL_FAILED -gt 0 ]; then
        echo -e "${RED}Failed:      $GLOBAL_FAILED${NC}"
        exit 1
    else
        echo -e "Failed:      $GLOBAL_FAILED"
        echo -e "\n${GREEN}✓ All tests passed!${NC}"
        exit 0
    fi
}

main

