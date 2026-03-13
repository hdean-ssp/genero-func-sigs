# Developer Guide

This guide is for developers and AI agents working on the Genero Function Signatures project. It covers the development workflow, code organization, and how to make changes effectively.

## Project Overview

**Purpose:** Extract and analyze function signatures, module dependencies, and code metadata from Genero/4GL codebases.

**Key Components:**
- Shell scripts for parsing (AWK/sed)
- Python scripts for JSON processing and database operations
- SQLite for efficient querying
- Comprehensive test suite

**Tech Stack:**
- Bash shell scripts
- AWK/sed for text processing
- Python 3.6+ for JSON and database operations
- SQLite 3 for indexing and queries

## Directory Structure

```
genero-func-sigs/
├── src/                          # Main generation scripts
│   ├── generate_signatures.sh     # Extract function signatures from .4gl
│   ├── generate_modules.sh        # Parse module dependencies from .m3
│   ├── generate_codebase_index.sh # Merge signatures and modules
│   └── query.sh                   # Query wrapper script
├── scripts/                       # Python utility scripts
│   ├── parse_headers.py           # Extract headers and author info
│   ├── merge_headers.py           # Merge headers into workspace.json
│   ├── json_to_sqlite.py          # Convert JSON to SQLite
│   ├── json_to_sqlite_headers.py  # Create header tables in DB
│   ├── query_db.py                # Query database functions
│   ├── query_headers.py           # Query header metadata
│   ├── process_*.py               # Data processing utilities
│   └── test_utils.py              # Test helper functions
├── tests/                         # Test suite
│   ├── run_all_tests.sh           # Run all tests
│   ├── run_tests.sh               # Test signature generation
│   ├── run_module_tests.sh        # Test module generation
│   ├── test_call_graph.sh         # Test call graph extraction
│   ├── test_header_integration.sh # Test header parsing
│   ├── test_header_parser.sh      # Test header parser
│   └── sample_codebase/           # Test data
├── docs/                          # Documentation
│   ├── ARCHITECTURE.md            # System architecture
│   ├── IMPLEMENTATION_SUMMARY.md  # Feature implementations
│   ├── HEADER_PARSING_*.md        # Header parsing docs
│   ├── CALL_GRAPH_QUERIES.md      # Call graph documentation
│   ├── QUICK_START_*.md           # Quick start guides
│   └── FUTURE_ENHANCEMENTS.md     # Roadmap
├── generate_all.sh                # Main orchestration script
├── query.sh                       # Query interface
└── README.md                      # Project overview
```

## Development Workflow

### 1. Understanding the Pipeline

The project follows a linear pipeline:

```
.4gl files → generate_signatures.sh → workspace.json
                                    ↓
                          parse_headers.py (extract headers)
                                    ↓
                          merge_headers.py (merge into JSON)
                                    ↓
                          json_to_sqlite.py (create DB)
                                    ↓
                          query_db.py (query interface)
```

### 2. Making Changes

**For parsing logic changes:**
1. Modify the appropriate shell script in `src/`
2. Update test data in `tests/sample_codebase/`
3. Regenerate expected output: `bash src/generate_signatures.sh tests/sample_codebase`
4. Copy to expected: `cp workspace.json tests/sample_codebase/expected_output.json`
5. Run tests: `bash tests/run_tests.sh`

**For Python script changes:**
1. Edit the script in `scripts/`
2. Test with sample data
3. Run relevant test suite
4. Verify with `bash tests/run_all_tests.sh`

**For adding new features:**
1. Create test cases first (TDD approach)
2. Implement feature in appropriate script
3. Update documentation
4. Run full test suite
5. Commit with clear message

### 3. Testing

**Run all tests:**
```bash
bash tests/run_all_tests.sh
```

**Run specific test suite:**
```bash
bash tests/run_tests.sh              # Signature generation
bash tests/run_module_tests.sh       # Module generation
bash tests/test_call_graph.sh        # Call graph
bash tests/test_header_integration.sh # Header parsing
```

**Test a single file:**
```bash
bash src/generate_signatures.sh tests/sample_codebase/simple_functions.4gl
```

**Debug with verbose output:**
```bash
VERBOSE=1 bash generate_all.sh tests/sample_codebase
```

### 4. Adding Test Data

To add a new test file:

1. Create `.4gl` or `.m3` file in `tests/sample_codebase/`
2. Run generation: `bash src/generate_signatures.sh tests/sample_codebase`
3. Verify output looks correct
4. Copy to expected: `cp workspace.json tests/sample_codebase/expected_output.json`
5. Run tests to verify

## Code Organization

### Shell Scripts (`src/`)

**Pattern:**
- Use `find` to locate files
- Use `sed` for text cleaning
- Use `awk` for parsing
- Output JSON lines (one per line)
- Use Python for final formatting

**Key Functions:**
- `extract_functions()` - Parse function definitions
- `extract_modules()` - Parse module files
- `normalize_path()` - Handle path variations

### Python Scripts (`scripts/`)

**Pattern:**
- Accept file paths as arguments
- Output JSON to stdout
- Handle errors gracefully
- Use type hints for clarity
- Include docstrings

**Key Classes:**
- `HeaderParser` - Parse file headers
- Database functions - Query operations

**Key Functions:**
- `parse_file()` - Parse single file
- `merge_headers()` - Merge header data
- `create_db()` - Create SQLite database

## Common Tasks

### Adding a New Query Function

1. Add function to `scripts/query_db.py`:
```python
def find_something(db_file: str, param: str) -> List[Dict]:
    """Find something in database."""
    conn = sqlite3.connect(db_file)
    c = conn.cursor()
    c.execute("SELECT * FROM table WHERE column = ?", (param,))
    results = [dict(row) for row in c.fetchall()]
    conn.close()
    return results
```

2. Add wrapper to `src/query.sh`:
```bash
find-something)
    python3 "$SCRIPT_DIR/scripts/query_db.py" find-something "$DB_FILE" "$2"
    ;;
```

3. Add test case to `tests/test_call_graph.sh`
4. Update documentation

### Fixing a Bug

1. Create minimal test case that reproduces bug
2. Add to test suite
3. Verify test fails
4. Fix the bug
5. Verify test passes
6. Run full test suite
7. Commit with "fix:" prefix

### Improving Performance

1. Profile with `time` command
2. Identify bottleneck
3. Optimize (usually in AWK or Python)
4. Verify with benchmarks
5. Run full test suite
6. Document performance impact

## Important Patterns

### Path Handling

Paths are relative to the workspace directory passed to `generate_all.sh`:
- Root files: `simple_functions.4gl`
- Subdirectory files: `./lib/complex_types.4gl`
- Full paths in workspace.json: `./tests/sample_codebase/simple_functions.4gl`

### Error Handling

- Shell scripts: Use `set -euo pipefail` for strict error handling
- Python scripts: Catch exceptions and continue gracefully
- Tests: Use `|| true` to continue on non-critical failures

### JSON Output

- One JSON object per line (for streaming)
- Use `json.dumps()` for single-line output
- Use `json.dump()` with indent for formatted output
- Always include `_metadata` section

### Database Operations

- Always create indexes for frequently queried columns
- Use `FOREIGN KEY` constraints for data integrity
- Normalize paths consistently
- Handle missing data gracefully

## Debugging Tips

### Check Intermediate Files

```bash
# View workspace.json structure
python3 -c "import json; data=json.load(open('workspace.json')); print(list(data.keys())[:5])"

# Count functions
python3 -c "import json; data=json.load(open('workspace.json')); print(sum(len(v) for k,v in data.items() if not k.startswith('_')))"

# Check specific file
python3 -c "import json; data=json.load(open('workspace.json')); print(data.get('./path/to/file.4gl', []))"
```

### Query Database Directly

```bash
# List all tables
sqlite3 workspace.db ".tables"

# Check function count
sqlite3 workspace.db "SELECT COUNT(*) FROM functions"

# Find specific function
sqlite3 workspace.db "SELECT * FROM functions WHERE name = 'my_func'"
```

### Enable Verbose Output

```bash
VERBOSE=1 bash generate_all.sh tests/sample_codebase
```

### Check Test Output

```bash
# Run single test with output
bash tests/run_tests.sh 2>&1 | head -50

# Check expected vs actual
diff tests/sample_codebase/expected_output.json workspace.json
```

## Git Workflow

### Commit Messages

Use conventional commits:
- `feat:` - New feature
- `fix:` - Bug fix
- `docs:` - Documentation
- `test:` - Test changes
- `refactor:` - Code refactoring
- `perf:` - Performance improvement

Example:
```
feat: add header parsing for code references

- Extract code references from file headers
- Parse author information
- Merge into workspace.json
- Add query functions for references
```

### Before Committing

1. Run full test suite: `bash tests/run_all_tests.sh`
2. Check for uncommitted changes: `git status`
3. Review changes: `git diff`
4. Verify no debug code left in

## Performance Considerations

### Large Codebases

- Use SQLite for queries (much faster than JSON)
- Consider incremental updates
- Monitor memory usage
- Profile with `time` command

### Optimization Opportunities

- AWK parsing is fast but could be parallelized
- Python JSON processing could use streaming
- Database queries could use connection pooling
- Consider caching for repeated queries

## Documentation Standards

### Code Comments

- Explain "why" not "what"
- Use docstrings for functions
- Include type hints
- Document edge cases

### Documentation Files

- Use Markdown format
- Include examples
- Keep up-to-date with code
- Link between related docs

## Resources

- **ARCHITECTURE.md** - System design and components
- **IMPLEMENTATION_SUMMARY.md** - Feature details
- **QUICK_START_*.md** - Usage examples
- **FUTURE_ENHANCEMENTS.md** - Roadmap
- **tests/README.md** - Test data documentation

## Getting Help

1. Check existing documentation
2. Look at similar implementations
3. Review test cases for examples
4. Check git history for context
5. Run with verbose output for debugging

## Next Steps for New Developers

1. Read README.md for project overview
2. Read ARCHITECTURE.md for system design
3. Run `bash tests/run_all_tests.sh` to verify setup
4. Explore test data in `tests/sample_codebase/`
5. Try making a small change and running tests
6. Read relevant feature documentation
7. Start working on assigned tasks
