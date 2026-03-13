#!/usr/bin/env python3
"""
Query functions for file header metadata (references and authors).

Provides functions to search and filter files by:
- Code references (tickets, issue IDs)
- Authors
- Change dates
- Author expertise areas
"""

import sqlite3
import json
import sys
from typing import List, Dict, Optional, Tuple


def find_files_by_reference(db_file: str, reference: str) -> List[Dict]:
    """
    Find all files modified for a specific code reference.
    
    Args:
        db_file: Path to SQLite database
        reference: Code reference to search for (e.g., "PRB-299", "EH100512")
        
    Returns:
        List of files with matching references
    """
    try:
        conn = sqlite3.connect(db_file)
        conn.row_factory = sqlite3.Row
        cursor = conn.cursor()
        
        cursor.execute("""
            SELECT DISTINCT f.path, fr.reference, fr.author, fr.date, fr.description
            FROM file_references fr
            JOIN files f ON fr.file_id = f.id
            WHERE fr.reference = ?
            ORDER BY f.path
        """, (reference,))
        
        results = [dict(row) for row in cursor.fetchall()]
        conn.close()
        return results
    except Exception as e:
        print(f"Error querying database: {e}", file=sys.stderr)
        return []


def find_files_by_author(db_file: str, author: str) -> List[Dict]:
    """
    Find all files authored or modified by a specific person.
    
    Args:
        db_file: Path to SQLite database
        author: Author name to search for
        
    Returns:
        List of files with changes by this author
    """
    try:
        conn = sqlite3.connect(db_file)
        conn.row_factory = sqlite3.Row
        cursor = conn.cursor()
        
        cursor.execute("""
            SELECT DISTINCT f.path, fr.reference, fr.author, fr.date, fr.description
            FROM file_references fr
            JOIN files f ON fr.file_id = f.id
            WHERE fr.author = ?
            ORDER BY f.path, fr.date DESC
        """, (author,))
        
        results = [dict(row) for row in cursor.fetchall()]
        conn.close()
        return results
    except Exception as e:
        print(f"Error querying database: {e}", file=sys.stderr)
        return []


def get_file_references(db_file: str, filepath: str) -> List[Dict]:
    """
    Get all code references for a specific file.
    
    Args:
        db_file: Path to SQLite database
        filepath: Path to file
        
    Returns:
        List of references for the file
    """
    try:
        conn = sqlite3.connect(db_file)
        conn.row_factory = sqlite3.Row
        cursor = conn.cursor()
        
        cursor.execute("""
            SELECT reference, author, date, description
            FROM file_references
            WHERE file_id = (SELECT id FROM files WHERE path = ?)
            ORDER BY date DESC
        """, (filepath,))
        
        results = [dict(row) for row in cursor.fetchall()]
        conn.close()
        return results
    except Exception as e:
        print(f"Error querying database: {e}", file=sys.stderr)
        return []


def get_file_authors(db_file: str, filepath: str) -> List[Dict]:
    """
    Get all authors who modified a specific file.
    
    Args:
        db_file: Path to SQLite database
        filepath: Path to file
        
    Returns:
        List of authors with their statistics
    """
    try:
        conn = sqlite3.connect(db_file)
        conn.row_factory = sqlite3.Row
        cursor = conn.cursor()
        
        cursor.execute("""
            SELECT author, first_change, last_change, change_count
            FROM file_authors
            WHERE file_id = (SELECT id FROM files WHERE path = ?)
            ORDER BY change_count DESC
        """, (filepath,))
        
        results = [dict(row) for row in cursor.fetchall()]
        conn.close()
        return results
    except Exception as e:
        print(f"Error querying database: {e}", file=sys.stderr)
        return []


def find_author_expertise(db_file: str, author: str) -> List[Dict]:
    """
    Find what areas/files an author has expertise in (based on changes).
    
    Args:
        db_file: Path to SQLite database
        author: Author name
        
    Returns:
        List of files with change counts, sorted by frequency
    """
    try:
        conn = sqlite3.connect(db_file)
        conn.row_factory = sqlite3.Row
        cursor = conn.cursor()
        
        cursor.execute("""
            SELECT f.path, COUNT(*) as change_count, 
                   MIN(fr.date) as first_change, MAX(fr.date) as last_change
            FROM file_references fr
            JOIN files f ON fr.file_id = f.id
            WHERE fr.author = ?
            GROUP BY f.path
            ORDER BY change_count DESC
        """, (author,))
        
        results = [dict(row) for row in cursor.fetchall()]
        conn.close()
        return results
    except Exception as e:
        print(f"Error querying database: {e}", file=sys.stderr)
        return []


def find_recent_changes(db_file: str, days: int = 30) -> List[Dict]:
    """
    Find files modified in the last N days.
    
    Args:
        db_file: Path to SQLite database
        days: Number of days to look back (default 30)
        
    Returns:
        List of recently modified files
    """
    try:
        conn = sqlite3.connect(db_file)
        conn.row_factory = sqlite3.Row
        cursor = conn.cursor()
        
        cursor.execute("""
            SELECT DISTINCT f.path, fr.reference, fr.author, fr.date, fr.description
            FROM file_references fr
            JOIN files f ON fr.file_id = f.id
            WHERE fr.date >= date('now', '-' || ? || ' days')
            ORDER BY fr.date DESC
        """, (days,))
        
        results = [dict(row) for row in cursor.fetchall()]
        conn.close()
        return results
    except Exception as e:
        print(f"Error querying database: {e}", file=sys.stderr)
        return []


def search_references(db_file: str, pattern: str) -> List[Dict]:
    """
    Search for code references matching a pattern.
    
    Args:
        db_file: Path to SQLite database
        pattern: Pattern to search for (supports % and _ wildcards)
        
    Returns:
        List of matching references
    """
    try:
        conn = sqlite3.connect(db_file)
        conn.row_factory = sqlite3.Row
        cursor = conn.cursor()
        
        cursor.execute("""
            SELECT DISTINCT f.path, fr.reference, fr.author, fr.date, fr.description
            FROM file_references fr
            JOIN files f ON fr.file_id = f.id
            WHERE fr.reference LIKE ?
            ORDER BY f.path, fr.date DESC
        """, (pattern,))
        
        results = [dict(row) for row in cursor.fetchall()]
        conn.close()
        return results
    except Exception as e:
        print(f"Error querying database: {e}", file=sys.stderr)
        return []


def main():
    """Command-line interface for header queries."""
    if len(sys.argv) < 3:
        print("Usage: query_headers.py <command> <db_file> [args...]", file=sys.stderr)
        print("Commands:", file=sys.stderr)
        print("  find-reference <reference>", file=sys.stderr)
        print("  find-author <author>", file=sys.stderr)
        print("  file-references <filepath>", file=sys.stderr)
        print("  file-authors <filepath>", file=sys.stderr)
        print("  author-expertise <author>", file=sys.stderr)
        print("  recent-changes [days]", file=sys.stderr)
        print("  search-references <pattern>", file=sys.stderr)
        sys.exit(1)
    
    command = sys.argv[1]
    db_file = sys.argv[2]
    
    results = []
    
    if command == "find-reference" and len(sys.argv) > 3:
        results = find_files_by_reference(db_file, sys.argv[3])
    elif command == "find-author" and len(sys.argv) > 3:
        results = find_files_by_author(db_file, sys.argv[3])
    elif command == "file-references" and len(sys.argv) > 3:
        results = get_file_references(db_file, sys.argv[3])
    elif command == "file-authors" and len(sys.argv) > 3:
        results = get_file_authors(db_file, sys.argv[3])
    elif command == "author-expertise" and len(sys.argv) > 3:
        results = find_author_expertise(db_file, sys.argv[3])
    elif command == "recent-changes":
        days = int(sys.argv[3]) if len(sys.argv) > 3 else 30
        results = find_recent_changes(db_file, days)
    elif command == "search-references" and len(sys.argv) > 3:
        results = search_references(db_file, sys.argv[3])
    else:
        print(f"Unknown command: {command}", file=sys.stderr)
        sys.exit(1)
    
    print(json.dumps(results, indent=2))


if __name__ == "__main__":
    main()
