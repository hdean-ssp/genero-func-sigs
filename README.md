# genero-func-sigs
shell script(s) to generate and index function signatures when run in a Genero codebase

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
```

The script will generate a `workspace.json` file containing function signatures for all `.4gl` files found.

### Output Format

The script generates a `workspace.json` file with structured function data grouped by file:

Example:
```json
{
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
      ]
    }
  ]
}
```

Each function entry includes:
- `name`: Function name for direct lookup
- `line`: Start and end line numbers
- `signature`: Human-readable signature string with line numbers
- `parameters`: Array of parameter objects with name and type
- `returns`: Array of return value objects with name and type

## Testing

Run the test suite to verify the script works correctly:

```bash
bash run_tests.sh
```

The test suite includes:
- Test 1: Validates output against expected results from test files
- Test 2: Verifies single file processing
- Test 3: Checks signature format validity

Test files are located in the `tests/` directory and include various function patterns:
- Simple functions with basic types
- Functions with multiple return values
- Functions with complex types (RECORD, DATE, ARRAY, etc.)
