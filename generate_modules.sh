#!/bin/bash
# desc:
# a shell script to generate a JSON index of Genero modules (.m3 files)
# and their dependencies (L4GLS, U4GLS, and 4GLS files)
#       -       -       -       -       -       -       -       -       -       -       -       -       -       -       -
#       12/03/2026              hdean           Initial
#       -       -       -       -       -       -       -       -       -       -       -       -       -       -       -

set -euo pipefail

# Configuration
VERSION="1.0.0"
VERBOSE="${VERBOSE:-0}"
OUTPUT_FILE="${OUTPUT_FILE:-modules.json}"

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
TOTAL_FILES=$(find "$TARGET" -name "*.m3" -type f | wc -l)
if [[ "$VERBOSE" == "1" ]]; then
    echo "Found $TOTAL_FILES .m3 files to process" >&2
fi

# Process all .m3 files in the target
find "$TARGET" -name "*.m3" -type f -print0 | while IFS= read -r -d '' file; do
    if [[ "$VERBOSE" == "1" ]]; then
        echo "Processing: $file" >&2
    fi
    
    # Extract module name from filename (without path and extension)
    module_name=$(basename "$file" .m3)
    
    # Use awk to parse the m3 file and extract L4GLS, U4GLS, and 4GLS
    awk -v file="$file" -v module="$module_name" '
    BEGIN {
        in_l4gls = 0
        in_u4gls = 0
        in_4gls = 0
        l4gls_list = ""
        u4gls_list = ""
        gls_4_list = ""
    }
    
    # Detect start of L4GLS section
    /^L4GLS[[:space:]]*=/ {
        in_l4gls = 1
        in_u4gls = 0
        in_4gls = 0
        # Extract files from the same line
        sub(/^L4GLS[[:space:]]*=[[:space:]]*/, "")
        line = $0
        # If line does not end with backslash, process immediately
        if (!/\\[[:space:]]*$/) {
            gsub(/\\/, "", line)
            gsub(/^[[:space:]]+|[[:space:]]+$/, "", line)
            n = split(line, files, /[[:space:]]+/)
            for (i = 1; i <= n; i++) {
                if (files[i] ~ /\.4gl$/) {
                    l4gls_list = l4gls_list (l4gls_list != "" ? "," : "") "\"" files[i] "\""
                }
            }
            line = ""
            in_l4gls = 0
        }
        next
    }
    
    # Detect start of U4GLS section
    /^U4GLS[[:space:]]*=/ {
        in_l4gls = 0
        in_u4gls = 1
        in_4gls = 0
        # Extract files from the same line
        sub(/^U4GLS[[:space:]]*=[[:space:]]*/, "")
        line = $0
        # If line does not end with backslash, process immediately
        if (!/\\[[:space:]]*$/) {
            gsub(/\\/, "", line)
            gsub(/^[[:space:]]+|[[:space:]]+$/, "", line)
            n = split(line, files, /[[:space:]]+/)
            for (i = 1; i <= n; i++) {
                if (files[i] ~ /\.4gl$/) {
                    u4gls_list = u4gls_list (u4gls_list != "" ? "," : "") "\"" files[i] "\""
                }
            }
            line = ""
            in_u4gls = 0
        }
        next
    }
    
    # Detect start of 4GLS section (not L4GLS or U4GLS)
    /^4GLS[[:space:]]*=/ {
        in_l4gls = 0
        in_u4gls = 0
        in_4gls = 1
        # Extract files from the same line
        sub(/^4GLS[[:space:]]*=[[:space:]]*/, "")
        line = $0
        # If line does not end with backslash, process immediately
        if (!/\\[[:space:]]*$/) {
            gsub(/\\/, "", line)
            gsub(/^[[:space:]]+|[[:space:]]+$/, "", line)
            n = split(line, files, /[[:space:]]+/)
            for (i = 1; i <= n; i++) {
                if (files[i] ~ /\.4gl$/) {
                    gls_4_list = gls_4_list (gls_4_list != "" ? "," : "") "\"" files[i] "\""
                }
            }
            line = ""
            in_4gls = 0
        }
        next
    }
    
    # Detect end of continuation (line without backslash)
    in_l4gls || in_u4gls || in_4gls {
        # Check if this is a new variable assignment (end of current section)
        if (/^[A-Z_][A-Z0-9_]*[[:space:]]*=/ && !/^(L4GLS|U4GLS|4GLS)[[:space:]]*=/) {
            in_l4gls = 0
            in_u4gls = 0
            in_4gls = 0
            next
        }
        
        # Accumulate the line
        line = (line != "" ? line " " : "") $0
        
        # Check if line continues (ends with backslash)
        if (!/\\[[:space:]]*$/) {
            # Process accumulated line
            gsub(/\\/, "", line)  # Remove backslashes
            gsub(/^[[:space:]]+|[[:space:]]+$/, "", line)  # Trim
            
            # Split by whitespace and extract .4gl files
            n = split(line, files, /[[:space:]]+/)
            for (i = 1; i <= n; i++) {
                if (files[i] ~ /\.4gl$/) {
                    if (in_l4gls) {
                        l4gls_list = l4gls_list (l4gls_list != "" ? "," : "") "\"" files[i] "\""
                    } else if (in_u4gls) {
                        u4gls_list = u4gls_list (u4gls_list != "" ? "," : "") "\"" files[i] "\""
                    } else if (in_4gls) {
                        gls_4_list = gls_4_list (gls_4_list != "" ? "," : "") "\"" files[i] "\""
                    }
                }
            }
            
            # Reset for next section
            line = ""
            in_l4gls = 0
            in_u4gls = 0
            in_4gls = 0
        }
    }
    
    END {
        # Output JSON object for this module
        printf "{\"file\":\"%s\",\"module\":\"%s\",\"L4GLS\":[%s],\"U4GLS\":[%s],\"4GLS\":[%s]}\n",
               file, module, l4gls_list, u4gls_list, gls_4_list
    }
    ' "$file" >> "$TEMP_FILE"
done

# Generate timestamp in ISO 8601 format
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Process modules using Python script
python3 scripts/process_modules.py "$TEMP_FILE" "$OUTPUT_FILE" "$VERSION" "$TIMESTAMP" "$TOTAL_FILES"

if [[ "$VERBOSE" == "1" ]]; then
    echo "Generated $OUTPUT_FILE successfully" >&2
fi
