#!/usr/bin/env python3
"""Process module definitions and generate JSON."""

import json
import sys
import os

def normalize_path(path):
    """Normalize path to be relative with ./ prefix, resolving .. components."""
    # First, resolve any .. or . components
    path = os.path.normpath(path)
    
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

def main():
    if len(sys.argv) < 3:
        print("Usage: process_modules.py <temp_file> <output_file> <version> <timestamp> <total_files>", file=sys.stderr)
        sys.exit(1)
    
    temp_file = sys.argv[1]
    output_file = sys.argv[2]
    version = sys.argv[3] if len(sys.argv) > 3 else "1.0.0"
    timestamp = sys.argv[4] if len(sys.argv) > 4 else ""
    total_files = int(sys.argv[5]) if len(sys.argv) > 5 else 0
    
    modules = []
    
    try:
        with open(temp_file, 'r') as f:
            for line in f:
                line = line.strip()
                if not line or not line.startswith('{'):
                    continue
                
                try:
                    obj = json.loads(line)
                    # Normalize the file path
                    if 'file' in obj:
                        obj['file'] = normalize_path(obj['file'])
                    modules.append(obj)
                except json.JSONDecodeError:
                    continue
        
        output = {
            "_metadata": {
                "version": version,
                "generated": timestamp,
                "files_processed": total_files
            },
            "modules": modules
        }
        
        with open(output_file, 'w') as f:
            json.dump(output, f, indent=2)
        
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()
