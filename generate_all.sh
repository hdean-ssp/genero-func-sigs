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

# Step 1: Generate function signatures
if [[ $GL4_COUNT -gt 0 ]]; then
    log_step "Generating function signatures from .4gl files..."
    if ! bash generate_signatures.sh "$TARGET" 2>&1 | tee /tmp/gen_sig_output.log; then
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

# Step 2: Generate module dependencies
if [[ $M3_COUNT -gt 0 ]]; then
    log_step "Generating module dependencies from .m3 files..."
    if bash generate_modules.sh "$TARGET"; then
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
    if bash generate_codebase_index.sh; then
        log_success "Codebase index generated (codebase_index.json)"
    else
        log_error "Failed to generate codebase index"
        exit 1
    fi
else
    log_info "Skipping codebase index generation (requires both .4gl and .m3 files)"
fi

echo ""

# Summary
log_success "All generators completed successfully!"
echo ""
log_info "Generated files:"
[[ $GL4_COUNT -gt 0 ]] && log_info "  - workspace.json (function signatures)"
[[ $M3_COUNT -gt 0 ]] && log_info "  - modules.json (module dependencies)"
[[ $GL4_COUNT -gt 0 && $M3_COUNT -gt 0 ]] && log_info "  - codebase_index.json (unified index)"
echo ""
log_info "Summary:"
log_info "  - $GL4_COUNT .4gl files processed"
log_info "  - $M3_COUNT .m3 files processed"
