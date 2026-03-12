# Codebase Index Generator

Shell script to generate a unified codebase index by combining function signatures and module dependencies into a single comprehensive reference with file IDs and module mappings.

## Purpose

This script merges data from two sources:
- **workspace.json** - Function signatures from all .4gl files
- **modules.json** - Module dependencies from all .m3 files

The result is a single index that enables:
- Module-scoped function lookup
- Dependency analysis across modules
- Impact analysis when functions change
- Module-specific documentation generation
- Call graph visualization

## Requirements

- Bash shell
- `jq` - Command-line JSON processor
- Both `workspace.json` and `modules.json` must exist

## Usage

### Generate Codebase Index

```bash
# Generate with default filenames (workspace.json, modules.json, codebase_index.json)
bash generate_codebase_index.sh

# Specify custom input/output files
WORKSPACE_FILE=my_workspace.json MODULES_FILE=my_modules.json OUTPUT_FILE=my_index.json bash generate_codebase_index.sh

# Enable verbose output
VERBOSE=1 bash generate_codebase_index.sh
```

### Workflow

```bash
# 1. Generate function signatures
bash generate_signatures.sh ./src

# 2. Generate module dependencies
bash generate_modules.sh ./modules

# 3. Generate unified index
bash generate_codebase_index.sh
```

## Output Format

The script generates a `codebase_index.json` file with the following structure:

```json
{
  "_metadata": {
    "version": "1.0.0",
    "generated": "2026-03-12T10:30:00Z",
    "source_files": {
      "workspace": {
        "version": "1.0.0",
        "generated": "2026-03-12T10:25:00Z",
        "files_processed": 7
      },
      "modules": {
        "version": "1.0.0",
        "generated": "2026-03-12T10:28:00Z",
        "files_processed": 9
      }
    }
  },
  "files": {
    "file_001": {
      "path": "./src/lib_core.4gl",
      "type": "L4GLS",
      "functions": [
        {
          "name": "initialize",
          "signature": "10-25: initialize():status INTEGER",
          "parameters": [],
          "returns": [{"name": "status", "type": "INTEGER"}]
        }
      ]
    },
    "file_002": {
      "path": "./src/main.4gl",
      "type": "4GLS",
      "functions": [...]
    }
  },
  "modules": [
    {
      "module": "core",
      "file": "./modules/core.m3",
      "L4GLS": ["file_001", "file_003"],
      "U4GLS": ["file_004"],
      "4GLS": ["file_002"]
    }
  ]
}
```

### Structure Details

**files** - Deduplicated file index with unique IDs:
- `file_NNN` - Unique file identifier (NNN = 001, 002, etc.)
- `path` - Full path to the .4gl file
- `type` - File category (L4GLS, U4GLS, or 4GLS)
- `functions` - Array of function signatures from this file

**modules** - Module definitions with file references:
- `module` - Module name
- `file` - Path to the .m3 makefile
- `L4GLS` - Array of file IDs for library files
- `U4GLS` - Array of file IDs for utility files
- `4GLS` - Array of file IDs for module files

## Benefits

### No Duplication
Each file is defined once with all its functions. Modules reference files by ID, not by repeating file data.

### Efficient Queries
With this structure, you can easily:
- Find all functions in a module: `modules[].4GLS | map(files[.])` 
- Find which modules use a file: `modules[] | select(.L4GLS[] == "file_001")`
- Get function details: `files["file_001"].functions`

### Scalability
Works efficiently with:
- Hundreds of modules
- Thousands of files
- Tens of thousands of functions

### Integration
Enables building tools for:
- IDE plugins for module-aware code completion
- Dependency graph visualization
- Module-specific API documentation
- Impact analysis and refactoring support

## Example Queries

Using `jq` to query the index:

```bash
# Find all functions in a specific module
jq '.modules[] | select(.module == "core") | .L4GLS[] as $fid | .files[$fid].functions' codebase_index.json

# Find which modules use a specific file
jq '.modules[] | select(.L4GLS[] == "file_001" or .U4GLS[] == "file_001" or ."4GLS"[] == "file_001") | .module' codebase_index.json

# Count functions per module
jq '.modules[] | {module: .module, functions: ((.L4GLS + .U4GLS + ."4GLS") | map(.files[.].functions | length) | add)}' codebase_index.json

# Find all functions with a specific name
jq '.files[].functions[] | select(.name == "initialize")' codebase_index.json
```

## Configuration

Environment variables:

- `WORKSPACE_FILE` - Path to workspace.json (default: `workspace.json`)
- `MODULES_FILE` - Path to modules.json (default: `modules.json`)
- `OUTPUT_FILE` - Output filename (default: `codebase_index.json`)
- `VERBOSE` - Set to `1` for progress output (default: `0`)

Example:
```bash
VERBOSE=1 OUTPUT_FILE=my_index.json bash generate_codebase_index.sh
```

## Notes

- File IDs are generated sequentially (file_001, file_002, etc.)
- Files are deduplicated - each unique file path appears only once
- Module file references use file IDs, not paths, for efficiency
- If a module references a file not in workspace.json, it won't have a file ID
- The index preserves all metadata from source files for traceability
