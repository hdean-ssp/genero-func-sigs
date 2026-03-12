#!/usr/bin/env python3
"""Query SQLite databases for signatures and modules."""

import sqlite3
import sys
import json
from pathlib import Path

def query_function(db_file, func_name):
    """Find a function by name."""
    conn = sqlite3.connect(db_file)
    conn.row_factory = sqlite3.Row
    c = conn.cursor()
    
    c.execute('''SELECT f.*, fi.path, fi.type FROM functions f
                 JOIN files fi ON f.file_id = fi.id
                 WHERE f.name = ?''', (func_name,))
    
    results = []
    for row in c.fetchall():
        result = dict(row)
        
        # Get parameters
        c.execute('SELECT name, type FROM parameters WHERE function_id = ?', (row['id'],))
        result['parameters'] = [dict(p) for p in c.fetchall()]
        
        # Get returns
        c.execute('SELECT name, type FROM returns WHERE function_id = ?', (row['id'],))
        result['returns'] = [dict(r) for r in c.fetchall()]
        
        results.append(result)
    
    conn.close()
    return results

def search_functions(db_file, pattern):
    """Search functions by name pattern."""
    conn = sqlite3.connect(db_file)
    conn.row_factory = sqlite3.Row
    c = conn.cursor()
    
    c.execute('''SELECT f.id, f.name, f.signature, fi.path FROM functions f
                 JOIN files fi ON f.file_id = fi.id
                 WHERE f.name LIKE ? LIMIT 100''', (f'%{pattern}%',))
    
    results = [dict(row) for row in c.fetchall()]
    conn.close()
    return results

def list_functions_in_file(db_file, file_path):
    """List all functions in a file."""
    conn = sqlite3.connect(db_file)
    conn.row_factory = sqlite3.Row
    c = conn.cursor()
    
    c.execute('''SELECT f.name, f.signature, f.line_start, f.line_end FROM functions f
                 JOIN files fi ON f.file_id = fi.id
                 WHERE fi.path = ?
                 ORDER BY f.line_start''', (file_path,))
    
    results = [dict(row) for row in c.fetchall()]
    conn.close()
    return results

def query_module(db_file, module_name):
    """Get module details."""
    conn = sqlite3.connect(db_file)
    conn.row_factory = sqlite3.Row
    c = conn.cursor()
    
    c.execute('SELECT * FROM modules WHERE name = ?', (module_name,))
    module = c.fetchone()
    
    if not module:
        conn.close()
        return None
    
    result = dict(module)
    
    # Get files by category
    c.execute('''SELECT file_name, category FROM module_files 
                 WHERE module_id = ? ORDER BY category, file_name''', (module['id'],))
    
    files_by_category = {'L4GLS': [], 'U4GLS': [], '4GLS': []}
    for row in c.fetchall():
        files_by_category[row['category']].append(row['file_name'])
    
    result['files'] = files_by_category
    conn.close()
    return result

def search_modules(db_file, pattern):
    """Search modules by name pattern."""
    conn = sqlite3.connect(db_file)
    conn.row_factory = sqlite3.Row
    c = conn.cursor()
    
    c.execute('SELECT name FROM modules WHERE name LIKE ? LIMIT 50', (f'%{pattern}%',))
    results = [row['name'] for row in c.fetchall()]
    conn.close()
    return results

def list_modules_for_file(db_file, file_name):
    """Find which modules use a specific file."""
    conn = sqlite3.connect(db_file)
    conn.row_factory = sqlite3.Row
    c = conn.cursor()
    
    c.execute('''SELECT DISTINCT m.name, mf.category FROM modules m
                 JOIN module_files mf ON m.id = mf.module_id
                 WHERE mf.file_name = ?
                 ORDER BY m.name''', (file_name,))
    
    results = [dict(row) for row in c.fetchall()]
    conn.close()
    return results

def list_modules_for_file(db_file, file_name):
    """Find which modules use a specific file."""
    conn = sqlite3.connect(db_file)
    conn.row_factory = sqlite3.Row
    c = conn.cursor()
    
    c.execute('''SELECT DISTINCT m.name, mf.category FROM modules m
                 JOIN module_files mf ON m.id = mf.module_id
                 WHERE mf.file_name = ?
                 ORDER BY m.name''', (file_name,))
    
    results = [dict(row) for row in c.fetchall()]
    conn.close()
    return results

def find_function_dependencies(db_file, func_name):
    """Find all functions called by a specific function."""
    conn = sqlite3.connect(db_file)
    conn.row_factory = sqlite3.Row
    c = conn.cursor()
    
    # First find the function
    c.execute('SELECT id FROM functions WHERE name = ?', (func_name,))
    func_row = c.fetchone()
    
    if not func_row:
        conn.close()
        return None
    
    # Get all calls made by this function
    c.execute('''SELECT called_function_name, line_number FROM calls
                 WHERE function_id = ?
                 ORDER BY line_number''', (func_row['id'],))
    
    results = [dict(row) for row in c.fetchall()]
    conn.close()
    return results

def find_function_dependents(db_file, func_name):
    """Find all functions that call a specific function."""
    conn = sqlite3.connect(db_file)
    conn.row_factory = sqlite3.Row
    c = conn.cursor()
    
    # Get all functions that call this function
    c.execute('''SELECT DISTINCT f.name, f.signature, fi.path, c.line_number
                 FROM calls c
                 JOIN functions f ON c.function_id = f.id
                 JOIN files fi ON f.file_id = fi.id
                 WHERE c.called_function_name = ?
                 ORDER BY f.name''', (func_name,))
    
    results = [dict(row) for row in c.fetchall()]
    conn.close()
    return results

def main():
    if len(sys.argv) < 3:
        print("Usage: query_db.py <command> <db_file> [args...]", file=sys.stderr)
        print("Commands:", file=sys.stderr)
        print("  find_function <name>                - Find function by exact name", file=sys.stderr)
        print("  search_functions <pattern>          - Search functions by name pattern", file=sys.stderr)
        print("  list_file_functions <path>          - List all functions in a file", file=sys.stderr)
        print("  find_module <name>                  - Find module by exact name", file=sys.stderr)
        print("  search_modules <pattern>            - Search modules by name pattern", file=sys.stderr)
        print("  list_file_modules <filename>        - Find modules using a file", file=sys.stderr)
        print("  find_function_dependencies <name>   - Find all functions called by a function", file=sys.stderr)
        print("  find_function_dependents <name>     - Find all functions that call a function", file=sys.stderr)
        sys.exit(1)
    
    command = sys.argv[1]
    db_file = sys.argv[2]
    
    if not Path(db_file).exists():
        print(f"Error: {db_file} not found", file=sys.stderr)
        sys.exit(1)
    
    try:
        if command == "find_function" and len(sys.argv) > 3:
            results = query_function(db_file, sys.argv[3])
            print(json.dumps(results, indent=2))
        
        elif command == "search_functions" and len(sys.argv) > 3:
            results = search_functions(db_file, sys.argv[3])
            print(json.dumps(results, indent=2))
        
        elif command == "list_file_functions" and len(sys.argv) > 3:
            results = list_functions_in_file(db_file, sys.argv[3])
            print(json.dumps(results, indent=2))
        
        elif command == "find_module" and len(sys.argv) > 3:
            result = query_module(db_file, sys.argv[3])
            if result:
                print(json.dumps(result, indent=2))
            else:
                print(f"Module '{sys.argv[3]}' not found", file=sys.stderr)
                sys.exit(1)
        
        elif command == "search_modules" and len(sys.argv) > 3:
            results = search_modules(db_file, sys.argv[3])
            for name in results:
                print(name)
        
        elif command == "list_file_modules" and len(sys.argv) > 3:
            results = list_modules_for_file(db_file, sys.argv[3])
            print(json.dumps(results, indent=2))
        
        elif command == "find_function_dependencies" and len(sys.argv) > 3:
            results = find_function_dependencies(db_file, sys.argv[3])
            if results is None:
                print(f"Function '{sys.argv[3]}' not found", file=sys.stderr)
                sys.exit(1)
            print(json.dumps(results, indent=2))
        
        elif command == "find_function_dependents" and len(sys.argv) > 3:
            results = find_function_dependents(db_file, sys.argv[3])
            print(json.dumps(results, indent=2))
        
        else:
            print(f"Error: Unknown command or missing arguments", file=sys.stderr)
            sys.exit(1)
    
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()
