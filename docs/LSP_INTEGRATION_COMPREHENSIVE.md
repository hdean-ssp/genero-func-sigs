# Comprehensive LSP Integration: Full Tool Capabilities

## Overview

This tool provides a rich set of code analysis capabilities that can power a comprehensive Genero Language Server. Rather than just reference search, the LSP can leverage function signatures, call graphs, module dependencies, code quality metrics, and type information.

## Complete Feature Set for LSP Integration

### 1. Function Signatures & Navigation

**Data Available:**
- Function names, parameters, return types
- Line numbers (start/end)
- Parameter types and names
- Return value types

**LSP Capabilities:**
```
✓ Go-to-Definition: Jump to function definition
✓ Hover: Show function signature and metadata
✓ Completion: Autocomplete function names
✓ Document Symbols: Outline of all functions in file
✓ Workspace Symbols: Search all functions across codebase
✓ Signature Help: Show parameter info while typing
```

**Example:**
```
User hovers over: process_request(amount)
LSP shows:
  process_request(amount INTEGER): result DECIMAL
  Line 15-42 in ./src/utils.4gl
  Calls: validate_input, calculate, log_message
  Called by: main, handle_request
```

### 2. Call Graphs & Dependencies

**Data Available:**
- Which functions call which functions
- Call depth and chains
- Dead code (functions never called)
- Dependency chains

**LSP Capabilities:**
```
✓ Find References: Show all calls to a function
✓ Find Implementations: Show all functions calling this one
✓ Code Lens: Display "X calls" and "Called by Y" inline
✓ Diagnostics: Warn about dead code
✓ Refactoring: Safe rename with call graph awareness
```

**Example:**
```
User right-clicks on: calculate()
LSP shows:
  Called by: process_request, handle_payment, batch_process
  Calls: validate_amount, apply_tax, format_result
  
Code Lens displays:
  "Called by 3 functions" (clickable)
  "Calls 3 functions" (clickable)
```

### 3. Module Dependencies

**Data Available:**
- Module definitions (.m3 files)
- File dependencies (L4GLS, U4GLS, 4GLS)
- Module structure and organization

**LSP Capabilities:**
```
✓ Go-to-Definition: Jump to module files
✓ Hover: Show module composition
✓ Diagnostics: Warn about missing dependencies
✓ Code Lens: Show module structure
✓ Workspace Symbols: Search modules
```

**Example:**
```
User hovers over: IMPORT "core"
LSP shows:
  Module: core
  Files: utils.4gl, helpers.4gl, constants.4gl
  Dependencies: stdlib, system
  Used by: 12 modules
```

### 4. Code Quality Metrics

**Data Available:**
- Lines of Code (LOC)
- Cyclomatic Complexity
- Variable count
- Parameter count
- Return count
- Call depth

**LSP Capabilities:**
```
✓ Diagnostics: Flag overly complex functions
✓ Code Lens: Display metrics inline
✓ Hover: Show detailed metrics
✓ Quick Fix: Suggest refactoring
✓ Performance Warnings: Identify problematic patterns
```

**Example:**
```
User hovers over: complex_calculation()
LSP shows:
  Complexity: 18 (⚠️ High - consider refactoring)
  LOC: 156
  Parameters: 8
  Variables: 23
  Call Depth: 5
  
Diagnostic: "Function complexity exceeds threshold (18 > 10)"
Quick Fix: "Extract method" suggestion
```

### 5. File Headers & References

**Data Available:**
- Code references (PRB-299, EH100512, etc.)
- Authors and modification dates
- Change descriptions
- Reference variants (EH100512-9a, EH100512-15)

**LSP Capabilities:**
```
✓ Hover: Show reference details
✓ Completion: Autocomplete reference IDs
✓ Find References: Find all files with reference
✓ Diagnostics: Flag invalid/unknown references
✓ Code Lens: Show "Modified by X on date"
✓ Go-to-Definition: Jump to files with reference
```

**Example:**
```
User hovers over: EH100512
LSP shows:
  Reference: EH100512
  Variants: EH100512-9a, EH100512-15
  Modified by: Chilly, Chris P, John
  Last change: 2024-09-19
  Files affected: 3
  Description: Use job_task_params for commshub
```

### 6. Type Resolution & Schema

**Data Available:**
- Database schema types
- LIKE type references
- Type mappings
- Type hierarchies

**LSP Capabilities:**
```
✓ Hover: Show resolved types
✓ Diagnostics: Type mismatch warnings
✓ Completion: Type-aware suggestions
✓ Go-to-Definition: Jump to type definitions
✓ Refactoring: Type-safe rename
```

**Example:**
```
User hovers over: customer_record LIKE customers
LSP shows:
  Type: RECORD (from schema)
  Fields: id INTEGER, name STRING, email STRING
  Database: customers table
  Used in: 5 functions
```

## LSP Architecture for Full Integration

```
┌─────────────────────────────────────────────────────────┐
│         Genero Language Server (Python)                 │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  ┌──────────────────────────────────────────────────┐  │
│  │ Database Layer                                   │  │
│  │ ├─ workspace.db (signatures, call graphs)       │  │
│  │ ├─ modules.db (module dependencies)             │  │
│  │ ├─ schema.db (type information)                 │  │
│  │ └─ headers.db (references, authors)             │  │
│  └──────────────────────────────────────────────────┘  │
│                                                         │
│  ┌──────────────────────────────────────────────────┐  │
│  │ Query Layer (Existing Tools)                     │  │
│  │ ├─ query_db.py (function queries)               │  │
│  │ ├─ query_headers.py (reference queries)         │  │
│  │ ├─ quality_analyzer.py (metrics)                │  │
│  │ └─ resolve_types.py (type resolution)           │  │
│  └──────────────────────────────────────────────────┘  │
│                                                         │
│  ┌──────────────────────────────────────────────────┐  │
│  │ LSP Handlers                                     │  │
│  │ ├─ hover_handler()                              │  │
│  │ ├─ definition_handler()                         │  │
│  │ ├─ references_handler()                         │  │
│  │ ├─ completion_handler()                         │  │
│  │ ├─ document_symbols_handler()                   │  │
│  │ ├─ workspace_symbols_handler()                  │  │
│  │ ├─ diagnostics_handler()                        │  │
│  │ ├─ code_lens_handler()                          │  │
│  │ └─ signature_help_handler()                     │  │
│  └──────────────────────────────────────────────────┘  │
│                                                         │
│  ┌──────────────────────────────────────────────────┐  │
│  │ LSP Protocol Handler (pygls)                     │  │
│  └──────────────────────────────────────────────────┘  │
│                                                         │
└─────────────────────────────────────────────────────────┘
         ↓ (JSON-RPC over stdio)
    Editor (VS Code, Vim, Neovim)
```

## LSP Capabilities Matrix

| Feature | Data Source | Complexity | Value |
|---------|-------------|-----------|-------|
| Go-to-Definition | Signatures | Low | High |
| Hover Info | Signatures + Metrics | Low | High |
| Find References | Call Graphs | Medium | High |
| Completion | Signatures + References | Low | High |
| Document Symbols | Signatures | Low | High |
| Workspace Symbols | Signatures | Low | High |
| Code Lens | Call Graphs + Metrics | Medium | High |
| Diagnostics | Metrics + References | Medium | High |
| Type Hover | Schema + Types | Medium | Medium |
| Signature Help | Signatures | Low | Medium |
| Module Navigation | Modules | Low | Medium |
| Reference Tracking | Headers | Low | Medium |

## Implementation Modules

```
lsp_server/
├── __init__.py
├── server.py                    # Main LSP server
├── handlers/
│   ├── __init__.py
│   ├── navigation.py            # Go-to-def, find-refs
│   ├── hover.py                 # Hover information
│   ├── completion.py            # Autocomplete
│   ├── symbols.py               # Document/workspace symbols
│   ├── diagnostics.py           # Quality warnings
│   ├── code_lens.py             # Inline metrics
│   └── signature_help.py        # Parameter hints
├── database/
│   ├── __init__.py
│   ├── manager.py               # Database connections
│   ├── cache.py                 # In-memory caching
│   └── watcher.py               # File watching
├── query/
│   ├── __init__.py
│   ├── functions.py             # Wrap query_db.py
│   ├── references.py            # Wrap query_headers.py
│   ├── metrics.py               # Wrap quality_analyzer.py
│   └── types.py                 # Wrap resolve_types.py
├── analysis/
│   ├── __init__.py
│   ├── extractor.py             # Extract symbols from code
│   ├── validator.py             # Validate references
│   └── ranker.py                # Rank completion results
└── config.py                    # Configuration
```

## Reusable Components from Existing Tool

```python
# Direct imports (no modification needed)
from scripts.query_db import (
    query_function,
    search_functions,
    list_file_functions,
    find_function_dependencies,
    find_function_dependents,
    find_dead_code,
    find_functions_in_module,
    find_module_for_function
)

from scripts.query_headers import (
    search_references,
    search_reference_prefix,
    find_files_by_reference,
    find_files_by_author,
    get_file_references,
    find_author_expertise
)

from scripts.quality_analyzer import (
    QualityAnalyzer,
    find_complex_functions,
    get_function_metrics
)

from scripts.resolve_types import (
    resolve_type,
    get_type_definition
)
```

## Implementation Phases

### Phase 1: Foundation (Week 1-2)
- [ ] LSP server skeleton with pygls
- [ ] Database connection & caching layer
- [ ] Hover handler (function signatures)
- [ ] Go-to-definition handler
- [ ] Basic completion (function names)

**Deliverable:** Basic navigation and hover

### Phase 2: Call Graphs & Metrics (Week 2-3)
- [ ] Find references handler
- [ ] Code lens (call counts, metrics)
- [ ] Diagnostics (complexity warnings)
- [ ] Document symbols
- [ ] Workspace symbols

**Deliverable:** Full navigation + quality insights

### Phase 3: References & Types (Week 3-4)
- [ ] Reference hover and completion
- [ ] Type resolution hover
- [ ] Module navigation
- [ ] Signature help
- [ ] Advanced diagnostics

**Deliverable:** Complete IDE experience

### Phase 4: Polish & Distribution (Week 4-5)
- [ ] Performance optimization
- [ ] Caching strategy
- [ ] Configuration system
- [ ] Editor extensions (VS Code, Vim)
- [ ] Documentation & examples

**Deliverable:** Production-ready LSP

## Performance Considerations

**Database Optimization:**
- Load all databases at startup (< 1 second)
- In-memory caching for frequent queries
- LRU cache for hover/completion results
- Lazy loading for large result sets

**Query Performance:**
- Function lookup: < 1ms
- Pattern search: < 10ms
- Call graph traversal: < 50ms
- Metrics calculation: < 5ms

**Memory Usage:**
- Typical codebase: 50-200 MB
- Configurable cache size
- Incremental updates for large changes

## Testing Strategy

```python
# Unit tests
test_hover_handler()
test_definition_handler()
test_references_handler()
test_completion_handler()
test_diagnostics_handler()
test_code_lens_handler()

# Integration tests
test_lsp_server_startup()
test_database_loading()
test_editor_communication()
test_query_accuracy()

# Performance tests
test_query_performance()
test_memory_usage()
test_concurrent_requests()
```

## Estimated Effort

- **LSP Server**: 60-80 hours
- **Database Integration**: 20-30 hours
- **Handlers**: 40-60 hours
- **Testing**: 20-30 hours
- **Documentation**: 10-15 hours
- **Editor Extensions**: 20-30 hours (per editor)
- **Total**: 170-245 hours for full implementation

## Why This Approach Works

1. **Leverages Existing Data**: All analysis already done, LSP just presents it
2. **No Tree-Sitter Needed**: Existing parsing is sufficient
3. **High Value**: Provides professional IDE features immediately
4. **Incremental**: Can add features phase by phase
5. **Reusable**: All query code already tested and working

## Next Steps

1. Evaluate LSP framework (pygls recommended)
2. Create LSP server skeleton
3. Implement database manager
4. Add hover handler (MVP)
5. Test with VS Code
6. Iterate on remaining handlers
