#!/bin/bash
# Unit tests for generate_modules.sh

set -e

SCRIPT="./generate_modules.sh"
TEST_DIR="./tests/sample_codebase"
EXPECTED_OUTPUT="$TEST_DIR/expected_modules.json"
TEMP_OUTPUT=$(mktemp)

echo "Running unit tests for generate_modules.sh..."
echo ""

# Test 1: Run against test directory
echo "Test 1: Running script against test directory..."
bash "$SCRIPT" "$TEST_DIR"
cp modules.json "$TEMP_OUTPUT"

# Sort both files for comparison (find order may vary)
SORTED_EXPECTED=$(mktemp)
SORTED_ACTUAL=$(mktemp)

jq -S 'del(._metadata) | .modules |= sort_by(.module)' "$EXPECTED_OUTPUT" > "$SORTED_EXPECTED"
jq -S 'del(._metadata) | .modules |= sort_by(.module)' "$TEMP_OUTPUT" > "$SORTED_ACTUAL"

if diff -q "$SORTED_EXPECTED" "$SORTED_ACTUAL" > /dev/null; then
    echo "✓ Test 1 PASSED: Output matches expected results"
else
    echo "✗ Test 1 FAILED: Output does not match expected results"
    echo ""
    echo "Diff:"
    diff "$SORTED_EXPECTED" "$SORTED_ACTUAL" || true
    rm "$TEMP_OUTPUT" "$SORTED_EXPECTED" "$SORTED_ACTUAL" modules.json
    exit 1
fi

# Test 2: Verify metadata structure
echo ""
echo "Test 2: Verifying metadata structure..."
if jq -e '._metadata' "$TEMP_OUTPUT" > /dev/null 2>&1; then
    METADATA_VALID=$(jq '._metadata | has("version") and has("generated") and has("files_processed")' "$TEMP_OUTPUT")
    if [ "$METADATA_VALID" = "true" ]; then
        FILES_PROCESSED=$(jq '._metadata.files_processed' "$TEMP_OUTPUT")
        echo "✓ Test 2 PASSED: Metadata structure is valid (processed $FILES_PROCESSED files)"
    else
        echo "✗ Test 2 FAILED: Metadata structure is incomplete"
        rm "$TEMP_OUTPUT" "$SORTED_EXPECTED" "$SORTED_ACTUAL" modules.json
        exit 1
    fi
else
    echo "✗ Test 2 FAILED: Metadata is missing"
    rm "$TEMP_OUTPUT" "$SORTED_EXPECTED" "$SORTED_ACTUAL" modules.json
    exit 1
fi

# Test 3: Verify module count
echo ""
echo "Test 3: Verifying module count..."
EXPECTED_MODULE_COUNT=$(jq '.modules | length' "$EXPECTED_OUTPUT")
ACTUAL_MODULE_COUNT=$(jq '.modules | length' "$TEMP_OUTPUT")

if [ "$EXPECTED_MODULE_COUNT" -eq "$ACTUAL_MODULE_COUNT" ]; then
    echo "✓ Test 3 PASSED: Found $ACTUAL_MODULE_COUNT modules as expected"
else
    echo "✗ Test 3 FAILED: Expected $EXPECTED_MODULE_COUNT modules, got $ACTUAL_MODULE_COUNT"
    rm "$TEMP_OUTPUT" "$SORTED_EXPECTED" "$SORTED_ACTUAL" modules.json
    exit 1
fi

# Test 4: Verify empty module handling
echo ""
echo "Test 4: Verifying empty module handling..."
EMPTY_MODULE=$(jq '.modules[] | select(.module == "empty")' "$TEMP_OUTPUT")
EMPTY_L4GLS=$(echo "$EMPTY_MODULE" | jq '.L4GLS | length')
EMPTY_U4GLS=$(echo "$EMPTY_MODULE" | jq '.U4GLS | length')
EMPTY_4GLS=$(echo "$EMPTY_MODULE" | jq '."4GLS" | length')

if [ "$EMPTY_L4GLS" -eq 0 ] && [ "$EMPTY_U4GLS" -eq 0 ] && [ "$EMPTY_4GLS" -eq 0 ]; then
    echo "✓ Test 4 PASSED: Empty module correctly has zero files"
else
    echo "✗ Test 4 FAILED: Empty module has unexpected files (L4GLS:$EMPTY_L4GLS, U4GLS:$EMPTY_U4GLS, 4GLS:$EMPTY_4GLS)"
    rm "$TEMP_OUTPUT" "$SORTED_EXPECTED" "$SORTED_ACTUAL" modules.json
    exit 1
fi

# Test 5: Verify multiline continuation handling
echo ""
echo "Test 5: Verifying multiline continuation handling..."
MULTILINE_MODULE=$(jq '.modules[] | select(.module == "multiline")' "$TEMP_OUTPUT")
MULTILINE_L4GLS=$(echo "$MULTILINE_MODULE" | jq '.L4GLS | length')
MULTILINE_U4GLS=$(echo "$MULTILINE_MODULE" | jq '.U4GLS | length')
MULTILINE_4GLS=$(echo "$MULTILINE_MODULE" | jq '."4GLS" | length')

if [ "$MULTILINE_L4GLS" -eq 8 ] && [ "$MULTILINE_U4GLS" -eq 3 ] && [ "$MULTILINE_4GLS" -eq 3 ]; then
    echo "✓ Test 5 PASSED: Multiline module correctly parsed (L4GLS:$MULTILINE_L4GLS, U4GLS:$MULTILINE_U4GLS, 4GLS:$MULTILINE_4GLS)"
else
    echo "✗ Test 5 FAILED: Multiline module parsing incorrect (L4GLS:$MULTILINE_L4GLS, U4GLS:$MULTILINE_U4GLS, 4GLS:$MULTILINE_4GLS)"
    rm "$TEMP_OUTPUT" "$SORTED_EXPECTED" "$SORTED_ACTUAL" modules.json
    exit 1
fi

# Test 6: Verify whitespace handling
echo ""
echo "Test 6: Verifying whitespace handling..."
WHITESPACE_MODULE=$(jq '.modules[] | select(.module == "whitespace")' "$TEMP_OUTPUT")
WHITESPACE_L4GLS=$(echo "$WHITESPACE_MODULE" | jq '.L4GLS | length')
WHITESPACE_U4GLS=$(echo "$WHITESPACE_MODULE" | jq '.U4GLS | length')

if [ "$WHITESPACE_L4GLS" -eq 4 ] && [ "$WHITESPACE_U4GLS" -eq 2 ]; then
    echo "✓ Test 6 PASSED: Whitespace variations handled correctly"
else
    echo "✗ Test 6 FAILED: Whitespace handling incorrect (L4GLS:$WHITESPACE_L4GLS, U4GLS:$WHITESPACE_U4GLS)"
    rm "$TEMP_OUTPUT" "$SORTED_EXPECTED" "$SORTED_ACTUAL" modules.json
    exit 1
fi

# Test 7: Verify mixed file types (only .4gl extracted)
echo ""
echo "Test 7: Verifying mixed file types (only .4gl files extracted)..."
MIXED_MODULE=$(jq '.modules[] | select(.module == "mixed_files")' "$TEMP_OUTPUT")
HAS_C_FILES=$(echo "$MIXED_MODULE" | jq '[.L4GLS[], .U4GLS[], ."4GLS"[]] | any(endswith(".c"))')
HAS_EC_FILES=$(echo "$MIXED_MODULE" | jq '[.L4GLS[], .U4GLS[], ."4GLS"[]] | any(endswith(".ec"))')

if [ "$HAS_C_FILES" = "false" ] && [ "$HAS_EC_FILES" = "false" ]; then
    echo "✓ Test 7 PASSED: Only .4gl files extracted, .c and .ec files ignored"
else
    echo "✗ Test 7 FAILED: Non-.4gl files found in output"
    rm "$TEMP_OUTPUT" "$SORTED_EXPECTED" "$SORTED_ACTUAL" modules.json
    exit 1
fi

# Test 8: Verify specific expected files
echo ""
echo "Test 8: Verifying specific expected files..."
TEST_MODULE=$(jq '.modules[] | select(.module == "test")' "$TEMP_OUTPUT")
HAS_TEST_4GL=$(echo "$TEST_MODULE" | jq '."4GLS" | contains(["test.4gl"])')
HAS_LIBERR=$(echo "$TEST_MODULE" | jq '.L4GLS | contains(["liberr.4gl"])')
HAS_SET_OPTS=$(echo "$TEST_MODULE" | jq '.U4GLS | contains(["set_opts.4gl"])')

if [ "$HAS_TEST_4GL" = "true" ] && [ "$HAS_LIBERR" = "true" ] && [ "$HAS_SET_OPTS" = "true" ]; then
    echo "✓ Test 8 PASSED: All expected files found in test module"
else
    echo "✗ Test 8 FAILED: Missing expected files in test module"
    echo "  test.4gl in 4GLS: $HAS_TEST_4GL"
    echo "  liberr.4gl in L4GLS: $HAS_LIBERR"
    echo "  set_opts.4gl in U4GLS: $HAS_SET_OPTS"
    rm "$TEMP_OUTPUT" "$SORTED_EXPECTED" "$SORTED_ACTUAL" modules.json
    exit 1
fi

# Cleanup
rm "$TEMP_OUTPUT" "$SORTED_EXPECTED" "$SORTED_ACTUAL"
rm -f modules.json

echo ""
echo "=========================================="
echo "All tests passed successfully!"
echo "=========================================="
