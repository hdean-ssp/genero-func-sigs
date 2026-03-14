# Quick Start - Type Resolution

## 5-Minute Setup

### Prerequisites

- Genero/4GL codebase with .4gl files
- Optional: .sch schema file for type resolution

### Automated Complete Workflow

The easiest way to generate everything:

```bash
# Generate schema, signatures, and resolve types all at once
bash src/generate_all.sh /path/to/codebase
```

This creates:
- `schema.json` - Parsed database schema
- `workspace.db` - Schema database
- `workspace.json` - Function signatures with LIKE references
- `workspace_resolved.json` - Same signatures with resolved types

### Manual Step-by-Step

If you prefer to run steps individually:

```bash
# Step 1: Parse schema
python3 scripts/parse_schema.py database.sch schema.json

# Step 2: Load schema into database
python3 scripts/json_to_sqlite_schema.py schema.json workspace.db

# Step 3: Generate signatures
bash src/generate_signatures.sh /path/to/codebase

# Step 4: Resolve LIKE types
RESOLVE_TYPES=1 bash src/generate_signatures.sh /path/to/codebase
```

### Signatures Only (No Schema)

If you don't have a schema file:

```bash
bash src/generate_signatures.sh /path/to/codebase
```

This creates:
- `workspace.json` - Function signatures with LIKE references (unresolved)

### Verify Resolution

```bash
# Check a resolved function
python3 -c "
import json
with open('workspace_resolved.json') as f:
    data = json.load(f)
    for file_path, functions in data.items():
        if file_path != '_metadata':
            for func in functions[:1]:  # First function
                print(json.dumps(func, indent=2))
                break
"
```

## Common Tasks

### Resolve a Single LIKE Reference

```python
from scripts.resolve_types import TypeResolver

resolver = TypeResolver('workspace.db')
result = resolver.resolve_like_reference('LIKE account.*')
print(result)
# Output: {'table': 'account', 'columns': [...], 'types': [...], 'resolved': True}
resolver.close()
```

### Check Resolution Status

```python
from scripts.resolve_types import TypeResolver

resolver = TypeResolver('workspace.db')

# Resolved successfully
result = resolver.resolve_like_reference('LIKE account.*')
print(f"Resolved: {result['resolved']}")  # True

# Unresolved - missing table
result = resolver.resolve_like_reference('LIKE nonexistent.*')
print(f"Resolved: {result['resolved']}")  # False
print(f"Error: {result['error']}")  # "Table not found: nonexistent"

resolver.close()
```

### Process Entire Workspace

```python
from scripts.resolve_types import TypeResolver

resolver = TypeResolver('workspace.db')
workspace = resolver.process_workspace_json('workspace.json')

# Save resolved workspace
import json
with open('workspace_resolved.json', 'w') as f:
    json.dump(workspace, f, indent=2)

resolver.close()
```

## Understanding Output

### Resolved Parameter

```json
{
  "name": "acc",
  "type": "LIKE account.*",
  "is_like_reference": true,
  "resolved": true,
  "table": "account",
  "columns": ["id", "name", "balance"],
  "types": ["INTEGER", "VARCHAR(100)", "DECIMAL(10,2)"]
}
```

### Unresolved Parameter

```json
{
  "name": "rec",
  "type": "LIKE nonexistent.*",
  "is_like_reference": true,
  "resolved": false,
  "error": "Table not found: nonexistent"
}
```

### Non-LIKE Parameter

```json
{
  "name": "id",
  "type": "INTEGER",
  "is_like_reference": false,
  "resolved": true
}
```

## Troubleshooting

### "Table not found" Error

**Problem**: LIKE references show "Table not found"

**Solution**: Load schema into workspace.db:
```bash
python3 scripts/json_to_sqlite_schema.py schema.json workspace.db
```

### workspace_resolved.json Not Created

**Problem**: Only workspace.json is created, no resolved version

**Solution**: Set RESOLVE_TYPES environment variable:
```bash
RESOLVE_TYPES=1 bash src/generate_signatures.sh /path/to/codebase
```

### Performance Issues

**Problem**: Type resolution is slow

**Solution**: Ensure schema is indexed:
```python
import sqlite3

conn = sqlite3.connect('workspace.db')
c = conn.cursor()

c.execute('CREATE INDEX IF NOT EXISTS idx_schema_tables_name ON schema_tables(name)')
c.execute('CREATE INDEX IF NOT EXISTS idx_schema_columns_table_id ON schema_columns(table_id)')

conn.commit()
conn.close()
print("Indexes created successfully")
```

## Next Steps

- Read [TYPE_RESOLUTION_GUIDE.md](TYPE_RESOLUTION_GUIDE.md) for detailed documentation
- Read [SCHEMA_PARSING_GUIDE.md](SCHEMA_PARSING_GUIDE.md) for schema setup
- Check [PHASE_1C_COMPLETION.md](../.kiro/specs/PHASE_1C_COMPLETION.md) for implementation details
