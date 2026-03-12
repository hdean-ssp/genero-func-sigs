#!/usr/bin/env python3
"""Utilities for testing JSON output."""

import json
import sys
import re

def sort_signatures(input_file, output_file):
    """Sort signatures JSON by file and function name."""
    with open(input_file, 'r') as f:
        data = json.load(f)
    
    data.pop('_metadata', None)
    sorted_data = {}
    for key in sorted(data.keys()):
        sorted_data[key] = sorted(data[key], key=lambda x: x.get('name', ''))
    
    with open(output_file, 'w') as f:
        json.dump(sorted_data, f, sort_keys=True, indent=2)

def sort_modules(input_file, output_file):
    """Sort modules JSON by module name."""
    with open(input_file, 'r') as f:
        data = json.load(f)
    
    data.pop('_metadata', None)
    if 'modules' in data:
        data['modules'] = sorted(data['modules'], key=lambda x: x.get('module', ''))
    
    with open(output_file, 'w') as f:
        json.dump(data, f, sort_keys=True, indent=2)

def check_metadata(json_file):
    """Check if metadata structure is valid."""
    with open(json_file, 'r') as f:
        data = json.load(f)
    
    if '_metadata' not in data:
        return False, "Metadata is missing"
    
    metadata = data['_metadata']
    required_keys = ['version', 'generated', 'files_processed']
    if not all(k in metadata for k in required_keys):
        return False, "Metadata structure is incomplete"
    
    return True, metadata['files_processed']

def check_signatures_format(json_file):
    """Check if all signatures have valid format."""
    with open(json_file, 'r') as f:
        data = json.load(f)
    
    data.pop('_metadata', None)
    invalid_sigs = []
    
    for file_funcs in data.values():
        for func in file_funcs:
            sig = func.get('signature', '')
            if not re.match(r'^\d+-\d+: [a-zA-Z_][a-zA-Z0-9_]*\(', sig):
                invalid_sigs.append(sig)
    
    return len(invalid_sigs) == 0, invalid_sigs

def count_functions(json_file):
    """Count total functions in signatures file."""
    with open(json_file, 'r') as f:
        data = json.load(f)
    
    data.pop('_metadata', None)
    return sum(len(funcs) for funcs in data.values())

def count_modules(json_file):
    """Count total modules in modules file."""
    with open(json_file, 'r') as f:
        data = json.load(f)
    
    return len(data.get('modules', []))

def get_module(json_file, module_name):
    """Get a specific module by name."""
    with open(json_file, 'r') as f:
        data = json.load(f)
    
    for module in data.get('modules', []):
        if module.get('module') == module_name:
            return module
    
    return None

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: test_utils.py <command> [args...]", file=sys.stderr)
        sys.exit(1)
    
    command = sys.argv[1]
    
    if command == "sort_signatures":
        if len(sys.argv) < 4:
            print("Usage: test_utils.py sort_signatures <input> <output>", file=sys.stderr)
            sys.exit(1)
        sort_signatures(sys.argv[2], sys.argv[3])
    
    elif command == "sort_modules":
        if len(sys.argv) < 4:
            print("Usage: test_utils.py sort_modules <input> <output>", file=sys.stderr)
            sys.exit(1)
        sort_modules(sys.argv[2], sys.argv[3])
    
    elif command == "check_metadata":
        if len(sys.argv) < 3:
            print("Usage: test_utils.py check_metadata <file>", file=sys.stderr)
            sys.exit(1)
        valid, result = check_metadata(sys.argv[2])
        if valid:
            print(result)
            sys.exit(0)
        else:
            print(result, file=sys.stderr)
            sys.exit(1)
    
    elif command == "check_signatures_format":
        if len(sys.argv) < 3:
            print("Usage: test_utils.py check_signatures_format <file>", file=sys.stderr)
            sys.exit(1)
        valid, invalid = check_signatures_format(sys.argv[2])
        if valid:
            print("All signatures valid")
            sys.exit(0)
        else:
            for sig in invalid:
                print(sig, file=sys.stderr)
            sys.exit(1)
    
    elif command == "count_functions":
        if len(sys.argv) < 3:
            print("Usage: test_utils.py count_functions <file>", file=sys.stderr)
            sys.exit(1)
        print(count_functions(sys.argv[2]))
    
    elif command == "count_modules":
        if len(sys.argv) < 3:
            print("Usage: test_utils.py count_modules <file>", file=sys.stderr)
            sys.exit(1)
        print(count_modules(sys.argv[2]))
    
    elif command == "get_module":
        if len(sys.argv) < 4:
            print("Usage: test_utils.py get_module <file> <module_name>", file=sys.stderr)
            sys.exit(1)
        module = get_module(sys.argv[2], sys.argv[3])
        if module:
            print(json.dumps(module))
            sys.exit(0)
        else:
            print(f"Module {sys.argv[3]} not found", file=sys.stderr)
            sys.exit(1)
    
    else:
        print(f"Unknown command: {command}", file=sys.stderr)
        sys.exit(1)
