# Test Directory Structure

This directory contains test codebases for validating the Genero function signature and module generators.

## Structure

```
tests/
├── sample_codebase/          # Sample Genero codebase with various test cases
│   ├── *.4gl                 # Genero 4GL source files (function signature tests)
│   ├── *.m3                  # Genero module makefiles (module dependency tests)
│   ├── expected_output.json  # Expected output for generate_signatures.sh
│   └── expected_modules.json # Expected output for generate_modules.sh
└── README.md                 # This file
```

## Test Codebases

### sample_codebase

A comprehensive test codebase containing:

**4GL Files (23 functions across 7 files):**
- `simple_functions.4gl` - Basic parameter and return types
- `complex_types.4gl` - RECORD, DATE, ARRAY types
- `multiple_returns.4gl` - Functions returning multiple values
- `edge_cases.4gl` - Long parameters, inline returns, mixed case
- `whitespace_variations.4gl` - Various spacing patterns
- `special_types.4gl` - INTERVAL, TEXT, MONEY, SERIAL, BOOLEAN, DYNAMIC ARRAY
- `no_returns.4gl` - Procedure-style functions without returns

**M3 Files (8 modules with 132 total dependencies):**
- `test.m3` - Real-world example (85 L4GLS, 6 U4GLS, 2 4GLS)
- `multiline.m3` - Multi-line continuations (8, 3, 3)
- `single_line.m3` - Single-line assignments (3, 1, 1)
- `whitespace.m3` - Whitespace variations (4, 2, 2)
- `comments.m3` - Inline comments (2, 1, 2)
- `mixed_files.m3` - Mixed file types (2, 1, 2)
- `minimal.m3` - Minimal module (0, 0, 2)
- `empty.m3` - Empty lists (0, 0, 0)

## Running Tests

From the repository root:

```bash
# Test function signature generator
bash run_tests.sh

# Test module dependency generator
bash run_module_tests.sh
```

## Adding New Test Codebases

To add a new test codebase:

1. Create a new directory under `tests/` (e.g., `tests/my_codebase/`)
2. Add your test `.4gl` and/or `.m3` files
3. Generate expected outputs:
   ```bash
   # For function signatures
   bash generate_signatures.sh ./tests/my_codebase
   jq 'del(._metadata)' workspace.json > tests/my_codebase/expected_output.json
   
   # For module dependencies
   bash generate_modules.sh ./tests/my_codebase
   jq 'del(._metadata)' modules.json > tests/my_codebase/expected_modules.json
   ```
4. Update test scripts to include the new codebase

## Test Coverage

The current test suite validates:

**Function Signature Generator:**
- ✓ Simple and complex data types
- ✓ Multiple return values
- ✓ Functions with no parameters or returns
- ✓ Various whitespace patterns
- ✓ Edge cases (long parameters, inline returns, mixed case)
- ✓ Special Genero types
- ✓ Metadata generation
- ✓ JSON formatting

**Module Dependency Generator:**
- ✓ Multi-line continuations (backslash)
- ✓ Single-line assignments
- ✓ Whitespace variations (spaces, tabs, mixed)
- ✓ Inline comments
- ✓ Empty lists
- ✓ Mixed file types (.4gl, .c, .ec) - only .4gl extracted
- ✓ Metadata generation
- ✓ JSON formatting
