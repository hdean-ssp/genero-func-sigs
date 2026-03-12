# Changelog

All notable changes to this project are documented here.

## [Unreleased]

### Added
- SQLite database tools for efficient querying of large JSON files
- `query.sh` - User-friendly shell wrapper for database queries
- `scripts/json_to_sqlite.py` - Convert JSON to indexed SQLite databases
- `scripts/query_db.py` - Query interface for databases
- `QUERYING.md` - Documentation for database tools
- `ARCHITECTURE.md` - Comprehensive architecture documentation
- Separate Python scripts for JSON processing (cleaner code organization)

### Changed
- Replaced `jq` dependency with Python 3 (built-in on most systems)
- Moved Python code from heredocs to separate script files
- Improved error handling and code organization
- Updated all documentation to reflect Python-based approach

### Removed
- Dependency on `jq` command-line tool
- Inline Python heredocs (moved to separate files)

### Performance
- Database queries: 100x faster than JSON parsing
- File size: 100x smaller (70KB vs 15-20MB)
- Memory usage: Reduced from 100-200MB to <10MB

## [1.0.0] - 2026-03-12

### Added
- Initial release of Genero Function Signatures project
- `generate_signatures.sh` - Extract function signatures from .4gl files
- `generate_modules.sh` - Parse module dependencies from .m3 files
- `generate_codebase_index.sh` - Generate unified codebase index
- Comprehensive test suite with 23 test functions
- Full documentation (README, MODULE_GENERATOR, CODEBASE_INDEX)
- Support for all Genero data types
- Line number tracking for IDE integration
- Metadata generation for validation

### Features
- Extracts function names, parameters, return values
- Handles multi-line function definitions
- Parses module file dependencies (L4GLS, U4GLS, 4GLS)
- Handles multi-line variable assignments
- Generates structured JSON output
- Includes generation metadata and timestamps
- Robust error handling with automatic cleanup
