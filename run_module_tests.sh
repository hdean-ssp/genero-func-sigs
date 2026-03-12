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
    
    # Sort modules by module name
    if 'modules' in data:
        data['modules'] = sorted(data['modules'], key=lambda x: x.get('module', ''))
    
    with open(output_file, 'w') as f:
        json.dump(data, f, sort_keys=True, indent=2)

sort_json(sys.argv[1], sys.argv[2])
sort_json(sys.argv[3], sys.argv[4])
PYTHON_SCRIPT
"$EXPECTED_OUTPUT" "$SORTED_EXPECTED" "$TEMP_OUTPUT" "$SORTED_ACTUAL"

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
python3 << 'PYTHON_SCRIPT'
import json
import sys

with open(sys.argv[1], 'r') as f:
    data = json.load(f)

if '_metadata' in data:
    metadata = data['_metadata']
    if all(k in metadata for k in ['version', 'generated', 'files_processed']):
        print(f"✓ Test 2 PASSED: Metadata structure is valid (processed {metadata['files_processed']} files)")
        sys.exit(0)

print("✗ Test 2 FAILED: Metadata structure is incomplete")
sys.exit(1)
PYTHON_SCRIPT
"$TEMP_OUTPUT" || {
    rm "$TEMP_OUTPUT" "$SORTED_EXPECTED" "$SORTED_ACTUAL" modules.json
    exit 1
}

# Test 3: Verify module count
echo ""
echo "Test 3: Verifying module count..."
python3 << 'PYTHON_SCRIPT'
import json
import sys

with open(sys.argv[1], 'r') as f:
    expected = json.load(f)
with open(sys.argv[2], 'r') as f:
    actual = json.load(f)

expected_count = len(expected.get('modules', []))
actual_count = len(actual.get('modules', []))

if expected_count == actual_count:
    print(f"✓ Test 3 PASSED: Found {actual_count} modules as expected")
    sys.exit(0)

print(f"✗ Test 3 FAILED: Expected {expected_count} modules, got {actual_count}")
sys.exit(1)
PYTHON_SCRIPT
"$EXPECTED_OUTPUT" "$TEMP_OUTPUT" || {
    rm "$TEMP_OUTPUT" "$SORTED_EXPECTED" "$SORTED_ACTUAL" modules.json
    exit 1
}

# Test 4: Verify empty module handling
echo ""
echo "Test 4: Verifying empty module handling..."
python3 << 'PYTHON_SCRIPT'
import json
import sys

with open(sys.argv[1], 'r') as f:
    data = json.load(f)

for module in data.get('modules', []):
    if module.get('module') == 'empty':
        l4gls = len(module.get('L4GLS', []))
        u4gls = len(module.get('U4GLS', []))
        gls_4 = len(module.get('4GLS', []))
        
        if l4gls == 0 and u4gls == 0 and gls_4 == 0:
            print("✓ Test 4 PASSED: Empty module correctly has zero files")
            sys.exit(0)
        else:
            print(f"✗ Test 4 FAILED: Empty module has unexpected files (L4GLS:{l4gls}, U4GLS:{u4gls}, 4GLS:{gls_4})")
            sys.exit(1)

print("✗ Test 4 FAILED: Empty module not found")
sys.exit(1)
PYTHON_SCRIPT
"$TEMP_OUTPUT" || {
    rm "$TEMP_OUTPUT" "$SORTED_EXPECTED" "$SORTED_ACTUAL" modules.json
    exit 1
}

# Test 5: Verify multiline continuation handling
echo ""
echo "Test 5: Verifying multiline continuation handling..."
python3 << 'PYTHON_SCRIPT'
import json
import sys

with open(sys.argv[1], 'r') as f:
    data = json.load(f)

for module in data.get('modules', []):
    if module.get('module') == 'multiline':
        l4gls = len(module.get('L4GLS', []))
        u4gls = len(module.get('U4GLS', []))
        gls_4 = len(module.get('4GLS', []))
        
        if l4gls == 8 and u4gls == 3 and gls_4 == 3:
            print(f"✓ Test 5 PASSED: Multiline module correctly parsed (L4GLS:{l4gls}, U4GLS:{u4gls}, 4GLS:{gls_4})")
            sys.exit(0)
        else:
            print(f"✗ Test 5 FAILED: Multiline module parsing incorrect (L4GLS:{l4gls}, U4GLS:{u4gls}, 4GLS:{gls_4})")
            sys.exit(1)

print("✗ Test 5 FAILED: Multiline module not found")
sys.exit(1)
PYTHON_SCRIPT
"$TEMP_OUTPUT" || {
    rm "$TEMP_OUTPUT" "$SORTED_EXPECTED" "$SORTED_ACTUAL" modules.json
    exit 1
}

# Test 6: Verify whitespace handling
echo ""
echo "Test 6: Verifying whitespace handling..."
python3 << 'PYTHON_SCRIPT'
import json
import sys

with open(sys.argv[1], 'r') as f:
    data = json.load(f)

for module in data.get('modules', []):
    if module.get('module') == 'whitespace':
        l4gls = len(module.get('L4GLS', []))
        u4gls = len(module.get('U4GLS', []))
        
        if l4gls == 4 and u4gls == 2:
            print("✓ Test 6 PASSED: Whitespace variations handled correctly")
            sys.exit(0)
        else:
            print(f"✗ Test 6 FAILED: Whitespace handling incorrect (L4GLS:{l4gls}, U4GLS:{u4gls})")
            sys.exit(1)

print("✗ Test 6 FAILED: Whitespace module not found")
sys.exit(1)
PYTHON_SCRIPT
"$TEMP_OUTPUT" || {
    rm "$TEMP_OUTPUT" "$SORTED_EXPECTED" "$SORTED_ACTUAL" modules.json
    exit 1
}

# Test 7: Verify mixed file types (only .4gl extracted)
echo ""
echo "Test 7: Verifying mixed file types (only .4gl files extracted)..."
python3 << 'PYTHON_SCRIPT'
import json
import sys

with open(sys.argv[1], 'r') as f:
    data = json.load(f)

for module in data.get('modules', []):
    if module.get('module') == 'mixed_files':
        all_files = module.get('L4GLS', []) + module.get('U4GLS', []) + module.get('4GLS', [])
        has_c = any(f.endswith('.c') for f in all_files)
        has_ec = any(f.endswith('.ec') for f in all_files)
        
        if not has_c and not has_ec:
            print("✓ Test 7 PASSED: Only .4gl files extracted, .c and .ec files ignored")
            sys.exit(0)
        else:
            print("✗ Test 7 FAILED: Non-.4gl files found in output")
            sys.exit(1)

print("✗ Test 7 FAILED: Mixed files module not found")
sys.exit(1)
PYTHON_SCRIPT
"$TEMP_OUTPUT" || {
    rm "$TEMP_OUTPUT" "$SORTED_EXPECTED" "$SORTED_ACTUAL" modules.json
    exit 1
}

# Test 8: Verify specific expected files
echo ""
echo "Test 8: Verifying specific expected files..."
python3 << 'PYTHON_SCRIPT'
import json
import sys

with open(sys.argv[1], 'r') as f:
    data = json.load(f)

for module in data.get('modules', []):
    if module.get('module') == 'test':
        has_test_4gl = 'test.4gl' in module.get('4GLS', [])
        has_liberr = 'liberr.4gl' in module.get('L4GLS', [])
        has_set_opts = 'set_opts.4gl' in module.get('U4GLS', [])
        
        if has_test_4gl and has_liberr and has_set_opts:
            print("✓ Test 8 PASSED: All expected files found in test module")
            sys.exit(0)
        else:
            print("✗ Test 8 FAILED: Missing expected files in test module")
            print(f"  test.4gl in 4GLS: {has_test_4gl}")
            print(f"  liberr.4gl in L4GLS: {has_liberr}")
            print(f"  set_opts.4gl in U4GLS: {has_set_opts}")
            sys.exit(1)

print("✗ Test 8 FAILED: Test module not found")
sys.exit(1)
PYTHON_SCRIPT
"$TEMP_OUTPUT" || {
    rm "$TEMP_OUTPUT" "$SORTED_EXPECTED" "$SORTED_ACTUAL" modules.json
    exit 1
}

# Cleanup
rm "$TEMP_OUTPUT" "$SORTED_EXPECTED" "$SORTED_ACTUAL"
rm -f modules.json

echo ""
echo "=========================================="
echo "All tests passed successfully!"
echo "=========================================="
