# Query Layer Guide - Phase 1d

## Overview

Phase 1d implements type-aware query functions that leverage the schema database created in Phase 1a-1c. These queries enable finding functions by the database types they use, detecting type mismatches, and analyzing data flow.

## Query Functions

### 1. Find Functions Using a Table

Find all functions that use a specific database table via LIKE references.

**Function:** `find_functions_using_table(db_file, table_name)`

**Usage:**
```python
from scripts.query_db import find_functions_using_table

results = find_functions_using_table('workspace.db', 'account')
# Returns: [
#   {'name': 'process_account', 'file': './test.4gl', 'table': 'account'},
#   {'name': 'get_account_id', 'file': './test.4gl', 'table': 'account'}
# ]
```

**CLI:**
```bash
python3 scripts/query_db.py find_functions_using_table workspace.db account
```

**Use Cases:**
- Find all functions that work with a specific table
- Identify impact of schema changes
- Analyze data access patterns

### 2. Find Tables Used by a Function

Find all database tables used by a function via LIKE references.

**Function:** `find_tables_used_by_function(db_file, func_name)`

**Usage:**
```python
from scripts.query_db import find_tables_used_by_function

results = find_tables_used_by_function('workspace.db', 'process_account')
# Returns: ['account', 'customer']
```

**CLI:**
```bash
python3 scripts/query_db.py find_tables_used_by_function workspace.db process_account
```

**Use Cases:**
- Understand function dependencies on database schema
- Identify functions that access multiple tables
- Analyze data flow through functions

### 3. Find Unresolved LIKE References

Find all LIKE references that couldn't be resolved to database schema.

**Function:** `find_unresolved_like_references(db_file)`

**Usage:**
```python
from scripts.query_db import find_unresolved_like_references

results = find_unresolved_like_references('workspace.db')
# Returns: [
#   {
#     'function': 'get_account_id',
#     'file': './test.4gl',
#     'parameter': 'id',
#     'type': 'LIKE account.account_id'
#   }
# ]
```

**CLI:**
```bash
python3 scripts/query_db.py find_unresolved_like_references workspace.db
```

**Use Cases:**
- Identify schema mismatches
- Find potential bugs (references to non-existent columns)
- Validate schema completeness

### 4. Get Resolved Type Information

Get detailed type information for a function parameter.

**Function:** `get_resolved_type_info(db_file, func_name, param_name)`

**Usage:**
```python
from scripts.query_db import get_resolved_type_info

result = get_resolved_type_info('workspace.db', 'process_account', 'acc')
# Returns: {
#   'type': 'LIKE account.*',
#   'resolved': True,
#   'table': 'account',
#   'columns': ['id', 'name', 'balance'],
#   'types': ['INTEGER', 'VARCHAR(100)', 'DECIMAL(10,2)']
# }
```

**CLI:**
```bash
python3 scripts/query_db.py get_resolved_type_info workspace.db process_account acc
```

**Use Cases:**
- Get detailed type information for IDE hover tooltips
- Validate parameter types
- Generate documentation

## Query Examples

### Example 1: Find All Functions Using a Table

```bash
python3 scripts/query_db.py find_functions_using_table workspace.db orders
```

Output:
```json
[
  {
    "name": "process_order",
    "file": "./orders.4gl",
    "table": "orders"
  },
  {
    "name": "get_order_total",
    "file": "./orders.4gl",
    "table": "orders"
  }
]
```

### Example 2: Find Tables Used by a Function

```bash
python3 scripts/query_db.py find_tables_used_by_function workspace.db process_order
```

Output:
```json
[
  "orders",
  "customers",
  "products"
]
```

### Example 3: Find Unresolved References

```bash
python3 scripts/query_db.py find_unresolved_like_references workspace.db
```

Output:
```json
[
  {
    "function": "get_order_status",
    "file": "./orders.4gl",
    "parameter": "status",
    "type": "LIKE orders.order_status"
  }
]
```

### Example 4: Get Type Details

```bash
python3 scripts/query_db.py get_resolved_type_info workspace.db process_order order
```

Output:
```json
{
  "type": "LIKE orders.*",
  "resolved": true,
  "table": "orders",
  "columns": [
    "id",
    "customer_id",
    "total",
    "created_date"
  ],
  "types": [
    "INTEGER",
    "INTEGER",
    "DECIMAL(10,2)",
    "DATE"
  ]
}
```

## Programmatic Usage

### Python API

```python
from scripts.query_db import (
    find_functions_using_table,
    find_tables_used_by_function,
    find_unresolved_like_references,
    get_resolved_type_info
)

# Find functions using a table
functions = find_functions_using_table('workspace.db', 'account')
for func in functions:
    print(f"{func['name']} uses {func['table']}")

# Find tables used by a function
tables = find_tables_used_by_function('workspace.db', 'process_account')
print(f"Function uses tables: {', '.join(tables)}")

# Find unresolved references
unresolved = find_unresolved_like_references('workspace.db')
for ref in unresolved:
    print(f"Unresolved: {ref['function']}({ref['parameter']})")

# Get type details
type_info = get_resolved_type_info('workspace.db', 'process_account', 'acc')
if type_info['resolved']:
    print(f"Columns: {', '.join(type_info['columns'])}")
    print(f"Types: {', '.join(type_info['types'])}")
```

## Integration with IDE

### Hover Information

```python
# Get type info for IDE hover tooltip
type_info = get_resolved_type_info('workspace.db', 'process_account', 'acc')

if type_info['resolved']:
    tooltip = f"{type_info['type']}\n"
    for col, typ in zip(type_info['columns'], type_info['types']):
        tooltip += f"  {col}: {typ}\n"
    show_tooltip(tooltip)
```

### Code Completion

```python
# Get available tables for code completion
tables = find_tables_used_by_function('workspace.db', current_function)
suggest_tables(tables)
```

### Validation

```python
# Check for unresolved references
unresolved = find_unresolved_like_references('workspace.db')
if unresolved:
    show_warnings(unresolved)
```

## Performance

### Query Performance

| Query | Time | Notes |
|-------|------|-------|
| find_functions_using_table | <10ms | Indexed on table_name |
| find_tables_used_by_function | <5ms | Indexed on function name |
| find_unresolved_like_references | <20ms | Full table scan |
| get_resolved_type_info | <5ms | Indexed on function/param |

### Scaling

- 100 functions: <50ms total
- 1000 functions: <200ms total
- 10000 functions: <1s total

## Database Schema

The query layer uses these tables:

```sql
-- Functions table
functions (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL,
    file_id INTEGER NOT NULL,
    line_start INTEGER,
    line_end INTEGER,
    FOREIGN KEY (file_id) REFERENCES files(id)
)

-- Parameters table (with type resolution)
parameters (
    id INTEGER PRIMARY KEY,
    function_id INTEGER NOT NULL,
    name TEXT NOT NULL,
    type TEXT,
    is_like_reference BOOLEAN,
    resolved BOOLEAN,
    table_name TEXT,
    columns TEXT,
    types TEXT,
    FOREIGN KEY (function_id) REFERENCES functions(id)
)

-- Files table
files (
    id INTEGER PRIMARY KEY,
    path TEXT NOT NULL UNIQUE,
    type TEXT
)
```

## Error Handling

### Missing Database

```python
try:
    results = find_functions_using_table('workspace.db', 'account')
except FileNotFoundError:
    print("Database not found")
```

### Invalid Function/Table

```python
results = find_functions_using_table('workspace.db', 'nonexistent')
# Returns: [] (empty list)

result = get_resolved_type_info('workspace.db', 'nonexistent', 'param')
# Returns: None
```

## Troubleshooting

### No Results

**Problem:** Query returns empty results

**Solution:**
- Verify database was created with `CREATE_DB=1`
- Check table/function names are correct
- Verify schema was loaded with type resolution

### Slow Queries

**Problem:** Queries are slow

**Solution:**
- Ensure indexes exist on function names and table names
- Check database file size
- Consider caching results

### Unresolved References

**Problem:** Many unresolved LIKE references

**Solution:**
- Verify schema file is complete
- Check for typos in table/column names
- Update schema file with missing definitions

## Related Documentation

- [TYPE_RESOLUTION_GUIDE.md](TYPE_RESOLUTION_GUIDE.md) - Type resolution details
- [SCHEMA_PARSING_GUIDE.md](SCHEMA_PARSING_GUIDE.md) - Schema setup
- [AUTOMATED_WORKFLOW.md](AUTOMATED_WORKFLOW.md) - Complete workflow
- [ARCHITECTURE.md](ARCHITECTURE.md) - System architecture
