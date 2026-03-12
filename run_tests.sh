#!/bin/bash
# Unit tests for generate_signatures.sh

set -e

SCRIPT="./generate_signatures.sh"
TEST_DIR="./tests/sample_codebase"
EXPECTED_OUTPUT="$TEST_DIR/expected_output.json"
TEMP_OUTPUT=$(mktemp)

echo "Running unit tests for generate_signatures.sh..."
echo ""

# Test 1: Run against test directory
echo "Test 1: Running script against test directory..."
bash "$SCRIPT" "$TEST_DIR"
cp workspace.json "$TEMP_OUTPUT"

# Sort both files for comparison
SORTED_EXPECTED=$(mktemp)
SORTED_ACTUAL=$(mktemp)

python3 scripts/test_utils.py sort_signatures "$EXPECTED_OUTPUT" "$SORTED_EXPECTED"
python3 scripts/test_utils.py sort_signatures "$TEMP_OUTPUT" "$SORTED_ACTUAL"

if diff -q "$SORTED_EXPECTED" "$SORTED_ACTUAL" > /dev/null; then
    echo "[PASS] Test 1 PASSED: Output matches expected results"
else
    echo "[FAIL] Test 1 FAILED: Output does not match expected results"
    echo ""
    echo "Expected:"
    cat "$SORTED_EXPECTED"
    echo ""
    echo "Actual:"
    cat "$SORTED_ACTUAL"
    echo ""
    echo "Diff:"
    diff "$SORTED_EXPECTED" "$SORTED_ACTUAL" || true
    rm "$TEMP_OUTPUT" "$SORTED_EXPECTED" "$SORTED_ACTUAL" workspace.json
    exit 1
fi

# Test 2: Run against a single file
echo ""
echo "Test 2: Running script against a single file..."
SINGLE_FILE_OUTPUT=$(mktemp)
bash "$SCRIPT" "$TEST_DIR/simple_functions.4gl"
cp workspace.json "$SINGLE_FILE_OUTPUT"

# Check that output contains only entries from simple_functions.4gl (excluding metadata)
python3 - "$SINGLE_FILE_OUTPUT" << 'EOF'
import json
import sys

with open(sys.argv[1], 'r') as f:
    data = json.load(f)

data.pop('_metadata', None)
file_count = len(data)
simple_count = len(data.get('./tests/sample_codebase/simple_functions.4gl', []))

if file_count == 1 and simple_count == 3:
    print(f"[PASS] Test 2 PASSED: Single file processing works correctly (found {simple_count} functions)")
    sys.exit(0)

print(f"[FAIL] Test 2 FAILED: Expected 1 file with 3 functions from simple_functions.4gl, got {file_count} files with {simple_count} functions")
sys.exit(1)
EOF
if [ $? -ne 0 ]; then
    cat "$SINGLE_FILE_OUTPUT"
    rm "$TEMP_OUTPUT" "$SORTED_EXPECTED" "$SORTED_ACTUAL" "$SINGLE_FILE_OUTPUT" workspace.json
    exit 1
fi

# Test 3: Verify signature format
echo ""
echo "Test 3: Verifying signature format..."
python3 scripts/test_utils.py check_signatures_format "$TEMP_OUTPUT" && echo "[PASS] Test 3 PASSED: All signatures have valid format" || {
    echo "[FAIL] Test 3 FAILED: Found invalid signature formats"
    rm "$TEMP_OUTPUT" "$SORTED_EXPECTED" "$SORTED_ACTUAL" "$SINGLE_FILE_OUTPUT" workspace.json
    exit 1
}

# Test 4: Verify function count
echo ""
echo "Test 4: Verifying total function count..."
EXPECTED_FUNCTION_COUNT=$(python3 scripts/test_utils.py count_functions "$EXPECTED_OUTPUT")
ACTUAL_FUNCTION_COUNT=$(python3 scripts/test_utils.py count_functions "$TEMP_OUTPUT")

if [ "$EXPECTED_FUNCTION_COUNT" -eq "$ACTUAL_FUNCTION_COUNT" ]; then
    echo "[PASS] Test 4 PASSED: Found $ACTUAL_FUNCTION_COUNT functions as expected"
else
    echo "[FAIL] Test 4 FAILED: Expected $EXPECTED_FUNCTION_COUNT functions, got $ACTUAL_FUNCTION_COUNT"
    rm "$TEMP_OUTPUT" "$SORTED_EXPECTED" "$SORTED_ACTUAL" "$SINGLE_FILE_OUTPUT" workspace.json
    exit 1
fi

# Test 5: Verify metadata structure
echo ""
echo "Test 5: Verifying metadata structure..."
FILES_PROCESSED=$(python3 scripts/test_utils.py check_metadata "$TEMP_OUTPUT") && echo "[PASS] Test 5 PASSED: Metadata structure is valid (processed $FILES_PROCESSED files)" || {
    echo "[FAIL] Test 5 FAILED: Metadata structure is incomplete"
    rm "$TEMP_OUTPUT" "$SORTED_EXPECTED" "$SORTED_ACTUAL" "$SINGLE_FILE_OUTPUT" workspace.json
    exit 1
}

# Cleanup
rm "$TEMP_OUTPUT" "$SORTED_EXPECTED" "$SORTED_ACTUAL" "$SINGLE_FILE_OUTPUT"
rm -f workspace.json

echo ""
echo "=========================================="
echo "All tests passed successfully!"
echo "=========================================="
