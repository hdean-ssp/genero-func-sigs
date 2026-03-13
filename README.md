# genero-func-sigs
shell script(s) to generate and index function signatures when run in a Genero codebase

## Features

- Extracts function signatures from Genero/4GL files
- **Extracts function calls and builds call graphs** (NEW)
- **Parses file headers to extract code references and author information** (NEW)
- Generates structured JSON output with metadata
- Human-readable JSON formatting with proper indentation
- Supports all Genero data types (basic, complex, and special types)
- Handles multiple return values
- Tracks line numbers for each function
- Configurable output file and verbose mode
- Robust error handling with automatic cleanup

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

See [QUICK_START_HEADERS.md](docs/QUICK_START_HEADERS.md) and [HEADER_PARSING_IMPLEMENTATION.md](docs/HEADER_PARSING_IMPLEMENTATION.md) for complete documentation.

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
  - See [HEADER_PARSING_IMPLEMENTATION.md](docs/HEADER_PARSING_IMPLEMENTATION.md) for details

## Planned Enhancements

The project has an ambitious roadmap for future improvements:

- **Call Resolution** - Map called function names to actual functions
- **Recursive Call Detection** - Identify and mark recursive calls
- **Enhanced Type Parser** - Support database LIKE types and RECORD types
- **Database Schema Integration** - Parse schema files and validate types
- **Advanced Queries** - Circular dependency detection, unused code analysis
- **IDE Integration** - Plugins for popular editors
- **Web Interface** - Browser-based code explorer

See [FUTURE_ENHANCEMENTS.md](FUTURE_ENHANCEMENTS.md) for the complete roadmap.
