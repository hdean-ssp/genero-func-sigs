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

# Build the unified index with jq
jq -n \
  --arg version "$VERSION" \
  --arg timestamp "$TIMESTAMP" \
  --slurpfile workspace "$WORKSPACE_FILE" \
  --slurpfile modules "$MODULES_FILE" \
  '
  # Extract workspace data (without metadata)
  ($workspace[0] | del(._metadata)) as $workspace_data |
  
  # Build files array with sequential IDs
  (
    [$workspace_data | to_entries | to_entries[] | 
      {
        id: "file_\((.key + 1 | tostring | "00\(.)" | .[-3:]))",
        path: .value.key,
        type: (if .value.key | contains("L4GLS") then "L4GLS" elif .value.key | contains("U4GLS") then "U4GLS" else "4GLS" end),
        functions: .value.value
      }
    ]
  ) as $files |
  
  # Build modules with file ID references
  (
    $modules[0].modules | map(
      . as $module |
      {
        module: .module,
        file: .file,
        L4GLS: (
          .L4GLS | map(
            . as $filename |
            ($files | map(select(.path | endswith($filename))) | .[0].id // empty)
          )
        ),
        U4GLS: (
          .U4GLS | map(
            . as $filename |
            ($files | map(select(.path | endswith($filename))) | .[0].id // empty)
          )
        ),
        "4GLS": (
          ."4GLS" | map(
            . as $filename |
            ($files | map(select(.path | endswith($filename))) | .[0].id // empty)
          )
        )
      }
    )
  ) as $modules_indexed |
  
  # Build final output
  {
    "_metadata": {
      "version": $version,
      "generated": $timestamp,
      "source_files": {
        "workspace": $workspace[0]._metadata,
        "modules": $modules[0]._metadata
      }
    },
    "files": ($files | map({(.id): {path: .path, type: .type, functions: .functions}}) | add),
    "modules": $modules_indexed
  }
  ' | jq '.' > "$OUTPUT_FILE"

if [[ "$VERBOSE" == "1" ]]; then
    echo "Generated $OUTPUT_FILE successfully" >&2
    FILE_COUNT=$(jq '.files | length' "$OUTPUT_FILE")
    MODULE_COUNT=$(jq '.modules | length' "$OUTPUT_FILE")
    echo "Index contains $FILE_COUNT files and $MODULE_COUNT modules" >&2
fi
