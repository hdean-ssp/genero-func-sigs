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
    find "$TARGET" -name "*.4gl" -type f -print0 | while IFS= read -r -d '' file; do
        python3 "$SCRIPT_DIR/scripts/parse_headers.py" "$file" >> "$HEADERS_TEMP" 2>/dev/null || true
    done
    
    # Merge headers into workspace.json
    if [[ -s "$HEADERS_TEMP" ]]; then
        python3 "$SCRIPT_DIR/scripts/merge_headers.py" workspace.json "$HEADERS_TEMP" workspace.json
        log_success "File headers extracted and merged"
    else
        log_info "No headers found to extract"
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

# Step 3: Generate unified codebase index
if [[ $GL4_COUNT -gt 0 && $M3_COUNT -gt 0 ]]; then
    log_step "Generating unified codebase index..."
    if bash "$SCRIPT_DIR/src/generate_codebase_index.sh"; then
        log_success "Codebase index generated (codebase_index.json)"
    else
        log_error "Failed to generate codebase index"
        exit 1
    fi
else
    log_info "Skipping codebase index generation (requires both .4gl and .m3 files)"
fi

echo ""

# Step 4: Create SQLite databases for fast querying
log_step "Creating SQLite databases for fast querying..."

# Remove old databases to avoid constraint errors
rm -f workspace.db modules.db

if [[ $GL4_COUNT -gt 0 ]]; then
    log_info "Creating workspace.db from workspace.json..."
    python3 "$SCRIPT_DIR/scripts/json_to_sqlite.py" signatures workspace.json workspace.db
    log_success "workspace.db created"
    
    # Add header tables to database
    HEADERS_TEMP=$(mktemp)
    trap 'rm -f "$HEADERS_TEMP"' EXIT
    
    find "$TARGET" -name "*.4gl" -type f -print0 | while IFS= read -r -d '' file; do
        python3 "$SCRIPT_DIR/scripts/parse_headers.py" "$file" >> "$HEADERS_TEMP" 2>/dev/null || true
    done
    
    if [[ -s "$HEADERS_TEMP" ]]; then
        python3 "$SCRIPT_DIR/scripts/json_to_sqlite_headers.py" "$HEADERS_TEMP" workspace.db
        log_success "Header metadata added to workspace.db"
    fi
fi

if [[ $M3_COUNT -gt 0 ]]; then
    log_info "Creating modules.db from modules.json..."
    python3 "$SCRIPT_DIR/scripts/json_to_sqlite.py" modules modules.json modules.db
    log_success "modules.db created"
fi

echo ""
log_success "All generators completed successfully!"
echo ""
log_info "Generated files:"
[[ $GL4_COUNT -gt 0 ]] && log_info "  - workspace.json (function signatures with headers)"
[[ $GL4_COUNT -gt 0 ]] && log_info "  - workspace.db (SQLite database with signatures and headers)"
[[ $M3_COUNT -gt 0 ]] && log_info "  - modules.json (module dependencies)"
[[ $M3_COUNT -gt 0 ]] && log_info "  - modules.db (SQLite database for fast queries)"
[[ $GL4_COUNT -gt 0 && $M3_COUNT -gt 0 ]] && log_info "  - codebase_index.json (unified index)"
echo ""
log_info "Summary:"
log_info "  - $GL4_COUNT .4gl files processed"
log_info "  - $M3_COUNT .m3 files processed"
echo ""
log_info "To query the generated databases:"
log_info "  bash query.sh find-function <name>"
log_info "  bash query.sh search-functions <pattern>"
log_info "  bash query.sh find-reference <ref>"
log_info "  bash query.sh find-author <author>"
log_info "  bash query.sh author-expertise <author>"
log_info "  bash query.sh find-module <name>"
log_info "See QUERYING.md and docs/HEADER_PARSING_IMPLEMENTATION.md for more examples"
