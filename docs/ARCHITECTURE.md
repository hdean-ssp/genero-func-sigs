# Architecture Overview

This document describes the architecture and design of the Genero Function Signatures project.

## Project Goals

1. Extract function signatures from Genero/4GL codebases
2. Parse module dependencies from .m3 makefiles
3. Generate unified codebase index for analysis
4. Provide efficient querying of large codebases
5. Enable integration with development tools

## Components

### 1. Signature Generation (`generate_signatures.sh`)

**Purpose:** Extract function signatures from .4gl files

**Process:**
1. Find all `.4gl` files in target directory
2. Use `sed` to clean non-printable characters
3. Use `awk` to parse function definitions:
   - Extract function name, parameters, return values
   - Track line numbers (start/end)
   - Build parameter and return type arrays
4. Output JSON lines (one function per line)
5. Use Python to group by file and format as JSON

**Output:** `workspace.json`
- Grouped by file path
- Contains function metadata (name, signature, parameters, returns)
- Includes generation metadata

**Key Features:**
- Handles multi-line function definitions
- Supports all Genero data types
- Tracks line numbers for IDE integration
- Robust error handling

### 2. Module Generation (`generate_modules.sh`)

**Purpose:** Parse .m3 makefiles and extract file dependencies

**Process:**
1. Find all `.m3` files in target directory
2. Use `awk` to parse module definitions:
   - Extract L4GLS (library files)
   - Extract U4GLS (utility files)
   - Extract 4GLS (module files)
   - Handle multi-line continuations (backslash)
   - Filter to only .4gl files
3. Output JSON lines (one module per line)
4. Use Python to format as JSON with metadata

**Output:** `modules.json`
- Array of module objects
- Each module contains file lists by category
- Includes generation metadata

**Key Features:**
- Handles multi-line variable assignments
- Filters non-.4gl files
- Preserves file order
- Robust whitespace handling

### 3. Codebase Index (`generate_codebase_index.sh`)

**Purpose:** Merge signatures and modules into unified index

**Process:**
1. Read `workspace.json` (function signatures)
2. Read `modules.json` (module dependencies)
3. Create file index with descriptive IDs
4. Map module file references to file IDs
5. Output unified index

**Output:** `codebase_index.json`
- Deduplicated file index with IDs
- Module definitions with file ID references
- Combined metadata from both sources

**Key Features:**
- No data duplication
- Efficient file ID references
- Enables module-scoped queries
- Supports dependency analysis

### 4. Database Tools

#### `scripts/json_to_sqlite.py`

**Purpose:** Convert JSON files to SQLite databases for efficient querying

**Features:**
- Creates indexed tables for fast lookups
- Supports both signatures and modules
- Normalizes data for efficient storage
- Creates appropriate indexes

**Databases:**
- `workspace.db` - Function signatures with indexes on name and file
- `modules.db` - Module dependencies with indexes on name and category

#### `scripts/query_db.py`

**Purpose:** Query SQLite databases with convenient commands

**Commands:**
- `find_function` - Exact function lookup
- `search_functions` - Pattern-based search
- `list_file_functions` - Functions in a file
- `find_module` - Exact module lookup
- `search_modules` - Pattern-based module search
- `list_file_modules` - Modules using a file

**Output:** JSON for easy parsing and integration

#### `query.sh`

**Purpose:** User-friendly shell wrapper for database queries

**Usage:**
```bash
bash query.sh find-function "my_func"
bash query.sh search-functions "get_*"
bash query.sh find-module "core"
```

### 5. Test Utilities (`scripts/test_utils.py`)

**Purpose:** Provide utilities for testing and validation

**Functions:**
- `sort_signatures()` - Sort JSON for comparison
- `sort_modules()` - Sort modules JSON
- `check_metadata()` - Validate metadata structure
- `check_signatures_format()` - Validate signature format
- `count_functions()` - Count total functions
- `count_modules()` - Count total modules
- `get_module()` - Retrieve specific module

**Usage:** Called by test scripts for validation

## Data Flow

```
Genero Codebase
    ↓
generate_signatures.sh → workspace.json
    ↓
generate_modules.sh → modules.json
    ↓
generate_codebase_index.sh → codebase_index.json
    ↓
json_to_sqlite.py → workspace.db, modules.db
    ↓
query.sh / query_db.py → Query Results (JSON)
```

## File Formats

### workspace.json

```json
{
  "_metadata": {
    "version": "1.0.0",
    "generated": "2026-03-12T...",
    "files_processed": N
  },
  "path/to/file.4gl": [
    {
      "name": "function_name",
      "line": {"start": 10, "end": 25},
      "signature": "10-25: function_name(param TYPE):return TYPE",
      "parameters": [{"name": "param", "type": "TYPE"}],
      "returns": [{"name": "return", "type": "TYPE"}]
    }
  ]
}
```

### modules.json

```json
{
  "_metadata": {
    "version": "1.0.0",
    "generated": "2026-03-12T...",
    "files_processed": N
  },
  "modules": [
    {
      "file": "path/to/module.m3",
      "module": "module_name",
      "L4GLS": ["lib1.4gl", "lib2.4gl"],
      "U4GLS": ["util1.4gl"],
      "4GLS": ["main.4gl"]
    }
  ]
}
```

### codebase_index.json

```json
{
  "_metadata": {...},
  "files": {
    "file_lib_core": {
      "path": "path/to/lib_core.4gl",
      "type": "L4GLS",
      "functions": [...]
    }
  },
  "modules": [
    {
      "module": "core",
      "file": "path/to/core.m3",
      "L4GLS": ["file_lib_core"],
      "U4GLS": ["file_util"],
      "4GLS": ["file_main"]
    }
  ]
}
```

## Database Schema

### workspace.db

```
files (id, path, type)
  ↓
functions (id, file_id, name, line_start, line_end, signature)
  ├─ parameters (id, function_id, name, type)
  └─ returns (id, function_id, name, type)
```

### modules.db

```
modules (id, name, file)
  ↓
module_files (id, module_id, file_name, category)
```

## Performance Characteristics

| Operation | JSON | SQLite |
|-----------|------|--------|
| File size | 15-20MB | 70KB |
| Load time | 2-5s | <100ms |
| Exact lookup | 2-5s | <1ms |
| Pattern search | 2-5s | <10ms |
| Memory usage | 100-200MB | <10MB |

## Design Decisions

### 1. Python for JSON Processing

**Why:** 
- Built-in on most systems
- No external dependencies (no jq needed)
- Better error handling
- Easier to maintain

### 2. Separate Python Scripts

**Why:**
- Avoids heredoc formatting issues
- Easier to test and debug
- Reusable components
- Better code organization

### 3. SQLite for Querying

**Why:**
- Built-in on most systems
- Efficient indexing
- Fast queries
- Low memory footprint
- No server needed

### 4. File ID References

**Why:**
- Avoids data duplication
- Efficient storage
- Readable (e.g., `file_lib_core`)
- Enables efficient queries

### 5. Metadata Tracking

**Why:**
- Enables validation
- Tracks data lineage
- Supports incremental updates
- Useful for debugging

## Testing Strategy

### Unit Tests

- `run_tests.sh` - Tests signature generation
- `run_module_tests.sh` - Tests module generation

### Test Coverage

- Simple and complex data types
- Multi-line continuations
- Whitespace variations
- Edge cases
- Metadata validation
- JSON format validation

### Test Data

- 7 .4gl files with 23 functions
- 9 .m3 files with various scenarios
- Expected output files for comparison

## Integration Points

### IDE Integration

- Line numbers enable editor navigation
- Function signatures for code completion
- Module context for scoped searches

### Build Systems

- Can be integrated into build pipelines
- Generates artifacts for documentation
- Enables dependency analysis

### Documentation Tools

- Module-specific API docs
- Dependency graphs
- Call graphs

### Analysis Tools

- Impact analysis
- Refactoring support
- Code quality metrics

## Future Enhancements

1. **Call Resolution** - Map called function names to actual functions
2. **Recursive Call Detection** - Identify and mark recursive calls
3. **Enhanced Type Parser** - Support LIKE types and records
4. **Database Schema Integration** - Parse and validate against schema
5. **Advanced Queries** - Circular dependency detection, dead code analysis
6. **IDE Plugins** - Direct integration with editors
7. **Web Interface** - Browser-based code explorer
8. **Performance Metrics** - Track function complexity
9. **Change Tracking** - Version control integration
10. **Advanced Queries** - Fuzzy matching, dependency analysis, etc.

See [FUTURE_ENHANCEMENTS.md](FUTURE_ENHANCEMENTS.md) for detailed roadmap.

## Maintenance

### Adding New Features

1. Add parsing logic to appropriate shell script
2. Update Python processing scripts if needed
3. Add test cases to `tests/sample_codebase/`
4. Update documentation
5. Run full test suite

### Debugging

```bash
# Enable verbose output
VERBOSE=1 bash generate_signatures.sh /path/to/code

# Check intermediate files
cat workspace.json | python3 -m json.tool | head -50

# Query database directly
sqlite3 workspace.db "SELECT * FROM functions LIMIT 10"
```

### Performance Optimization

- Use SQLite for large codebases (>10MB JSON)
- Consider incremental updates for CI/CD
- Profile with `time` command
- Monitor memory usage with `top`
