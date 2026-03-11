#!/bin/bash
# Unit tests for generate_signatures.sh

set -e

SCRIPT="./generate_signatures.sh"
TEST_DIR="./tests"
EXPECTED_OUTPUT="$TEST_DIR/expected_output.json"
TEMP_OUTPUT=$(mktemp)

echo "Running unit tests for generate_signatures.sh..."
echo ""

# Test 1: Run against test directory
echo "Test 1: Running script against test directory..."
bash "$SCRIPT" "$TEST_DIR"
cp workspace.json "$TEMP_OUTPUT"

# Sort both files for comparison (find order may vary)
SORTED_EXPECTED=$(mktemp)
SORTED_ACTUAL=$(mktemp)

jq -S 'to_entries | sort_by(.key) | from_entries | with_entries(.value |= sort_by(.name))' "$EXPECTED_OUTPUT" > "$SORTED_EXPECTED"
jq -S 'to_entries | sort_by(.key) | from_entries | with_entries(.value |= sort_by(.name))' "$TEMP_OUTPUT" > "$SORTED_ACTUAL"

if diff -q "$SORTED_EXPECTED" "$SORTED_ACTUAL" > /dev/null; then
    echo "✓ Test 1 PASSED: Output matches expected results"
else
    echo "✗ Test 1 FAILED: Output does not match expected results"
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

# Check that output contains only entries from simple_functions.4gl
FILE_COUNT=$(jq 'keys | length' "$SINGLE_FILE_OUTPUT")
SIMPLE_COUNT=$(jq '."./tests/simple_functions.4gl" | length' "$SINGLE_FILE_OUTPUT")

if [ "$FILE_COUNT" -eq 1 ] && [ "$SIMPLE_COUNT" -eq 3 ]; then
    echo "✓ Test 2 PASSED: Single file processing works correctly (found $SIMPLE_COUNT functions)"
else
    echo "✗ Test 2 FAILED: Expected 1 file with 3 functions from simple_functions.4gl, got $FILE_COUNT files with $SIMPLE_COUNT functions"
    cat "$SINGLE_FILE_OUTPUT"
    rm "$TEMP_OUTPUT" "$SORTED_EXPECTED" "$SORTED_ACTUAL" "$SINGLE_FILE_OUTPUT" workspace.json
    exit 1
fi

# Test 3: Verify signature format
echo ""
echo "Test 3: Verifying signature format..."
INVALID_SIGS=$(jq -r '.[][] | .signature' "$TEMP_OUTPUT" | grep -v -E '^[0-9]+-[0-9]+: [a-zA-Z_][a-zA-Z0-9_]*\(' || true)

if [ -z "$INVALID_SIGS" ]; then
    echo "✓ Test 3 PASSED: All signatures have valid format"
else
    echo "✗ Test 3 FAILED: Found invalid signature formats:"
    echo "$INVALID_SIGS"
    rm "$TEMP_OUTPUT" "$SORTED_EXPECTED" "$SORTED_ACTUAL" "$SINGLE_FILE_OUTPUT" workspace.json
    exit 1
fi

# Cleanup
rm "$TEMP_OUTPUT" "$SORTED_EXPECTED" "$SORTED_ACTUAL" "$SINGLE_FILE_OUTPUT"
rm -f workspace.json

echo ""
echo "=========================================="
echo "All tests passed successfully!"
echo "=========================================="
