# LSP Integration Summary: Reference Search Tool

## Overview

This document outlines what's required to integrate the reference search tool into a generic Language Server Protocol (LSP) to provide IDE-like functionality for Genero code.

## Architecture

```
Genero Editor (VS Code, Vim, etc.)
    ↓
LSP Client
    ↓
LSP Server (Python-based)
    ├─ Reference Search Module (existing tool)
    ├─ Database Manager (workspace.db)
    └─ LSP Protocol Handler
    ↓
SQLite Database (workspace.db)
```

## Core Requirements

### 1. LSP Server Foundation
- **Language**: Python (leverages existing codebase)
- **Framework**: `pygls` (Python Language Server) or `python-lsp-server`
- **Entry Point**: Standalone process that communicates via JSON-RPC over stdio
- **Initialization**: Load `workspace.db` on startup, watch for changes

### 2. Database Integration
- **In-Memory Caching**: Load reference data at startup for fast queries
- **File Watching**: Monitor `workspace.db` for changes and reload
- **Query Layer**: Wrap existing `query_headers.py` functions
- **Connection Pool**: Maintain SQLite connection for concurrent requests

### 3. LSP Capabilities to Implement

#### Hover Information
```
User hovers over "EH100512" in editor
→ LSP requests textDocument/hover
→ Server queries database
→ Returns: Reference details (author, date, description, files modified)
```

#### Go-to-Definition / References
```
User clicks "Go to Definition" on "EH100512"
→ LSP requests textDocument/definition
→ Server returns list of files containing this reference
→ Editor opens first file or shows list
```

#### Code Lens
```
Display inline information above reference mentions:
"Modified by: Chilly on 2024-09-19 | 3 files affected"
```

#### Diagnostics
```
Highlight invalid or unknown references:
- Reference doesn't exist in database
- Reference is deprecated
- Reference has multiple variants (suggest alternatives)
```

#### Completion
```
User types "EH1" and presses Ctrl+Space
→ LSP requests textDocument/completion
→ Server returns matching references from database
→ Editor shows autocomplete list
```

#### Document Symbols
```
User requests document outline
→ LSP returns all references in current file
→ Editor shows hierarchical list
```

### 4. Implementation Modules

```
lsp_server/
├── __init__.py
├── server.py                 # Main LSP server entry point
├── handlers.py               # LSP request handlers
│   ├── hover_handler()
│   ├── definition_handler()
│   ├── completion_handler()
│   ├── diagnostics_handler()
│   └── document_symbols_handler()
├── database.py               # Database connection & caching
│   ├── DatabaseManager
│   ├── load_references()
│   ├── watch_database()
│   └── query_reference()
├── reference_extractor.py    # Extract references from code
│   ├── extract_references_from_line()
│   ├── find_reference_at_position()
│   └── get_reference_context()
└── config.py                 # Configuration & settings
```

### 5. Reference Extraction from Code

The LSP needs to identify references in Genero code:

```genero
# In modification headers (already handled)
# EH100512-9a    19/09/2024    Chilly    Description

# In comments
# TODO: Fix per EH100512
# See EH100512-9a for details

# In code (optional)
DEFINE g_reference = "EH100512"
```

**Implementation**: Regex patterns to find reference IDs in:
- File headers (existing)
- Comments
- String literals
- Variable assignments

### 6. Configuration

LSP server configuration (`.lsp-config.json` or similar):

```json
{
  "database": {
    "path": "workspace.db",
    "watch": true,
    "cache_size": 10000
  },
  "features": {
    "hover": true,
    "definition": true,
    "completion": true,
    "diagnostics": true,
    "code_lens": true
  },
  "reference_patterns": {
    "header": "^[A-Z]{2}\\d+(-\\d+[a-z]?)?",
    "comment": "[A-Z]{2}\\d+(-\\d+[a-z]?)?",
    "inline": "[A-Z]{2}\\d+(-\\d+[a-z]?)?"
  }
}
```

## Implementation Phases

### Phase 1: Foundation (Week 1)
- [ ] Set up LSP server skeleton with `pygls`
- [ ] Implement database connection & caching
- [ ] Add hover capability (simplest feature)
- [ ] Test with VS Code

### Phase 2: Core Features (Week 2)
- [ ] Implement go-to-definition
- [ ] Add completion support
- [ ] Implement document symbols
- [ ] Add reference extraction from code

### Phase 3: Advanced Features (Week 3)
- [ ] Add diagnostics (invalid references)
- [ ] Implement code lens
- [ ] Add configuration support
- [ ] Performance optimization

### Phase 4: Polish & Distribution (Week 4)
- [ ] Editor extensions (VS Code, Vim, Neovim)
- [ ] Documentation & examples
- [ ] Testing & bug fixes
- [ ] Release & packaging

## Reusable Components

From existing codebase:

```python
# Direct reuse
from scripts.query_headers import (
    search_references,
    search_reference_prefix,
    find_files_by_reference,
    find_files_by_author,
    get_file_references
)

# Adapt for LSP
from scripts.parse_headers import HeaderParser
```

## Editor Integration

### VS Code Extension
```typescript
// Extension activates LSP server
// Provides UI for reference navigation
// Registers commands for reference lookup
```

### Vim/Neovim Plugin
```lua
-- Uses LSP client built into Neovim
-- Provides keybindings for reference navigation
-- Integrates with native LSP UI
```

## Performance Considerations

- **Database Size**: Load only necessary references into memory
- **Query Caching**: Cache frequent queries (LRU cache)
- **Incremental Updates**: Watch database for changes, update cache
- **Lazy Loading**: Load reference data on-demand per file
- **Timeout**: Set reasonable timeouts for database queries (100ms)

## Testing Strategy

```python
# Unit tests
test_hover_handler()
test_definition_handler()
test_completion_handler()
test_reference_extraction()

# Integration tests
test_lsp_server_startup()
test_editor_communication()
test_database_updates()

# Performance tests
test_query_performance()
test_memory_usage()
```

## Estimated Effort

- **LSP Server**: 40-60 hours
- **Editor Extensions**: 20-30 hours (per editor)
- **Testing & Documentation**: 20-30 hours
- **Total**: 80-120 hours for full implementation

## Next Steps

1. Choose LSP framework (`pygls` recommended for Python)
2. Create LSP server skeleton
3. Implement database manager
4. Add hover handler (MVP)
5. Test with VS Code
6. Iterate on features based on feedback

## Resources

- [LSP Specification](https://microsoft.github.io/language-server-protocol/)
- [pygls Documentation](https://pygls.readthedocs.io/)
- [VS Code Extension API](https://code.visualstudio.com/api)
- [Neovim LSP](https://neovim.io/doc/user/lsp.html)
