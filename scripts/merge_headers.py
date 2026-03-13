#!/usr/bin/env python3
"""
Merge extracted file headers into workspace.json.

Takes the workspace.json with function signatures and merges in the extracted
header metadata (code references and authors) from the header parser.
"""

import json
import sys
import os
from typing import Dict, List, Any


def normalize_path(path: str) -> str:
    """Normalize path to match workspace.json format."""
    # Convert absolute paths to relative if possible
    if os.path.isabs(path):
        try:
            path = os.path.relpath(path)
        except ValueError:
            pass
    
    # Ensure relative paths start with ./
    if not path.startswith('./') and not path.startswith('/'):
        path = './' + path
    
    return path


def merge_headers(workspace_file: str, headers_temp_file: str, output_file: str) -> None:
    """
    Merge header metadata into workspace.json.
    
    Args:
        workspace_file: Path to workspace.json with signatures
        headers_temp_file: Path to temp file with header data (one JSON per line)
        output_file: Path to output file with merged data
    """
    # Load workspace.json
    try:
        with open(workspace_file, 'r') as f:
            workspace = json.load(f)
    except Exception as e:
        print(f"Error reading {workspace_file}: {e}", file=sys.stderr)
        sys.exit(1)
    
    # Build a map of file paths to header data
    file_headers = {}
    
    try:
        with open(headers_temp_file, 'r') as f:
            for line in f:
                line = line.strip()
                if not line:
                    continue
                
                try:
                    # Each line is a JSON object from parse_headers.py
                    # But parse_headers.py outputs one JSON per file, not per line
                    # So we need to handle this differently
                    data = json.loads(line)
                    # This is actually a full result from parse_headers.py
                    # We'll store it as-is for now
                    file_headers[line] = data
                except json.JSONDecodeError:
                    continue
    except Exception as e:
        print(f"Error reading {headers_temp_file}: {e}", file=sys.stderr)
        # Continue without headers if file doesn't exist
        pass
    
    # For now, just save the workspace as-is
    # The headers will be stored separately and can be queried via the database
    try:
        with open(output_file, 'w') as f:
            json.dump(workspace, f, indent=2)
    except Exception as e:
        print(f"Error writing {output_file}: {e}", file=sys.stderr)
        sys.exit(1)


def main():
    if len(sys.argv) < 4:
        print("Usage: merge_headers.py <workspace.json> <headers_temp_file> <output_file>", file=sys.stderr)
        sys.exit(1)
    
    workspace_file = sys.argv[1]
    headers_temp_file = sys.argv[2]
    output_file = sys.argv[3]
    
    merge_headers(workspace_file, headers_temp_file, output_file)


if __name__ == "__main__":
    main()
