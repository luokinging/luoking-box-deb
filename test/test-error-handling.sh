#!/bin/bash
# Test error handling

source "$(dirname "$0")/test-common.sh"

run_tests() {
    init_test_suite "Error Handling"
    
    # Test invalid targets
    test_case "enable invalid target fails" \
        "/usr/bin/luoking-box enable invalid" \
        "Unknown target" \
        true
    
    test_case "clear invalid target fails" \
        "/usr/bin/luoking-box clear invalid" \
        "Unknown target" \
        true
    
    # Test missing targets
    test_case "enable without target fails" \
        "/usr/bin/luoking-box enable" \
        "No target specified" \
        true
    
    test_case "clear without target fails" \
        "/usr/bin/luoking-box clear" \
        "No target specified" \
        true
    
    # Test multiple invalid targets
    test_case "enable multiple invalid targets fails" \
        "/usr/bin/luoking-box enable invalid1 invalid2" \
        "Unknown target" \
        true
    
    # Test mixed valid and invalid targets
    test_case "enable mixed valid/invalid targets fails" \
        "/usr/bin/luoking-box enable session invalid" \
        "Unknown target" \
        true
    
    print_test_summary
}

run_tests

