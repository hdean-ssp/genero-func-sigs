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
        
        # Get parameters with resolved type information
        c.execute('''SELECT name, type, actual_type, is_like_reference, resolved, 
                            resolution_error, table_name, columns, types 
                     FROM parameters WHERE function_id = ?''', (row['id'],))
        result['parameters'] = []
        for p in c.fetchall():
            param = dict(p)
            # Parse JSON fields if present
            if param['types']:
                try:
                    param['types'] = json.loads(param['types'])
                except (json.JSONDecodeError, TypeError):
                    pass
            if param['columns']:
                param['columns'] = param['columns'].split(',')
            result['parameters'].append(param)
        
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

def find_functions_in_module(modules_db, signatures_db, module_name):
    """Find all functions in a specific module."""
    # Get files in module from modules.db
    conn_mod = sqlite3.connect(modules_db)
    conn_mod.row_factory = sqlite3.Row
    c_mod = conn_mod.cursor()
    
    c_mod.execute('SELECT id FROM modules WHERE name = ?', (module_name,))
    module_row = c_mod.fetchone()
    
    if not module_row:
        conn_mod.close()
        return None
    
    # Get all files in this module
    c_mod.execute('''SELECT file_name FROM module_files WHERE module_id = ?''', (module_row['id'],))
    files = [row['file_name'] for row in c_mod.fetchall()]
    conn_mod.close()
    
    if not files:
        return []
    
    # Query functions from those files in workspace.db
    conn_sig = sqlite3.connect(signatures_db)
    conn_sig.row_factory = sqlite3.Row
    c_sig = conn_sig.cursor()
    
    results = []
    for file_name in files:
        # Match by filename ending (e.g., "main.4gl" matches "./path/to/main.4gl")
        c_sig.execute('''SELECT f.name, f.signature, f.line_start, f.line_end, fi.path
                         FROM functions f
                         JOIN files fi ON f.file_id = fi.id
                         WHERE fi.path LIKE ? OR fi.path LIKE ?
                         ORDER BY f.line_start''', (f'%/{file_name}', f'%\\{file_name}'))
        results.extend([dict(row) for row in c_sig.fetchall()])
    
    conn_sig.close()
    return results

def find_module_for_function(modules_db, signatures_db, func_name):
    """Find which module(s) contain a specific function."""
    # First find the function in workspace.db
    conn_sig = sqlite3.connect(signatures_db)
    conn_sig.row_factory = sqlite3.Row
    c_sig = conn_sig.cursor()
    
    c_sig.execute('SELECT id FROM functions WHERE name = ?', (func_name,))
    func_row = c_sig.fetchone()
    
    if not func_row:
        conn_sig.close()
        return None
    
    # Get the file path
    c_sig.execute('''SELECT fi.path FROM functions f
                     JOIN files fi ON f.file_id = fi.id
                     WHERE f.id = ?''', (func_row['id'],))
    file_row = c_sig.fetchone()
    conn_sig.close()
    
    if not file_row:
        return []
    
    file_path = file_row['path']
    file_name = file_path.split('/')[-1]
    
    # Find modules using this file
    conn_mod = sqlite3.connect(modules_db)
    conn_mod.row_factory = sqlite3.Row
    c_mod = conn_mod.cursor()
    
    c_mod.execute('''SELECT DISTINCT m.name, mf.category FROM modules m
                     JOIN module_files mf ON m.id = mf.module_id
                     WHERE mf.file_name LIKE ?
                     ORDER BY m.name''', (f'%{file_name}%',))
    
    results = [dict(row) for row in c_mod.fetchall()]
    conn_mod.close()
    return results

def find_functions_calling_in_module(modules_db, signatures_db, module_name, called_func):
    """Find functions in a module that call a specific function."""
    # Get all functions in the module
    functions_in_module = find_functions_in_module(modules_db, signatures_db, module_name)
    
    if functions_in_module is None:
        return None
    
    if not functions_in_module:
        return []
    
    # For each function, check if it calls the target function
    conn_sig = sqlite3.connect(signatures_db)
    conn_sig.row_factory = sqlite3.Row
    c_sig = conn_sig.cursor()
    
    results = []
    for func in functions_in_module:
        c_sig.execute('''SELECT c.called_function_name, c.line_number FROM calls c
                         JOIN functions f ON c.function_id = f.id
                         WHERE f.name = ? AND c.called_function_name = ?''',
                     (func['name'], called_func))
        calls = c_sig.fetchall()
        
        if calls:
            func_result = dict(func)
            func_result['calls'] = [dict(call) for call in calls]
            results.append(func_result)
    
    conn_sig.close()
    return results

def find_functions_using_table(db_file, table_name):
    """Find all functions that use a specific database table via LIKE references."""
    conn = sqlite3.connect(db_file)
    conn.row_factory = sqlite3.Row
    c = conn.cursor()
    
    try:
        c.execute('''SELECT DISTINCT f.name, f.file_id, fi.path
                     FROM functions f
                     JOIN files fi ON f.file_id = fi.id
                     JOIN parameters p ON f.id = p.function_id
                     WHERE p.table_name = ?
                     ORDER BY f.name''', (table_name,))
        
        results = []
        for row in c.fetchall():
            results.append({
                'name': row['name'],
                'file': row['path'],
                'table': table_name
            })
        
        conn.close()
        return results
    except Exception as e:
        conn.close()
        raise e


def find_tables_used_by_function(db_file, func_name):
    """Find all database tables used by a function via LIKE references."""
    conn = sqlite3.connect(db_file)
    conn.row_factory = sqlite3.Row
    c = conn.cursor()
    
    try:
        c.execute('''SELECT DISTINCT p.table_name
                     FROM functions f
                     JOIN parameters p ON f.id = p.function_id
                     WHERE f.name = ? AND p.table_name IS NOT NULL
                     ORDER BY p.table_name''', (func_name,))
        
        results = []
        for row in c.fetchall():
            results.append(row['table_name'])
        
        conn.close()
        return results
    except Exception as e:
        conn.close()
        raise e


def find_unresolved_like_references(db_file):
    """Find all unresolved LIKE references in the codebase."""
    conn = sqlite3.connect(db_file)
    conn.row_factory = sqlite3.Row
    c = conn.cursor()
    
    try:
        c.execute('''SELECT f.name, f.file_id, fi.path, p.name as param_name, p.type
                     FROM functions f
                     JOIN files fi ON f.file_id = fi.id
                     JOIN parameters p ON f.id = p.function_id
                     WHERE p.is_like_reference = 1 AND p.resolved = 0
                     ORDER BY f.name, p.name''')
        
        results = []
        for row in c.fetchall():
            results.append({
                'function': row['name'],
                'file': row['path'],
                'parameter': row['param_name'],
                'type': row['type']
            })
        
        conn.close()
        return results
    except Exception as e:
        conn.close()
        return []


def get_resolved_type_info(db_file, func_name, param_name):
    """Get resolved type information for a function parameter."""
    conn = sqlite3.connect(db_file)
    conn.row_factory = sqlite3.Row
    c = conn.cursor()
    
    try:
        c.execute('''SELECT p.type, p.table_name, p.columns, p.types, p.resolved
                     FROM functions f
                     JOIN parameters p ON f.id = p.function_id
                     WHERE f.name = ? AND p.name = ?''', (func_name, param_name))
        
        row = c.fetchone()
        if not row:
            conn.close()
            return None
        
        result = {
            'type': row['type'],
            'resolved': bool(row['resolved']),
            'table': row['table_name']
        }
        
        if row['columns']:
            result['columns'] = row['columns'].split(',')
        if row['types']:
            try:
                # Try to parse as JSON first
                result['types'] = json.loads(row['types'])
            except (json.JSONDecodeError, TypeError):
                # Fall back to comma split
                result['types'] = row['types'].split(',')
        
        conn.close()
        return result
    except Exception as e:
        conn.close()
        raise e


def find_module_dependencies(modules_db, signatures_db, module_name):
    """Find all modules that a module depends on (via function calls)."""
    # Get all functions in the module
    functions_in_module = find_functions_in_module(modules_db, signatures_db, module_name)
    
    if functions_in_module is None:
        return None
    
    if not functions_in_module:
        return []
    
    # Get all functions called by functions in this module
    conn_sig = sqlite3.connect(signatures_db)
    conn_sig.row_factory = sqlite3.Row
    c_sig = conn_sig.cursor()
    
    called_functions = set()
    for func in functions_in_module:
        c_sig.execute('''SELECT DISTINCT c.called_function_name FROM calls c
                         JOIN functions f ON c.function_id = f.id
                         WHERE f.name = ?''', (func['name'],))
        for row in c_sig.fetchall():
            called_functions.add(row['called_function_name'])
    
    # For each called function, find which module it belongs to
    conn_mod = sqlite3.connect(modules_db)
    conn_mod.row_factory = sqlite3.Row
    c_mod = conn_mod.cursor()
    
    dependent_modules = set()
    for called_func in called_functions:
        modules = find_module_for_function(modules_db, signatures_db, called_func)
        if modules:
            for mod in modules:
                if mod['name'] != module_name:  # Exclude self-references
                    dependent_modules.add(mod['name'])
    
    conn_sig.close()
    conn_mod.close()
    
    return sorted(list(dependent_modules))

def find_dead_code(db_file):
    """Find functions that are never called (dead code)."""
    conn = sqlite3.connect(db_file)
    conn.row_factory = sqlite3.Row
    c = conn.cursor()
    
    # Find all functions that are not called by any other function
    c.execute('''SELECT f.name, fi.path, f.line_start, f.line_end
                 FROM functions f
                 JOIN files fi ON f.file_id = fi.id
                 WHERE f.name NOT IN (SELECT DISTINCT called_function_name FROM calls)
                 ORDER BY fi.path, f.name''')
    
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
        print("  find_functions_in_module <module>   - Find all functions in a module", file=sys.stderr)
        print("  find_module_for_function <name>     - Find which module(s) contain a function", file=sys.stderr)
        print("  find_functions_calling_in_module <module> <func> - Find functions in module that call a function", file=sys.stderr)
        print("  find_module_dependencies <module>   - Find modules that a module depends on", file=sys.stderr)
        print("  find_dead_code                      - Find functions that are never called", file=sys.stderr)
        print("", file=sys.stderr)
        print("Type-aware queries (Phase 1d):", file=sys.stderr)
        print("  find_functions_using_table <table>  - Find functions using a database table", file=sys.stderr)
        print("  find_tables_used_by_function <name> - Find database tables used by a function", file=sys.stderr)
        print("  find_unresolved_like_references     - Find all unresolved LIKE references", file=sys.stderr)
        print("  get_resolved_type_info <func> <param> - Get resolved type info for a parameter", file=sys.stderr)
        sys.exit(1)
    
    command = sys.argv[1]
    
    # Commands that need two databases (modules_db, signatures_db)
    two_db_commands = {
        'find_functions_in_module',
        'find_module_for_function',
        'find_functions_calling_in_module',
        'find_module_dependencies'
    }
    
    if command in two_db_commands:
        if len(sys.argv) < 4:
            print(f"Error: {command} requires two database files", file=sys.stderr)
            sys.exit(1)
        modules_db = sys.argv[2]
        signatures_db = sys.argv[3]
        
        if not Path(modules_db).exists():
            print(f"Error: {modules_db} not found", file=sys.stderr)
            sys.exit(1)
        if not Path(signatures_db).exists():
            print(f"Error: {signatures_db} not found", file=sys.stderr)
            sys.exit(1)
        
        try:
            if command == "find_functions_in_module" and len(sys.argv) > 4:
                results = find_functions_in_module(modules_db, signatures_db, sys.argv[4])
                if results is None:
                    print(f"Module '{sys.argv[4]}' not found", file=sys.stderr)
                    sys.exit(1)
                print(json.dumps(results, indent=2))
            
            elif command == "find_module_for_function" and len(sys.argv) > 4:
                results = find_module_for_function(modules_db, signatures_db, sys.argv[4])
                if results is None:
                    print(f"Function '{sys.argv[4]}' not found", file=sys.stderr)
                    sys.exit(1)
                print(json.dumps(results, indent=2))
            
            elif command == "find_functions_calling_in_module" and len(sys.argv) > 5:
                results = find_functions_calling_in_module(modules_db, signatures_db, sys.argv[4], sys.argv[5])
                if results is None:
                    print(f"Module '{sys.argv[4]}' not found", file=sys.stderr)
                    sys.exit(1)
                print(json.dumps(results, indent=2))
            
            elif command == "find_module_dependencies" and len(sys.argv) > 4:
                results = find_module_dependencies(modules_db, signatures_db, sys.argv[4])
                if results is None:
                    print(f"Module '{sys.argv[4]}' not found", file=sys.stderr)
                    sys.exit(1)
                print(json.dumps(results, indent=2))
            
            else:
                print(f"Error: Unknown command or missing arguments", file=sys.stderr)
                sys.exit(1)
        
        except Exception as e:
            print(f"Error: {e}", file=sys.stderr)
            sys.exit(1)
    
    else:
        # Single database commands
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
            
            elif command == "find_dead_code":
                results = find_dead_code(db_file)
                print(json.dumps(results, indent=2))
            
            # Type-aware queries (Phase 1d)
            elif command == "find_functions_using_table" and len(sys.argv) > 3:
                results = find_functions_using_table(db_file, sys.argv[3])
                print(json.dumps(results, indent=2))
            
            elif command == "find_tables_used_by_function" and len(sys.argv) > 3:
                results = find_tables_used_by_function(db_file, sys.argv[3])
                print(json.dumps(results, indent=2))
            
            elif command == "find_unresolved_like_references":
                results = find_unresolved_like_references(db_file)
                print(json.dumps(results, indent=2))
            
            elif command == "get_resolved_type_info" and len(sys.argv) > 4:
                result = get_resolved_type_info(db_file, sys.argv[3], sys.argv[4])
                if result:
                    print(json.dumps(result, indent=2))
                else:
                    print(f"Parameter '{sys.argv[4]}' not found in function '{sys.argv[3]}'", file=sys.stderr)
                    sys.exit(1)
            
            elif command == "find_function_resolved" and len(sys.argv) > 3:
                # Query function with resolved types from workspace_resolved.json
                result = query_function_resolved(db_file, sys.argv[3])
                if result:
                    print(json.dumps(result, indent=2))
                else:
                    print(f"Function '{sys.argv[3]}' not found", file=sys.stderr)
                    sys.exit(1)
            
            else:
                print(f"Error: Unknown command or missing arguments", file=sys.stderr)
                sys.exit(1)
        
        except Exception as e:
            print(f"Error: {e}", file=sys.stderr)
            sys.exit(1)

if __name__ == "__main__":
    main()


def query_function_resolved(workspace_resolved_path, func_name):
    """Query function with resolved types from workspace_resolved.json."""
    try:
        with open(workspace_resolved_path, 'r') as f:
            workspace_resolved = json.load(f)
    except FileNotFoundError:
        return None
    except json.JSONDecodeError:
        return None
    
    # Search for the function across all files
    for file_path, functions in workspace_resolved.items():
        if file_path == '_metadata':
            continue
        
        if isinstance(functions, list):
            for func in functions:
                if func.get('name') == func_name:
                    return func
    
    return None
