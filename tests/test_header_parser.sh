#!/bin/bash

# Test suite for header parser
# Tests extraction of code references and author information from file headers

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

TESTS_PASSED=0
TESTS_FAILED=0

# Test helper function
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

# Test helper for JSON field extraction
get_json_field() {
    local json="$1"
    local field="$2"
    echo "$json" | python3 -c "import sys, json; data=json.load(sys.stdin); print(data.get('$field', ''))" 2>/dev/null || echo ""
}

# Test helper for JSON array length
get_json_array_length() {
    local json="$1"
    local field="$2"
    echo "$json" | python3 -c "import sys, json; data=json.load(sys.stdin); print(len(data.get('$field', [])))" 2>/dev/null || echo "0"
}

echo "Testing Header Parser"
echo "===================="
echo ""

# Test 1: Parse sample file
echo "Test 1: Parse sample file and extract references"
RESULT=$(python3 "$PROJECT_ROOT/scripts/parse_headers.py" "$PROJECT_ROOT/tests/sample_codebase/simple_functions.4gl")
REF_COUNT=$(get_json_array_length "$RESULT" "file_references")
assert_equals "Extract 10 references from sample file" "10" "$REF_COUNT"

# Test 2: Check specific references are extracted
echo ""
echo "Test 2: Verify specific references are extracted"
REFS=$(echo "$RESULT" | python3 -c "import sys, json; data=json.load(sys.stdin); print(','.join([r['reference'] for r in data['file_references']]))")
assert_equals "Contains EH100466-4" "true" "$(echo "$REFS" | grep -q 'EH100466-4' && echo 'true' || echo 'false')"
assert_equals "Contains PRB-299" "true" "$(echo "$REFS" | grep -q 'PRB-299' && echo 'true' || echo 'false')"
assert_equals "Contains SR-40356-3" "true" "$(echo "$REFS" | grep -q 'SR-40356-3' && echo 'true' || echo 'false')"

# Test 3: Check author extraction
echo ""
echo "Test 3: Verify author extraction"
AUTHOR_COUNT=$(get_json_array_length "$RESULT" "file_authors")
assert_equals "Extract 5 unique authors" "5" "$AUTHOR_COUNT"

# Test 4: Check author names
echo ""
echo "Test 4: Verify specific authors are extracted"
AUTHORS=$(echo "$RESULT" | python3 -c "import sys, json; data=json.load(sys.stdin); print(','.join([a['author'] for a in data['file_authors']]))")
assert_equals "Contains Rich" "true" "$(echo "$AUTHORS" | grep -q 'Rich' && echo 'true' || echo 'false')"
assert_equals "Contains Chris P" "true" "$(echo "$AUTHORS" | grep -q 'Chris P' && echo 'true' || echo 'false')"
assert_equals "Contains MartinB" "true" "$(echo "$AUTHORS" | grep -q 'MartinB' && echo 'true' || echo 'false')"

# Test 5: Check date parsing
echo ""
echo "Test 5: Verify date parsing and normalization"
FIRST_REF=$(echo "$RESULT" | python3 -c "import sys, json; data=json.load(sys.stdin); print(data['file_references'][0]['date'])")
assert_equals "First reference date is ISO 8601 format" "2024-03-20" "$FIRST_REF"

# Test 6: Check description extraction
echo ""
echo "Test 6: Verify description extraction"
FIRST_DESC=$(echo "$RESULT" | python3 -c "import sys, json; data=json.load(sys.stdin); print(data['file_references'][0]['description'])")
assert_equals "First reference has description" "Initial" "$FIRST_DESC"

# Test 7: Check multi-line description handling
echo ""
echo "Test 7: Verify multi-line description handling"
PRB299_DESC=$(echo "$RESULT" | python3 -c "import sys, json; data=json.load(sys.stdin); refs=[r for r in data['file_references'] if r['reference']=='PRB-299']; print(refs[0]['description'] if refs else '')")
assert_equals "PRB-299 has correct description" "Enhanced MailMerge Error Handling" "$PRB299_DESC"

# Test 8: Check author statistics
echo ""
echo "Test 8: Verify author statistics"
RICH_STATS=$(echo "$RESULT" | python3 -c "import sys, json; data=json.load(sys.stdin); authors=[a for a in data['file_authors'] if a['author']=='Rich']; print(authors[0]['count'] if authors else 0)")
assert_equals "Rich has 2 changes" "2" "$RICH_STATS"

# Test 9: Check author date range
echo ""
echo "Test 9: Verify author date range tracking"
RICH_FIRST=$(echo "$RESULT" | python3 -c "import sys, json; data=json.load(sys.stdin); authors=[a for a in data['file_authors'] if a['author']=='Rich']; print(authors[0]['first_change'] if authors else '')")
RICH_LAST=$(echo "$RESULT" | python3 -c "import sys, json; data=json.load(sys.stdin); authors=[a for a in data['file_authors'] if a['author']=='Rich']; print(authors[0]['last_change'] if authors else '')")
assert_equals "Rich first change date" "2024-03-20" "$RICH_FIRST"
assert_equals "Rich last change date" "2025-04-01" "$RICH_LAST"

# Test 10: Check that references with different formats are handled
echo ""
echo "Test 10: Verify handling of different reference formats"
assert_equals "Contains EH100512-9a (alphanumeric suffix)" "true" "$(echo "$REFS" | grep -q 'EH100512-9a' && echo 'true' || echo 'false')"
assert_equals "Contains EH100512 (no suffix)" "true" "$(echo "$REFS" | grep -q 'EH100512' && echo 'true' || echo 'false')"

# Summary
echo ""
echo "===================="
echo "Tests Passed: $TESTS_PASSED"
echo "Tests Failed: $TESTS_FAILED"
echo ""

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}All tests passed!${NC}"
    exit 0
else
    echo -e "${RED}Some tests failed!${NC}"
    exit 1
fi
