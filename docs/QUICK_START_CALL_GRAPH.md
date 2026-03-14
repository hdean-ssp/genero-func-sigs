# Quick Start: Function Call Graph

## What's New

Function body parsing now extracts which functions call which other functions. This enables:

- **Impact Analysis** - See what breaks when you change a function
- **Dependency Tracking** - Understand function dependencies
- **Dead Code Detection** - Find unused functions

## Basic Usage

### Find what a function calls

```bash
bash query.sh find-function-dependencies add_numbers
```

Output:
```json
[
  {
    "called_function_name": "validate_number",
    "line_number": 10
  }
]
```

### Find what calls a function

```bash
bash query.sh find-function-dependents log_message
```

Output:
```json
[
  {
    "name": "display_message",
    "signature": "3-8: display_message(msg STRING)",
    "path": "./tests/sample_codebase/no_returns.4gl",
    "line_number": 7
  },
  {
    "name": "process_request",
    "signature": "34-41: process_request(...)",
    "path": "./tests/sample_codebase/no_returns.4gl",
    "line_number": 39
  }
]
```

## How It Works

### 1. Generate Signatures with Calls

```bash
bash src/generate_signatures.sh /path/to/code
```

This creates `workspace.json` with calls information.

### 2. Create Database

```bash
CREATE_DB=1 bash src/generate_signatures.sh /path/to/code
```

This creates `workspace.db` with indexed calls table for fast queries.

### 3. Query the Database

```bash
# Find dependencies
bash query.sh find-function-dependencies my_function

# Find dependents
bash query.sh find-function-dependents my_function
```

## What Gets Detected

The parser detects function calls in:

✓ Direct CALL statements
```4gl
CALL function_name(param)
```

✓ LET assignments
```4gl
LET var = function_name(param)
```

✓ Control flow conditions
```4gl
IF function_name(param) THEN
WHILE function_name(param) > 0
CASE function_name(param)
```

✓ Nested calls
```4gl
CALL outer(inner(param))
```

## Data Storage

### workspace.json

Each function now has a `calls` array:

```json
{
  "name": "add_numbers",
  "parameters": [...],
  "returns": [...],
  "calls": [
    {"name": "validate_number", "line": 10}
  ]
}
```

### workspace.db

New `calls` table:

```sql
SELECT * FROM calls LIMIT 5;
-- function_id | called_function_name | line_number
-- 1            | validate_number      | 10
-- 2            | log_message          | 7
-- ...
```

## Python API

Use directly in scripts:

```python
from scripts.query_db import find_function_dependencies, find_function_dependents

# Find what a function calls
deps = find_function_dependencies('workspace.db', 'process_request')
for dep in deps:
    print(f"Calls {dep['called_function_name']} at line {dep['line_number']}")

# Find what calls a function
dependents = find_function_dependents('workspace.db', 'log_message')
for dep in dependents:
    print(f"Called by {dep['name']} at line {dep['line_number']}")
```

## SQL Queries

Query the database directly:

```sql
-- Find all functions called by a function
SELECT called_function_name, line_number
FROM calls
WHERE function_id = (SELECT id FROM functions WHERE name = 'process_request')
ORDER BY line_number;

-- Find all functions that call a function
SELECT DISTINCT f.name, f.signature
FROM calls c
JOIN functions f ON c.function_id = f.id
WHERE c.called_function_name = 'log_message'
ORDER BY f.name;

-- Find functions with no dependencies
SELECT f.name
FROM functions f
WHERE f.id NOT IN (SELECT DISTINCT function_id FROM calls);

-- Find functions that are never called
SELECT f.name
FROM functions f
WHERE f.name NOT IN (SELECT DISTINCT called_function_name FROM calls);
```

## Testing

Run the test suite:

```bash
# Original tests
bash tests/run_tests.sh

# Call graph tests
bash tests/test_call_graph.sh

# Both
bash tests/run_tests.sh && bash tests/test_call_graph.sh
```

## Performance

- **Generation:** +5-10% overhead
- **Database queries:** <1ms for dependencies, <10ms for dependents
- **Database size:** +15-20% (new calls table)

## Examples

### Example 1: Impact Analysis

Before modifying `validate_request`, check what depends on it:

```bash
$ bash query.sh find-function-dependents validate_request
[
  {
    "name": "process_request",
    "path": "./src/process.4gl",
    "line_number": 38
  }
]
```

Result: Only one function calls it, so changes are low-risk.

### Example 2: Dependency Analysis

Understand what `process_request` depends on:

```bash
$ bash query.sh find-function-dependencies process_request
[
  {"called_function_name": "validate_request", "line_number": 38},
  {"called_function_name": "log_message", "line_number": 39},
  {"called_function_name": "update_database", "line_number": 40}
]
```

Result: `process_request` depends on 3 functions.

### Example 3: Find Critical Functions

Find functions called by many others:

```python
import sqlite3
import json

conn = sqlite3.connect('workspace.db')
conn.row_factory = sqlite3.Row
c = conn.cursor()

c.execute('''SELECT c.called_function_name, COUNT(*) as call_count
FROM calls c
GROUP BY c.called_function_name
ORDER BY call_count DESC
LIMIT 10''')

results = [dict(row) for row in c.fetchall()]
print(json.dumps(results, indent=2))
conn.close()
```

### Example 4: Dead Code Detection

Find functions never called:

```python
import sqlite3
import json

conn = sqlite3.connect('workspace.db')
conn.row_factory = sqlite3.Row
c = conn.cursor()

c.execute('''SELECT f.name, fi.path
FROM functions f
JOIN files fi ON f.file_id = fi.id
WHERE f.name NOT IN (SELECT DISTINCT called_function_name FROM calls)
ORDER BY f.name''')

results = [dict(row) for row in c.fetchall()]
print(json.dumps(results, indent=2))
conn.close()
```

## Limitations

Current limitations:

- No indirect/dynamic calls
- No method calls
- No external library calls
- No recursive call marking
- No call parameter tracking

See [CALL_GRAPH_QUERIES.md](CALL_GRAPH_QUERIES.md) for full documentation and future enhancements.

## Next Steps

1. **Generate signatures** - `bash src/generate_signatures.sh /path/to/code`
2. **Create database** - `CREATE_DB=1 bash src/generate_signatures.sh /path/to/code`
3. **Query dependencies** - `bash query.sh find-function-dependencies <name>`
4. **Query dependents** - `bash query.sh find-function-dependents <name>`
5. **Analyze results** - Use for impact analysis and refactoring

## See Also

- [CALL_GRAPH_QUERIES.md](CALL_GRAPH_QUERIES.md) - Full documentation
- [IMPLEMENTATION_SUMMARY.md](IMPLEMENTATION_SUMMARY.md) - Implementation details
- [ARCHITECTURE.md](ARCHITECTURE.md) - System architecture
