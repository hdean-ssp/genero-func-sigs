#!/usr/bin/env python3
"""
Preservation property tests for tag-parsing-clipping-fix.

These tests verify that the fix for reference ID truncation does NOT break
existing behavior for references without suffixes and other field extraction.

**Validates: Requirements 3.1, 3.2, 3.3, 3.4**

These tests should PASS on both unfixed and fixed code, confirming that
the fix preserves all existing functionality.
"""

import unittest
import sys
import os
from typing import Dict, List

# Add scripts directory to path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'scripts'))

from parse_headers import HeaderParser


class TestTagParsingPreservation(unittest.TestCase):
    """
    Preservation tests for reference ID extraction and other fields.
    
    These tests verify that references without suffixes, author names, dates,
    and descriptions continue to be extracted correctly after the fix.
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
    
    def test_reference_without_suffix_extraction(self):
        """
        Test that references without suffixes continue to be extracted correctly.
        
        Requirement 3.1: WHEN a reference_id has no suffix (e.g., "EH100512") 
        THEN the system SHALL CONTINUE TO extract it correctly as "EH100512"
        """
        # Reference without suffix
        line = "EH100512    15/03/2024  Jane  Updated logic"
        columns = {'ref': 0, 'date': 15}
        
        result = self._parse_row_directly(line, columns)
        
        self.assertEqual(
            result['reference'], 
            'EH100512',
            f"Expected 'EH100512' but got '{result['reference']}' - "
            "Reference without suffix should be extracted correctly"
        )
    
    def test_author_extraction_preservation(self):
        """
        Test that author names continue to be extracted correctly.
        
        Requirement 3.2: WHEN a reference_id is followed by whitespace and other columns 
        THEN the system SHALL CONTINUE TO correctly identify the end of the reference token 
        at the first whitespace boundary
        
        Requirement 3.3: WHEN parsing files with properly formatted modification headers 
        THEN the system SHALL CONTINUE TO extract all other fields (author, date, description) correctly
        """
        # Single-word author
        line = "EH100512    15/03/2024  Jane  Updated logic"
        columns = {'ref': 0, 'date': 15}
        
        result = self._parse_row_directly(line, columns)
        
        self.assertEqual(
            result['author'], 
            'Jane',
            f"Expected author 'Jane' but got '{result['author']}' - "
            "Author extraction should work correctly"
        )
    
    def test_author_extraction_two_word_names(self):
        """
        Test that two-word author names (e.g., "Chris P") are extracted correctly.
        """
        # Two-word author name
        line = "EH100512-15 1410.17    06/09/2024  Chris P     Don't run SMS/Email if not active"
        columns = {'ref': 0, 'date': 20}
        
        result = self._parse_row_directly(line, columns)
        
        self.assertEqual(
            result['author'], 
            'Chris P',
            f"Expected author 'Chris P' but got '{result['author']}' - "
            "Two-word author names should be extracted correctly"
        )
    
    def test_date_extraction_preservation(self):
        """
        Test that dates continue to be extracted and normalized correctly.
        
        Requirement 3.3: WHEN parsing files with properly formatted modification headers 
        THEN the system SHALL CONTINUE TO extract all other fields (author, date, description) correctly
        """
        # Date extraction and normalization
        line = "EH100512    15/03/2024  Jane  Updated logic"
        columns = {'ref': 0, 'date': 15}
        
        result = self._parse_row_directly(line, columns)
        
        # Date should be normalized to ISO 8601 format (YYYY-MM-DD)
        self.assertEqual(
            result['date'], 
            '2024-03-15',
            f"Expected date '2024-03-15' but got '{result['date']}' - "
            "Date should be normalized to ISO 8601 format"
        )
    
    def test_description_extraction_preservation(self):
        """
        Test that descriptions continue to be extracted correctly.
        
        Requirement 3.3: WHEN parsing files with properly formatted modification headers 
        THEN the system SHALL CONTINUE TO extract all other fields (author, date, description) correctly
        """
        # Description extraction
        line = "EH100512    15/03/2024  Jane  Updated logic for new feature"
        columns = {'ref': 0, 'date': 15}
        
        result = self._parse_row_directly(line, columns)
        
        self.assertEqual(
            result['description'], 
            'Updated logic for new feature',
            f"Expected description 'Updated logic for new feature' but got '{result['description']}' - "
            "Description should be extracted correctly"
        )
    
    def test_multiple_references_without_suffixes(self):
        """
        Test that multiple references without suffixes are extracted correctly.
        """
        test_cases = [
            ("EH100512    15/03/2024  Jane  Updated logic", "EH100512"),
            ("EH100058    01/02/2024  John  Fixed issue", "EH100058"),
            ("EH100001    10/01/2024  Bob   Initial commit", "EH100001"),
        ]
        
        for line, expected_ref in test_cases:
            columns = {'ref': 0, 'date': 15}
            result = self._parse_row_directly(line, columns)
            
            self.assertEqual(
                result['reference'], 
                expected_ref,
                f"Expected reference '{expected_ref}' but got '{result['reference']}'"
            )
    
    def test_edge_case_minimal_spacing(self):
        """
        Test that references are correctly extracted with minimal spacing.
        """
        # Minimal spacing between columns
        line = "EH100512 15/03/2024 Jane Updated"
        columns = {'ref': 0, 'date': 9}
        
        result = self._parse_row_directly(line, columns)
        
        self.assertEqual(
            result['reference'], 
            'EH100512',
            f"Expected 'EH100512' but got '{result['reference']}' - "
            "Reference should be extracted correctly with minimal spacing"
        )
    
    def test_edge_case_extra_spacing(self):
        """
        Test that references are correctly extracted with extra spacing.
        """
        # Extra spacing between columns
        line = "EH100512                15/03/2024  Jane  Updated"
        columns = {'ref': 0, 'date': 25}
        
        result = self._parse_row_directly(line, columns)
        
        self.assertEqual(
            result['reference'], 
            'EH100512',
            f"Expected 'EH100512' but got '{result['reference']}' - "
            "Reference should be extracted correctly with extra spacing"
        )
    
    def test_real_world_example_no_suffix(self):
        """
        Test with real-world example without suffix.
        """
        # Real data without suffix
        line = "EH100512 1410.18    19/09/2024      Chilly          Use job_task_params for commshub"
        columns = {'ref': 0, 'date': 20}
        
        result = self._parse_row_directly(line, columns)
        
        self.assertEqual(
            result['reference'], 
            'EH100512',
            f"Expected 'EH100512' but got '{result['reference']}' - "
            "Real-world reference without suffix should be extracted correctly"
        )


if __name__ == '__main__':
    unittest.main()
