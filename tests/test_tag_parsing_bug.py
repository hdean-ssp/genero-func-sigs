#!/usr/bin/env python3
"""
Bug condition exploration test for tag-parsing-clipping-fix.

This test demonstrates the bug where reference IDs with numeric or alphanumeric 
suffixes (e.g., "EH100058-10", "EH100512-9a") are being truncated to their base form.

**Validates: Requirements 1.1, 1.2, 1.3**

IMPORTANT: This test is expected to FAIL on unfixed code. The failure demonstrates 
that the bug exists. Do NOT attempt to fix the code when this test fails.
"""

import unittest
import sys
import os
from typing import Dict, List

# Add scripts directory to path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'scripts'))

from parse_headers import HeaderParser


class TestTagParsingBugCondition(unittest.TestCase):
    """
    Bug condition exploration tests for reference ID truncation.
    
    These tests demonstrate the bug where references with numeric or alphanumeric
    suffixes are being truncated. They are expected to FAIL on unfixed code.
    """
    
    def setUp(self):
        """Set up test fixtures."""
        self.parser = HeaderParser()
    
    def _parse_row_directly(self, line: str, columns: Dict) -> Dict:
        """
        Helper to parse a single row directly.
        
        Args:
            line: Data row to parse
            columns: Column position mapping
            
        Returns:
            Parsed reference data
        """
        # Remove comment marker if present
        if line.startswith('#'):
            line = line.lstrip('#').strip()
        
        # Call the internal _parse_row method
        result = self.parser._parse_row(line, columns, [line], 0, 0)
        return result
    
    def test_numeric_suffix_extraction(self):
        """
        Test that references with numeric suffixes are extracted completely.
        
        Bug Condition: Reference ID "EH100058-10" should extract as "EH100058-10"
        Current Behavior (Bug): Extracts as "EH100058"
        Expected Behavior: Extracts as "EH100058-10"
        
        Requirement 1.1: WHEN a reference_id contains a numeric suffix after a hyphen 
        (e.g., "EH100058-10") THEN the system extracts only the base reference without 
        the suffix (e.g., "EH100058")
        """
        # Simulate a modification row with numeric suffix
        line = "EH100058-10    01/02/2024  John  Fixed issue"
        columns = {'ref': 0, 'date': 15}
        
        result = self._parse_row_directly(line, columns)
        
        # This assertion will FAIL on unfixed code (demonstrating the bug)
        self.assertEqual(
            result['reference'], 
            'EH100058-10',
            f"Expected 'EH100058-10' but got '{result['reference']}' - "
            "Reference with numeric suffix was truncated"
        )
    
    def test_alphanumeric_suffix_extraction(self):
        """
        Test that references with alphanumeric suffixes are extracted completely.
        
        Bug Condition: Reference ID "EH100512-9a" should extract as "EH100512-9a"
        Current Behavior (Bug): Extracts as "EH100512"
        Expected Behavior: Extracts as "EH100512-9a"
        
        Requirement 1.2: WHEN a reference_id contains an alphanumeric suffix after a 
        hyphen (e.g., "EH100512-9a") THEN the system extracts only the base reference 
        without the suffix (e.g., "EH100512")
        """
        # Simulate a modification row with alphanumeric suffix
        line = "EH100512-9a    15/03/2024  Jane  Updated logic"
        columns = {'ref': 0, 'date': 15}
        
        result = self._parse_row_directly(line, columns)
        
        # This assertion will FAIL on unfixed code (demonstrating the bug)
        self.assertEqual(
            result['reference'], 
            'EH100512-9a',
            f"Expected 'EH100512-9a' but got '{result['reference']}' - "
            "Reference with alphanumeric suffix was truncated"
        )
    
    def test_multiple_hyphens_extraction(self):
        """
        Test that references with multiple hyphens are extracted completely.
        
        Bug Condition: Reference ID "EH100058-10-beta" should extract as "EH100058-10-beta"
        Current Behavior (Bug): Extracts as "EH100058"
        Expected Behavior: Extracts as "EH100058-10-beta"
        
        Requirement 1.3: WHEN a reference_id is positioned at the start of a data row 
        with variable spacing before the next column THEN the system clips the reference 
        at the first detected column boundary instead of extracting the complete reference token
        """
        # Simulate a modification row with multiple hyphens
        line = "EH100058-10-beta    01/02/2024  John  Fixed issue"
        columns = {'ref': 0, 'date': 20}
        
        result = self._parse_row_directly(line, columns)
        
        # This assertion will FAIL on unfixed code (demonstrating the bug)
        self.assertEqual(
            result['reference'], 
            'EH100058-10-beta',
            f"Expected 'EH100058-10-beta' but got '{result['reference']}' - "
            "Reference with multiple hyphens was truncated"
        )
    
    def test_real_world_example_eh100512_9a(self):
        """
        Test with real-world example from simple_functions.4gl.
        
        This is the actual reference "EH100512-9a" from the test data file.
        """
        # Real data from simple_functions.4gl
        line = "EH100512-9a 1410.18    19/09/2024      Chilly          Use job_task_params for commshub for passing file attachments"
        columns = {'ref': 0, 'date': 20}
        
        result = self._parse_row_directly(line, columns)
        
        # This assertion will FAIL on unfixed code (demonstrating the bug)
        self.assertEqual(
            result['reference'], 
            'EH100512-9a',
            f"Expected 'EH100512-9a' but got '{result['reference']}' - "
            "Real-world reference with alphanumeric suffix was truncated"
        )
    
    def test_real_world_example_eh100512_15(self):
        """
        Test with another real-world example from simple_functions.4gl.
        
        This is the actual reference "EH100512-15" from the test data file.
        """
        # Real data from simple_functions.4gl
        line = "EH100512-15 1410.17    06/09/2024  Chris P     Don't run SMS/Email if not active"
        columns = {'ref': 0, 'date': 20}
        
        result = self._parse_row_directly(line, columns)
        
        # This assertion will FAIL on unfixed code (demonstrating the bug)
        self.assertEqual(
            result['reference'], 
            'EH100512-15',
            f"Expected 'EH100512-15' but got '{result['reference']}' - "
            "Real-world reference with numeric suffix was truncated"
        )


if __name__ == '__main__':
    unittest.main()
