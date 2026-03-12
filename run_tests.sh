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

# Sort both files for comparison using Python
SORTED_EXPECTED=$(mktemp)
SORTED_ACTUAL=$(mktemp)

python3 << 'PYTHON_SCRIPT'
import json
import sys

def sort_json(input_file, output_file):
    with open(input_file, 'r') as f:
        data = json.load(f)
    
    # Remove metadata
    data.pop('_metadata', None)
    
    # Sort all entries
    sorted_data = {}
    for key in sorted(data.keys()):
        sorted_data[key] = sorted(data[key], key=lambda x: x.get('name', ''))
    
    with open(output_file, 'w') as f:
        json.dump(sorted_data, f, sort_keys=True, indent=2)

sort_json(sys.argv[1], sys.argv[2])
sort_json(sys.argv[3], sys.argv[4])
PYTHON_SCRIPT
"$EXPECTED_OUTPUT" "$SORTED_EXPECTED" "$TEMP_OUTPUT" "$SORTED_ACTUAL"

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

# Check that output contains only entries from simple_functions.4gl (excluding metadata)
python3 << 'PYTHON_SCRIPT'
import json
import sys

with open(sys.argv[1], 'r') as f:
    data = json.load(f)

data.pop('_metadata', None)
file_count = len(data)
simple_count = len(data.get('./tests/sample_codebase/simple_functions.4gl', []))

if file_count == 1 and simple_count == 3:
    print(f"✓ Test 2 PASSED: Single file processing works correctly (found {simple_count} functions)")
    sys.exit(0)

print(f"✗ Test 2 FAILED: Expected 1 file with 3 functions from simple_functions.4gl, got {file_count} files with {simple_count} functions")
sys.exit(1)
PYTHON_SCRIPT
"$SINGLE_FILE_OUTPUT" || {
    cat "$SINGLE_FILE_OUTPUT"
    rm "$TEMP_OUTPUT" "$SORTED_EXPECTED" "$SORTED_ACTUAL" "$SINGLE_FILE_OUTPUT" workspace.json
    exit 1
}

# Test 3: Verify signature format
echo ""
echo "Test 3: Verifying signature format..."
python3 << 'PYTHON_SCRIPT'
import json
import re
import sys

with open(sys.argv[1], 'r') as f:
    data = json.load(f)

data.pop('_metadata', None)

invalid_sigs = []
for file_funcs in data.values():
    for func in file_funcs:
        sig = func.get('signature', '')
        if not re.match(r'^\d+-\d+: [a-zA-Z_][a-zA-Z0-9_]*\(', sig):
            invalid_sigs.append(sig)

if not invalid_sigs:
    print("✓ Test 3 PASSED: All signatures have valid format")
    sys.exit(0)

print("✗ Test 3 FAILED: Found invalid signature formats:")
for sig in invalid_sigs:
    print(f"  {sig}")
sys.exit(1)
PYTHON_SCRIPT
"$TEMP_OUTPUT" || {
    rm "$TEMP_OUTPUT" "$SORTED_EXPECTED" "$SORTED_ACTUAL" "$SINGLE_FILE_OUTPUT" workspace.json
    exit 1
}

# Test 4: Verify function count
echo ""
echo "Test 4: Verifying total function count..."
python3 << 'PYTHON_SCRIPT'
import json
import sys

with open(sys.argv[1], 'r') as f:
    expected = json.load(f)
with open(sys.argv[2], 'r') as f:
    actual = json.load(f)

expected.pop('_metadata', None)
actual.pop('_metadata', None)

expected_count = sum(len(funcs) for funcs in expected.values())
actual_count = sum(len(funcs) for funcs in actual.values())

if expected_count == actual_count:
    print(f"✓ Test 4 PASSED: Found {actual_count} functions as expected")
    sys.exit(0)

print(f"✗ Test 4 FAILED: Expected {expected_count} functions, got {actual_count}")
sys.exit(1)
PYTHON_SCRIPT
"$EXPECTED_OUTPUT" "$TEMP_OUTPUT" || {
    rm "$TEMP_OUTPUT" "$SORTED_EXPECTED" "$SORTED_ACTUAL" "$SINGLE_FILE_OUTPUT" workspace.json
    exit 1
}

# Test 5: Verify metadata structure
echo ""
echo "Test 5: Verifying metadata structure..."
python3 << 'PYTHON_SCRIPT'
import json
import sys

with open(sys.argv[1], 'r') as f:
    data = json.load(f)

if '_metadata' in data:
    metadata = data['_metadata']
    if all(k in metadata for k in ['version', 'generated', 'files_processed']):
        print(f"✓ Test 5 PASSED: Metadata structure is valid (processed {metadata['files_processed']} files)")
        sys.exit(0)

print("✗ Test 5 FAILED: Metadata structure is incomplete")
sys.exit(1)
PYTHON_SCRIPT
"$TEMP_OUTPUT" || {
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
