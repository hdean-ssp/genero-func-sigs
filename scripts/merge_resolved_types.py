#!/usr/bin/env python3
"""
Merge resolved types from workspace_resolved.json into workspace.db.

This script:
1. Reads workspace_resolved.json (output from resolve_types.py)
2. Updates the parameters table in workspace.db with resolved type information
3. Stores actual_type, is_like_reference, resolved status, and resolution errors
"""

import json
import sqlite3
import sys
from pathlib import Path
from typing import Dict, List, Any, Optional


class ResolvedTypeMerger:
    """Merges resolved types into the workspace database."""
    
    def __init__(self, db_path: str):
        """Initialize merger with database connection."""
        self.db_path = db_path
        self.conn = sqlite3.connect(db_path)
        self.cursor = self.conn.cursor()
        self.stats = {
            'parameters_updated': 0,
            'parameters_resolved': 0,
            'parameters_unresolved': 0,
            'errors': []
        }
    
    def _ensure_columns(self):
        """Ensure resolved type columns exist in parameters table."""
        try:
            # Check if columns exist
            self.cursor.execute("PRAGMA table_info(parameters)")
            columns = {row[1] for row in self.cursor.fetchall()}
            
            # Add missing columns
            if 'actual_type' not in columns:
                self.cursor.execute("ALTER TABLE parameters ADD COLUMN actual_type TEXT")
            
            if 'is_like_reference' not in columns:
                self.cursor.execute("ALTER TABLE parameters ADD COLUMN is_like_reference INTEGER DEFAULT 0")
            
            if 'resolved' not in columns:
                self.cursor.execute("ALTER TABLE parameters ADD COLUMN resolved INTEGER DEFAULT 0")
            
            if 'resolution_error' not in columns:
                self.cursor.execute("ALTER TABLE parameters ADD COLUMN resolution_error TEXT")
            
            if 'table_name' not in columns:
                self.cursor.execute("ALTER TABLE parameters ADD COLUMN table_name TEXT")
            
            if 'columns' not in columns:
                self.cursor.execute("ALTER TABLE parameters ADD COLUMN columns TEXT")
            
            if 'types' not in columns:
                self.cursor.execute("ALTER TABLE parameters ADD COLUMN types TEXT")
            
            self.conn.commit()
        except sqlite3.Error as e:
            self.stats['errors'].append(f"Failed to ensure columns: {e}")
    
    def merge_resolved_types(self, workspace_resolved_path: str) -> None:
        """
        Merge resolved types from workspace_resolved.json into database.
        
        Args:
            workspace_resolved_path: Path to workspace_resolved.json
        """
        # Load resolved types
        try:
            with open(workspace_resolved_path, 'r') as f:
                workspace_resolved = json.load(f)
        except FileNotFoundError:
            self.stats['errors'].append(f"workspace_resolved.json not found: {workspace_resolved_path}")
            return
        except json.JSONDecodeError as e:
            self.stats['errors'].append(f"Invalid JSON in workspace_resolved.json: {e}")
            return
        
        # Ensure columns exist
        self._ensure_columns()
        
        # Process each file's functions
        for file_path, functions in workspace_resolved.items():
            if file_path == '_metadata':
                continue
            
            if not isinstance(functions, list):
                continue
            
            # Process each function
            for func in functions:
                func_name = func.get('name')
                if not func_name:
                    continue
                
                # Get function ID from database
                self.cursor.execute('SELECT id FROM functions WHERE name = ?', (func_name,))
                func_row = self.cursor.fetchone()
                
                if not func_row:
                    continue
                
                func_id = func_row[0]
                
                # Process parameters
                if 'parameters' in func:
                    for param_idx, param in enumerate(func['parameters']):
                        param_name = param.get('name')
                        if not param_name:
                            continue
                        
                        # Build update data
                        update_data = {
                            'is_like_reference': 1 if param.get('is_like_reference') else 0,
                            'resolved': 1 if param.get('resolved') else 0,
                            'resolution_error': param.get('error'),
                            'actual_type': None,
                            'table_name': param.get('table'),
                            'columns': None,
                            'types': None
                        }
                        
                        # Extract resolved type information
                        if param.get('types'):
                            types_list = param['types']
                            if isinstance(types_list, list):
                                update_data['actual_type'] = types_list[0] if types_list else None
                                update_data['types'] = json.dumps(types_list)
                            else:
                                update_data['actual_type'] = types_list
                                update_data['types'] = json.dumps([types_list])
                        
                        if param.get('columns'):
                            columns_list = param['columns']
                            if isinstance(columns_list, list):
                                update_data['columns'] = ','.join(columns_list)
                            else:
                                update_data['columns'] = columns_list
                        
                        # Update database
                        try:
                            self.cursor.execute('''
                                UPDATE parameters 
                                SET actual_type = ?, 
                                    is_like_reference = ?, 
                                    resolved = ?, 
                                    resolution_error = ?,
                                    table_name = ?,
                                    columns = ?,
                                    types = ?
                                WHERE function_id = ? AND name = ?
                            ''', (
                                update_data['actual_type'],
                                update_data['is_like_reference'],
                                update_data['resolved'],
                                update_data['resolution_error'],
                                update_data['table_name'],
                                update_data['columns'],
                                update_data['types'],
                                func_id,
                                param_name
                            ))
                            
                            if self.cursor.rowcount > 0:
                                self.stats['parameters_updated'] += 1
                                if update_data['resolved']:
                                    self.stats['parameters_resolved'] += 1
                                else:
                                    self.stats['parameters_unresolved'] += 1
                        
                        except sqlite3.Error as e:
                            self.stats['errors'].append(f"Failed to update parameter {param_name} in function {func_name}: {e}")
        
        self.conn.commit()
    
    def close(self):
        """Close database connection."""
        self.conn.close()


def main():
    """Main entry point."""
    if len(sys.argv) < 2:
        print("Usage: merge_resolved_types.py <workspace_resolved.json> [workspace.db]")
        print()
        print("Merges resolved types from workspace_resolved.json into workspace.db")
        sys.exit(1)
    
    workspace_resolved_path = sys.argv[1]
    db_path = sys.argv[2] if len(sys.argv) > 2 else "workspace.db"
    
    # Validate inputs
    if not Path(workspace_resolved_path).exists():
        print(f"Error: workspace_resolved.json not found: {workspace_resolved_path}", file=sys.stderr)
        sys.exit(1)
    
    if not Path(db_path).exists():
        print(f"Error: workspace.db not found: {db_path}", file=sys.stderr)
        sys.exit(1)
    
    # Merge resolved types
    merger = ResolvedTypeMerger(db_path)
    try:
        merger.merge_resolved_types(workspace_resolved_path)
        
        print(f"[OK] Merged resolved types into {db_path}")
        print(f"[OK] Parameters updated: {merger.stats['parameters_updated']}")
        print(f"[OK] Parameters resolved: {merger.stats['parameters_resolved']}")
        print(f"[OK] Parameters unresolved: {merger.stats['parameters_unresolved']}")
        
        if merger.stats['errors']:
            print(f"\n[WARN] Errors ({len(merger.stats['errors'])}):")
            for error in merger.stats['errors'][:5]:
                print(f"  - {error}")
            if len(merger.stats['errors']) > 5:
                print(f"  ... and {len(merger.stats['errors']) - 5} more")
    
    finally:
        merger.close()


if __name__ == '__main__':
    main()
