#!/bin/bash
# Run all test suites

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/test-common.sh"

# Global counters
GLOBAL_PASSED=0
GLOBAL_FAILED=0
GLOBAL_TOTAL=0

run_test_suite() {
    local test_file="$1"
    local test_name=$(basename "$test_file" .sh)
    
    echo -e "\n${YELLOW}Running $test_name...${NC}"
    
    # Run test file and capture output
    local output
    output=$(bash "$test_file" 2>&1)
    local exit_code=$?
    
    # Display output
    echo "$output"
    
    # Parse results from output
    local result_line=$(echo "$output" | grep "^TEST_RESULTS:")
    if [ -n "$result_line" ]; then
        local total=$(echo "$result_line" | sed 's/.*TOTAL=\([0-9]*\).*/\1/')
        local passed=$(echo "$result_line" | sed 's/.*PASSED=\([0-9]*\).*/\1/')
        local failed=$(echo "$result_line" | sed 's/.*FAILED=\([0-9]*\).*/\1/')
        
        # Accumulate results
        GLOBAL_PASSED=$((GLOBAL_PASSED + passed))
        GLOBAL_FAILED=$((GLOBAL_FAILED + failed))
        GLOBAL_TOTAL=$((GLOBAL_TOTAL + total))
    fi
    
    return $exit_code
}

main() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}  Running All Test Suites${NC}"
    echo -e "${BLUE}========================================${NC}"
    
    # Run all test suites
    run_test_suite "$SCRIPT_DIR/test-basic-commands.sh"
    run_test_suite "$SCRIPT_DIR/test-config-parsing.sh"
    run_test_suite "$SCRIPT_DIR/test-session-proxy.sh"
    run_test_suite "$SCRIPT_DIR/test-docker-proxy.sh"
    run_test_suite "$SCRIPT_DIR/test-multiple-targets.sh"
    run_test_suite "$SCRIPT_DIR/test-error-handling.sh"
    run_test_suite "$SCRIPT_DIR/test-shell-integration.sh"
    
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

