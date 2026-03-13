#!/usr/bin/env python3
"""
Parse file header comments to extract code references and author information.

Handles flexible column parsing for change history tables with variations in:
- Column positions and spacing (tabs vs spaces)
- Optional columns (e.g., missing "For" column)
- Multi-line descriptions
- Various reference ID formats
"""

import re
import sys
from typing import List, Dict, Tuple, Optional
from datetime import datetime


class HeaderParser:
    """Parse file headers to extract references and author information."""
    
    # Pattern to detect modification section
    MODIFICATIONS_PATTERN = re.compile(r'^\s*#\s*Modifications:', re.IGNORECASE)
    
    # Pattern to detect column headers
    HEADER_KEYWORDS = {'ref', 'for', 'date', 'who', 'description', 'author', 'change'}
    
    # Pattern to detect a data row (starts with non-whitespace after # and contains a date)
    DATE_PATTERN = re.compile(r'\d{1,2}/\d{1,2}/\d{4}')
    
    def __init__(self, max_header_lines: int = 100):
        """
        Initialize parser.
        
        Args:
            max_header_lines: Maximum lines to scan for header (default 100)
        """
        self.max_header_lines = max_header_lines
    
    def parse_file(self, filepath: str) -> Dict:
        """
        Parse a file and extract header metadata.
        
        Args:
            filepath: Path to .4gl file
            
        Returns:
            Dictionary with extracted references and authors
        """
        try:
            with open(filepath, 'r', encoding='utf-8', errors='ignore') as f:
                lines = f.readlines()
        except Exception as e:
            print(f"Error reading file {filepath}: {e}", file=sys.stderr)
            return {'file': filepath, 'file_references': [], 'file_authors': {}}
        
        # Extract header comments (first N lines)
        header_lines = self._extract_header_comments(lines)
        
        # Find and parse modifications section
        references = self._parse_modifications_section(header_lines)
        
        # Aggregate author information
        authors = self._aggregate_authors(references)
        
        return {
            'file': filepath,
            'file_references': references,
            'file_authors': authors
        }
    
    def _extract_header_comments(self, lines: List[str]) -> List[str]:
        """
        Extract header comment lines from file.
        
        Args:
            lines: All lines from file
            
        Returns:
            List of header comment lines
        """
        header_lines = []
        for i, line in enumerate(lines[:self.max_header_lines]):
            # Stop at first non-comment line after some content
            if i > 5 and not line.strip().startswith('#') and not line.strip():
                break
            if line.strip().startswith('#'):
                header_lines.append(line)
            elif header_lines and line.strip():
                # Continuation line (part of previous comment)
                header_lines.append('#' + line)
        
        return header_lines
    
    def _parse_modifications_section(self, header_lines: List[str]) -> List[Dict]:
        """
        Parse modifications section to extract references and authors.
        
        Args:
            header_lines: Header comment lines
            
        Returns:
            List of reference dictionaries
        """
        references = []
        
        # First, join lines that are broken (continuation lines without reference)
        joined_lines = self._join_broken_lines(header_lines)
        
        # Find modifications section
        mod_idx = None
        for i, line in enumerate(joined_lines):
            if self.MODIFICATIONS_PATTERN.search(line):
                mod_idx = i
                break
        
        if mod_idx is None:
            return references
        
        # Find column header line
        header_line_idx = None
        for i in range(mod_idx + 1, len(joined_lines)):
            line = joined_lines[i]
            # Look for line with column keywords
            if any(keyword in line.lower() for keyword in self.HEADER_KEYWORDS):
                header_line_idx = i
                break
        
        if header_line_idx is None:
            return references
        
        # Parse column positions from header
        header_line = joined_lines[header_line_idx]
        columns = self._detect_columns(header_line)
        
        # Parse data rows
        for i in range(header_line_idx + 1, len(joined_lines)):
            line = joined_lines[i]
            
            # Skip separator lines and empty lines
            if not line.strip() or line.strip().startswith('#-'):
                continue
            
            # Remove comment marker
            line = line.lstrip('#').strip()
            
            # Check if line is a data row (contains a date)
            if not self._is_data_row(line):
                continue
            
            # Parse row
            ref_data = self._parse_row(line, columns, joined_lines, i, header_line_idx)
            if ref_data:
                references.append(ref_data)
        
        return references
    
    def _join_broken_lines(self, lines: List[str]) -> List[str]:
        """
        Join lines that are broken in the middle (continuation lines).
        
        Args:
            lines: Header lines
            
        Returns:
            List of joined lines
        """
        joined = []
        i = 0
        while i < len(lines):
            line = lines[i]
            
            # Check if next line is a continuation (doesn't start with # or is empty)
            while i + 1 < len(lines):
                next_line = lines[i + 1]
                # If next line doesn't start with # and isn't empty, it's a continuation
                if next_line.strip() and not next_line.strip().startswith('#'):
                    # Join the lines
                    line = line.rstrip('\n') + ' ' + next_line.lstrip('#').strip()
                    i += 1
                else:
                    break
            
            joined.append(line)
            i += 1
        
        return joined
    
    def _detect_columns(self, header_line: str) -> Dict[str, int]:
        """
        Detect column positions from header line.
        
        Args:
            header_line: Header line with column names
            
        Returns:
            Dictionary mapping column names to start positions
        """
        columns = {}
        
        # Remove comment marker
        header_line = header_line.lstrip('#').strip()
        
        # Find positions of known column keywords (case-insensitive)
        keywords = ['Ref', 'For', 'Date', 'Who', 'Description', 'Author', 'Change']
        
        for keyword in keywords:
            # Case-insensitive search
            pattern = re.compile(r'\b' + keyword + r'\b', re.IGNORECASE)
            match = pattern.search(header_line)
            if match:
                columns[keyword.lower()] = match.start()
        
        return columns
    
    def _is_data_row(self, line: str) -> bool:
        """
        Check if line is a data row (contains a date pattern).
        
        Args:
            line: Line to check
            
        Returns:
            True if line contains a date pattern
        """
        return self.DATE_PATTERN.search(line) is not None
    
    def _parse_row(self, line: str, columns: Dict, all_lines: List[str], 
                   line_idx: int, header_idx: int) -> Optional[Dict]:
        """
        Parse a single data row using column positions.
        
        Args:
            line: Data line to parse
            columns: Column position mapping
            all_lines: All header lines (for multi-line descriptions)
            line_idx: Current line index
            header_idx: Header line index
            
        Returns:
            Dictionary with parsed reference data or None
        """
        # Extract fields based on column positions
        reference = None
        author = None
        date_str = None
        description = None
        
        # Get column positions (sorted by position)
        col_positions = sorted([(name, pos) for name, pos in columns.items()], key=lambda x: x[1])
        
        # Extract reference from Ref column
        if 'ref' in columns:
            ref_pos = columns['ref']
            # Find next column position or end of line
            next_col_pos = None
            for name, pos in col_positions:
                if pos > ref_pos:
                    next_col_pos = pos
                    break
            
            if next_col_pos is None:
                next_col_pos = len(line)
            
            # Extract reference (trim whitespace)
            reference = line[ref_pos:next_col_pos].strip()
        
        # Extract date
        date_match = self.DATE_PATTERN.search(line)
        if date_match:
            date_str = date_match.group(0)
            date_idx = date_match.start()
            
            # Extract author (typically after date)
            after_date = line[date_idx + len(date_str):].strip()
            after_parts = after_date.split()
            
            if after_parts:
                # Author might be multiple tokens (e.g., "Chris P")
                author = after_parts[0]
                # Check if next token is also part of author (single letter or short name)
                if len(after_parts) > 1 and len(after_parts[1]) <= 2:
                    author = author + ' ' + after_parts[1]
                    desc_start = 2
                else:
                    desc_start = 1
                
                # Description is rest after author
                if len(after_parts) > desc_start:
                    description = ' '.join(after_parts[desc_start:])
        
        # Handle multi-line descriptions
        if description is None:
            description = ''
        
        # Check for continuation lines (only if they don't contain a date)
        for i in range(line_idx + 1, min(line_idx + 3, len(all_lines))):
            next_line = all_lines[i].lstrip('#').strip()
            # Continuation lines don't contain a date and aren't separators
            if next_line and not self._is_data_row(next_line) and not next_line.startswith('-'):
                # Only add if it looks like a continuation (starts with lowercase or special char)
                if next_line and (next_line[0].islower() or next_line[0] in '-,'):
                    description += ' ' + next_line
                else:
                    break
            else:
                break
        
        # Normalize date to ISO 8601
        if date_str:
            try:
                date_obj = datetime.strptime(date_str, '%d/%m/%Y')
                date_str = date_obj.strftime('%Y-%m-%d')
            except ValueError:
                pass
        
        return {
            'reference': reference,
            'author': author,
            'date': date_str,
            'description': description.strip()
        }
    
    def _aggregate_authors(self, references: List[Dict]) -> Dict[str, Dict]:
        """
        Aggregate author information from references.
        
        Args:
            references: List of reference dictionaries
            
        Returns:
            Dictionary mapping author names to their statistics
        """
        authors = {}
        
        for ref in references:
            author = ref.get('author')
            if not author:
                continue
            
            if author not in authors:
                authors[author] = {
                    'author': author,
                    'first_change': ref.get('date'),
                    'last_change': ref.get('date'),
                    'count': 0
                }
            
            authors[author]['count'] += 1
            
            # Update date range
            if ref.get('date'):
                if authors[author]['first_change'] is None or ref['date'] < authors[author]['first_change']:
                    authors[author]['first_change'] = ref['date']
                if authors[author]['last_change'] is None or ref['date'] > authors[author]['last_change']:
                    authors[author]['last_change'] = ref['date']
        
        return list(authors.values())


def main():
    """Command-line interface for header parser."""
    if len(sys.argv) < 2:
        print("Usage: python3 parse_headers.py <file.4gl>", file=sys.stderr)
        sys.exit(1)
    
    filepath = sys.argv[1]
    parser = HeaderParser()
    result = parser.parse_file(filepath)
    
    import json
    print(json.dumps(result, indent=2))


if __name__ == '__main__':
    main()
