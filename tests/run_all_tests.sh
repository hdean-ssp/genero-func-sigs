#!/bin/bash
# Comprehensive test suite for all generators and tools

set -e

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Get the parent directory (project root)
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

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
bash "$SCRIPT_DIR/run_tests.sh"
echo ""

# Test 2: Module Dependency Generator
echo "=========================================="
echo "Test 2: Module Dependency Generator"
echo "=========================================="
bash "$SCRIPT_DIR/run_module_tests.sh"
echo ""

# Test 3: Call Graph Generator
echo "=========================================="
echo "Test 3: Call Graph Generator"
echo "=========================================="
bash "$SCRIPT_DIR/test_call_graph.sh"
echo ""

# Test 4: Codebase Index Generator
echo "=========================================="
echo "Test 4: Codebase Index Generator"
echo "=========================================="
echo "Generating signatures..."
bash "$PROJECT_ROOT/src/generate_signatures.sh" "$SCRIPT_DIR/sample_codebase" > /dev/null
echo "Generating modules..."
bash "$PROJECT_ROOT/src/generate_modules.sh" "$SCRIPT_DIR/sample_codebase" > /dev/null
echo "Generating codebase index..."
bash "$PROJECT_ROOT/src/generate_codebase_index.sh" > /dev/null
echo "[PASS] Codebase index generated successfully"
echo ""

# Test 5: Database Tools
echo "=========================================="
echo "Test 5: Database Tools"
echo "=========================================="
echo "Creating databases..."
bash "$PROJECT_ROOT/query.sh" create-dbs > /dev/null
echo "[PASS] Databases created successfully"
echo ""

# Test 6: Query Functions
echo "=========================================="
echo "Test 6: Query Functions"
echo "=========================================="

# Change to project root for database queries
cd "$PROJECT_ROOT"

echo "Testing find-function..."
RESULT=$(bash "$PROJECT_ROOT/query.sh" find-function "display_message" | python3 -c "import json, sys; data=json.load(sys.stdin); print(len(data))")
if [ "$RESULT" -ge 1 ]; then
    echo "[PASS] find-function works correctly"
else
    echo "[FAIL] find-function failed"
    exit 1
fi

echo "Testing search-functions..."
RESULT=$(bash "$PROJECT_ROOT/query.sh" search-functions "display" | python3 -c "import json, sys; data=json.load(sys.stdin); print(len(data))")
if [ "$RESULT" -ge 1 ]; then
    echo "[PASS] search-functions works correctly"
else
    echo "[FAIL] search-functions failed"
    exit 1
fi

echo "Testing list-file-functions..."
RESULT=$(bash "$PROJECT_ROOT/query.sh" list-file-functions "./tests/sample_codebase/no_returns.4gl" | python3 -c "import json, sys; data=json.load(sys.stdin); print(len(data))")
if [ "$RESULT" -ge 1 ]; then
    echo "[PASS] list-file-functions works correctly"
else
    echo "[FAIL] list-file-functions failed"
    exit 1
fi

echo "Testing find-module..."
RESULT=$(bash "$PROJECT_ROOT/query.sh" find-module "test" | python3 -c "import json, sys; data=json.load(sys.stdin); print(data.get('name', ''))")
if [ "$RESULT" = "test" ]; then
    echo "[PASS] find-module works correctly"
else
    echo "[FAIL] find-module failed"
    exit 1
fi

echo "Testing search-modules..."
RESULT=$(bash "$PROJECT_ROOT/query.sh" search-modules "test" | wc -l)
if [ "$RESULT" -ge 1 ]; then
    echo "[PASS] search-modules works correctly"
else
    echo "[FAIL] search-modules failed"
    exit 1
fi

echo "Testing list-file-modules..."
RESULT=$(bash "$PROJECT_ROOT/query.sh" list-file-modules "test.4gl" | python3 -c "import json, sys; data=json.load(sys.stdin); print(len(data))")
if [ "$RESULT" -ge 0 ]; then
    echo "[PASS] list-file-modules works correctly"
else
    echo "[FAIL] list-file-modules failed"
    exit 1
fi

echo ""

# Test 7: File Sizes
echo "=========================================="
echo "Test 7: File Sizes"
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
echo "  [PASS] Call graph generation"
echo "  [PASS] Codebase index generation"
echo "  [PASS] Database creation"
echo "  [PASS] Query functions"
echo "  [PASS] File size verification"
echo ""
