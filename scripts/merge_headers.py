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
    # We need to handle both relative and absolute paths
    file_headers_map = {}
    
    try:
        if os.path.exists(headers_temp_file) and os.path.getsize(headers_temp_file) > 0:
            with open(headers_temp_file, 'r') as f:
                for line in f:
                    line = line.strip()
                    if not line:
                        continue
                    
                    try:
                        data = json.loads(line)
                        filepath = data.get('file')
                        if filepath:
                            # Store both the original path and normalized versions
                            # to handle matching with workspace.json paths
                            file_headers_map[filepath] = {
                                'file_references': data.get('file_references', []),
                                'file_authors': data.get('file_authors', [])
                            }
                            
                            # Also store normalized version
                            normalized_path = normalize_path(filepath)
                            file_headers_map[normalized_path] = file_headers_map[filepath]
                    except json.JSONDecodeError:
                        # Skip malformed JSON lines
                        continue
    except Exception as e:
        # Continue without headers if file doesn't exist or can't be read
        pass
    
    # Merge headers into workspace
    # For each file in workspace, add its header metadata
    for filepath in workspace:
        if filepath.startswith('_'):
            # Skip metadata entries
            continue
        
        # Try to find matching header data
        header_data = None
        
        # First try exact match
        if filepath in file_headers_map:
            header_data = file_headers_map[filepath]
        else:
            # Try to match by comparing the relative path components
            # workspace paths are like: ./tests/sample_codebase/simple_functions.4gl
            # header paths are like: simple_functions.4gl or ./lib/complex_types.4gl
            
            for header_path, data in file_headers_map.items():
                # Normalize both paths for comparison
                ws_normalized = filepath.lstrip('./')
                hdr_normalized = header_path.lstrip('./')
                
                # Check if header path is a suffix of workspace path
                # This handles both root files and subdirectory files
                if ws_normalized.endswith(hdr_normalized):
                    # Verify it's a proper path boundary (not partial filename match)
                    # e.g., "complex_types.4gl" should match "lib/complex_types.4gl"
                    # but not "my_complex_types.4gl"
                    if len(ws_normalized) == len(hdr_normalized) or \
                       ws_normalized[-(len(hdr_normalized)+1)] == os.sep:
                        header_data = data
                        break
        
        if header_data:
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
