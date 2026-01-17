#!/bin/bash
#
# run-all-tests.sh
#
# Runs MarkdownExtendedView tests.
#
# Usage: ./scripts/run-all-tests.sh [--verbose]
#
# Options:
#   --verbose     Show full test output
#

set -e

# Colors for output (disabled if not a terminal)
if [ -t 1 ]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    BLUE='\033[0;34m'
    NC='\033[0m' # No Color
else
    RED=''
    GREEN=''
    BLUE=''
    NC=''
fi

# Default options
VERBOSE=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --verbose|-v)
            VERBOSE=true
            shift
            ;;
        --help|-h)
            echo "Usage: $0 [--verbose]"
            echo ""
            echo "Options:"
            echo "  --verbose, -v    Show full test output"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Verify we're in the right directory
if [ ! -f "Package.swift" ]; then
    echo -e "${RED}Error: Must be run from MarkdownExtendedView root directory${NC}"
    exit 1
fi

echo ""
echo -e "${BLUE}MarkdownExtendedView Test Runner${NC}"
echo "================================="
echo ""

echo -e "${BLUE}Building...${NC}"
if [ "$VERBOSE" = true ]; then
    swift build
else
    swift build 2>&1 | tail -5
fi

echo ""
echo -e "${BLUE}Running tests...${NC}"
if [ "$VERBOSE" = true ]; then
    swift test
    TEST_EXIT=$?
else
    swift test 2>&1 | grep -E "(Test Suite|Executed|passed|failed|error:)" || true
    TEST_EXIT=${PIPESTATUS[0]}
fi

echo ""
if [ $TEST_EXIT -eq 0 ]; then
    echo -e "${GREEN}All tests passed!${NC}"
else
    echo -e "${RED}Tests failed${NC}"
    exit 1
fi
