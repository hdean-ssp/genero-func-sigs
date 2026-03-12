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

# Generate the unified index using Python
python3 << 'PYTHON_SCRIPT'
import json
import sys
from datetime import datetime

VERSION = "1.0.0"
WORKSPACE_FILE = "workspace.json"
MODULES_FILE = "modules.json"
OUTPUT_FILE = "codebase_index.json"
TIMESTAMP = sys.argv[1] if len(sys.argv) > 1 else datetime.utcnow().isoformat() + "Z"

try:
    with open(WORKSPACE_FILE, 'r') as f:
        workspace_data = json.load(f)
    with open(MODULES_FILE, 'r') as f:
        modules_data = json.load(f)
    
    # Remove metadata from workspace
    workspace_data.pop('_metadata', None)
    
    # Build files array with descriptive IDs
    files = {}
    for file_path, functions in workspace_data.items():
        filename = file_path.split('/')[-1].replace('.4gl', '').replace('.', '_')
        file_id = f"file_{filename}"
        files[file_id] = {
            "path": file_path,
            "type": "L4GLS" if "L4GLS" in file_path else ("U4GLS" if "U4GLS" in file_path else "4GLS"),
            "functions": functions
        }
    
    # Build modules with file ID references
    modules_indexed = []
    for module in modules_data.get('modules', []):
        module_entry = {
            "module": module.get('module'),
            "file": module.get('file'),
            "L4GLS": module.get('L4GLS', []),
            "U4GLS": module.get('U4GLS', []),
            "4GLS": module.get('4GLS', [])
        }
        modules_indexed.append(module_entry)
    
    # Build final output
    output = {
        "_metadata": {
            "version": VERSION,
            "generated": TIMESTAMP,
            "source_files": {
                "workspace": workspace_data.get('_metadata', {}),
                "modules": modules_data.get('_metadata', {})
            }
        },
        "files": files,
        "modules": modules_indexed
    }
    
    with open(OUTPUT_FILE, 'w') as f:
        json.dump(output, f, indent=2)
    
    print(f"Generated {OUTPUT_FILE} successfully", file=sys.stderr)
    print(f"Index contains {len(files)} files and {len(modules_indexed)} modules", file=sys.stderr)
    
except Exception as e:
    print(f"Error: Failed to generate codebase index: {e}", file=sys.stderr)
    sys.exit(1)
PYTHON_SCRIPT

