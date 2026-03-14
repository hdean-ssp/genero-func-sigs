# Quick Start: File Header Parsing

## Overview

The header parsing feature automatically extracts code references (e.g., PRB-299, EH100512) and author information from file headers in your Genero codebase.

## Generate Everything

To generate all artifacts including headers, databases, and indexes:

```bash
bash generate_all.sh /path/to/codebase
```

This will create:
- `workspace.json` - Function signatures with extracted headers
- `workspace.db` - SQLite database with signatures and header metadata
- `modules.json` - Module dependencies
- `modules.db` - SQLite database for module queries
- `codebase_index.json` - Unified codebase index

## Query Code References

### Find files modified for a specific reference

```bash
bash query.sh find-reference PRB-299
```

Output:
```json
[
  {
    "path": "./src/payment.4gl",
    "reference_id": "PRB-299",
    "author": "MartinB",
    "change_date": "2024-08-28",
    "description": "Enhanced MailMerge Error Handling"
  }
]
```

### Search references by pattern

```bash
bash query.sh search-references "EH%"
bash query.sh search-references "PRB-%"
bash query.sh search-references "SR-%"
```

## Query Authors

### Find files modified by an author

```bash
bash query.sh find-author "Rich"
```

### Show what areas an author has expertise in

```bash
bash query.sh author-expertise "Chilly"
```

Output:
```json
[
  {
    "path": "./src/messaging.4gl",
    "change_count": 3,
    "first_change": "2024-08-19",
    "last_change": "2024-09-19"
  }
]
```

## Query File Metadata

### Get all references for a file

```bash
bash query.sh file-references "./src/payment.4gl"
```

### Get all authors who modified a file

```bash
bash query.sh file-authors "./src/payment.4gl"
```

## Find Recent Changes

### Find files modified in the last 30 days

```bash
bash query.sh recent-changes
```

### Find files modified in the last 7 days

```bash
bash query.sh recent-changes 7
```

## Use Cases

### Code Review Assignment
Find who has expertise in a specific area:
```bash
bash query.sh author-expertise "John Smith"
```

### Impact Analysis
Before modifying a file, see who else has worked on it:
```bash
bash query.sh file-authors "./src/core.4gl"
```

### Audit Trail
Find all changes related to a specific ticket:
```bash
bash query.sh find-reference SR-40356-3
```

### Knowledge Management
Find all files an author has worked on:
```bash
bash query.sh find-author "MartinB"
```

## Header Format

The parser automatically detects and extracts from modification tables like:

```
#  Modifications:
# Ref        For                Date            Who                     Description
#EH100466-4      1410.05        20/03/2024  Rich                Initial
#PRB-299         1410.16        28/08/2024      MartinB         Enhanced MailMerge Error Handling
#SR-40356-3      1410.30        01/04/2025      Rich            Error email service
```

The parser:
- Detects column positions automatically (no hard-coded patterns)
- Handles variable spacing and alignment
- Supports any reference format
- Extracts author names and dates
- Handles multi-line descriptions

## Advanced Queries

### Using Python API directly

```python
from scripts.query_headers import find_files_by_reference, find_author_expertise

# Find files for a reference
files = find_files_by_reference('workspace.db', 'PRB-299')

# Find author expertise
expertise = find_author_expertise('workspace.db', 'Rich')
```

### Using Python with sqlite3

```python
import sqlite3
import json

# Find all references by an author
conn = sqlite3.connect('workspace.db')
conn.row_factory = sqlite3.Row
c = conn.cursor()

c.execute('''SELECT reference_id, change_date, description
FROM file_references
WHERE author = ?
ORDER BY change_date DESC''', ('Rich',))

results = [dict(row) for row in c.fetchall()]
print(json.dumps(results, indent=2))

# Find most active authors
c.execute('''SELECT author, COUNT(*) as change_count
FROM file_references
GROUP BY author
ORDER BY change_count DESC''')

results = [dict(row) for row in c.fetchall()]
print(json.dumps(results, indent=2))

# Find files with most changes
SELECT f.path, COUNT(*) as change_count
FROM file_references fr
JOIN files f ON fr.file_id = f.id
GROUP BY f.path
ORDER BY change_count DESC;
EOF
```

## See Also

- [HEADER_PARSING_IMPLEMENTATION.md](HEADER_PARSING_IMPLEMENTATION.md) - Full implementation details
- [QUERYING.md](QUERYING.md) - General querying guide
- [CALL_GRAPH_QUERIES.md](CALL_GRAPH_QUERIES.md) - Function dependency queries
