#!/usr/bin/env python3
"""Generate unified codebase index from workspace and modules."""

import json
import sys

def main():
    if len(sys.argv) < 4:
        print("Usage: process_codebase_index.py <workspace_file> <modules_file> <output_file> <version> <timestamp>", file=sys.stderr)
        sys.exit(1)
    
    workspace_file = sys.argv[1]
    modules_file = sys.argv[2]
    output_file = sys.argv[3]
    version = sys.argv[4] if len(sys.argv) > 4 else "1.0.0"
    timestamp = sys.argv[5] if len(sys.argv) > 5 else ""
    
    try:
        with open(workspace_file, 'r') as f:
            workspace_data = json.load(f)
        with open(modules_file, 'r') as f:
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
                "version": version,
                "generated": timestamp,
                "source_files": {
                    "workspace": workspace_data.get('_metadata', {}),
                    "modules": modules_data.get('_metadata', {})
                }
            },
            "files": files,
            "modules": modules_indexed
        }
        
        with open(output_file, 'w') as f:
            json.dump(output, f, indent=2)
        
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()
