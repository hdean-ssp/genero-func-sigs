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

### 4. Metrics Extraction (`scripts/metrics_extractor.py`)

**Purpose:** Extract code quality metrics from function signatures

**Metrics Extracted:**
1. Lines of Code (LOC) - Function body line count
2. Cyclomatic Complexity - Decision point count
3. Variable Count - Local variable declarations
4. Parameter Count - Function parameters
5. Return Count - Return value count
6. Call Depth - Maximum nesting depth of function calls

**Process:**
1. Parse function signatures and bodies
2. Analyze control flow structures
3. Count variables and parameters
4. Calculate complexity metrics
5. Output metrics JSON

**Output:** Metrics data for each function
- Integrated with workspace.json
- Stored in metrics database

**Key Features:**
- Accurate complexity calculation
- Handles nested structures
- Efficient processing
- Extensible metric framework

### 5. Incremental Generator (`scripts/incremental_generator.py`)

**Purpose:** Efficiently update metrics for changed files

**Process:**
1. Track file modification times
2. Identify changed files since last run
3. Re-extract metrics only for changed files
4. Merge with existing metrics database
5. Update indexes

**Output:** Updated metrics database
- Only changed files processed
- Existing data preserved
- Efficient incremental updates

**Key Features:**
- File-level and function-level updates
- Preserves unchanged data
- Fast incremental processing
- Suitable for CI/CD pipelines

### 6. Quality Analyzer (`scripts/quality_analyzer.py`)

**Purpose:** Query and analyze code quality metrics

**Query Methods:**
1. `get_function_metrics()` - Retrieve metrics for a function
2. `find_complex_functions()` - Find functions above complexity threshold
3. `find_long_functions()` - Find functions exceeding LOC threshold
4. `find_high_parameter_functions()` - Find functions with many parameters
5. `get_file_metrics()` - Aggregate metrics for a file

**Process:**
1. Query metrics database
2. Apply filters and thresholds
3. Return results with analysis
4. Support sorting and ranking

**Output:** Query results in JSON format
- Function-level metrics
- File-level aggregates
- Ranked by complexity/size

**Key Features:**
- Fast indexed queries
- Flexible filtering
- Extensible query framework
- Integration with code review tools

### 7. Database Tools

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

### 8. Test Utilities (`scripts/test_utils.py`)

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

### IDE/Editor Integration

**Vim Plugin:**
- Query API for function lookup and navigation
- Metrics for complexity highlighting
- Call graph for dependency visualization
- Example: `:VimFunctionLookup my_function` shows full context

**VS Code Extension:**
- Code lens showing function complexity and call count
- Hover information with full signature and dependencies
- Quick navigation to function definitions
- Autocompletion context with parameter types

**Other Editors:**
- Query the SQLite database directly
- Use Python API for programmatic access
- JSON output for easy integration

### AI-Powered Code Review

**New Function Review:**
- Get full function context (signature, metrics, dependencies)
- Find similar functions for pattern matching
- Check for unresolved calls and type mismatches
- Prioritize review based on complexity metrics

**Impact Analysis:**
- Understand what breaks when you modify a function
- See all direct and transitive dependents
- Identify affected modules
- Track code ownership and expertise

**Code Quality Checks:**
- Detect dead code (unused functions)
- Find unresolved calls (calls to non-existent functions)
- Identify type mismatches
- Flag overly complex functions

### Build Systems

- Can be integrated into build pipelines
- Generates artifacts for documentation
- Enables dependency analysis
- Fails build on critical issues (unresolved calls)

### Documentation Tools

- Module-specific API docs
- Dependency graphs
- Call graphs
- Architecture diagrams

### Analysis Tools

- Impact analysis before refactoring
- Dead code detection
- Code quality metrics
- Codebase understanding

## Future Enhancements

### Phase 3 (Next - Advanced Analysis)
- Circular dependency detection - Find problematic call cycles
- Code duplication analysis - Identify similar/duplicate functions
- Performance metrics - Track function complexity over time
- Visualization exports - Generate architecture diagrams

See [QUERY_LAYER_GUIDE.md](QUERY_LAYER_GUIDE.md) for Phase 2 implementation details.

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

# Query database using Python
python3 -c "import sqlite3; conn=sqlite3.connect('workspace.db'); c=conn.cursor(); c.execute('SELECT * FROM functions LIMIT 10'); print([dict(row) for row in c.fetchall()])"
```

### Performance Optimization

- Use SQLite for large codebases (>10MB JSON)
- Consider incremental updates for CI/CD
- Profile with `time` command
- Monitor memory usage with `top`
