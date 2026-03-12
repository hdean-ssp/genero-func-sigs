#!/usr/bin/env python3
"""Convert JSON files to SQLite database for efficient querying."""

import json
import sqlite3
import sys
from pathlib import Path

def create_signatures_db(json_file, db_file):
    """Create SQLite database from workspace.json signatures."""
    conn = sqlite3.connect(db_file)
    c = conn.cursor()
    
    # Create tables
    c.execute('''CREATE TABLE IF NOT EXISTS files
                 (id INTEGER PRIMARY KEY, path TEXT UNIQUE, type TEXT)''')
    
    c.execute('''CREATE TABLE IF NOT EXISTS functions
                 (id INTEGER PRIMARY KEY, file_id INTEGER, name TEXT, 
                  line_start INTEGER, line_end INTEGER, signature TEXT,
                  FOREIGN KEY(file_id) REFERENCES files(id))''')
    
    c.execute('''CREATE TABLE IF NOT EXISTS parameters
                 (id INTEGER PRIMARY KEY, function_id INTEGER, name TEXT, type TEXT,
                  FOREIGN KEY(function_id) REFERENCES functions(id))''')
    
    c.execute('''CREATE TABLE IF NOT EXISTS returns
                 (id INTEGER PRIMARY KEY, function_id INTEGER, name TEXT, type TEXT,
                  FOREIGN KEY(function_id) REFERENCES functions(id))''')
    
    c.execute('''CREATE TABLE IF NOT EXISTS calls
                 (id INTEGER PRIMARY KEY, function_id INTEGER, called_function_name TEXT, 
                  line_number INTEGER,
                  FOREIGN KEY(function_id) REFERENCES functions(id))''')
    
    # Create indexes
    c.execute('CREATE INDEX IF NOT EXISTS idx_functions_name ON functions(name)')
    c.execute('CREATE INDEX IF NOT EXISTS idx_functions_file ON functions(file_id)')
    c.execute('CREATE INDEX IF NOT EXISTS idx_parameters_function ON parameters(function_id)')
    c.execute('CREATE INDEX IF NOT EXISTS idx_returns_function ON returns(function_id)')
    c.execute('CREATE INDEX IF NOT EXISTS idx_calls_function ON calls(function_id)')
    c.execute('CREATE INDEX IF NOT EXISTS idx_calls_called_name ON calls(called_function_name)')
    
    # Load data
    with open(json_file, 'r') as f:
        data = json.load(f)
    
    data.pop('_metadata', None)
    
    for file_path, functions in data.items():
        # Determine file type
        file_type = "L4GLS" if "L4GLS" in file_path else ("U4GLS" if "U4GLS" in file_path else "4GLS")
        
        c.execute('INSERT INTO files (path, type) VALUES (?, ?)', (file_path, file_type))
        file_id = c.lastrowid
        
        for func in functions:
            c.execute('''INSERT INTO functions (file_id, name, line_start, line_end, signature)
                        VALUES (?, ?, ?, ?, ?)''',
                     (file_id, func['name'], func['line']['start'], func['line']['end'], func['signature']))
            func_id = c.lastrowid
            
            # Insert parameters
            for param in func.get('parameters', []):
                c.execute('INSERT INTO parameters (function_id, name, type) VALUES (?, ?, ?)',
                         (func_id, param['name'], param['type']))
            
            # Insert returns
            for ret in func.get('returns', []):
                c.execute('INSERT INTO returns (function_id, name, type) VALUES (?, ?, ?)',
                         (func_id, ret['name'], ret['type']))
            
            # Insert calls
            for call in func.get('calls', []):
                c.execute('INSERT INTO calls (function_id, called_function_name, line_number) VALUES (?, ?, ?)',
                         (func_id, call['name'], call['line']))
    
    conn.commit()
    conn.close()
    print(f"Created {db_file} from {json_file}")

def create_modules_db(json_file, db_file):
    """Create SQLite database from modules.json."""
    conn = sqlite3.connect(db_file)
    c = conn.cursor()
    
    # Create tables
    c.execute('''CREATE TABLE IF NOT EXISTS modules
                 (id INTEGER PRIMARY KEY, name TEXT UNIQUE, file TEXT)''')
    
    c.execute('''CREATE TABLE IF NOT EXISTS module_files
                 (id INTEGER PRIMARY KEY, module_id INTEGER, file_name TEXT, category TEXT,
                  FOREIGN KEY(module_id) REFERENCES modules(id))''')
    
    # Create indexes
    c.execute('CREATE INDEX IF NOT EXISTS idx_modules_name ON modules(name)')
    c.execute('CREATE INDEX IF NOT EXISTS idx_module_files_module ON module_files(module_id)')
    c.execute('CREATE INDEX IF NOT EXISTS idx_module_files_category ON module_files(category)')
    
    # Load data
    with open(json_file, 'r') as f:
        data = json.load(f)
    
    for module in data.get('modules', []):
        c.execute('INSERT INTO modules (name, file) VALUES (?, ?)',
                 (module['module'], module['file']))
        module_id = c.lastrowid
        
        # Insert L4GLS files
        for fname in module.get('L4GLS', []):
            c.execute('INSERT INTO module_files (module_id, file_name, category) VALUES (?, ?, ?)',
                     (module_id, fname, 'L4GLS'))
        
        # Insert U4GLS files
        for fname in module.get('U4GLS', []):
            c.execute('INSERT INTO module_files (module_id, file_name, category) VALUES (?, ?, ?)',
                     (module_id, fname, 'U4GLS'))
        
        # Insert 4GLS files
        for fname in module.get('4GLS', []):
            c.execute('INSERT INTO module_files (module_id, file_name, category) VALUES (?, ?, ?)',
                     (module_id, fname, '4GLS'))
    
    conn.commit()
    conn.close()
    print(f"Created {db_file} from {json_file}")

def main():
    if len(sys.argv) < 3:
        print("Usage: json_to_sqlite.py <type> <json_file> [db_file]", file=sys.stderr)
        print("  type: 'signatures' or 'modules'", file=sys.stderr)
        sys.exit(1)
    
    json_type = sys.argv[1]
    json_file = sys.argv[2]
    db_file = sys.argv[3] if len(sys.argv) > 3 else json_file.replace('.json', '.db')
    
    if not Path(json_file).exists():
        print(f"Error: {json_file} not found", file=sys.stderr)
        sys.exit(1)
    
    try:
        if json_type == 'signatures':
            create_signatures_db(json_file, db_file)
        elif json_type == 'modules':
            create_modules_db(json_file, db_file)
        else:
            print(f"Error: Unknown type '{json_type}'", file=sys.stderr)
            sys.exit(1)
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()
