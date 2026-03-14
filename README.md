# genero-tools
Comprehensive codebase analysis tool that extracts and indexes rich metadata from Genero/4GL codebases to enable IDE/editor integration, AI-powered code review, and developer tooling.

## Features

- **Extracts function signatures** - Names, parameters, return types, line numbers
- **Builds call graphs** - Tracks which functions call which other functions
- **Parses file headers** - Extracts code references and author information for impact analysis
- **Generates structured metadata** - JSON and SQLite databases for fast querying
- **Supports all Genero data types** - Basic, complex, and special types
- **Handles multiple return values** - Full signature capture
- **Tracks line numbers** - For IDE integration and navigation
- **Configurable and robust** - Environment variables, error handling, automatic cleanup

## Requirements

- Bash shell
- Python 3.6+ (for JSON processing and database tools)
- Standard Unix utilities: `find`, `sed`, `awk`, `date`

No external dependencies like `jq` needed - everything uses built-in Python.

## Usage

### Generate Signatures

Run the script against your Genero/4GL codebase:

```bash
# Run against current directory (default)
bash generate_signatures.sh

# Run against a specific directory
bash generate_signatures.sh /path/to/genero/code

# Run against a single file
bash generate_signatures.sh path/to/file.4gl

# Enable verbose output
VERBOSE=1 bash generate_signatures.sh /path/to/code

# Specify custom output file
OUTPUT_FILE=my_signatures.json bash generate_signatures.sh /path/to/code
```

The script will generate a `workspace.json` file (or custom filename) containing function signatures for all `.4gl` files found.

### Output Format

The script generates a `workspace.json` file with structured function data grouped by file:

Example:
```json
{
  "_metadata": {
    "version": "1.0.0",
    "generated": "2026-03-11T23:51:33Z",
    "files_processed": 3
  },
  "./src/utils.4gl": [
    {
      "name": "calculate",
      "line": {"start": 15, "end": 42},
      "signature": "15-42: calculate(amount INTEGER, label STRING):result DECIMAL, status INTEGER",
      "parameters": [
        {"name": "amount", "type": "INTEGER"},
        {"name": "label", "type": "STRING"}
      ],
      "returns": [
        {"name": "result", "type": "DECIMAL"},
        {"name": "status", "type": "INTEGER"}
      ],
      "calls": [
        {"name": "validate_amount", "line": 20},
        {"name": "calculate_tax", "line": 32}
      ]
    }
  ]
}
```

The output includes:
- `_metadata`: Generation information (version, timestamp, file count)
- Each function entry includes:
  - `name`: Function name for direct lookup
  - `line`: Start and end line numbers
  - `signature`: Human-readable signature string with line numbers
  - `parameters`: Array of parameter objects with name and type
  - `returns`: Array of return value objects with name and type
  - `calls`: Array of function calls with name and line number (NEW)

## Testing

Run the test suite to verify the script works correctly:

```bash
bash run_tests.sh
```

The test suite includes 5 comprehensive tests:
- Test 1: Validates output against expected results from test files
- Test 2: Verifies single file processing
- Test 3: Checks signature format validity
- Test 4: Verifies function count accuracy
- Test 5: Validates metadata structure

### Test Coverage

The test suite includes 7 test files with 23 functions covering:
- `simple_functions.4gl` (3 functions) - Basic parameter and return types
- `complex_types.4gl` (2 functions) - RECORD, DATE, ARRAY types
- `multiple_returns.4gl` (2 functions) - Functions returning multiple values
- `edge_cases.4gl` (4 functions) - Long parameters, inline returns, mixed case
- `whitespace_variations.4gl` (3 functions) - Various spacing patterns
- `special_types.4gl` (5 functions) - INTERVAL, TEXT, MONEY, SERIAL, BOOLEAN, DYNAMIC ARRAY
- `no_returns.4gl` (4 functions) - Procedure-style functions without returns

## Configuration

The script supports environment variables for customization:

- `VERBOSE`: Set to `1` to enable progress output (default: `0`)
- `OUTPUT_FILE`: Specify output filename (default: `workspace.json`)

Example:
```bash
VERBOSE=1 OUTPUT_FILE=signatures.json bash generate_signatures.sh ./src
```

## Querying Large Files

For large codebases, the JSON files can be 15-20MB+. Use the SQLite database tools for efficient searching:

```bash
# Create indexed databases (one-time setup)
bash query.sh create-dbs

# Find a function
bash query.sh find-function "my_function"

# Search functions by pattern
bash query.sh search-functions "get_*"

# List functions in a file
bash query.sh list-file-functions "path/to/file.4gl"
```

**Benefits:**
- Fast indexed queries (<1ms for exact lookups)
- Fully indexed for fast pattern matching
- Efficient storage with proper indexing

See [QUERYING.md](QUERYING.md) for complete documentation.

## Call Graph Queries

Analyze function dependencies and call relationships:

```bash
# Find what a function calls
bash query.sh find-function-dependencies process_request

# Find what calls a function
bash query.sh find-function-dependents log_message
```

**Use Cases:**
- Impact analysis before changes
- Dependency tracking
- Dead code detection
- Refactoring support

See [QUICK_START_CALL_GRAPH.md](docs/QUICK_START_CALL_GRAPH.md) and [CALL_GRAPH_QUERIES.md](docs/CALL_GRAPH_QUERIES.md) for complete documentation.

## File Header Queries

Extract code references and author information from file modification sections:

```bash
# Find files containing a code reference
bash query.sh find-reference "PRB-299"

# Find files modified by an author
bash query.sh find-author "Rich"

# Get all references for a file
bash query.sh get-file-references "./src/utils.4gl"

# Show author expertise areas
bash query.sh author-expertise "Chilly"

# Find recently modified files
bash query.sh find-recent-changes

# Search references by pattern
bash query.sh search-references "EH100%"
```

**Use Cases:**
- Track which code changes affect which files
- Find author expertise areas
- Impact analysis for code references
- Audit trail of modifications

See [QUICK_START_HEADERS.md](docs/QUICK_START_HEADERS.md) for complete documentation.

## Completed Enhancements

- ✅ **Function Call Graph** - Extract and query function calls and dependencies
  - Detects calls in CALL statements, LET assignments, control flow conditions, and nested calls
  - Stores calls in JSON and SQLite database
  - Query functions: `find-function-dependencies`, `find-function-dependents`
  - See [CALL_GRAPH_QUERIES.md](docs/CALL_GRAPH_QUERIES.md) for details

- ✅ **File Header Parsing** - Extract code references and author information
  - Flexible column detection (no hard-coded patterns)
  - Handles variable spacing and optional columns
  - Supports any reference format (PRB-299, EH100512, SR-40356-3, etc.)
  - Graceful error handling for files without headers
  - Query functions: `find-reference`, `find-author`, `author-expertise`, etc.
  - See [QUICK_START_HEADERS.md](docs/QUICK_START_HEADERS.md) for details

- ✅ **Code Quality Analysis & Metrics** (Phase 2) - Extract and analyze code metrics
  - 6 core metrics: Lines of Code, Cyclomatic Complexity, Variable Count, Parameter Count, Return Count, Call Depth
  - Incremental generation for efficient updates (file-level and function-level)
  - SQLite database with optimized indexes for fast queries
  - Quality analyzer with 5 query methods for code review
  - Property-based testing framework for correctness validation
  - See [QUERY_LAYER_GUIDE.md](docs/QUERY_LAYER_GUIDE.md) for details

## Use Cases

### IDE/Editor Integration
This tool provides rich metadata for editor plugins and extensions:

**Vim Plugin Example:**
```bash
# Get full function context for hover information
bash query.sh get-function-full-context my_function
# Returns: signature, file location, who calls it, what it calls, metrics
```

**VS Code Extension Example:**
- Code lens showing function complexity and call count
- Hover information with full signature and dependencies
- Quick navigation to function definitions
- Autocompletion context with parameter types

**Any Editor:**
- Query the SQLite database directly
- Use Python API for programmatic access
- JSON output for easy integration

### AI-Powered Code Review
Automated analysis agents can use this data to:

**New Function Review:**
```bash
# Get everything needed to review a new function
bash query.sh get-function-full-context new_function
# Find similar functions for pattern matching
bash query.sh find-similar-functions new_function
# Check for unresolved calls
bash query.sh find-unresolved-calls ./src/new_file.4gl
```

**Analysis Capabilities:**
- Review new functions against codebase patterns
- Detect type mismatches and unresolved calls
- Identify similar functions for pattern matching
- Prioritize review based on complexity metrics
- Understand impact of changes

### Developer Tooling
Command-line tools for common development tasks:

**Impact Analysis:**
```bash
# Understand what breaks when you modify a function
bash query.sh get-impact-analysis function_name
# Shows: direct dependents, transitive dependents, affected modules
```

**Dead Code Detection:**
```bash
# Find unused functions
bash query.sh find-dead-code
# Shows: function name, file, last modified, author
```

**Refactoring Support:**
- Understand function dependencies before changes
- See all callers and callees
- Identify functions with similar signatures
- Track code ownership and expertise

See [INTEGRATION_GUIDE.md](docs/INTEGRATION_GUIDE.md) for implementation examples and [USE_CASES.md](docs/USE_CASES.md) for detailed scenarios.

## Planned Enhancements

The project is nearing completion with core analysis capabilities established. Future development focuses on tooling integration:

**Phase 3 (Next - Tooling Integration):**
- Vim plugin for IDE integration - Query interface for Vim editor
- VS Code extension - Code lens and hover information
- Other editor integrations - Generic query API for any editor

**Deferred/Out of Scope:**
- Code duplication analysis - Requires full function body analysis (unrealistic for 6M+ LOC codebases)
- Unresolved call detection - Compiler already handles this
- Circular dependency detection - Not a priority for current use cases
- Visualization exports - Better as separate project for large codebases

See [FEATURES.md](docs/FEATURES.md) for complete feature list.
