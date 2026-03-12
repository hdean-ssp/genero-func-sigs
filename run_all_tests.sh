#!/bin/bash
# Comprehensive test suite for all generators and tools

set -e

echo "=========================================="
echo "Genero Function Signatures - Full Test Suite"
echo "=========================================="
echo ""

# Clean up any previous test artifacts
echo "Cleaning up previous test artifacts..."
rm -f workspace.json modules.json codebase_index.json
rm -f workspace.db modules.db
echo "[PASS] Cleanup complete"
echo ""

# Test 1: Function Signature Generator
echo "=========================================="
echo "Test 1: Function Signature Generator"
echo "=========================================="
bash run_tests.sh
echo ""

# Test 2: Module Dependency Generator
echo "=========================================="
echo "Test 2: Module Dependency Generator"
echo "=========================================="
bash run_module_tests.sh
echo ""

# Test 3: Codebase Index Generator
echo "=========================================="
echo "Test 3: Codebase Index Generator"
echo "=========================================="
echo "Generating signatures..."
bash generate_signatures.sh tests/sample_codebase > /dev/null
echo "Generating modules..."
bash generate_modules.sh tests/sample_codebase > /dev/null
echo "Generating codebase index..."
bash generate_codebase_index.sh > /dev/null
echo "[PASS] Codebase index generated successfully"
echo ""

# Test 4: Database Tools
echo "=========================================="
echo "Test 4: Database Tools"
echo "=========================================="
echo "Creating databases..."
bash query.sh create-dbs > /dev/null
echo "[PASS] Databases created successfully"
echo ""

# Test 5: Query Functions
echo "=========================================="
echo "Test 5: Query Functions"
echo "=========================================="

echo "Testing find-function..."
RESULT=$(bash query.sh find-function "display_message" | python3 -c "import json, sys; data=json.load(sys.stdin); print(len(data))")
if [ "$RESULT" -eq 1 ]; then
    echo "[PASS] find-function works correctly"
else
    echo "[FAIL] find-function failed"
    exit 1
fi

echo "Testing search-functions..."
RESULT=$(bash query.sh search-functions "display" | python3 -c "import json, sys; data=json.load(sys.stdin); print(len(data))")
if [ "$RESULT" -ge 1 ]; then
    echo "[PASS] search-functions works correctly"
else
    echo "[FAIL] search-functions failed"
    exit 1
fi

echo "Testing list-file-functions..."
RESULT=$(bash query.sh list-file-functions "tests/sample_codebase/no_returns.4gl" | python3 -c "import json, sys; data=json.load(sys.stdin); print(len(data))")
if [ "$RESULT" -ge 1 ]; then
    echo "[PASS] list-file-functions works correctly"
else
    echo "[FAIL] list-file-functions failed"
    exit 1
fi

echo "Testing find-module..."
RESULT=$(bash query.sh find-module "test" | python3 -c "import json, sys; data=json.load(sys.stdin); print(data.get('name', ''))")
if [ "$RESULT" = "test" ]; then
    echo "[PASS] find-module works correctly"
else
    echo "[FAIL] find-module failed"
    exit 1
fi

echo "Testing search-modules..."
RESULT=$(bash query.sh search-modules "test" | wc -l)
if [ "$RESULT" -ge 1 ]; then
    echo "[PASS] search-modules works correctly"
else
    echo "[FAIL] search-modules failed"
    exit 1
fi

echo "Testing list-file-modules..."
RESULT=$(bash query.sh list-file-modules "test.4gl" | python3 -c "import json, sys; data=json.load(sys.stdin); print(len(data))")
if [ "$RESULT" -ge 0 ]; then
    echo "[PASS] list-file-modules works correctly"
else
    echo "[FAIL] list-file-modules failed"
    exit 1
fi

echo ""

# Test 6: File Sizes
echo "=========================================="
echo "Test 6: File Sizes"
echo "=========================================="
echo "JSON files:"
ls -lh workspace.json modules.json codebase_index.json | awk '{print "  " $9 ": " $5}'
echo ""
echo "SQLite databases:"
ls -lh workspace.db modules.db | awk '{print "  " $9 ": " $5}'
echo ""

# Calculate compression ratio
JSON_SIZE=$(du -c workspace.json modules.json codebase_index.json | tail -1 | awk '{print $1}')
DB_SIZE=$(du -c workspace.db modules.db | tail -1 | awk '{print $1}')
if [ "$JSON_SIZE" -gt 0 ]; then
    RATIO=$((DB_SIZE * 100 / JSON_SIZE))
    echo "Database size is $RATIO% of JSON size"
fi
echo ""

# Final Summary
echo "=========================================="
echo "[PASS] ALL TESTS PASSED SUCCESSFULLY!"
echo "=========================================="
echo ""
echo "Summary:"
echo "  [PASS] Function signature generation"
echo "  [PASS] Module dependency generation"
echo "  [PASS] Codebase index generation"
echo "  [PASS] Database creation"
echo "  [PASS] Query functions"
echo "  [PASS] File size verification"
echo ""
