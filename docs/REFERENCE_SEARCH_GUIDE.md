# Reference Search Enhancement Guide

## Overview

The reference search functionality has been enhanced to ensure that all matching references are returned, including partial matches with suffixes. This allows you to search for references like "100512" and get all related references such as "EH100512", "EH100512-9a", "EH100512-15", etc.

## Search Modes

### 1. Partial Match Search (Recommended)

Search for any part of a reference ID. The system automatically adds wildcards to find all matches.

```bash
# Search for numeric part - returns all references containing "100512"
bash query.sh search-references "100512"
# Results: EH100512, EH100512-9a, EH100512-15, etc.

# Search for prefix - returns all references starting with "EH100512"
bash query.sh search-references "EH100512"
# Results: EH100512, EH100512-9a, EH100512-15, etc.

# Search for any part of reference
bash query.sh search-references "PRB-299"
# Results: PRB-299, PRB-299-alpha, etc.
```

### 2. Prefix Search

Explicitly search for references starting with a specific prefix.

```bash
# Find all references starting with "EH100512"
bash query.sh search-reference-prefix "EH100512"
# Results: EH100512, EH100512-9a, EH100512-15, etc.

# Find all references starting with "EH"
bash query.sh search-reference-prefix "EH"
# Results: All EH references
```

### 3. Wildcard Search

Use SQL LIKE wildcards for advanced pattern matching.

```bash
# Explicit wildcard - find all references starting with "EH100512"
bash query.sh search-references "EH100512%"

# Find references with specific pattern
bash query.sh search-references "EH%512%"
# Results: Any reference starting with "EH" and containing "512"

# Find references ending with specific suffix
bash query.sh search-references "%9a"
# Results: All references ending with "9a"
```

## Examples

### Example 1: Find all variants of a reference

```bash
# User wants to find all modifications related to ticket EH100512
bash query.sh search-references "100512"

# Output:
# [
#   {
#     "path": "./src/utils.4gl",
#     "reference_id": "EH100512",
#     "author": "John",
#     "change_date": "2024-09-19",
#     "description": "Use job_task_params"
#   },
#   {
#     "path": "./src/utils.4gl",
#     "reference_id": "EH100512-9a",
#     "author": "Chilly",
#     "change_date": "2024-09-19",
#     "description": "Use job_task_params for commshub"
#   },
#   {
#     "path": "./src/utils.4gl",
#     "reference_id": "EH100512-15",
#     "author": "Chris P",
#     "change_date": "2024-09-06",
#     "description": "Don't run SMS/Email if not active"
#   }
# ]
```

### Example 2: Find all references by a specific author for a ticket

```bash
# Find all files modified for reference EH100512
bash query.sh search-references "EH100512"

# Then filter by author or use find-author to see all changes by that author
bash query.sh find-author "Chilly"
```

### Example 3: Track all sub-versions of a reference

```bash
# Find all sub-versions of PRB-299
bash query.sh search-references "PRB-299"

# Results will include:
# - PRB-299 (base version)
# - PRB-299-alpha (alpha version)
# - PRB-299-beta (beta version, if exists)
# - etc.
```

## API Reference

### search_references(db_file, pattern)

Search for code references matching a pattern.

**Parameters:**
- `db_file`: Path to SQLite database
- `pattern`: Pattern to search for
  - Without wildcards: Treated as partial match (e.g., "100512" → "%100512%")
  - With wildcards: Used as-is (e.g., "EH100512%" → "EH100512%")

**Returns:** List of matching references with metadata

**Examples:**
```python
from scripts.query_headers import search_references

# Partial match
results = search_references("workspace.db", "100512")

# Wildcard match
results = search_references("workspace.db", "EH100512%")

# Explicit partial match
results = search_references("workspace.db", "%100512%")
```

### search_reference_prefix(db_file, prefix)

Search for code references starting with a specific prefix.

**Parameters:**
- `db_file`: Path to SQLite database
- `prefix`: Prefix to search for (e.g., "EH100512")

**Returns:** List of matching references with metadata

**Examples:**
```python
from scripts.query_headers import search_reference_prefix

# Find all references starting with "EH100512"
results = search_reference_prefix("workspace.db", "EH100512")

# Find all references starting with "EH"
results = search_reference_prefix("workspace.db", "EH")
```

## Shell Commands

### search-references

```bash
bash query.sh search-references <pattern>
```

Search for references matching a pattern. Automatically adds wildcards for partial matches.

**Examples:**
```bash
# Partial numeric search
bash query.sh search-references "100512"

# Partial prefix search
bash query.sh search-references "EH100512"

# Explicit wildcard search
bash query.sh search-references "EH100512%"
```

### search-reference-prefix

```bash
bash query.sh search-reference-prefix <prefix>
```

Search for references starting with a specific prefix.

**Examples:**
```bash
# Find all variants of EH100512
bash query.sh search-reference-prefix "EH100512"

# Find all EH references
bash query.sh search-reference-prefix "EH"
```

## Behavior

### Automatic Wildcard Addition

When you search without explicit wildcards, the system automatically adds wildcards:

- Input: `"100512"` → Query: `"%100512%"` (finds any reference containing "100512")
- Input: `"EH100512"` → Query: `"%EH100512%"` (finds any reference containing "EH100512")
- Input: `"EH100512%"` → Query: `"EH100512%"` (finds references starting with "EH100512")

### Result Ordering

Results are ordered by:
1. File path (alphabetically)
2. Change date (most recent first)

### Deduplication

Results are deduplicated by reference ID and file path to avoid duplicate entries.

## Troubleshooting

### No results returned

1. Check that the reference exists in the database
2. Try a shorter search pattern (e.g., "100512" instead of "EH100512-9a")
3. Verify the database has been created with `bash query.sh create-dbs`

### Too many results

1. Use a more specific pattern (e.g., "EH100512" instead of "100512")
2. Use explicit wildcards (e.g., "EH100512%" instead of "100512")
3. Filter results by author using `bash query.sh find-author <author>`

### Case sensitivity

Searches are case-insensitive by default (SQL LIKE behavior).

## Related Commands

- `find-reference <ref>` - Find files modified for an exact reference
- `find-author <author>` - Find files modified by an author
- `file-references <path>` - Get all references for a specific file
- `author-expertise <author>` - Show what areas an author has expertise in
