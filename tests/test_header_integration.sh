#!/bin/bash

# Integration test for header parsing and querying
# Tests the full pipeline: parse headers -> merge -> database -> query

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

TESTS_PASSED=0
TESTS_FAILED=0

# Test helper
assert_equals() {
    local test_name="$1"
    local expected="$2"
    local actual="$3"
    
    if [ "$expected" = "$actual" ]; then
        echo -e "${GREEN}✓${NC} $test_name"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}✗${NC} $test_name"
        echo "  Expected: $expected"
        echo "  Actual:   $actual"
        ((TESTS_FAILED++))
    fi
}

echo "Header Integration Tests"
echo "======================="
echo ""

# Test 1: Parse headers from sample file
echo "Test 1: Parse headers from sample file"
HEADERS=$(python3 "$PROJECT_ROOT/scripts/parse_headers.py" "$PROJECT_ROOT/tests/sample_codebase/simple_functions.4gl")
REF_COUNT=$(echo "$HEADERS" | python3 -c "import sys, json; data=json.load(sys.stdin); print(len(data.get('file_references', [])))")
assert_equals "Extract 10 references" "10" "$REF_COUNT"

# Test 2: Merge headers into workspace
echo ""
echo "Test 2: Merge headers into workspace.json"
# Create a minimal workspace.json for testing
TEST_WORKSPACE=$(mktemp)
TEST_HEADERS=$(mktemp)
TEST_OUTPUT=$(mktemp)

trap "rm -f $TEST_WORKSPACE $TEST_HEADERS $TEST_OUTPUT" EXIT

# Create test workspace
cat > "$TEST_WORKSPACE" << 'EOF'
{
  "_metadata": {"version": "1.0.0"},
  "./tests/sample_codebase/simple_functions.4gl": [
    {"name": "add_numbers", "line": {"start": 1, "end": 5}, "signature": "1-5: add_numbers(a INTEGER, b INTEGER):result INTEGER", "parameters": [], "returns": [], "calls": []}
  ]
}
EOF

# Create test headers
python3 "$PROJECT_ROOT/scripts/parse_headers.py" "$PROJECT_ROOT/tests/sample_codebase/simple_functions.4gl" > "$TEST_HEADERS"

# Merge
python3 "$PROJECT_ROOT/scripts/merge_headers.py" "$TEST_WORKSPACE" "$TEST_HEADERS" "$TEST_OUTPUT"

# Check that headers were merged
MERGED=$(cat "$TEST_OUTPUT")
HAS_REFS=$(echo "$MERGED" | python3 -c "import sys, json; data=json.load(sys.stdin); funcs=list(data.values())[1:]; print('true' if funcs and 'file_references' in funcs[0][0] else 'false')" 2>/dev/null || echo "false")
assert_equals "Headers merged into workspace" "true" "$HAS_REFS"

# Test 3: Create database with headers
echo ""
echo "Test 3: Create database with header tables"
TEST_DB=$(mktemp --suffix=.db)
trap "rm -f $TEST_DB" EXIT

# First create signatures database
python3 "$PROJECT_ROOT/scripts/json_to_sqlite.py" signatures "$TEST_OUTPUT" "$TEST_DB"

# Then add header tables
python3 "$PROJECT_ROOT/scripts/json_to_sqlite_headers.py" "$TEST_HEADERS" "$TEST_DB"

# Check that tables exist
TABLES=$(sqlite3 "$TEST_DB" ".tables")
assert_equals "file_references table exists" "true" "$(echo "$TABLES" | grep -q 'file_references' && echo 'true' || echo 'false')"
assert_equals "file_authors table exists" "true" "$(echo "$TABLES" | grep -q 'file_authors' && echo 'true' || echo 'false')"

# Test 4: Query references from database
echo ""
echo "Test 4: Query references from database"
QUERY_RESULT=$(python3 "$PROJECT_ROOT/scripts/query_headers.py" search-references "$TEST_DB" "PRB-%" 2>/dev/null || echo "[]")
REF_COUNT=$(echo "$QUERY_RESULT" | python3 -c "import sys, json; data=json.load(sys.stdin); print(len(data))")
assert_equals "Find PRB references" "2" "$REF_COUNT"

# Test 5: Query authors from database
echo ""
echo "Test 5: Query authors from database"
QUERY_RESULT=$(python3 "$PROJECT_ROOT/scripts/query_headers.py" find-author "$TEST_DB" "Rich" 2>/dev/null || echo "[]")
AUTHOR_COUNT=$(echo "$QUERY_RESULT" | python3 -c "import sys, json; data=json.load(sys.stdin); print(len(data))")
assert_equals "Find Rich's changes" "2" "$AUTHOR_COUNT"

# Test 6: Query author expertise
echo ""
echo "Test 6: Query author expertise"
QUERY_RESULT=$(python3 "$PROJECT_ROOT/scripts/query_headers.py" author-expertise "$TEST_DB" "Chilly" 2>/dev/null || echo "[]")
EXPERTISE_COUNT=$(echo "$QUERY_RESULT" | python3 -c "import sys, json; data=json.load(sys.stdin); print(len(data))")
assert_equals "Chilly has expertise in 1 file" "1" "$EXPERTISE_COUNT"

# Summary
echo ""
echo "======================="
echo "Tests Passed: $TESTS_PASSED"
echo "Tests Failed: $TESTS_FAILED"
echo ""

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}All integration tests passed!${NC}"
    exit 0
else
    echo -e "${RED}Some tests failed!${NC}"
    exit 1
fi
