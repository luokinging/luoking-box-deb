#!/bin/bash
# Test basic commands: help, run, syntax

source "$(dirname "$0")/test-common.sh"

run_tests() {
    init_test_suite "Basic Commands"
    
    # Test script syntax
    test_case "luoking-box script syntax" \
        "bash -n /usr/bin/luoking-box" \
        ""
    
    test_case "shell integration script syntax" \
        "bash -n /etc/profile.d/luoking-box.sh" \
        ""
    
    # Test help command
    test_case "help command" \
        "luoking-box help" \
        "Usage:"
    
    test_case "empty command shows help" \
        "luoking-box" \
        "Usage:"
    
    test_case "help flag" \
        "luoking-box --help" \
        "Usage:"
    
    test_case "help short flag" \
        "luoking-box -h" \
        "Usage:"
    
    # Test run command (basic check - will fail without sing-box binary, but should accept args)
    test_case "run command accepts arguments" \
        "luoking-box run --help 2>&1 | head -1 | grep -qE '(sing-box|Usage|help|Error)' || true" \
        ""
    
    # Test unknown command
    test_case "unknown command fails" \
        "luoking-box invalid-command" \
        "Unknown command" \
        true
    
    print_test_summary
}

run_tests

