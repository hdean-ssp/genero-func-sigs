# Function Call Graph Implementation Plan

## Current Parser Architecture

The current `generate_signatures.sh` uses an AWK-based state machine to parse 4GL files:

### Current State Machine States:
1. **BEGIN** - Initialize variables
2. **FUNCTION** - Detect function start, extract name and parameters
3. **DEFINE** - Track variable definitions and types
4. **RETURN** - Extract return values
5. **END FUNCTION** - Output function metadata and reset state

### Current Output:
- Function name, parameters, return values
- Line numbers (start/end)
- Type information

## Proposed Enhancement: Function Call Detection

### Phase 0 Implementation Strategy

#### 1. Add New State Machine Variable (in BEGIN block)

```awk
BEGIN {
    in_function = 0
    delete vars
    delete param_order
    delete param_types
    delete return_order
    delete function_calls        # NEW: Track calls within function
    call_count = 0               # NEW: Count of calls in current function
}
```

#### 2. Add Call Detection Logic (in_function && main loop)

**Location:** After the RETURN pattern block, before END FUNCTION

**New Pattern Blocks to Add:**

```awk
# Pattern 1: CALL function_name(params) [RETURNING ret1, ret2]
in_function && /^[ \t]*CALL[ \t]+[a-zA-Z_][a-zA-Z0-9_]*[ \t]*\(/ {
    # Extract function name and line number
    line_content = $0
    sub(/^[ \t]*CALL[ \t]+/, "", line_content)
    match(line_content, /^[a-zA-Z_][a-zA-Z0-9_]*/)
    called_func = substr(line_content, RSTART, RLENGTH)
    
    # Store call information
    call_count++
    function_calls[call_count] = called_func "|" NR
    next
}

# Pattern 2: LET var = function_name(params)
in_function && /^[ \t]*LET[ \t]+[a-zA-Z_][a-zA-Z0-9_]*[ \t]*=[ \t]*[a-zA-Z_][a-zA-Z0-9_]*[ \t]*\(/ {
    # Extract function name (after = and before ()
    line_content = $0
    sub(/.*=[ \t]*/, "", line_content)
    match(line_content, /^[a-zA-Z_][a-zA-Z0-9_]*/)
    called_func = substr(line_content, RSTART, RLENGTH)
    
    # Store call information
    call_count++
    function_calls[call_count] = called_func "|" NR
    next
}
```

#### 3. Output Call Information (in END FUNCTION block)

**Location:** Before the final printf statement

```awk
# Build calls array
calls_json = ""
for (i = 1; i <= call_count; i++) {
    split(function_calls[i], call_parts, "|")
    called_name = call_parts[1]
    call_line = call_parts[2]
    
    calls_json = calls_json (i > 1 ? ", " : "")
    calls_json = calls_json sprintf("{\"name\":\"%s\",\"line\":%d}", called_name, call_line)
}
```

#### 4. Modify Output JSON (in END FUNCTION block)

**Current printf:**
```awk
printf "{\"file\":\"%s\",\"name\":\"%s\",\"line\":{\"start\":%d,\"end\":%d},\"signature\":\"%s\",\"parameters\":[%s],\"returns\":[%s]}\n",
       file, current_function, function_start_line, function_end_line, function_sig, params_json, returns_json
```

**Updated printf:**
```awk
printf "{\"file\":\"%s\",\"name\":\"%s\",\"line\":{\"start\":%d,\"end\":%d},\"signature\":\"%s\",\"parameters\":[%s],\"returns\":[%s],\"calls\":[%s]}\n",
       file, current_function, function_start_line, function_end_line, function_sig, params_json, returns_json, calls_json
```

#### 5. Reset Call Tracking (in END FUNCTION block)

```awk
# Reset for next function
delete function_calls
call_count = 0
```

## Implementation Details

### Call Pattern Recognition

The implementation should handle:

1. **Direct CALL statements:**
   ```
   CALL function_name(param1, param2)
   CALL function_name(param1, param2) RETURNING ret1, ret2
   ```

2. **Assignment from function returns:**
   ```
   LET var = function_name(param1, param2)
   LET var1, var2 = function_name(param1)
   ```

3. **Whitespace variations:**
   ```
   CALL  function_name  (  param1  )
   LET var=function_name(param1)
   ```

4. **Mixed case function names:**
   ```
   CALL My_Function(param)
   CALL myFunction(param)
   ```

### Edge Cases to Handle

1. **Comments:** Strip comments before pattern matching
   ```
   CALL function_name(param)  # This is a comment
   ```

2. **String literals:** Avoid matching function calls inside strings
   ```
   DISPLAY "CALL function_name(param)"  # Should NOT match
   ```

3. **Nested parentheses:** Handle function calls with complex parameters
   ```
   CALL function_name(other_func(param1), param2)
   ```

4. **Multi-line statements:** Currently handled by sed cleanup

## Data Flow

```
4GL File
    ↓
sed (clean non-printable chars)
    ↓
awk (state machine)
    ├─ FUNCTION: Extract signature
    ├─ DEFINE: Track types
    ├─ RETURN: Extract returns
    ├─ CALL/LET: Extract calls (NEW)
    └─ END FUNCTION: Output with calls
    ↓
Temp file (JSON lines with calls)
    ↓
process_signatures.py (group by file)
    ↓
workspace.json (with calls array)
```

## Database Schema Update

### New calls table:

```sql
CREATE TABLE calls (
    id INTEGER PRIMARY KEY,
    function_id INTEGER NOT NULL,
    called_function_name TEXT NOT NULL,
    line_number INTEGER NOT NULL,
    FOREIGN KEY (function_id) REFERENCES functions(id)
);

CREATE INDEX idx_calls_function_id ON calls(function_id);
CREATE INDEX idx_calls_called_name ON calls(called_function_name);
```

## Testing Strategy

### Test Cases:

1. **Simple CALL:**
   ```
   CALL validate_number(result)
   ```
   Expected: Extract "validate_number" at line N

2. **LET assignment:**
   ```
   LET name = format_string(name)
   ```
   Expected: Extract "format_string" at line N

3. **Multiple calls:**
   ```
   CALL func1(param)
   CALL func2(param)
   ```
   Expected: Extract both calls with correct line numbers

4. **Whitespace variations:**
   ```
   CALL  function_name  (  param  )
   ```
   Expected: Extract "function_name"

5. **Comments:**
   ```
   CALL function_name(param)  # Comment
   ```
   Expected: Extract "function_name", ignore comment

6. **No calls:**
   ```
   FUNCTION no_calls()
       DISPLAY "Hello"
   END FUNCTION
   ```
   Expected: Empty calls array

## Implementation Phases

### Phase 0a: AWK Parser Enhancement
- Add call detection patterns to AWK
- Output calls in JSON
- Update process_signatures.py to handle calls

### Phase 0b: Database Schema Update
- Create calls table
- Update json_to_sqlite.py to populate calls table
- Create indexes for performance

### Phase 0c: Query Implementation
- Implement find-function-dependencies query
- Implement find-function-dependents query
- Add call graph traversal logic

## Performance Considerations

1. **Regex Complexity:** Keep patterns simple for AWK performance
2. **Memory:** Store calls in array during function parsing (minimal overhead)
3. **Database:** Index on called_function_name for fast lookups
4. **Query Performance:** Use database views for call graph traversal

## Backward Compatibility

- Existing workspace.json will have "calls": [] for functions without calls
- Existing queries unaffected
- New queries only available after Phase 0 implementation
- Database schema is additive (new table, no changes to existing tables)

## Success Criteria

- [ ] All test functions have calls extracted correctly
- [ ] Call line numbers are accurate
- [ ] Whitespace variations handled
- [ ] Comments ignored
- [ ] Database queries return correct call graphs
- [ ] Performance impact < 10% on generation time
- [ ] All existing tests still pass
