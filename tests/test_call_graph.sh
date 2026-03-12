#!/bin/bash
# Unit tests for function call graph functionality

set -e

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Get the parent directory (project root)
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo "Running call graph tests..."
echo ""

# Generate database with calls
echo "Test 1: Generating database with calls..."
cd "$PROJECT_ROOT"
CREATE_DB=1 bash src/generate_signatures.sh tests/sample_codebase > /dev/null 2>&1
echo "[PASS] Test 1 PASSED: Database generated successfully"

# Test 2: Verify calls table exists and has data
echo ""
echo "Test 2: Verifying calls table..."
CALL_COUNT=$(python3 << 'EOF'
import sqlite3
conn = sqlite3.connect('workspace.db')
c = conn.cursor()
c.execute("SELECT COUNT(*) FROM calls")
count = c.fetchone()[0]
conn.close()
print(count)
EOF
)

if [ "$CALL_COUNT" -gt 0 ]; then
    echo "[PASS] Test 2 PASSED: Found $CALL_COUNT function calls in database"
else
    echo "[FAIL] Test 2 FAILED: No calls found in database"
    exit 1
fi

# Test 3: Test find_function_dependencies query
echo ""
echo "Test 3: Testing find_function_dependencies query..."
DEPS=$(python3 scripts/query_db.py find_function_dependencies workspace.db add_numbers 2>/dev/null | python3 -c "import sys, json; data = json.load(sys.stdin); print(len(data))")

if [ "$DEPS" -eq 1 ]; then
    echo "[PASS] Test 3 PASSED: Found $DEPS dependency for add_numbers"
else
    echo "[FAIL] Test 3 FAILED: Expected 1 dependency, got $DEPS"
    exit 1
fi

# Test 4: Test find_function_dependents query
echo ""
echo "Test 4: Testing find_function_dependents query..."
DEPENDENTS=$(python3 scripts/query_db.py find_function_dependents workspace.db log_message 2>/dev/null | python3 -c "import sys, json; data = json.load(sys.stdin); print(len(data))")

if [ "$DEPENDENTS" -gt 0 ]; then
    echo "[PASS] Test 4 PASSED: Found $DEPENDENTS functions that call log_message"
else
    echo "[FAIL] Test 4 FAILED: Expected at least 1 dependent, got $DEPENDENTS"
    exit 1
fi

# Test 5: Test query.sh wrapper for dependencies
echo ""
echo "Test 5: Testing query.sh wrapper for find-function-dependencies..."
WRAPPER_DEPS=$(bash query.sh find-function-dependencies add_numbers 2>/dev/null | python3 -c "import sys, json; data = json.load(sys.stdin); print(len(data))")

if [ "$WRAPPER_DEPS" -eq 1 ]; then
    echo "[PASS] Test 5 PASSED: Wrapper query returned $WRAPPER_DEPS dependency"
else
    echo "[FAIL] Test 5 FAILED: Wrapper query returned $WRAPPER_DEPS dependencies"
    exit 1
fi

# Test 6: Test query.sh wrapper for dependents
echo ""
echo "Test 6: Testing query.sh wrapper for find-function-dependents..."
WRAPPER_DEPENDENTS=$(bash query.sh find-function-dependents log_message 2>/dev/null | python3 -c "import sys, json; data = json.load(sys.stdin); print(len(data))")

if [ "$WRAPPER_DEPENDENTS" -gt 0 ]; then
    echo "[PASS] Test 6 PASSED: Wrapper query returned $WRAPPER_DEPENDENTS dependents"
else
    echo "[FAIL] Test 6 FAILED: Wrapper query returned $WRAPPER_DEPENDENTS dependents"
    exit 1
fi

# Test 7: Verify calls are in workspace.json
echo ""
echo "Test 7: Verifying calls in workspace.json..."
CALLS_IN_JSON=$(python3 << 'EOF'
import json
with open('workspace.json', 'r') as f:
    data = json.load(f)

total_calls = 0
for file_path, functions in data.items():
    if file_path == '_metadata':
        continue
    for func in functions:
        total_calls += len(func.get('calls', []))

print(total_calls)
EOF
)

if [ "$CALLS_IN_JSON" -gt 0 ]; then
    echo "[PASS] Test 7 PASSED: Found $CALLS_IN_JSON calls in workspace.json"
else
    echo "[FAIL] Test 7 FAILED: No calls found in workspace.json"
    exit 1
fi

# Test 8: Verify control flow calls are detected
echo ""
echo "Test 8: Verifying control flow call detection..."
CONTROL_FLOW_CALLS=$(python3 << 'EOF'
import json
with open('workspace.json', 'r') as f:
    data = json.load(f)

# Find control_flow_calls function
for file_path, functions in data.items():
    if file_path == '_metadata':
        continue
    for func in functions:
        if func['name'] == 'control_flow_calls':
            print(len(func.get('calls', [])))
            exit(0)

print(0)
EOF
)

if [ "$CONTROL_FLOW_CALLS" -gt 5 ]; then
    echo "[PASS] Test 8 PASSED: Found $CONTROL_FLOW_CALLS calls in control_flow_calls function"
else
    echo "[FAIL] Test 8 FAILED: Expected >5 calls in control_flow_calls, got $CONTROL_FLOW_CALLS"
    exit 1
fi

# Cleanup
rm -f workspace.json workspace.db

echo ""
echo "=========================================="
echo "All call graph tests passed successfully!"
echo "=========================================="
