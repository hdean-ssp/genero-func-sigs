#!/bin/bash
# desc:
# a shell script to generate a unified codebase index by combining
# function signatures (workspace.json) and module dependencies (modules.json)
# into a single comprehensive index with file IDs and module references
#       -       -       -       -       -       -       -       -       -       -       -       -       -       -       -
#       12/03/2026              hdean           Initial
#       -       -       -       -       -       -       -       -       -       -       -       -       -       -       -

set -euo pipefail

# Configuration
VERSION="1.0.0"
VERBOSE="${VERBOSE:-0}"
WORKSPACE_FILE="${WORKSPACE_FILE:-workspace.json}"
MODULES_FILE="${MODULES_FILE:-modules.json}"
OUTPUT_FILE="${OUTPUT_FILE:-codebase_index.json}"

# Validate input files exist
if [[ ! -f "$WORKSPACE_FILE" ]]; then
    echo "Error: Workspace file '$WORKSPACE_FILE' not found" >&2
    echo "Please run: bash generate_signatures.sh <path>" >&2
    exit 1
fi

if [[ ! -f "$MODULES_FILE" ]]; then
    echo "Error: Modules file '$MODULES_FILE' not found" >&2
    echo "Please run: bash generate_modules.sh <path>" >&2
    exit 1
fi

if [[ "$VERBOSE" == "1" ]]; then
    echo "Reading workspace signatures from: $WORKSPACE_FILE" >&2
    echo "Reading module dependencies from: $MODULES_FILE" >&2
fi

# Generate timestamp in ISO 8601 format
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Generate the unified index using Python script
python3 scripts/process_codebase_index.py "$WORKSPACE_FILE" "$MODULES_FILE" "$OUTPUT_FILE" "$VERSION" "$TIMESTAMP" 2>&1 || {
    echo "Error: Failed to generate codebase index" >&2
    echo "Check that workspace.json and modules.json are valid JSON" >&2
    exit 1
}

if [[ "$VERBOSE" == "1" ]]; then
    echo "Generated $OUTPUT_FILE successfully" >&2
    FILE_COUNT=$(python3 -c "import json; data=json.load(open('$OUTPUT_FILE')); print(len(data.get('files', {})))")
    MODULE_COUNT=$(python3 -c "import json; data=json.load(open('$OUTPUT_FILE')); print(len(data.get('modules', [])))")
    echo "Index contains $FILE_COUNT files and $MODULE_COUNT modules" >&2
fi
