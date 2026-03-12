# Genero Module Generator

Shell script to parse Genero module makefiles (.m3 files) and generate a JSON index of module dependencies.

## Purpose

This script extracts the three types of 4GL file dependencies from .m3 makefiles:
- **L4GLS**: Library files (shared libraries used across modules)
- **U4GLS**: Utility files (utility functions and helpers)
- **4GLS**: Module files (module-specific source files)

## Requirements

- Bash shell
- Python 3.6+ (for JSON processing)
- Standard Unix utilities: `find`, `awk`, `date`

No external dependencies like `jq` needed - everything uses built-in Python.

## Usage

### Generate Module Index

Run the script against your Genero .m3 files:

```bash
# Run against current directory (default)
bash generate_modules.sh

# Run against a specific directory
bash generate_modules.sh /path/to/modules

# Run against a single .m3 file
bash generate_modules.sh path/to/module.m3

# Enable verbose output
VERBOSE=1 bash generate_modules.sh /path/to/modules

# Specify custom output file
OUTPUT_FILE=my_modules.json bash generate_modules.sh /path/to/modules
```

The script will generate a `modules.json` file (or custom filename) containing module dependencies for all `.m3` files found.

## Output Format

The script generates a `modules.json` file with structured module data:

```json
{
  "_metadata": {
    "version": "1.0.0",
    "generated": "2026-03-12T09:33:55Z",
    "files_processed": 1
  },
  "modules": [
    {
      "file": "tests/test.m3",
      "module": "test",
      "L4GLS": [
        "liberr.4gl",
        "lib_esc.4gl",
        "lib_inpt.4gl"
      ],
      "U4GLS": [
        "set_opts.4gl",
        "eltrace.4gl",
        "lib_strg.4gl"
      ],
      "4GLS": [
        "test.4gl",
        "jobiface.4gl"
      ]
    }
  ]
}
```

Each module entry includes:
- `file`: Path to the .m3 file
- `module`: Module name (derived from filename)
- `L4GLS`: Array of library .4gl files
- `U4GLS`: Array of utility .4gl files
- `4GLS`: Array of module-specific .4gl files

## Configuration

The script supports environment variables for customization:

- `VERBOSE`: Set to `1` to enable progress output (default: `0`)
- `OUTPUT_FILE`: Specify output filename (default: `modules.json`)

Example:
```bash
VERBOSE=1 OUTPUT_FILE=my_modules.json bash generate_modules.sh ./modules
```

## Testing

Run the test suite to verify the script works correctly:

```bash
bash run_module_tests.sh
```

The test suite includes 8 comprehensive tests:
- Test 1: Validates output against expected results from test files
- Test 2: Verifies metadata structure
- Test 3: Verifies module count accuracy
- Test 4: Verifies empty module handling
- Test 5: Verifies multiline continuation handling
- Test 6: Verifies whitespace handling
- Test 7: Verifies mixed file types (only .4gl extracted)
- Test 8: Verifies specific expected files

### Test Coverage

The test suite includes 8 test .m3 files covering various scenarios:

| Test File | Description | L4GLS | U4GLS | 4GLS |
|-----------|-------------|-------|-------|------|
| `test.m3` | Real-world example with large file lists | 85 | 6 | 2 |
| `multiline.m3` | Multi-line continuations with backslashes | 8 | 3 | 3 |
| `single_line.m3` | Single-line assignments (no continuations) | 3 | 1 | 1 |
| `whitespace.m3` | Various whitespace patterns (spaces, tabs) | 4 | 2 | 2 |
| `comments.m3` | Inline comments after file lists | 2 | 1 | 2 |
| `mixed_files.m3` | Mixed .4gl, .c, and .ec files | 2 | 1 | 2 |
| `minimal.m3` | Only 4GLS files, no libraries | 0 | 0 | 2 |
| `empty.m3` | All empty lists | 0 | 0 | 0 |

**Total:** 8 modules with 104 L4GLS files, 14 U4GLS files, and 14 4GLS files

## Integration with Function Signatures

This module index can be combined with the function signature index (`workspace.json` from `generate_signatures.sh`) to:
- Filter function searches by module context
- Identify which functions are available in a specific module
- Map dependencies between modules
- Generate module-specific documentation

Example workflow:
```bash
# Generate function signatures
bash generate_signatures.sh /path/to/code

# Generate module index
bash generate_modules.sh /path/to/modules

# Now you can cross-reference:
# - Which functions are defined in each module's 4GLS files
# - Which library functions (L4GLS) are available to each module
# - Module dependency graphs
```

## Notes

- The script handles multi-line variable assignments (backslash continuations)
- Only extracts .4gl files (ignores .c, .ec, and other file types)
- Module names are derived from the .m3 filename
- Comments and non-4GL files in the makefiles are ignored
