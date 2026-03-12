
#!/bin/bash
# desc:
# a shell script to generate a large index of signatures for
# all of the functions in the current Genero/4GL codebase
#       -       -       -       -       -       -       -       -       -       -       -       -       -       -       -
#       11/03/2026              hdean           Initial
#       -       -       -       -       -       -       -       -       -       -       -       -       -       -       -

set -euo pipefail

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Get the parent directory (project root)
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Configuration
VERSION="1.0.0"
VERBOSE="${VERBOSE:-0}"
OUTPUT_FILE="${OUTPUT_FILE:-workspace.json}"

# Accept directory/file as parameter, default to current directory
TARGET="${1:-.}"

# Validate target exists
if [[ ! -e "$TARGET" ]]; then
    echo "Error: Target '$TARGET' does not exist" >&2
    exit 1
fi

# Normalize TARGET to be relative if it's absolute and starts with current directory
if [[ "$TARGET" = /* ]]; then
    # Absolute path - try to make it relative
    if [[ "$TARGET" = "$PWD"* ]]; then
        TARGET=".${TARGET#$PWD}"
    fi
fi

# Create temp file and ensure cleanup
TEMP_FILE=$(mktemp)
trap 'rm -f "$TEMP_FILE"' EXIT

# Count total files for metadata
TOTAL_FILES=$(find "$TARGET" -name "*.4gl" -type f | wc -l)
if [[ "$VERBOSE" == "1" ]]; then
    echo "Found $TOTAL_FILES .4gl files to process" >&2
fi

# Process all .4gl files in the target
find "$TARGET" -name "*.4gl" -type f -print0 | while IFS= read -r -d '' file; do
    if [[ "$VERBOSE" == "1" ]]; then
        echo "Processing: $file" >&2
    fi
    
    sed 's/[^[:print:]\t]//g' "$file" | awk -v file="$file" '


    BEGIN {
        in_function = 0
        delete vars
        delete param_order
        delete param_types
        delete return_order
        delete function_calls
        call_count = 0
    }

    /^FUNCTION / {
        # If we were in a function, skip it (incomplete function)
        if (in_function) {
            in_function = 0
            delete vars
            delete param_order
            delete param_types
            delete return_order
        }
        
        in_function = 1
        function_start_line = NR  # Track start line
        current_function = substr($0, index($0, "FUNCTION ") + 9)
        sub(/\(.*/, "", current_function)
        gsub(/^[ \t]+|[ \t]+$/, "", current_function)  # Trim whitespace

        sub(/.*\(/, "", $0)
        sub(/\).*/, "", $0)
        params = $0
        param_count = split(params, param_arr, /, */)

        delete param_order
        delete param_types
        delete return_order
        return_count = 0  # Initialize return count to 0
        for (i = 1; i <= param_count; i++) {
            if (split(param_arr[i], parts, /[ \t]+/) >= 2) {
                name = parts[1]
                type = parts[2]
            } else {
                name = param_arr[i]
                type = ""
            }
            param_order[i] = name
            param_types[name] = type
            vars[name] = type
        }
        next
    }

    in_function && /^[ \t]*DEFINE / {
        sub(/^[ \t]*DEFINE[ \t]+/, "")
        # Extract variable name (first word)
        match($0, /^[^ \t]+/)
        var_name = substr($0, RSTART, RLENGTH)
        # Extract type (everything after first whitespace, trimmed)
        sub(/^[^ \t]+[ \t]+/, "")
        var_type = $0
        gsub(/^[ \t]+|[ \t]+$/, "", var_type)  # Trim whitespace

        if (var_name in param_types) {
            param_types[var_name] = var_type
        }
        vars[var_name] = var_type
        next
    }

    in_function && /RETURN / {
        sub(/.*RETURN[ \t]+/, "")
        sub(/[ \t]*(#|;).*/, "")
        return_count = split($0, return_arr, /, */)
        for (i = 1; i <= return_count; i++) {
            return_order[i] = return_arr[i]
        }
        next
    }

    # Pattern 1: Direct CALL statements
    in_function && /^[ \t]*CALL[ \t]+[a-zA-Z_][a-zA-Z0-9_]*[ \t]*\(/ {
        line_content = $0
        sub(/^[ \t]*CALL[ \t]+/, "", line_content)
        match(line_content, /^[a-zA-Z_][a-zA-Z0-9_]*/)
        called_func = substr(line_content, RSTART, RLENGTH)
        
        call_count++
        function_calls[call_count] = called_func "|" NR
        next
    }

    # Pattern 2: LET var = function_name(params)
    in_function && /^[ \t]*LET[ \t]+[a-zA-Z_][a-zA-Z0-9_]*[ \t]*=[ \t]*[a-zA-Z_][a-zA-Z0-9_]*[ \t]*\(/ {
        line_content = $0
        sub(/.*=[ \t]*/, "", line_content)
        match(line_content, /^[a-zA-Z_][a-zA-Z0-9_]*/)
        called_func = substr(line_content, RSTART, RLENGTH)
        
        call_count++
        function_calls[call_count] = called_func "|" NR
        next
    }

    # Pattern 3: Function calls in control flow conditions (IF, WHILE, CASE, WHEN)
    in_function && /^[ \t]*(IF|ELSEIF|WHILE|CASE|WHEN).*[a-zA-Z_][a-zA-Z0-9_]*[ \t]*\(/ {
        line_content = $0
        sub(/^[ \t]*(IF|ELSEIF|WHILE|CASE|WHEN)[ \t]+/, "", line_content)
        
        # Extract all function calls from this line
        while (match(line_content, /[a-zA-Z_][a-zA-Z0-9_]*[ \t]*\(/)) {
            called_func = substr(line_content, RSTART, RLENGTH)
            sub(/[ \t]*\(.*/, "", called_func)
            
            # Avoid duplicates and false positives
            if (called_func != current_function && called_func != "IF" && called_func != "ELSEIF" && called_func != "WHILE" && called_func != "CASE" && called_func != "WHEN") {
                call_count++
                function_calls[call_count] = called_func "|" NR
            }
            
            line_content = substr(line_content, RSTART + RLENGTH)
        }
        next
    }

    /END FUNCTION/ {
        if (!in_function) {
            next  # Skip END FUNCTION without matching FUNCTION
        }
        
        function_end_line = NR  # Track end line
        
        # Build parameters array
        params_json = ""
        params_str = ""
        for (i = 1; i <= param_count; i++) {
            name = param_order[i]
            type = param_types[name]
            params_json = params_json (i > 1 ? ", " : "")
            params_json = params_json sprintf("{\"name\":\"%s\",\"type\":\"%s\"}", name, type ? type : "unknown")
            params_str = params_str (i > 1 ? ", " : "") name " " (type ? type : "unknown")
        }

        # Build returns array
        returns_json = ""
        returns_str = ""
        for (i = 1; i <= return_count; i++) {
            var = return_order[i]
            type = vars[var]
            returns_json = returns_json (i > 1 ? ", " : "")
            returns_json = returns_json sprintf("{\"name\":\"%s\",\"type\":\"%s\"}", var, type ? type : "unknown")
            returns_str = returns_str (i > 1 ? ", " : "") var " " (type ? type : "unknown")
        }

        # Build calls array
        calls_json = ""
        for (i = 1; i <= call_count; i++) {
            split(function_calls[i], call_parts, "|")
            called_name = call_parts[1]
            call_line = call_parts[2]
            
            calls_json = calls_json (i > 1 ? ", " : "")
            calls_json = calls_json sprintf("{\"name\":\"%s\",\"line\":%d}", called_name, call_line)
        }

        # Create signature string with line numbers
        function_sig = function_start_line "-" function_end_line ": " current_function "(" params_str ")"
        if (returns_str != "" && return_count > 0) {
            function_sig = function_sig ":" returns_str
        }

        # Print structured JSON with calls
        printf "{\"file\":\"%s\",\"name\":\"%s\",\"line\":{\"start\":%d,\"end\":%d},\"signature\":\"%s\",\"parameters\":[%s],\"returns\":[%s],\"calls\":[%s]}\n",
               file, current_function, function_start_line, function_end_line, function_sig, params_json, returns_json, calls_json

        in_function = 0
        delete vars
        delete param_order
        delete param_types
        delete return_order
        delete function_calls
        call_count = 0
    }
    ' "$file" >> "$TEMP_FILE" 2>/dev/null || true
done

# Generate timestamp in ISO 8601 format
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Process signatures using Python script
python3 "$PROJECT_ROOT/scripts/process_signatures.py" "$TEMP_FILE" "$OUTPUT_FILE" "$VERSION" "$TIMESTAMP" "$TOTAL_FILES"

# Optional: Generate SQLite database (only if CREATE_DB is set)
if [[ "${CREATE_DB:-0}" == "1" ]]; then
    DB_FILE="${OUTPUT_FILE%.json}.db"
    # Remove existing database to avoid UNIQUE constraint errors
    rm -f "$DB_FILE"
    python3 "$PROJECT_ROOT/scripts/json_to_sqlite.py" signatures "$OUTPUT_FILE" "$DB_FILE"
    if [[ "$VERBOSE" == "1" ]]; then
        echo "Generated $DB_FILE for fast querying" >&2
    fi
fi

if [[ "$VERBOSE" == "1" ]]; then
    echo "Generated $OUTPUT_FILE successfully" >&2
fi
