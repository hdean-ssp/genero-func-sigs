#!/usr/bin/env python3
"""
Tests for Query Layer (Phase 1d) - Type-aware queries

Tests cover:
- Finding functions using a specific table
- Finding tables used by a function
- Finding unresolved LIKE references
- Getting resolved type information
"""

import json
import sqlite3
import tempfile
import unittest
from pathlib import Path

# Add scripts to path
import sys
sys.path.insert(0, str(Path(__file__).parent.parent / 'scripts'))

from query_db import (
    find_functions_using_table,
    find_tables_used_by_function,
    find_unresolved_like_references,
    get_resolved_type_info
)


class TestQueryLayer(unittest.TestCase):
    """Test Phase 1d query layer functions."""
    
    def setUp(self):
        """Create temporary database with test data."""
        self.temp_db = tempfile.NamedTemporaryFile(delete=False, suffix='.db')
        self.db_path = self.temp_db.name
        self.temp_db.close()
        
        # Create tables
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()
        
        # Files table
        cursor.execute("""
            CREATE TABLE files (
                id INTEGER PRIMARY KEY,
                path TEXT NOT NULL UNIQUE,
                type TEXT
            )
        """)
        
        # Functions table
        cursor.execute("""
            CREATE TABLE functions (
                id INTEGER PRIMARY KEY,
                name TEXT NOT NULL,
                file_id INTEGER NOT NULL,
                line_start INTEGER,
                line_end INTEGER,
                FOREIGN KEY (file_id) REFERENCES files(id)
            )
        """)
        
        # Parameters table
        cursor.execute("""
            CREATE TABLE parameters (
                id INTEGER PRIMARY KEY,
                function_id INTEGER NOT NULL,
                name TEXT NOT NULL,
                type TEXT,
                is_like_reference BOOLEAN,
                resolved BOOLEAN,
                table_name TEXT,
                columns TEXT,
                types TEXT,
                FOREIGN KEY (function_id) REFERENCES functions(id)
            )
        """)
        
        # Insert test files
        cursor.execute("INSERT INTO files (path, type) VALUES (?, ?)", ('./test1.4gl', 'source'))
        file1_id = cursor.lastrowid
        
        cursor.execute("INSERT INTO files (path, type) VALUES (?, ?)", ('./test2.4gl', 'source'))
        file2_id = cursor.lastrowid
        
        # Insert test functions
        cursor.execute("""
            INSERT INTO functions (name, file_id, line_start, line_end)
            VALUES (?, ?, ?, ?)
        """, ('process_account', file1_id, 1, 10))
        func1_id = cursor.lastrowid
        
        cursor.execute("""
            INSERT INTO functions (name, file_id, line_start, line_end)
            VALUES (?, ?, ?, ?)
        """, ('process_customer', file1_id, 12, 20))
        func2_id = cursor.lastrowid
        
        cursor.execute("""
            INSERT INTO functions (name, file_id, line_start, line_end)
            VALUES (?, ?, ?, ?)
        """, ('get_account_id', file2_id, 1, 5))
        func3_id = cursor.lastrowid
        
        # Insert parameters with LIKE references
        # process_account uses account table
        cursor.execute("""
            INSERT INTO parameters 
            (function_id, name, type, is_like_reference, resolved, table_name, columns, types)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        """, (func1_id, 'acc', 'LIKE account.*', 1, 1, 'account', 'id,name,balance', json.dumps(['INTEGER', 'VARCHAR(100)', 'DECIMAL(10,2)'])))
        
        # process_customer uses customer table
        cursor.execute("""
            INSERT INTO parameters 
            (function_id, name, type, is_like_reference, resolved, table_name, columns, types)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        """, (func2_id, 'cust', 'LIKE customer.*', 1, 1, 'customer', 'id,email', json.dumps(['INTEGER', 'VARCHAR(255)'])))
        
        # get_account_id uses account table (specific column, unresolved)
        cursor.execute("""
            INSERT INTO parameters 
            (function_id, name, type, is_like_reference, resolved, table_name, columns, types)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        """, (func3_id, 'id', 'LIKE account.account_id', 1, 0, 'account', None, None))
        
        # Non-LIKE parameter
        cursor.execute("""
            INSERT INTO parameters 
            (function_id, name, type, is_like_reference, resolved, table_name, columns, types)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        """, (func1_id, 'flag', 'INTEGER', 0, 1, None, None, None))
        
        conn.commit()
        conn.close()
    
    def tearDown(self):
        """Clean up temporary database."""
        Path(self.db_path).unlink()
    
    def test_find_functions_using_table(self):
        """Test finding functions that use a specific table."""
        results = find_functions_using_table(self.db_path, 'account')
        
        self.assertEqual(len(results), 2)
        names = [r['name'] for r in results]
        self.assertIn('process_account', names)
        self.assertIn('get_account_id', names)
    
    def test_find_functions_using_table_no_results(self):
        """Test finding functions using non-existent table."""
        results = find_functions_using_table(self.db_path, 'nonexistent')
        
        self.assertEqual(len(results), 0)
    
    def test_find_tables_used_by_function(self):
        """Test finding tables used by a function."""
        results = find_tables_used_by_function(self.db_path, 'process_account')
        
        self.assertEqual(len(results), 1)
        self.assertIn('account', results)
    
    def test_find_tables_used_by_function_multiple(self):
        """Test finding multiple tables used by a function."""
        # Add another parameter to process_account
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()
        
        cursor.execute("SELECT id FROM functions WHERE name = 'process_account'")
        func_id = cursor.fetchone()[0]
        
        cursor.execute("""
            INSERT INTO parameters 
            (function_id, name, type, is_like_reference, resolved, table_name, columns, types)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        """, (func_id, 'cust', 'LIKE customer.*', 1, 1, 'customer', 'id,email', 'INTEGER,VARCHAR(255)'))
        
        conn.commit()
        conn.close()
        
        results = find_tables_used_by_function(self.db_path, 'process_account')
        
        self.assertEqual(len(results), 2)
        self.assertIn('account', results)
        self.assertIn('customer', results)
    
    def test_find_unresolved_like_references(self):
        """Test finding unresolved LIKE references."""
        results = find_unresolved_like_references(self.db_path)
        
        self.assertEqual(len(results), 1)
        self.assertEqual(results[0]['function'], 'get_account_id')
        self.assertEqual(results[0]['parameter'], 'id')
        self.assertEqual(results[0]['type'], 'LIKE account.account_id')
    
    def test_get_resolved_type_info(self):
        """Test getting resolved type information."""
        result = get_resolved_type_info(self.db_path, 'process_account', 'acc')
        
        self.assertIsNotNone(result)
        self.assertTrue(result['resolved'])
        self.assertEqual(result['table'], 'account')
        self.assertEqual(result['columns'], ['id', 'name', 'balance'])
        self.assertEqual(result['types'], ['INTEGER', 'VARCHAR(100)', 'DECIMAL(10,2)'])
    
    def test_get_resolved_type_info_unresolved(self):
        """Test getting unresolved type information."""
        result = get_resolved_type_info(self.db_path, 'get_account_id', 'id')
        
        self.assertIsNotNone(result)
        self.assertFalse(result['resolved'])
        self.assertEqual(result['table'], 'account')
    
    def test_get_resolved_type_info_non_like(self):
        """Test getting type info for non-LIKE parameter."""
        result = get_resolved_type_info(self.db_path, 'process_account', 'flag')
        
        self.assertIsNotNone(result)
        self.assertTrue(result['resolved'])
        self.assertEqual(result['type'], 'INTEGER')
        self.assertIsNone(result['table'])
    
    def test_get_resolved_type_info_not_found(self):
        """Test getting type info for non-existent parameter."""
        result = get_resolved_type_info(self.db_path, 'process_account', 'nonexistent')
        
        self.assertIsNone(result)


class TestQueryLayerIntegration(unittest.TestCase):
    """Integration tests for query layer with real data."""
    
    def setUp(self):
        """Set up test environment."""
        self.temp_dir = tempfile.mkdtemp()
        self.db_path = Path(self.temp_dir) / 'test.db'
    
    def tearDown(self):
        """Clean up test environment."""
        import shutil
        shutil.rmtree(self.temp_dir)
    
    def test_query_layer_with_resolved_types(self):
        """Test query layer with resolved types from Phase 1c."""
        # Create database with schema and resolved types
        conn = sqlite3.connect(str(self.db_path))
        cursor = conn.cursor()
        
        # Create tables
        cursor.execute("""
            CREATE TABLE files (
                id INTEGER PRIMARY KEY,
                path TEXT NOT NULL UNIQUE,
                type TEXT
            )
        """)
        
        cursor.execute("""
            CREATE TABLE functions (
                id INTEGER PRIMARY KEY,
                name TEXT NOT NULL,
                file_id INTEGER NOT NULL,
                line_start INTEGER,
                line_end INTEGER,
                FOREIGN KEY (file_id) REFERENCES files(id)
            )
        """)
        
        cursor.execute("""
            CREATE TABLE parameters (
                id INTEGER PRIMARY KEY,
                function_id INTEGER NOT NULL,
                name TEXT NOT NULL,
                type TEXT,
                is_like_reference BOOLEAN,
                resolved BOOLEAN,
                table_name TEXT,
                columns TEXT,
                types TEXT,
                FOREIGN KEY (function_id) REFERENCES functions(id)
            )
        """)
        
        # Insert test data
        cursor.execute("INSERT INTO files (path, type) VALUES (?, ?)", ('./test.4gl', 'source'))
        file_id = cursor.lastrowid
        
        cursor.execute("""
            INSERT INTO functions (name, file_id, line_start, line_end)
            VALUES (?, ?, ?, ?)
        """, ('process_order', file_id, 1, 15))
        func_id = cursor.lastrowid
        
        cursor.execute("""
            INSERT INTO parameters 
            (function_id, name, type, is_like_reference, resolved, table_name, columns, types)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        """, (func_id, 'order', 'LIKE orders.*', 1, 1, 'orders', 'id,customer_id,total', 'INTEGER,INTEGER,DECIMAL(10,2)'))
        
        conn.commit()
        conn.close()
        
        # Test queries
        functions = find_functions_using_table(str(self.db_path), 'orders')
        self.assertEqual(len(functions), 1)
        self.assertEqual(functions[0]['name'], 'process_order')
        
        tables = find_tables_used_by_function(str(self.db_path), 'process_order')
        self.assertEqual(len(tables), 1)
        self.assertEqual(tables[0], 'orders')
        
        type_info = get_resolved_type_info(str(self.db_path), 'process_order', 'order')
        self.assertTrue(type_info['resolved'])
        self.assertEqual(type_info['table'], 'orders')
        self.assertEqual(len(type_info['columns']), 3)


if __name__ == '__main__':
    unittest.main()
