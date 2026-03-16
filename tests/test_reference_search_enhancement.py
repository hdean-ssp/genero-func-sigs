#!/usr/bin/env python3
"""
Test for enhanced reference search functionality.

This test demonstrates that reference searches now return all matching references,
including partial matches with suffixes.

Example:
- Searching for "100512" returns: EH100512, EH100512-9a, EH100512-15, etc.
- Searching for "EH100512" returns: EH100512, EH100512-9a, EH100512-15, etc.
- Searching for "EH100512%" returns: EH100512, EH100512-9a, EH100512-15, etc.
"""

import unittest
import sys
import os
import sqlite3
import tempfile
from pathlib import Path

# Add scripts directory to path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'scripts'))

from query_headers import search_references, search_reference_prefix


class TestReferenceSearchEnhancement(unittest.TestCase):
    """Test enhanced reference search functionality."""
    
    @classmethod
    def setUpClass(cls):
        """Create a test database with sample references."""
        cls.temp_db = tempfile.NamedTemporaryFile(delete=False, suffix='.db')
        cls.db_file = cls.temp_db.name
        cls.temp_db.close()
        
        # Create test database
        conn = sqlite3.connect(cls.db_file)
        c = conn.cursor()
        
        # Create tables
        c.execute('''CREATE TABLE files (id INTEGER PRIMARY KEY, path TEXT UNIQUE)''')
        c.execute('''CREATE TABLE file_references
                     (id INTEGER PRIMARY KEY, file_id INTEGER, reference_id TEXT, 
                      author TEXT, change_date TEXT, description TEXT,
                      FOREIGN KEY(file_id) REFERENCES files(id))''')
        
        # Insert test files
        test_files = [
            './src/utils.4gl',
            './src/helpers.4gl',
            './src/core.4gl',
        ]
        for filepath in test_files:
            c.execute('INSERT INTO files (path) VALUES (?)', (filepath,))
        
        # Insert test references
        test_references = [
            (1, 'EH100512', 'John', '2024-09-19', 'Use job_task_params'),
            (1, 'EH100512-9a', 'Chilly', '2024-09-19', 'Use job_task_params for commshub'),
            (1, 'EH100512-15', 'Chris P', '2024-09-06', "Don't run SMS/Email if not active"),
            (2, 'EH100058', 'Jane', '2024-02-01', 'Fixed issue'),
            (2, 'EH100058-10', 'John', '2024-02-01', 'Fixed issue with numeric suffix'),
            (3, 'PRB-299', 'Alice', '2024-03-15', 'Bug fix'),
            (3, 'PRB-299-alpha', 'Bob', '2024-03-16', 'Enhancement'),
        ]
        
        for file_id, ref_id, author, date, desc in test_references:
            c.execute('''INSERT INTO file_references 
                        (file_id, reference_id, author, change_date, description)
                        VALUES (?, ?, ?, ?, ?)''',
                     (file_id, ref_id, author, date, desc))
        
        conn.commit()
        conn.close()
    
    @classmethod
    def tearDownClass(cls):
        """Clean up test database."""
        if os.path.exists(cls.db_file):
            os.unlink(cls.db_file)
    
    def test_partial_numeric_search(self):
        """Test searching for partial numeric reference (e.g., "100512")."""
        results = search_references(self.db_file, '100512')
        
        # Should find all references containing "100512"
        ref_ids = [r['reference_id'] for r in results]
        self.assertIn('EH100512', ref_ids)
        self.assertIn('EH100512-9a', ref_ids)
        self.assertIn('EH100512-15', ref_ids)
        self.assertEqual(len(ref_ids), 3)
    
    def test_partial_prefix_search(self):
        """Test searching for partial prefix (e.g., "EH100512")."""
        results = search_references(self.db_file, 'EH100512')
        
        # Should find all references starting with "EH100512"
        ref_ids = [r['reference_id'] for r in results]
        self.assertIn('EH100512', ref_ids)
        self.assertIn('EH100512-9a', ref_ids)
        self.assertIn('EH100512-15', ref_ids)
        self.assertEqual(len(ref_ids), 3)
    
    def test_wildcard_search(self):
        """Test searching with explicit wildcard pattern."""
        results = search_references(self.db_file, 'EH100512%')
        
        # Should find all references starting with "EH100512"
        ref_ids = [r['reference_id'] for r in results]
        self.assertIn('EH100512', ref_ids)
        self.assertIn('EH100512-9a', ref_ids)
        self.assertIn('EH100512-15', ref_ids)
        self.assertEqual(len(ref_ids), 3)
    
    def test_prefix_search_function(self):
        """Test the dedicated prefix search function."""
        results = search_reference_prefix(self.db_file, 'EH100512')
        
        # Should find all references starting with "EH100512"
        ref_ids = [r['reference_id'] for r in results]
        self.assertIn('EH100512', ref_ids)
        self.assertIn('EH100512-9a', ref_ids)
        self.assertIn('EH100512-15', ref_ids)
        self.assertEqual(len(ref_ids), 3)
    
    def test_different_prefix_search(self):
        """Test searching for different prefix."""
        results = search_references(self.db_file, 'EH100058')
        
        # Should find all references starting with "EH100058"
        ref_ids = [r['reference_id'] for r in results]
        self.assertIn('EH100058', ref_ids)
        self.assertIn('EH100058-10', ref_ids)
        self.assertEqual(len(ref_ids), 2)
    
    def test_prb_prefix_search(self):
        """Test searching for PRB references."""
        results = search_references(self.db_file, 'PRB-299')
        
        # Should find all references starting with "PRB-299"
        ref_ids = [r['reference_id'] for r in results]
        self.assertIn('PRB-299', ref_ids)
        self.assertIn('PRB-299-alpha', ref_ids)
        self.assertEqual(len(ref_ids), 2)
    
    def test_numeric_only_search(self):
        """Test searching with just the numeric part."""
        results = search_references(self.db_file, '299')
        
        # Should find all references containing "299"
        ref_ids = [r['reference_id'] for r in results]
        self.assertIn('PRB-299', ref_ids)
        self.assertIn('PRB-299-alpha', ref_ids)
        self.assertEqual(len(ref_ids), 2)
    
    def test_results_include_metadata(self):
        """Test that results include all metadata."""
        results = search_references(self.db_file, '100512')
        
        # Should have at least one result
        self.assertGreater(len(results), 0)
        
        # Each result should have required fields
        for result in results:
            self.assertIn('path', result)
            self.assertIn('reference_id', result)
            self.assertIn('author', result)
            self.assertIn('change_date', result)
            self.assertIn('description', result)


if __name__ == '__main__':
    unittest.main()
