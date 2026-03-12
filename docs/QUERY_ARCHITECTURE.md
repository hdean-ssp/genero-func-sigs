# Query Architecture

Technical architecture and design patterns for advanced query functionality.

## Overview

The advanced query system is built on a layered architecture that separates concerns and enables extensibility.

```
┌─────────────────────────────────────────────────────────┐
│                    CLI Interface                         │
│                   (query.sh wrapper)                     │
└────────────────────┬────────────────────────────────────┘
                     │
┌────────────────────▼────────────────────────────────────┐
│              Query Dispatcher                            │
│         (routes to appropriate handler)                  │
└────────────────────┬────────────────────────────────────┘
                     │
        ┌────────────┼────────────┐
        │            │            │
┌───────▼──┐  ┌──────▼──┐  ┌─────▼──────┐
│ Module   │  │Function │  │ Type       │
│ Queries  │  │ Queries │  │ Queries    │
└───────┬──┘  └──────┬──┘  └─────┬──────┘
        │            │            │
        └────────────┼────────────┘
                     │
┌────────────────────▼────────────────────────────────────┐
│              Query Builder                               │
│    (constructs SQL, handles parameters)                 │
└────────────────────┬────────────────────────────────────┘
                     │
┌────────────────────▼────────────────────────────────────┐
│              Query Cache                                 │
│    (caches results, manages invalidation)               │
└────────────────────┬────────────────────────────────────┘
                     │
┌────────────────────▼────────────────────────────────────┐
│              Database Layer                              │
│    (SQLite/PostgreSQL connection)                       │
└─────────────────────────────────────────────────────────┘
```

## 1. Core Components

### 1.1 Query Dispatcher

**File:** `scripts/query_dispatcher.py`

Responsible for routing queries to appropriate handlers.

```python
class QueryDispatcher:
    def __init__(self, db_path):
        self.db = sqlite3.connect(db_path)
        self.handlers = {
            'module': ModuleQueryHandler,
            'function': FunctionQueryHandler,
            'type': TypeQueryHandler,
            'analysis': AnalysisQueryHandler,
            'dependency': DependencyQueryHandler
        }
    
    def dispatch(self, category, command, args):
        handler_class = self.handlers.get(category)
        if not handler_class:
            raise ValueError(f"Unknown category: {category}")
        
        handler = handler_class(self.db)
        return handler.execute(command, args)
```

### 1.2 Query Handlers

**File:** `scripts/queries/base_handler.py`

Base class for all query handlers.

```python
class BaseQueryHandler:
    def __init__(self, db):
        self.db = db
        self.cache = QueryCache()
    
    def execute(self, command, args):
        # Check cache
        cache_key = self._make_cache_key(command, args)
        cached = self.cache.get(cache_key)
        if cached:
            return cached
        
        # Execute query
        result = self._execute_query(command, args)
        
        # Cache result
        self.cache.set(cache_key, result)
        
        return result
    
    def _execute_query(self, command, args):
        raise NotImplementedError
    
    def _make_cache_key(self, command, args):
        return f"{self.__class__.__name__}:{command}:{json.dumps(args)}"
```

### 1.3 Query Builder

**File:** `scripts/query_builder.py`

Constructs SQL queries dynamically.

```python
class QueryBuilder:
    def __init__(self):
        self.select = []
        self.from_clause = None
        self.joins = []
        self.where = []
        self.order_by = []
        self.limit_val = None
    
    def select_fields(self, *fields):
        self.select.extend(fields)
        return self
    
    def from_table(self, table):
        self.from_clause = table
        return self
    
    def join(self, table, on):
        self.joins.append((table, on))
        return self
    
    def where(self, condition, params=None):
        self.where.append((condition, params or []))
        return self
    
    def order_by(self, field, direction='ASC'):
        self.order_by.append(f"{field} {direction}")
        return self
    
    def limit(self, count):
        self.limit_val = count
        return self
    
    def build(self):
        sql = f"SELECT {', '.join(self.select)} FROM {self.from_clause}"
        
        for table, on in self.joins:
            sql += f" JOIN {table} ON {on}"
        
        if self.where:
            conditions = [cond for cond, _ in self.where]
            sql += f" WHERE {' AND '.join(conditions)}"
        
        if self.order_by:
            sql += f" ORDER BY {', '.join(self.order_by)}"
        
        if self.limit_val:
            sql += f" LIMIT {self.limit_val}"
        
        params = []
        for _, p in self.where:
            params.extend(p)
        
        return sql, params
```

### 1.4 Query Cache

**File:** `scripts/query_cache.py`

Manages query result caching with TTL and invalidation.

```python
class QueryCache:
    def __init__(self, ttl_seconds=3600):
        self.cache = {}
        self.ttl = ttl_seconds
        self.timestamps = {}
    
    def get(self, key):
        if key not in self.cache:
            return None
        
        # Check TTL
        age = time.time() - self.timestamps[key]
        if age > self.ttl:
            del self.cache[key]
            del self.timestamps[key]
            return None
        
        return self.cache[key]
    
    def set(self, key, value):
        self.cache[key] = value
        self.timestamps[key] = time.time()
    
    def invalidate(self, pattern=None):
        if pattern is None:
            self.cache.clear()
            self.timestamps.clear()
        else:
            keys_to_delete = [k for k in self.cache if pattern in k]
            for k in keys_to_delete:
                del self.cache[k]
                del self.timestamps[k]
    
    def invalidate_on_change(self, table):
        # Invalidate cache entries related to a table
        self.invalidate(table)
```

---

## 2. Query Handler Implementations

### 2.1 Module Query Handler

**File:** `scripts/queries/module_handler.py`

```python
class ModuleQueryHandler(BaseQueryHandler):
    def _execute_query(self, command, args):
        if command == 'find-with-file':
            return self._find_modules_with_file(args['filename'])
        elif command == 'find-with-function':
            return self._find_modules_with_function(args['function_name'])
        elif command == 'analyze':
            return self._analyze_module(args['module_name'])
        else:
            raise ValueError(f"Unknown command: {command}")
    
    def _find_modules_with_file(self, filename):
        query = """
            SELECT DISTINCT m.name, m.file, mf.category, mf.position
            FROM modules m
            JOIN module_files mf ON m.id = mf.module_id
            WHERE mf.file_name = ?
            ORDER BY m.name
        """
        
        cursor = self.db.cursor()
        cursor.execute(query, (filename,))
        
        results = []
        for row in cursor.fetchall():
            results.append({
                'module': row[0],
                'file': row[1],
                'category': row[2],
                'position': row[3]
            })
        
        return results
    
    def _find_modules_with_function(self, function_name):
        query = """
            SELECT DISTINCT m.name, m.file, f.name, f.line_start, f.line_end, f.signature
            FROM modules m
            JOIN module_files mf ON m.id = mf.module_id
            JOIN files fi ON mf.file_name = fi.path
            JOIN functions f ON fi.id = f.file_id
            WHERE f.name LIKE ?
            ORDER BY m.name, f.name
        """
        
        cursor = self.db.cursor()
        cursor.execute(query, (f"%{function_name}%",))
        
        results = []
        for row in cursor.fetchall():
            results.append({
                'module': row[0],
                'file': row[1],
                'function': row[2],
                'line_start': row[3],
                'line_end': row[4],
                'signature': row[5]
            })
        
        return results
    
    def _analyze_module(self, module_name):
        # Get module info
        module_query = "SELECT id, name, file FROM modules WHERE name = ?"
        cursor = self.db.cursor()
        cursor.execute(module_query, (module_name,))
        module = cursor.fetchone()
        
        if not module:
            raise ValueError(f"Module not found: {module_name}")
        
        module_id, name, file = module
        
        # Get files in module
        files_query = """
            SELECT file_name, category
            FROM module_files
            WHERE module_id = ?
            ORDER BY category, file_name
        """
        cursor.execute(files_query, (module_id,))
        files = cursor.fetchall()
        
        # Get functions in module
        functions_query = """
            SELECT COUNT(*) FROM functions f
            JOIN files fi ON f.file_id = fi.id
            JOIN module_files mf ON fi.path = mf.file_name
            WHERE mf.module_id = ?
        """
        cursor.execute(functions_query, (module_id,))
        function_count = cursor.fetchone()[0]
        
        # Build analysis
        return {
            'module': name,
            'file': file,
            'files': {
                'L4GLS': [f[0] for f in files if f[1] == 'L4GLS'],
                'U4GLS': [f[0] for f in files if f[1] == 'U4GLS'],
                '4GLS': [f[0] for f in files if f[1] == '4GLS']
            },
            'function_count': function_count,
            'file_count': len(files)
        }
```

### 2.2 Function Query Handler

**File:** `scripts/queries/function_handler.py`

```python
class FunctionQueryHandler(BaseQueryHandler):
    def _execute_query(self, command, args):
        if command == 'find-closest':
            return self._find_closest_function(args['name'], args.get('threshold', 0.8))
        elif command == 'find-dependencies':
            return self._find_dependencies(args['function_name'], args.get('depth', 1))
        elif command == 'find-dependents':
            return self._find_dependents(args['function_name'], args.get('depth', 1))
        elif command == 'analyze':
            return self._analyze_function(args['function_name'])
        else:
            raise ValueError(f"Unknown command: {command}")
    
    def _find_closest_function(self, name, threshold):
        query = "SELECT id, name, signature FROM functions"
        cursor = self.db.cursor()
        cursor.execute(query)
        
        results = []
        for row in cursor.fetchall():
            similarity = self._calculate_similarity(name, row[1])
            if similarity >= threshold:
                results.append({
                    'name': row[1],
                    'similarity': similarity,
                    'signature': row[2]
                })
        
        # Sort by similarity
        results.sort(key=lambda x: x['similarity'], reverse=True)
        return results[:10]
    
    def _calculate_similarity(self, s1, s2):
        # Levenshtein distance
        from difflib import SequenceMatcher
        return SequenceMatcher(None, s1, s2).ratio()
    
    def _find_dependencies(self, function_name, depth):
        # Find function
        query = "SELECT id FROM functions WHERE name = ?"
        cursor = self.db.cursor()
        cursor.execute(query, (function_name,))
        result = cursor.fetchone()
        
        if not result:
            raise ValueError(f"Function not found: {function_name}")
        
        func_id = result[0]
        
        # Build dependency graph
        dependencies = self._build_dependency_graph(func_id, depth)
        
        return {
            'function': function_name,
            'dependencies': dependencies,
            'depth': depth
        }
    
    def _build_dependency_graph(self, func_id, max_depth, current_depth=0, visited=None):
        if visited is None:
            visited = set()
        
        if current_depth >= max_depth or func_id in visited:
            return []
        
        visited.add(func_id)
        
        # Get direct dependencies
        query = """
            SELECT f.id, f.name, f.signature
            FROM function_calls fc
            JOIN functions f ON fc.callee_id = f.id
            WHERE fc.caller_id = ?
        """
        cursor = self.db.cursor()
        cursor.execute(query, (func_id,))
        
        dependencies = []
        for row in cursor.fetchall():
            dep = {
                'name': row[1],
                'signature': row[2],
                'depth': current_depth + 1
            }
            
            # Recursively get sub-dependencies
            if current_depth + 1 < max_depth:
                dep['dependencies'] = self._build_dependency_graph(
                    row[0], max_depth, current_depth + 1, visited
                )
            
            dependencies.append(dep)
        
        return dependencies
```

### 2.3 Type Query Handler

**File:** `scripts/queries/type_handler.py`

```python
class TypeQueryHandler(BaseQueryHandler):
    def _execute_query(self, command, args):
        if command == 'find-usage':
            return self._find_type_usage(args['type_name'])
        elif command == 'find-with-database':
            return self._find_functions_with_database_type(args['table_name'])
        elif command == 'find-with-record':
            return self._find_functions_with_record(args['record_name'])
        else:
            raise ValueError(f"Unknown command: {command}")
    
    def _find_type_usage(self, type_name):
        query = """
            SELECT f.name, f.signature, tu.usage_type, COUNT(*) as count
            FROM type_usage tu
            JOIN functions f ON tu.function_id = f.id
            WHERE tu.type_name = ?
            GROUP BY f.id, tu.usage_type
            ORDER BY count DESC
        """
        
        cursor = self.db.cursor()
        cursor.execute(query, (type_name,))
        
        results = []
        for row in cursor.fetchall():
            results.append({
                'function': row[0],
                'signature': row[1],
                'usage_type': row[2],
                'count': row[3]
            })
        
        return results
    
    def _find_functions_with_database_type(self, table_name):
        query = """
            SELECT f.name, f.signature, dr.column_name, dr.reference_type
            FROM database_references dr
            JOIN functions f ON dr.function_id = f.id
            WHERE dr.table_name = ?
            ORDER BY f.name
        """
        
        cursor = self.db.cursor()
        cursor.execute(query, (table_name,))
        
        results = []
        for row in cursor.fetchall():
            results.append({
                'function': row[0],
                'signature': row[1],
                'column': row[2],
                'reference_type': row[3]
            })
        
        return results
```

---

## 3. Database Schema

### 3.1 Core Tables

```sql
-- Existing tables (from original schema)
CREATE TABLE files (
    id INTEGER PRIMARY KEY,
    path TEXT UNIQUE,
    type TEXT
);

CREATE TABLE functions (
    id INTEGER PRIMARY KEY,
    file_id INTEGER,
    name TEXT,
    line_start INTEGER,
    line_end INTEGER,
    signature TEXT,
    FOREIGN KEY (file_id) REFERENCES files(id)
);

-- New tables for advanced queries
CREATE TABLE function_calls (
    id INTEGER PRIMARY KEY,
    caller_id INTEGER,
    callee_id INTEGER,
    line_number INTEGER,
    FOREIGN KEY (caller_id) REFERENCES functions(id),
    FOREIGN KEY (callee_id) REFERENCES functions(id)
);

CREATE TABLE type_usage (
    id INTEGER PRIMARY KEY,
    function_id INTEGER,
    type_name TEXT,
    usage_type TEXT,  -- 'parameter', 'return', 'variable'
    position INTEGER,
    FOREIGN KEY (function_id) REFERENCES functions(id)
);

CREATE TABLE database_references (
    id INTEGER PRIMARY KEY,
    function_id INTEGER,
    table_name TEXT,
    column_name TEXT,
    reference_type TEXT,  -- 'LIKE', 'RECORD', etc.
    FOREIGN KEY (function_id) REFERENCES functions(id)
);

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

### 3.2 Indexes

```sql
-- Performance indexes
CREATE INDEX idx_function_calls_caller ON function_calls(caller_id);
CREATE INDEX idx_function_calls_callee ON function_calls(callee_id);
CREATE INDEX idx_type_usage_function ON type_usage(function_id);
CREATE INDEX idx_type_usage_type ON type_usage(type_name);
CREATE INDEX idx_db_refs_function ON database_references(function_id);
CREATE INDEX idx_db_refs_table ON database_references(table_name);
CREATE INDEX idx_functions_name ON functions(name);
CREATE INDEX idx_functions_file ON functions(file_id);
```

---

## 4. Query Execution Flow

### 4.1 Typical Query Execution

```
1. User runs: query.sh function find-dependencies "process_order"
   ↓
2. query.sh wrapper calls src/query.sh
   ↓
3. src/query.sh parses arguments and calls query_db.py
   ↓
4. query_db.py creates QueryDispatcher
   ↓
5. QueryDispatcher routes to FunctionQueryHandler
   ↓
6. FunctionQueryHandler checks cache
   ↓
7. If not cached:
   - Build SQL query using QueryBuilder
   - Execute query against database
   - Cache results
   ↓
8. Format results as JSON
   ↓
9. Return to user
```

### 4.2 Cache Invalidation

```
When code is regenerated:
1. generate_all.sh runs
   ↓
2. Generates new workspace.json, modules.json
   ↓
3. Recreates databases
   ↓
4. Invalidates all query caches
   ↓
5. Next query rebuilds cache
```

---

## 5. Performance Optimization

### 5.1 Query Optimization Strategies

1. **Indexing:** Create indexes on frequently searched columns
2. **Caching:** Cache query results with TTL
3. **Pagination:** Limit result sets
4. **Lazy Loading:** Load related data on demand
5. **Query Batching:** Combine multiple queries

### 5.2 Benchmark Targets

| Query Type | Target | Notes |
|-----------|--------|-------|
| Simple lookup | <10ms | Exact match |
| Pattern search | <50ms | Wildcard search |
| Dependency analysis | <200ms | Depth 3 |
| Module analysis | <500ms | Full analysis |
| Dead code detection | <1s | Full codebase |

---

## 6. Error Handling

### 6.1 Error Types

```python
class QueryError(Exception):
    """Base query error"""
    pass

class QueryNotFoundError(QueryError):
    """Query result not found"""
    pass

class QueryTimeoutError(QueryError):
    """Query execution timeout"""
    pass

class QueryValidationError(QueryError):
    """Invalid query parameters"""
    pass
```

### 6.2 Error Handling Pattern

```python
try:
    result = handler.execute(command, args)
except QueryNotFoundError as e:
    print(f"Error: {e}", file=sys.stderr)
    sys.exit(1)
except QueryTimeoutError as e:
    print(f"Query timeout: {e}", file=sys.stderr)
    sys.exit(2)
except Exception as e:
    print(f"Unexpected error: {e}", file=sys.stderr)
    sys.exit(3)
```

---

## 7. Testing Strategy

### 7.1 Unit Tests

```python
def test_find_modules_with_file():
    handler = ModuleQueryHandler(test_db)
    result = handler._find_modules_with_file("util.4gl")
    assert len(result) > 0
    assert result[0]['category'] in ['L4GLS', 'U4GLS', '4GLS']

def test_find_closest_function():
    handler = FunctionQueryHandler(test_db)
    result = handler._find_closest_function("calcuate_total", 0.8)
    assert len(result) > 0
    assert result[0]['name'] == "calculate_total"
```

### 7.2 Integration Tests

```python
def test_end_to_end_dependency_analysis():
    # Generate test data
    # Run dependency query
    # Verify results
    # Check performance
    pass
```

---

## 8. Extensibility

### 8.1 Adding New Query Types

1. Create new handler class extending `BaseQueryHandler`
2. Implement `_execute_query` method
3. Register handler in `QueryDispatcher`
4. Add tests
5. Update documentation

### 8.2 Adding New Queries to Existing Handler

1. Add case to `_execute_query` method
2. Implement query method
3. Add tests
4. Update documentation

---

## Conclusion

This architecture provides a solid foundation for implementing advanced query functionality. The layered design allows for easy extension and maintenance, while the caching and optimization strategies ensure good performance even with large codebases.

