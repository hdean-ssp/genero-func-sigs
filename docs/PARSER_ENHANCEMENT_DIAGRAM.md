# Parser Enhancement Diagram

## Current AWK State Machine

```
┌─────────────────────────────────────────────────────────────┐
│                    AWK State Machine                         │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  BEGIN                                                       │
│    ├─ in_function = 0                                       │
│    ├─ vars = {}                                             │
│    ├─ param_order = {}                                      │
│    ├─ param_types = {}                                      │
│    └─ return_order = {}                                     │
│                                                              │
│  FUNCTION pattern                                            │
│    ├─ Extract function name                                 │
│    ├─ Extract parameters                                    │
│    ├─ Set in_function = 1                                   │
│    └─ Track function_start_line                             │
│                                                              │
│  DEFINE pattern (while in_function)                          │
│    ├─ Extract variable name                                 │
│    ├─ Extract variable type                                 │
│    └─ Store in vars{}                                       │
│                                                              │
│  RETURN pattern (while in_function)                          │
│    ├─ Extract return values                                 │
│    └─ Store in return_order{}                               │
│                                                              │
│  END FUNCTION pattern                                        │
│    ├─ Track function_end_line                               │
│    ├─ Build JSON output                                     │
│    ├─ Reset all variables                                   │
│    └─ Set in_function = 0                                   │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

## Proposed Enhanced AWK State Machine

```
┌─────────────────────────────────────────────────────────────┐
│              Enhanced AWK State Machine                      │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  BEGIN                                                       │
│    ├─ in_function = 0                                       │
│    ├─ vars = {}                                             │
│    ├─ param_order = {}                                      │
│    ├─ param_types = {}                                      │
│    ├─ return_order = {}                                     │
│    ├─ function_calls = {}          ◄─── NEW                │
│    └─ call_count = 0               ◄─── NEW                │
│                                                              │
│  FUNCTION pattern                                            │
│    ├─ Extract function name                                 │
│    ├─ Extract parameters                                    │
│    ├─ Set in_function = 1                                   │
│    └─ Track function_start_line                             │
│                                                              │
│  DEFINE pattern (while in_function)                          │
│    ├─ Extract variable name                                 │
│    ├─ Extract variable type                                 │
│    └─ Store in vars{}                                       │
│                                                              │
│  RETURN pattern (while in_function)                          │
│    ├─ Extract return values                                 │
│    └─ Store in return_order{}                               │
│                                                              │
│  CALL pattern (while in_function)  ◄─── NEW                │
│    ├─ Match: /^[ \t]*CALL[ \t]+func_name[ \t]*\(/          │
│    ├─ Extract called function name                          │
│    ├─ Store: function_calls[++call_count] = name|line       │
│    └─ Continue to next line                                 │
│                                                              │
│  LET pattern (while in_function)   ◄─── NEW                │
│    ├─ Match: /^[ \t]*LET.*=.*func_name[ \t]*\(/            │
│    ├─ Extract called function name                          │
│    ├─ Store: function_calls[++call_count] = name|line       │
│    └─ Continue to next line                                 │
│                                                              │
│  END FUNCTION pattern                                        │
│    ├─ Track function_end_line                               │
│    ├─ Build calls_json array      ◄─── NEW                │
│    │   └─ For each call in function_calls{}                 │
│    │       └─ Add {name, line} to calls_json                │
│    ├─ Build JSON output (with calls)  ◄─── MODIFIED        │
│    ├─ Reset all variables                                   │
│    ├─ delete function_calls       ◄─── NEW                │
│    ├─ call_count = 0              ◄─── NEW                │
│    └─ Set in_function = 0                                   │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

## JSON Output Comparison

### Current Output:
```json
{
  "file": "./tests/sample_codebase/simple_functions.4gl",
  "name": "add_numbers",
  "line": {"start": 3, "end": 8},
  "signature": "3-8: add_numbers(a INTEGER, b INTEGER):result INTEGER",
  "parameters": [
    {"name": "a", "type": "INTEGER"},
    {"name": "b", "type": "INTEGER"}
  ],
  "returns": [
    {"name": "result", "type": "INTEGER"}
  ]
}
```

### Enhanced Output (with calls):
```json
{
  "file": "./tests/sample_codebase/simple_functions.4gl",
  "name": "add_numbers",
  "line": {"start": 3, "end": 8},
  "signature": "3-8: add_numbers(a INTEGER, b INTEGER):result INTEGER",
  "parameters": [
    {"name": "a", "type": "INTEGER"},
    {"name": "b", "type": "INTEGER"}
  ],
  "returns": [
    {"name": "result", "type": "INTEGER"}
  ],
  "calls": [
    {"name": "validate_number", "line": 7}
  ]
}
```

## Call Detection Pattern Matching

### Pattern 1: CALL Statement
```
Input:  CALL validate_number(result)
        ↓
Regex:  /^[ \t]*CALL[ \t]+[a-zA-Z_][a-zA-Z0-9_]*[ \t]*\(/
        ↓
Extract: validate_number
        ↓
Store:  function_calls[1] = "validate_number|7"
```

### Pattern 2: LET Assignment
```
Input:  LET name = format_string(name)
        ↓
Regex:  /^[ \t]*LET[ \t]+[a-zA-Z_][a-zA-Z0-9_]*[ \t]*=[ \t]*[a-zA-Z_][a-zA-Z0-9_]*[ \t]*\(/
        ↓
Extract: format_string
        ↓
Store:  function_calls[2] = "format_string|8"
```

## Processing Pipeline

```
┌──────────────────┐
│  4GL Source File │
└────────┬─────────┘
         │
         ▼
┌──────────────────────────────────────┐
│  sed: Clean non-printable chars      │
└────────┬─────────────────────────────┘
         │
         ▼
┌──────────────────────────────────────┐
│  AWK: Parse with call detection      │
│  ├─ Extract signatures               │
│  ├─ Extract parameters               │
│  ├─ Extract returns                  │
│  └─ Extract calls (NEW)              │
└────────┬─────────────────────────────┘
         │
         ▼
┌──────────────────────────────────────┐
│  Temp file: JSON lines               │
│  (one function per line with calls)  │
└────────┬─────────────────────────────┘
         │
         ▼
┌──────────────────────────────────────┐
│  process_signatures.py               │
│  ├─ Group by file                    │
│  ├─ Normalize paths                  │
│  └─ Format as JSON                   │
└────────┬─────────────────────────────┘
         │
         ▼
┌──────────────────────────────────────┐
│  workspace.json                      │
│  (functions with calls array)        │
└────────┬─────────────────────────────┘
         │
         ▼
┌──────────────────────────────────────┐
│  json_to_sqlite.py (ENHANCED)        │
│  ├─ Create functions table           │
│  ├─ Create calls table (NEW)         │
│  └─ Populate both tables             │
└────────┬─────────────────────────────┘
         │
         ▼
┌──────────────────────────────────────┐
│  workspace.db                        │
│  ├─ functions table                  │
│  ├─ calls table (NEW)                │
│  └─ Indexes for performance          │
└──────────────────────────────────────┘
```

## Code Insertion Points in generate_signatures.sh

```awk
BEGIN {
    in_function = 0
    delete vars
    delete param_order
    delete param_types
    delete return_order
    delete function_calls        # ◄─── INSERT 1: Initialize calls tracking
    call_count = 0               # ◄─── INSERT 1
}

/^FUNCTION / {
    # ... existing code ...
}

in_function && /^[ \t]*DEFINE / {
    # ... existing code ...
}

in_function && /RETURN / {
    # ... existing code ...
}

# ◄─── INSERT 2: Add CALL pattern detection
in_function && /^[ \t]*CALL[ \t]+[a-zA-Z_][a-zA-Z0-9_]*[ \t]*\(/ {
    # Extract and store call
}

# ◄─── INSERT 3: Add LET pattern detection
in_function && /^[ \t]*LET[ \t]+[a-zA-Z_][a-zA-Z0-9_]*[ \t]*=[ \t]*[a-zA-Z_][a-zA-Z0-9_]*[ \t]*\(/ {
    # Extract and store call
}

/END FUNCTION/ {
    if (!in_function) {
        next
    }
    
    # ... existing code ...
    
    # ◄─── INSERT 4: Build calls_json array
    calls_json = ""
    for (i = 1; i <= call_count; i++) {
        # Build calls array
    }
    
    # ◄─── INSERT 5: Modify printf to include calls
    printf "{...\"calls\":[%s]}\n", ..., calls_json
    
    # ◄─── INSERT 6: Reset call tracking
    delete function_calls
    call_count = 0
    
    in_function = 0
    # ... rest of existing code ...
}
```

## Summary of Changes

| Component | Current | Enhanced | Impact |
|-----------|---------|----------|--------|
| AWK Variables | 5 | 7 | +2 tracking variables |
| Pattern Blocks | 4 | 6 | +2 call detection patterns |
| JSON Output | 5 fields | 6 fields | +calls array |
| Database Tables | 3 | 4 | +calls table |
| Processing Time | Baseline | ~5-10% increase | Minimal overhead |
| Memory Usage | Baseline | ~2-5% increase | Per-function tracking |

