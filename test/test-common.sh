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
test_pass() {
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "${GREEN}✓${NC} $1"
}

test_fail() {
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} $1"
    if [ -n "$2" ]; then
        echo -e "  ${RED}Error: $2${NC}"
    fi
}

# Print test suite summary
print_test_summary() {
    echo -e "\n${BLUE}=== $TEST_SUITE_NAME Summary ===${NC}"
    echo -e "Total:  $TESTS_TOTAL"
    echo -e "${GREEN}Passed: $TESTS_PASSED${NC}"
    if [ $TESTS_FAILED -gt 0 ]; then
        echo -e "${RED}Failed: $TESTS_FAILED${NC}"
        return 1
    else
        echo -e "Failed: $TESTS_FAILED"
        return 0
    fi
}

# Get test results (for parent script)
get_test_results() {
    echo "TOTAL=$TESTS_TOTAL PASSED=$TESTS_PASSED FAILED=$TESTS_FAILED"
}

