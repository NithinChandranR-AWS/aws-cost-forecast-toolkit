#!/bin/bash
# AWS Cost Forecast Toolkit - Test Runner
# Author: Nithin Chandran R (rajashan@amazon.com)
# License: MIT

set -euo pipefail

# Configuration
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="$(dirname "${SCRIPT_DIR}")"
readonly TEST_OUTPUT_DIR="${SCRIPT_DIR}/results"

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m'
readonly BOLD='\033[1m'

# Test counters
declare -i tests_run=0
declare -i tests_passed=0
declare -i tests_failed=0

# Create test output directory
mkdir -p "${TEST_OUTPUT_DIR}"

# Logging function
log() {
    local level=$1
    local message=$2
    local color
    
    case $level in
        "INFO") color="${CYAN}";;
        "PASS") color="${GREEN}";;
        "FAIL") color="${RED}";;
        "WARN") color="${YELLOW}";;
        *) color="${NC}";;
    esac
    
    echo -e "$(date '+%H:%M:%S') [${color}${level}${NC}] ${message}"
}

# Test assertion functions
assert_command_exists() {
    local command=$1
    local description=${2:-"Command $command exists"}
    
    tests_run=$((tests_run + 1))
    
    if command -v "$command" >/dev/null 2>&1; then
        log "PASS" "$description"
        tests_passed=$((tests_passed + 1))
        return 0
    else
        log "FAIL" "$description"
        tests_failed=$((tests_failed + 1))
        return 1
    fi
}

assert_file_exists() {
    local file=$1
    local description=${2:-"File $file exists"}
    
    tests_run=$((tests_run + 1))
    
    if [[ -f "$file" ]]; then
        log "PASS" "$description"
        tests_passed=$((tests_passed + 1))
        return 0
    else
        log "FAIL" "$description"
        tests_failed=$((tests_failed + 1))
        return 1
    fi
}

assert_file_executable() {
    local file=$1
    local description=${2:-"File $file is executable"}
    
    tests_run=$((tests_run + 1))
    
    if [[ -x "$file" ]]; then
        log "PASS" "$description"
        tests_passed=$((tests_passed + 1))
        return 0
    else
        log "FAIL" "$description"
        tests_failed=$((tests_failed + 1))
        return 1
    fi
}

assert_script_syntax() {
    local script=$1
    local description=${2:-"Script $script has valid syntax"}
    
    tests_run=$((tests_run + 1))
    
    if bash -n "$script" 2>/dev/null; then
        log "PASS" "$description"
        tests_passed=$((tests_passed + 1))
        return 0
    else
        log "FAIL" "$description - Syntax errors found"
        tests_failed=$((tests_failed + 1))
        return 1
    fi
}

# Test suites
test_prerequisites() {
    log "INFO" "Testing prerequisites..."
    
    assert_command_exists "bash" "Bash shell is available"
    assert_command_exists "aws" "AWS CLI is installed"
    assert_command_exists "jq" "jq is installed"
    assert_command_exists "curl" "curl is available"
    assert_command_exists "date" "date command is available"
    assert_command_exists "find" "find command is available"
}

test_file_structure() {
    log "INFO" "Testing file structure..."
    
    # Core files
    assert_file_exists "${PROJECT_ROOT}/README.md" "README.md exists"
    assert_file_exists "${PROJECT_ROOT}/LICENSE" "LICENSE file exists"
    assert_file_exists "${PROJECT_ROOT}/CONTRIBUTING.md" "CONTRIBUTING.md exists"
    assert_file_exists "${PROJECT_ROOT}/.gitignore" ".gitignore exists"
    
    # Scripts
    assert_file_exists "${PROJECT_ROOT}/scripts/forecast-data-fetch.sh" "Main forecast script exists"
    assert_file_exists "${PROJECT_ROOT}/scripts/quicksight-dashboard.sh" "QuickSight script exists"
    assert_file_exists "${PROJECT_ROOT}/scripts/setup.sh" "Setup script exists"
    
    # Directories
    [[ -d "${PROJECT_ROOT}/config" ]] && log "PASS" "Config directory exists" || log "FAIL" "Config directory missing"
    [[ -d "${PROJECT_ROOT}/templates" ]] && log "PASS" "Templates directory exists" || log "FAIL" "Templates directory missing"
    [[ -d "${PROJECT_ROOT}/examples" ]] && log "PASS" "Examples directory exists" || log "FAIL" "Examples directory missing"
}

test_script_permissions() {
    log "INFO" "Testing script permissions..."
    
    assert_file_executable "${PROJECT_ROOT}/scripts/forecast-data-fetch.sh" "Main forecast script is executable"
    assert_file_executable "${PROJECT_ROOT}/scripts/quicksight-dashboard.sh" "QuickSight script is executable"
    assert_file_executable "${PROJECT_ROOT}/scripts/setup.sh" "Setup script is executable"
}

test_script_syntax() {
    log "INFO" "Testing script syntax..."
    
    assert_script_syntax "${PROJECT_ROOT}/scripts/forecast-data-fetch.sh" "Main forecast script syntax"
    assert_script_syntax "${PROJECT_ROOT}/scripts/quicksight-dashboard.sh" "QuickSight script syntax"
    assert_script_syntax "${PROJECT_ROOT}/scripts/setup.sh" "Setup script syntax"
}

test_script_help() {
    log "INFO" "Testing script help functionality..."
    
    tests_run=$((tests_run + 1))
    if "${PROJECT_ROOT}/scripts/forecast-data-fetch.sh" --help >/dev/null 2>&1; then
        log "PASS" "Main forecast script shows help"
        tests_passed=$((tests_passed + 1))
    else
        log "FAIL" "Main forecast script help failed"
        tests_failed=$((tests_failed + 1))
    fi
    
    tests_run=$((tests_run + 1))
    if "${PROJECT_ROOT}/scripts/quicksight-dashboard.sh" --help >/dev/null 2>&1; then
        log "PASS" "QuickSight script shows help"
        tests_passed=$((tests_passed + 1))
    else
        log "FAIL" "QuickSight script help failed"
        tests_failed=$((tests_failed + 1))
    fi
    
    tests_run=$((tests_run + 1))
    if "${PROJECT_ROOT}/scripts/setup.sh" --help >/dev/null 2>&1; then
        log "PASS" "Setup script shows help"
        tests_passed=$((tests_passed + 1))
    else
        log "FAIL" "Setup script help failed"
        tests_failed=$((tests_failed + 1))
    fi
}

test_shellcheck() {
    log "INFO" "Running ShellCheck (if available)..."
    
    if command -v shellcheck >/dev/null 2>&1; then
        for script in "${PROJECT_ROOT}/scripts"/*.sh; do
            tests_run=$((tests_run + 1))
            if shellcheck "$script" >/dev/null 2>&1; then
                log "PASS" "ShellCheck passed for $(basename "$script")"
                tests_passed=$((tests_passed + 1))
            else
                log "FAIL" "ShellCheck failed for $(basename "$script")"
                tests_failed=$((tests_failed + 1))
            fi
        done
    else
        log "WARN" "ShellCheck not available - skipping linting tests"
    fi
}

# Main test execution
main() {
    echo -e "${BOLD}AWS Cost Forecast Toolkit - Test Suite${NC}"
    echo "========================================"
    echo
    
    # Run test suites
    test_prerequisites
    echo
    test_file_structure
    echo
    test_script_permissions
    echo
    test_script_syntax
    echo
    test_script_help
    echo
    test_shellcheck
    echo
    
    # Test summary
    echo "========================================"
    echo -e "${BOLD}Test Results Summary${NC}"
    echo "========================================"
    echo -e "Tests Run:    ${tests_run}"
    echo -e "Tests Passed: ${GREEN}${tests_passed}${NC}"
    echo -e "Tests Failed: ${RED}${tests_failed}${NC}"
    
    if [[ $tests_failed -eq 0 ]]; then
        echo -e "\n${GREEN}${BOLD}✅ All tests passed!${NC}"
        exit 0
    else
        echo -e "\n${RED}${BOLD}❌ Some tests failed!${NC}"
        exit 1
    fi
}

# Handle command line arguments
case "${1:-}" in
    --help|-h)
        echo "AWS Cost Forecast Toolkit Test Runner"
        echo
        echo "Usage: $0 [OPTIONS]"
        echo
        echo "Options:"
        echo "  --help, -h    Show this help message"
        echo "  --verbose, -v Enable verbose output"
        echo
        echo "This script runs basic tests to validate the toolkit setup:"
        echo "- Prerequisites check"
        echo "- File structure validation"
        echo "- Script permissions"
        echo "- Script syntax validation"
        echo "- Help functionality"
        echo "- ShellCheck linting (if available)"
        exit 0
        ;;
    --verbose|-v)
        set -x
        ;;
esac

# Execute main function
main "$@"
