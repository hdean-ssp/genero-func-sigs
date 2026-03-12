# Advanced Query Functionality

This document provides a detailed expansion of the advanced query capabilities planned for the Genero Function Signatures project.

## Overview

The advanced query system will enable developers to:
- Understand code dependencies and relationships
- Analyze code structure and complexity
- Identify dead code and unused components
- Track database schema dependencies
- Generate comprehensive code reports
- Support refactoring and impact analysis

## 1. Module Content Queries

### 1.1 find-modules-with-file

**Purpose:** Locate all modules that use a specific file

**Syntax:**
```bash
query.sh find-modules-with-file <filename>
```

**Examples:**
```bash
query.sh find-modules-with-file "util.4gl"
query.sh find-modules-with-file "lib/common.4gl"
```

**Output Format:**
```json
[
  {
    "module": "core",
    "file": "./modules/core.m3",
    "category": "U4GLS",
    "position": 3
  },
  {
    "module": "main",
    "file": "./modules/main.m3",
    "category": "4GLS",
    "position": 1
  }
]
```

**Use Cases:**
- Find all modules using a utility file
- Identify impact of changing a shared file
- Understand file dependencies
- Refactoring analysis

**Implementation Details:**
- Query module_files table for file_name matches
- Return module info and file category
- Sort by module name
- Include position in module file list

---

### 1.2 find-modules-with-function

**Purpose:** Find all modules containing a specific function

**Syntax:**
```bash
query.sh find-modules-with-function <function_name>
```

**Examples:**
```bash
query.sh find-modules-with-function "calculate_total"
query.sh find-modules-with-function "validate_*"
```

**Output Format:**
```json
[
  {
    "module": "accounting",
    "file": "./src/accounting.4gl",
    "function": "calculate_total",
    "line_start": 45,
    "line_end": 78,
    "signature": "45-78: calculate_total(amount DECIMAL):result DECIMAL"
  },
  {
    "module": "reports",
    "file": "./src/reports.4gl",
    "function": "calculate_total",
    "line_start": 120,
    "line_end": 145,
    "signature": "120-145: calculate_total(amount DECIMAL):result DECIMAL"
  }
]
```

**Use Cases:**
- Find all implementations of a function
- Identify duplicate functions across modules
- Understand function distribution
- Locate function definitions

**Implementation Details:**
- Join functions with files and modules
- Support pattern matching with wildcards
- Return full function metadata
- Sort by module name, then file

---

## 2. Fuzzy/Approximate Matching Queries

### 2.1 find-closest-function

**Purpose:** Find functions with similar names (typo tolerance)

**Syntax:**
```bash
query.sh find-closest-function <name> [--threshold 0.8] [--limit 10]
```

**Examples:**
```bash
query.sh find-closest-function "calcuate_total"  # Typo
query.sh find-closest-function "get_" --limit 20
query.sh find-closest-function "validate" --threshold 0.7
```

**Output Format:**
```json
[
  {
    "name": "calculate_total",
    "similarity": 0.95,
    "file": "./src/accounting.4gl",
    "signature": "45-78: calculate_total(amount DECIMAL):result DECIMAL",
    "distance": 1
  },
  {
    "name": "calculate_subtotal",
    "similarity": 0.88,
    "file": "./src/accounting.4gl",
    "signature": "80-110: calculate_subtotal(items ARRAY):result DECIMAL",
    "distance": 3
  }
]
```

**Algorithm Options:**
- Levenshtein distance (default)
- Jaro-Winkler similarity
- Soundex matching
- Prefix matching

**Use Cases:**
- Find functions when you don't remember exact name
- Identify similarly named functions
- Detect naming inconsistencies
- Support IDE autocomplete

**Implementation Details:**
- Calculate similarity score for all functions
- Sort by similarity (descending)
- Filter by threshold (default 0.8)
- Limit results (default 10)
- Return distance metric for debugging

---

### 2.2 find-closest-module

**Purpose:** Find modules with similar names

**Syntax:**
```bash
query.sh find-closest-module <name> [--threshold 0.8] [--limit 10]
```

**Examples:**
```bash
query.sh find-closest-module "acounting"  # Typo
query.sh find-closest-module "report"
```

**Output Format:**
```json
[
  {
    "name": "accounting",
    "similarity": 0.95,
    "file": "./modules/accounting.m3",
    "file_count": 12,
    "distance": 1
  }
]
```

**Use Cases:**
- Find modules by partial name
- Identify naming patterns
- Support module discovery

---

## 3. Dependency Analysis Queries

### 3.1 find-function-dependencies

**Purpose:** Identify all functions called by a specific function

**Syntax:**
```bash
query.sh find-function-dependencies <function_name> [--depth 1] [--format tree|json]
```

**Examples:**
```bash
query.sh find-function-dependencies "process_order"
query.sh find-function-dependencies "process_order" --depth 3
query.sh find-function-dependencies "process_order" --format tree
```

**Output Format (JSON):**
```json
{
  "function": "process_order",
  "file": "./src/orders.4gl",
  "direct_dependencies": [
    {
      "name": "validate_order",
      "file": "./src/orders.4gl",
      "type": "internal",
      "calls": 1
    },
    {
      "name": "calculate_total",
      "file": "./src/accounting.4gl",
      "type": "external",
      "calls": 2
    }
  ],
  "indirect_dependencies": [
    {
      "name": "validate_items",
      "file": "./src/items.4gl",
      "depth": 2,
      "path": ["process_order", "validate_order", "validate_items"]
    }
  ],
  "total_dependencies": 5,
  "circular_dependencies": []
}
```

**Output Format (Tree):**
```
process_order
├── validate_order (internal)
│   ├── validate_items (internal)
│   └── check_inventory (external)
├── calculate_total (external)
│   └── apply_tax (external)
└── save_order (internal)
```

**Use Cases:**
- Understand function call chains
- Identify dependencies before refactoring
- Detect circular dependencies
- Impact analysis
- Performance profiling

**Implementation Details:**
- Parse function bodies for CALL statements
- Build dependency graph
- Support depth limiting
- Detect cycles
- Cache results for performance

---

### 3.2 find-function-dependents

**Purpose:** Find all functions that call a specific function

**Syntax:**
```bash
query.sh find-function-dependents <function_name> [--depth 1] [--format tree|json]
```

**Examples:**
```bash
query.sh find-function-dependents "calculate_total"
query.sh find-function-dependents "calculate_total" --depth 2
```

**Output Format:**
```json
{
  "function": "calculate_total",
  "file": "./src/accounting.4gl",
  "direct_dependents": [
    {
      "name": "process_order",
      "file": "./src/orders.4gl",
      "calls": 2
    },
    {
      "name": "generate_invoice",
      "file": "./src/invoices.4gl",
      "calls": 1
    }
  ],
  "indirect_dependents": [
    {
      "name": "process_batch",
      "file": "./src/batch.4gl",
      "depth": 2,
      "path": ["process_batch", "process_order", "calculate_total"]
    }
  ],
  "total_dependents": 5,
  "impact_scope": "high"
}
```

**Use Cases:**
- Impact analysis before changes
- Identify affected functions
- Understand function usage
- Refactoring safety analysis
- Dead code detection

---

### 3.3 find-module-dependencies

**Purpose:** Identify all modules a module depends on

**Syntax:**
```bash
query.sh find-module-dependencies <module_name> [--format tree|json|graph]
```

**Examples:**
```bash
query.sh find-module-dependencies "accounting"
query.sh find-module-dependencies "accounting" --format tree
```

**Output Format:**
```json
{
  "module": "accounting",
  "file": "./modules/accounting.m3",
  "direct_dependencies": [
    {
      "module": "core",
      "type": "L4GLS",
      "files": ["lib_core.4gl"]
    },
    {
      "module": "utils",
      "type": "U4GLS",
      "files": ["util_math.4gl", "util_string.4gl"]
    }
  ],
  "indirect_dependencies": [
    {
      "module": "database",
      "depth": 2,
      "path": ["accounting", "core", "database"]
    }
  ],
  "circular_dependencies": [],
  "dependency_count": 3,
  "complexity_score": 0.65
}
```

**Use Cases:**
- Understand module architecture
- Identify circular dependencies
- Refactoring planning
- Module isolation analysis
- Build order determination

---

## 4. Type-Based Queries

### 4.1 find-functions-with-type

**Purpose:** Find all functions using a specific type

**Syntax:**
```bash
query.sh find-functions-with-type <type_name> [--filter parameter|return|both]
```

**Examples:**
```bash
query.sh find-functions-with-type "DECIMAL"
query.sh find-functions-with-type "DECIMAL" --filter parameter
query.sh find-functions-with-type "STRING" --filter return
```

**Output Format:**
```json
[
  {
    "function": "calculate_total",
    "file": "./src/accounting.4gl",
    "type": "DECIMAL",
    "usage": [
      {
        "position": "parameter",
        "name": "amount",
        "index": 1
      },
      {
        "position": "return",
        "name": "result",
        "index": 1
      }
    ],
    "count": 2
  },
  {
    "function": "apply_discount",
    "file": "./src/sales.4gl",
    "type": "DECIMAL",
    "usage": [
      {
        "position": "parameter",
        "name": "discount_rate",
        "index": 2
      }
    ],
    "count": 1
  }
]
```

**Use Cases:**
- Find all functions using a type
- Type migration analysis
- Type usage patterns
- Refactoring impact

---

### 4.2 find-functions-with-database-type

**Purpose:** Find functions using LIKE references to database tables

**Syntax:**
```bash
query.sh find-functions-with-database-type <table_name> [--column column_name]
```

**Examples:**
```bash
query.sh find-functions-with-database-type "customers"
query.sh find-functions-with-database-type "customers" --column "id"
```

**Output Format:**
```json
[
  {
    "function": "get_customer",
    "file": "./src/customers.4gl",
    "references": [
      {
        "type": "LIKE customers.*",
        "parameter": "customer_rec",
        "columns": ["id", "name", "email"]
      }
    ],
    "dependency_type": "direct"
  },
  {
    "function": "process_order",
    "file": "./src/orders.4gl",
    "references": [
      {
        "type": "LIKE customers.id",
        "parameter": "customer_id",
        "columns": ["id"]
      }
    ],
    "dependency_type": "column_specific"
  }
]
```

**Use Cases:**
- Schema change impact analysis
- Database refactoring planning
- Identify schema dependencies
- Data migration planning

---

### 4.3 find-functions-with-record

**Purpose:** Find functions using a specific record type

**Syntax:**
```bash
query.sh find-functions-with-record <record_name>
```

**Examples:**
```bash
query.sh find-functions-with-record "customer_record"
```

**Output Format:**
```json
[
  {
    "function": "validate_customer",
    "file": "./src/customers.4gl",
    "record_usage": {
      "parameter": "cust_rec",
      "fields_accessed": ["id", "name", "email"],
      "fields_modified": ["status"]
    }
  }
]
```

---

## 5. Cross-Reference Queries

### 5.1 find-file-usage

**Purpose:** Show comprehensive usage information for a file

**Syntax:**
```bash
query.sh find-file-usage <filename> [--format detailed|summary]
```

**Examples:**
```bash
query.sh find-file-usage "util.4gl"
query.sh find-file-usage "util.4gl" --format detailed
```

**Output Format:**
```json
{
  "file": "./src/util.4gl",
  "modules_using": [
    {
      "module": "core",
      "category": "U4GLS",
      "position": 2
    },
    {
      "module": "accounting",
      "category": "U4GLS",
      "position": 1
    }
  ],
  "functions_in_file": [
    {
      "name": "format_currency",
      "signature": "format_currency(amount DECIMAL):result STRING",
      "called_by": ["calculate_total", "generate_invoice"]
    },
    {
      "name": "validate_email",
      "signature": "validate_email(email STRING):result INTEGER",
      "called_by": ["process_customer", "update_contact"]
    }
  ],
  "total_functions": 5,
  "total_callers": 12,
  "usage_score": 0.85
}
```

**Use Cases:**
- Understand file importance
- Identify file dependencies
- Plan file refactoring
- Assess file removal impact

---

### 5.2 find-type-usage

**Purpose:** Show all usage of a specific type across codebase

**Syntax:**
```bash
query.sh find-type-usage <type_name> [--format detailed|summary]
```

**Examples:**
```bash
query.sh find-type-usage "DECIMAL"
query.sh find-type-usage "customer_record"
```

**Output Format:**
```json
{
  "type": "DECIMAL",
  "usage_count": 145,
  "functions_using": 42,
  "modules_affected": 8,
  "usage_breakdown": {
    "parameter": 89,
    "return": 34,
    "variable": 22
  },
  "top_users": [
    {
      "function": "calculate_total",
      "count": 5
    },
    {
      "function": "apply_tax",
      "count": 4
    }
  ],
  "modules": [
    {
      "module": "accounting",
      "count": 67
    },
    {
      "module": "sales",
      "count": 45
    }
  ]
}
```

---

## 6. Analysis Queries

### 6.1 analyze-module

**Purpose:** Generate comprehensive module analysis report

**Syntax:**
```bash
query.sh analyze-module <module_name> [--format json|html|text]
```

**Examples:**
```bash
query.sh analyze-module "accounting"
query.sh analyze-module "accounting" --format html > accounting_report.html
```

**Output Format:**
```json
{
  "module": "accounting",
  "file": "./modules/accounting.m3",
  "summary": {
    "total_files": 12,
    "total_functions": 45,
    "total_lines": 3500,
    "complexity_score": 0.72
  },
  "files": {
    "L4GLS": ["lib_core.4gl"],
    "U4GLS": ["util_math.4gl", "util_string.4gl"],
    "4GLS": ["main.4gl", "orders.4gl", "invoices.4gl"]
  },
  "functions": {
    "total": 45,
    "exported": 12,
    "internal": 33,
    "average_complexity": 2.3
  },
  "dependencies": {
    "modules": ["core", "utils"],
    "external_functions": 8,
    "circular_dependencies": 0
  },
  "metrics": {
    "cohesion": 0.85,
    "coupling": 0.45,
    "maintainability": 0.78,
    "test_coverage": 0.65
  },
  "recommendations": [
    "Consider breaking into smaller modules",
    "Reduce coupling with core module",
    "Improve test coverage for critical functions"
  ]
}
```

**Use Cases:**
- Module health assessment
- Architecture review
- Refactoring planning
- Quality metrics tracking

---

### 6.2 analyze-function

**Purpose:** Generate comprehensive function analysis report

**Syntax:**
```bash
query.sh analyze-function <function_name> [--format json|html|text]
```

**Examples:**
```bash
query.sh analyze-function "calculate_total"
query.sh analyze-function "calculate_total" --format html
```

**Output Format:**
```json
{
  "function": "calculate_total",
  "file": "./src/accounting.4gl",
  "module": "accounting",
  "signature": "45-78: calculate_total(amount DECIMAL, tax_rate DECIMAL):result DECIMAL, tax DECIMAL",
  "metrics": {
    "lines_of_code": 34,
    "cyclomatic_complexity": 3,
    "cognitive_complexity": 2.5,
    "parameters": 2,
    "returns": 2
  },
  "parameters": [
    {
      "name": "amount",
      "type": "DECIMAL",
      "usage": "input"
    },
    {
      "name": "tax_rate",
      "type": "DECIMAL",
      "usage": "input"
    }
  ],
  "returns": [
    {
      "name": "result",
      "type": "DECIMAL"
    },
    {
      "name": "tax",
      "type": "DECIMAL"
    }
  ],
  "dependencies": {
    "calls": ["apply_discount", "calculate_tax"],
    "called_by": ["process_order", "generate_invoice"],
    "external_calls": 1
  },
  "quality": {
    "maintainability_index": 78,
    "test_coverage": 0.85,
    "documentation": "complete"
  },
  "recommendations": [
    "Consider extracting tax calculation logic",
    "Add error handling for edge cases",
    "Document parameter constraints"
  ]
}
```

---

### 6.3 find-unused-functions

**Purpose:** Identify functions that are never called

**Syntax:**
```bash
query.sh find-unused-functions [--exclude-tests] [--min-lines 5]
```

**Examples:**
```bash
query.sh find-unused-functions
query.sh find-unused-functions --exclude-tests
query.sh find-unused-functions --min-lines 10
```

**Output Format:**
```json
[
  {
    "function": "legacy_calculate",
    "file": "./src/accounting.4gl",
    "module": "accounting",
    "lines": 45,
    "last_modified": "2023-06-15",
    "risk_level": "high",
    "reason": "never_called"
  },
  {
    "function": "debug_helper",
    "file": "./src/utils.4gl",
    "module": "utils",
    "lines": 12,
    "last_modified": "2024-01-10",
    "risk_level": "low",
    "reason": "only_test_calls"
  }
]
```

**Use Cases:**
- Dead code identification
- Code cleanup
- Maintenance planning
- Technical debt reduction

---

### 6.4 find-unused-files

**Purpose:** Identify files not used by any module

**Syntax:**
```bash
query.sh find-unused-files [--min-lines 10]
```

**Examples:**
```bash
query.sh find-unused-files
query.sh find-unused-files --min-lines 50
```

**Output Format:**
```json
[
  {
    "file": "./src/old_reports.4gl",
    "lines": 234,
    "last_modified": "2022-12-01",
    "size_kb": 8.5,
    "risk_level": "high",
    "reason": "not_in_any_module"
  }
]
```

---

## 7. Implementation Architecture

### 7.1 Database Schema Extensions

**New Tables:**
```sql
-- Function call relationships
CREATE TABLE function_calls (
  id INTEGER PRIMARY KEY,
  caller_id INTEGER,
  callee_id INTEGER,
  line_number INTEGER,
  FOREIGN KEY (caller_id) REFERENCES functions(id),
  FOREIGN KEY (callee_id) REFERENCES functions(id)
);

-- Type usage tracking
CREATE TABLE type_usage (
  id INTEGER PRIMARY KEY,
  function_id INTEGER,
  type_name TEXT,
  usage_type TEXT,  -- 'parameter', 'return', 'variable'
  position INTEGER,
  FOREIGN KEY (function_id) REFERENCES functions(id)
);

-- Database type references
CREATE TABLE database_references (
  id INTEGER PRIMARY KEY,
  function_id INTEGER,
  table_name TEXT,
  column_name TEXT,
  reference_type TEXT,  -- 'LIKE', 'RECORD', etc.
  FOREIGN KEY (function_id) REFERENCES functions(id)
);

-- Function metrics
CREATE TABLE function_metrics (
  id INTEGER PRIMARY KEY,
  function_id INTEGER,
  cyclomatic_complexity INTEGER,
  lines_of_code INTEGER,
  parameters_count INTEGER,
  returns_count INTEGER,
  FOREIGN KEY (function_id) REFERENCES functions(id)
);
```

### 7.2 Query Implementation Strategy

**Phase 1: Basic Queries**
- Implement module content queries
- Add fuzzy matching support
- Create cross-reference queries

**Phase 2: Dependency Analysis**
- Parse function bodies for CALL statements
- Build dependency graph
- Implement dependency queries

**Phase 3: Advanced Analysis**
- Calculate complexity metrics
- Implement analysis queries
- Add dead code detection

### 7.3 Performance Optimization

**Indexing Strategy:**
```sql
CREATE INDEX idx_function_calls_caller ON function_calls(caller_id);
CREATE INDEX idx_function_calls_callee ON function_calls(callee_id);
CREATE INDEX idx_type_usage_function ON type_usage(function_id);
CREATE INDEX idx_type_usage_type ON type_usage(type_name);
CREATE INDEX idx_db_refs_function ON database_references(function_id);
CREATE INDEX idx_db_refs_table ON database_references(table_name);
```

**Caching Strategy:**
- Cache dependency graphs (invalidate on code changes)
- Cache complexity metrics
- Cache analysis results
- Implement TTL-based cache expiration

---

## 8. CLI Integration

### 8.1 Enhanced query.sh

```bash
# New command structure
query.sh <category> <command> [options]

# Categories:
# - module      (module-related queries)
# - function    (function-related queries)
# - type        (type-related queries)
# - analysis    (analysis queries)
# - dependency  (dependency queries)
```

### 8.2 Example Usage

```bash
# Module queries
query.sh module find-with-file "util.4gl"
query.sh module find-with-function "calculate_total"
query.sh module analyze "accounting"

# Function queries
query.sh function find-closest "calcuate_total"
query.sh function find-dependencies "process_order" --depth 3
query.sh function find-dependents "calculate_total"
query.sh function analyze "calculate_total"

# Type queries
query.sh type find-usage "DECIMAL"
query.sh type find-with-database "customers"

# Analysis queries
query.sh analysis find-unused-functions
query.sh analysis find-unused-files
query.sh analysis module-report "accounting"
```

---

## 9. Testing Strategy

### 9.1 Unit Tests

- Test each query function independently
- Test with various input patterns
- Test edge cases and error conditions
- Test performance with large datasets

### 9.2 Integration Tests

- Test query combinations
- Test with real codebase samples
- Test output format consistency
- Test caching behavior

### 9.3 Performance Tests

- Benchmark query execution times
- Test with large codebases (10K+ functions)
- Measure memory usage
- Test cache effectiveness

---

## 10. Documentation Requirements

### 10.1 User Documentation

- Query reference guide
- Usage examples for each query
- Output format documentation
- Performance tips

### 10.2 Developer Documentation

- Query implementation guide
- Database schema documentation
- Performance optimization guide
- Extension points for custom queries

---

## 11. Success Metrics

- [ ] All queries execute in <100ms on typical codebases
- [ ] Support codebases with 10K+ functions
- [ ] 95%+ accuracy in dependency detection
- [ ] 90%+ test coverage
- [ ] Comprehensive documentation
- [ ] User satisfaction score >4.5/5

