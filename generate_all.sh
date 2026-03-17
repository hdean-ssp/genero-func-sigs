#!/bin/bash
# desc:
# central orchestration script to generate all codebase indexes
# runs generate_signatures.sh, generate_modules.sh, and generate_codebase_index.sh
# in sequence to produce a complete codebase analysis
#       -       -       -       -       -       -       -       -       -       -       -       -       -       -       -
#       12/03/2026              hdean           Initial
#       -       -       -       -       -       -       -       -       -       -       -       -       -       -       -

set -euo pipefail

# Configuration
VERSION="1.0.0"
VERBOSE="${VERBOSE:-0}"
TARGET="${1:-.}"
SCHEMA_FILE="${2:-}"  # Optional schema file parameter

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
log_info() {
    if [[ "$VERBOSE" == "1" ]]; then
        echo -e "${BLUE}[INFO]${NC} $1" >&2
    fi
}

log_success() {
    echo -e "${GREEN}[✓]${NC} $1" >&2
}

log_error() {
    echo -e "${RED}[✗]${NC} $1" >&2
}

log_step() {
    echo -e "${YELLOW}[STEP]${NC} $1" >&2
}

# Validate target directory
if [[ ! -d "$TARGET" ]]; then
    log_error "Target directory '$TARGET' does not exist"
    exit 1
fi

# Check if there are any .4gl or .m3 files
GL4_COUNT=$(find "$TARGET" -name "*.4gl" -type f | wc -l)
M3_COUNT=$(find "$TARGET" -name "*.m3" -type f | wc -l)

if [[ $GL4_COUNT -eq 0 && $M3_COUNT -eq 0 ]]; then
    log_error "No .4gl or .m3 files found in '$TARGET'"
    exit 1
fi

log_info "Target directory: $TARGET"
log_info "Found $GL4_COUNT .4gl files and $M3_COUNT .m3 files"

# Find schema file if not provided
if [[ -z "$SCHEMA_FILE" ]]; then
    # Look for .sch files in the target directory
    SCHEMA_FILES=$(find "$TARGET" -name "*.sch" -type f)
    SCHEMA_COUNT=$(echo "$SCHEMA_FILES" | grep -c . || true)
    
    if [[ $SCHEMA_COUNT -gt 0 ]]; then
        # Use the first schema file found
        SCHEMA_FILE=$(echo "$SCHEMA_FILES" | head -1)
        log_info "Found schema file: $SCHEMA_FILE"
    else
        log_info "No schema file found in target directory (type resolution will be skipped)"
    fi
else
    # Validate provided schema file
    if [[ ! -f "$SCHEMA_FILE" ]]; then
        log_error "Schema file not found: $SCHEMA_FILE"
        exit 1
    fi
    log_info "Using provided schema file: $SCHEMA_FILE"
fi

echo ""

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Step 1: Generate function signatures
if [[ $GL4_COUNT -gt 0 ]]; then
    log_step "Generating function signatures from .4gl files..."
    if ! bash "$SCRIPT_DIR/src/generate_signatures.sh" "$TARGET" 2>&1 | tee /tmp/gen_sig_output.log; then
        log_error "Failed to generate function signatures"
        log_error "Last output:"
        tail -20 /tmp/gen_sig_output.log >&2
        exit 1
    fi
    log_success "Function signatures generated (workspace.json)"
else
    log_info "Skipping function signature generation (no .4gl files found)"
fi

echo ""

# Step 1b: Extract file headers and merge
if [[ $GL4_COUNT -gt 0 ]]; then
    log_step "Extracting file headers and code references..."
    
    # Create temp file for headers
    HEADERS_TEMP=$(mktemp)
    trap 'rm -f "$HEADERS_TEMP"' EXIT
    
    # Process all .4gl files to extract headers
    # Continue even if some files fail to parse
    find "$TARGET" -name "*.4gl" -type f -print0 | while IFS= read -r -d '' file; do
        python3 "$SCRIPT_DIR/scripts/parse_headers.py" "$file" "$TARGET" >> "$HEADERS_TEMP" 2>/dev/null || true
    done
    
    # Merge headers into workspace.json (only if we have headers)
    if [[ -s "$HEADERS_TEMP" ]]; then
        if python3 "$SCRIPT_DIR/scripts/merge_headers.py" workspace.json "$HEADERS_TEMP" workspace.json 2>/dev/null; then
            log_success "File headers extracted and merged"
        else
            log_info "Some headers could not be merged (continuing)"
        fi
    else
        log_info "No headers found to extract (some or all files may not have modification sections)"
    fi
fi

echo ""

# Step 2: Generate module dependencies
if [[ $M3_COUNT -gt 0 ]]; then
    log_step "Generating module dependencies from .m3 files..."
    if bash "$SCRIPT_DIR/src/generate_modules.sh" "$TARGET"; then
        log_success "Module dependencies generated (modules.json)"
    else
        log_error "Failed to generate module dependencies"
        exit 1
    fi
else
    log_info "Skipping module dependency generation (no .m3 files found)"
fi

echo ""

# Step 3: Create SQLite databases for fast querying
log_step "Creating SQLite databases for fast querying..."

# Remove old databases to avoid constraint errors
rm -f workspace.db modules.db

if [[ $GL4_COUNT -gt 0 ]]; then
    log_info "Creating workspace.db from workspace.json..."
    python3 "$SCRIPT_DIR/scripts/json_to_sqlite.py" signatures workspace.json workspace.db
    log_success "workspace.db created"
    
    # Add header tables to database (continue even if this fails)
    HEADERS_TEMP=$(mktemp)
    trap 'rm -f "$HEADERS_TEMP"' EXIT
    
    find "$TARGET" -name "*.4gl" -type f -print0 | while IFS= read -r -d '' file; do
        python3 "$SCRIPT_DIR/scripts/parse_headers.py" "$file" "$TARGET" >> "$HEADERS_TEMP" 2>/dev/null || true
    done
    
    if [[ -s "$HEADERS_TEMP" ]]; then
        if python3 "$SCRIPT_DIR/scripts/json_to_sqlite_headers.py" "$HEADERS_TEMP" workspace.db 2>/dev/null; then
            log_success "Header metadata added to workspace.db"
        else
            log_info "Some header metadata could not be added (continuing)"
        fi
    else
        log_info "No header metadata to add"
    fi
fi

if [[ $M3_COUNT -gt 0 ]]; then
    log_info "Creating modules.db from modules.json..."
    python3 "$SCRIPT_DIR/scripts/json_to_sqlite.py" modules modules.json modules.db
    log_success "modules.db created"
fi

echo ""

# Step 4: Parse and load schema if available
if [[ -n "$SCHEMA_FILE" && -f "$SCHEMA_FILE" ]]; then
    log_step "Parsing schema file and loading into database..."
    
    # Create temp files for schema JSON and output
    SCHEMA_JSON=$(mktemp)
    PARSE_OUTPUT=$(mktemp)
    trap 'rm -f "$SCHEMA_JSON" "$PARSE_OUTPUT"' EXIT
    
    # Parse schema file (capture both stdout and stderr)
    if python3 "$SCRIPT_DIR/scripts/parse_schema.py" "$SCHEMA_FILE" "$SCHEMA_JSON" >"$PARSE_OUTPUT" 2>&1; then
        # Show the output (which includes success messages)
        cat "$PARSE_OUTPUT" >&2
        log_success "Schema parsed: $SCHEMA_FILE"
        
        # Load schema into workspace.db
        LOAD_OUTPUT=$(mktemp)
        trap 'rm -f "$LOAD_OUTPUT"' EXIT
        
        if python3 "$SCRIPT_DIR/scripts/json_to_sqlite_schema.py" "$SCHEMA_JSON" workspace.db >"$LOAD_OUTPUT" 2>&1; then
            cat "$LOAD_OUTPUT" >&2
            log_success "Schema loaded into workspace.db"
            
            # Enable type resolution for subsequent steps
            export RESOLVE_TYPES=1
            log_info "Type resolution enabled"
        else
            log_info "Could not load schema into database (type resolution will be skipped)"
            echo -e "${BLUE}[INFO]${NC} Error details:" >&2
            cat "$LOAD_OUTPUT" | sed 's/^/  /' >&2
        fi
    else
        log_info "Could not parse schema file (type resolution will be skipped)"
        echo -e "${BLUE}[INFO]${NC} Error details:" >&2
        cat "$PARSE_OUTPUT" | sed 's/^/  /' >&2
    fi
else
    log_info "No schema file available (type resolution will be skipped)"
fi

echo ""

# Step 5: Generate resolved types if schema was loaded
if [[ "${RESOLVE_TYPES:-0}" == "1" ]]; then
    log_step "Generating type-resolved signatures..."
    
    if python3 "$SCRIPT_DIR/scripts/resolve_types.py" workspace.db workspace.json workspace_resolved.json 2>/dev/null; then
        log_success "Type-resolved signatures generated (workspace_resolved.json)"
        
        # Merge resolved types back into database for fast querying
        if python3 "$SCRIPT_DIR/scripts/merge_resolved_types.py" workspace_resolved.json workspace.db 2>/dev/null; then
            log_success "Resolved types merged into workspace.db"
        else
            log_info "Could not merge resolved types into database (JSON queries still available)"
        fi
    else
        log_info "Could not generate type-resolved signatures (continuing)"
    fi
fi

echo ""
log_success "All generators completed successfully!"
echo ""
log_info "Generated files:"
[[ $GL4_COUNT -gt 0 ]] && log_info "  - workspace.json (function signatures with headers)"
[[ $GL4_COUNT -gt 0 ]] && log_info "  - workspace.db (SQLite database with signatures and headers)"
[[ -n "$SCHEMA_FILE" && -f "$SCHEMA_FILE" ]] && log_info "  - workspace_resolved.json (signatures with resolved types)"
[[ $M3_COUNT -gt 0 ]] && log_info "  - modules.json (module dependencies)"
[[ $M3_COUNT -gt 0 ]] && log_info "  - modules.db (SQLite database for fast queries)"
echo ""
log_info "Summary:"
log_info "  - $GL4_COUNT .4gl files processed"
log_info "  - $M3_COUNT .m3 files processed"
[[ -n "$SCHEMA_FILE" && -f "$SCHEMA_FILE" ]] && log_info "  - Schema file processed: $SCHEMA_FILE"
echo ""
log_info "To query the generated databases:"
log_info "  bash query.sh find-function <name>"
log_info "  bash query.sh search-functions <pattern>"
log_info "  bash query.sh find-reference <ref>"
log_info "  bash query.sh find-author <author>"
log_info "  bash query.sh author-expertise <author>"
log_info "  bash query.sh find-module <name>"
log_info "See QUERYING.md and docs/HEADER_PARSING_IMPLEMENTATION.md for more examples"
