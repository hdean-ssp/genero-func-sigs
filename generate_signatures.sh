
#!/bin/bash
# desc:
# a shell script to generate a large index of signatures for
# all of the functions in the current Genero/4GL codebase
#       -       -       -       -       -       -       -       -       -       -       -       -       -       -       -
#       11/03/2026              hdean           Initial
#       -       -       -       -       -       -       -       -       -       -       -       -       -       -       -

set -euo pipefail

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

        # Create signature string with line numbers
        function_sig = function_start_line "-" function_end_line ": " current_function "(" params_str ")"
        if (returns_str != "" && return_count > 0) {
            function_sig = function_sig ":" returns_str
        }

        # Print structured JSON
        printf "{\"file\":\"%s\",\"name\":\"%s\",\"line\":{\"start\":%d,\"end\":%d},\"signature\":\"%s\",\"parameters\":[%s],\"returns\":[%s]}\n",
               file, current_function, function_start_line, function_end_line, function_sig, params_json, returns_json

        in_function = 0
        delete vars
        delete param_order
        delete param_types
        delete return_order
    }
    ' "$file" >> "$TEMP_FILE" 2>/dev/null || true
done

# Generate timestamp in ISO 8601 format
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Process signatures using Python script
python3 scripts/process_signatures.py "$TEMP_FILE" "$OUTPUT_FILE" "$VERSION" "$TIMESTAMP" "$TOTAL_FILES"

if [[ "$VERBOSE" == "1" ]]; then
    echo "Generated $OUTPUT_FILE successfully" >&2
fi
