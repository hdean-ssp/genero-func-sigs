#!/bin/bash
# Generate function signatures and extract file header metadata
# Combines signature generation with header parsing for code references and authors

set -euo pipefail

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Get the parent directory (project root)
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Configuration
VERSION="1.0.0"
VERBOSE="${VERBOSE:-0}"
OUTPUT_FILE="${OUTPUT_FILE:-workspace.json}"
HEADERS_FILE="${HEADERS_FILE:-workspace_headers.json}"

# Accept directory/file as parameter, default to current directory
TARGET="${1:-.}"

# Validate target exists
if [[ ! -e "$TARGET" ]]; then
    echo "Error: Target '$TARGET' does not exist" >&2
    exit 1
fi

if [[ "$VERBOSE" == "1" ]]; then
    echo "Generating signatures and extracting headers from: $TARGET" >&2
fi

# Step 1: Generate signatures using existing script
bash "$SCRIPT_DIR/generate_signatures.sh" "$TARGET"

# Step 2: Extract headers from all .4gl files
if [[ "$VERBOSE" == "1" ]]; then
    echo "Extracting file headers..." >&2
fi

# Create temp file for headers
HEADERS_TEMP=$(mktemp)
trap 'rm -f "$HEADERS_TEMP"' EXIT

# Process all .4gl files to extract headers
find "$TARGET" -name "*.4gl" -type f -print0 | while IFS= read -r -d '' file; do
    if [[ "$VERBOSE" == "1" ]]; then
        echo "Extracting headers from: $file" >&2
    fi
    
    python3 "$PROJECT_ROOT/scripts/parse_headers.py" "$file" >> "$HEADERS_TEMP" 2>/dev/null || true
done

# Step 3: Merge headers into workspace.json using Python
if [[ -s "$HEADERS_TEMP" ]]; then
    python3 "$PROJECT_ROOT/scripts/merge_headers.py" "$OUTPUT_FILE" "$HEADERS_TEMP" "$OUTPUT_FILE"
    if [[ "$VERBOSE" == "1" ]]; then
        echo "Merged headers into $OUTPUT_FILE" >&2
    fi
fi

# Step 4: Generate SQLite database with headers (if CREATE_DB is set)
if [[ "${CREATE_DB:-0}" == "1" ]]; then
    DB_FILE="${OUTPUT_FILE%.json}.db"
    
    # Remove existing database to avoid constraint errors
    rm -f "$DB_FILE"
    
    # Create signatures database
    python3 "$PROJECT_ROOT/scripts/json_to_sqlite.py" signatures "$OUTPUT_FILE" "$DB_FILE"
    
    # Add header tables to database
    if [[ -s "$HEADERS_TEMP" ]]; then
        python3 "$PROJECT_ROOT/scripts/json_to_sqlite_headers.py" "$HEADERS_TEMP" "$DB_FILE"
        if [[ "$VERBOSE" == "1" ]]; then
            echo "Added header metadata to $DB_FILE" >&2
        fi
    fi
    
    if [[ "$VERBOSE" == "1" ]]; then
        echo "Generated $DB_FILE for fast querying" >&2
    fi
fi

if [[ "$VERBOSE" == "1" ]]; then
    echo "Complete! Generated $OUTPUT_FILE with header metadata" >&2
fi
