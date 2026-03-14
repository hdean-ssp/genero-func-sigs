# Querying Large Codebase Files

The generated JSON files can be quite large (15-20MB+). For efficient searching and indexing, this project includes SQLite database tools.

## Quick Start

### 1. Create Databases

Convert your JSON files to SQLite databases (one-time setup):

```bash
bash query.sh create-dbs
```

This creates:
- `workspace.db` - Function signatures (from workspace.json)
- `modules.db` - Module dependencies (from modules.json)

**Size comparison:**
- JSON files: ~15-20MB total
- SQLite databases: ~70KB total (100x smaller!)
- Queries: Instant (indexed)

### 2. Query Functions

Find a specific function:
```bash
bash query.sh find-function "my_function"
```

Search for functions by pattern:
```bash
bash query.sh search-functions "get_*"
bash query.sh search-functions "*init*"
```

List all functions in a file:
```bash
bash query.sh list-file-functions "path/to/file.4gl"
```

### 3. Query Modules

Find a module:
```bash
bash query.sh find-module "core"
```

Search modules by pattern:
```bash
bash query.sh search-modules "*util*"
```

Find which modules use a specific file:
```bash
bash query.sh list-file-modules "util.4gl"
```

## Output Format

All queries return JSON for easy parsing:

```bash
# Get function details
bash query.sh find-function "my_func" | jq '.[] | {name, signature, parameters}'

# Count search results
bash query.sh search-functions "get_" | jq 'length'

# Extract file paths
bash query.sh search-functions "init" | jq '.[].path'
```

## Direct Python Usage

For programmatic access:

```python
from scripts.query_db import query_function, search_functions

# Find exact function
results = query_function('workspace.db', 'my_function')

# Search by pattern
results = search_functions('workspace.db', 'get_*')
```

## Database Schema

### workspace.db (Signatures)

```
files
  ├─ id (PRIMARY KEY)
  ├─ path (UNIQUE)
  └─ type (L4GLS, U4GLS, 4GLS)

functions
  ├─ id (PRIMARY KEY)
  ├─ file_id (FOREIGN KEY)
  ├─ name (INDEXED)
  ├─ line_start
  ├─ line_end
  └─ signature

parameters
  ├─ id (PRIMARY KEY)
  ├─ function_id (FOREIGN KEY)
  ├─ name
  └─ type

returns
  ├─ id (PRIMARY KEY)
  ├─ function_id (FOREIGN KEY)
  ├─ name
  └─ type
```

### modules.db (Dependencies)

```
modules
  ├─ id (PRIMARY KEY)
  ├─ name (UNIQUE, INDEXED)
  └─ file

module_files
  ├─ id (PRIMARY KEY)
  ├─ module_id (FOREIGN KEY, INDEXED)
  ├─ file_name
  └─ category (L4GLS, U4GLS, 4GLS, INDEXED)
```

## Performance

- **Database creation**: ~1-2 seconds
- **Exact function lookup**: <1ms
- **Pattern search**: <10ms
- **Module lookup**: <1ms

## Regenerating Databases

If you regenerate the JSON files, recreate the databases:

```bash
bash generate_signatures.sh /path/to/codebase
bash generate_modules.sh /path/to/codebase
bash query.sh create-dbs
```

Or individually:
```bash
bash query.sh create-signatures-db
bash query.sh create-modules-db
```

## Advanced Queries

For complex queries, use Python with sqlite3:

```python
import sqlite3
import json

# Find all functions with STRING parameters
conn = sqlite3.connect('workspace.db')
conn.row_factory = sqlite3.Row
c = conn.cursor()
c.execute('''SELECT DISTINCT f.name FROM functions f 
  JOIN parameters p ON f.id = p.function_id 
  WHERE p.type = 'STRING' ''')
results = [dict(row) for row in c.fetchall()]
print(json.dumps(results, indent=2))
conn.close()

# Find modules with most files
conn = sqlite3.connect('modules.db')
conn.row_factory = sqlite3.Row
c = conn.cursor()
c.execute('''SELECT m.name, COUNT(*) as file_count FROM modules m 
  JOIN module_files mf ON m.id = mf.module_id 
  GROUP BY m.id ORDER BY file_count DESC LIMIT 10''')
results = [dict(row) for row in c.fetchall()]
print(json.dumps(results, indent=2))
conn.close()

# Find functions in specific file type
conn = sqlite3.connect('workspace.db')
conn.row_factory = sqlite3.Row
c = conn.cursor()
c.execute('''SELECT f.name, f.signature FROM functions f 
  JOIN files fi ON f.file_id = fi.id 
  WHERE fi.type = 'L4GLS' LIMIT 20''')
results = [dict(row) for row in c.fetchall()]
print(json.dumps(results, indent=2))
conn.close()
```

## Troubleshooting

**Database not found:**
```bash
bash query.sh create-dbs
```

**Stale database (after regenerating JSON):**
```bash
rm *.db
bash query.sh create-dbs
```

**Want to see raw database:**
```python
import sqlite3

# List all tables
conn = sqlite3.connect('workspace.db')
c = conn.cursor()
c.execute("SELECT name FROM sqlite_master WHERE type='table'")
tables = [row[0] for row in c.fetchall()]
print("Tables:", tables)

# Get database schema
c.execute(".schema")
conn.close()
```
