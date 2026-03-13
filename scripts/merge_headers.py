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
    
    Adds file_references and file_authors to each file's entry in the workspace.
    
    Args:
        workspace_file: Path to workspace.json with signatures
        headers_temp_file: Path to temp file with header data (one JSON per file)
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
    file_headers_map = {}
    
    try:
        with open(headers_temp_file, 'r') as f:
            for line in f:
                line = line.strip()
                if not line:
                    continue
                
                try:
                    data = json.loads(line)
                    filepath = data.get('file')
                    if filepath:
                        # Normalize path to match workspace.json format
                        normalized_path = normalize_path(filepath)
                        file_headers_map[normalized_path] = {
                            'file_references': data.get('file_references', []),
                            'file_authors': data.get('file_authors', [])
                        }
                except json.JSONDecodeError:
                    continue
    except Exception as e:
        print(f"Warning: Could not read headers file: {e}", file=sys.stderr)
        # Continue without headers if file doesn't exist
        pass
    
    # Merge headers into workspace
    # For each file in workspace, add its header metadata
    for filepath in workspace:
        if filepath.startswith('_'):
            # Skip metadata entries
            continue
        
        if filepath in file_headers_map:
            header_data = file_headers_map[filepath]
            # Add header metadata to each function in the file
            if isinstance(workspace[filepath], list):
                for func in workspace[filepath]:
                    func['file_references'] = header_data['file_references']
                    func['file_authors'] = header_data['file_authors']
    
    # Save merged workspace
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
