#!/bin/bash
# Convenient wrapper for querying the codebase databases

set -euo pipefail

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Get the parent directory (project root)
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Default database files - look in current directory first, then project root
if [[ -f "workspace.db" ]]; then
    SIGNATURES_DB="${SIGNATURES_DB:-workspace.db}"
else
    SIGNATURES_DB="${SIGNATURES_DB:-$PROJECT_ROOT/workspace.db}"
fi

if [[ -f "modules.db" ]]; then
    MODULES_DB="${MODULES_DB:-modules.db}"
else
    MODULES_DB="${MODULES_DB:-$PROJECT_ROOT/modules.db}"
fi

# Show usage
usage() {
    cat << 'EOF'
Usage: query.sh <command> [args...]

Signature queries (workspace.db):
  find-function <name>                Find function by exact name
  search-functions <pattern>          Search functions by name pattern
  list-file-functions <path>          List all functions in a file
  find-function-dependencies <name>   Find all functions called by a function
  find-function-dependents <name>     Find all functions that call a function

Module queries (modules.db):
  find-module <name>                  Find module by exact name
  search-modules <pattern>            Search modules by name pattern
  list-file-modules <filename>        Find modules using a file

Module-scoped queries (both databases):
  find-functions-in-module <name>     Find all functions in a module
  find-module-for-function <name>     Find which module(s) contain a function
  find-functions-calling-in-module <module> <func>  Find functions in module that call a function
  find-module-dependencies <name>     Find modules that a module depends on

Header/Reference queries (workspace.db):
  find-reference <ref>                Find files modified for a code reference
  find-author <author>                Find files modified by an author
  file-references <path>              Get all references for a file
  file-authors <path>                 Get all authors who modified a file
  author-expertise <author>           Show what areas an author has expertise in
  recent-changes [days]               Find files modified in last N days (default 30)
  search-references <pattern>         Search references by pattern

Database management:
  create-dbs                          Create both databases from JSON files
  create-signatures-db                Create workspace.db from workspace.json
  create-modules-db                   Create modules.db from modules.json

Examples:
  query.sh find-function my_function
  query.sh search-functions "get_*"
  query.sh find-function-dependencies my_function
  query.sh find-functions-in-module core
  query.sh find-module-for-function my_function
  query.sh find-functions-calling-in-module core validate_input
  query.sh find-module-dependencies core
  query.sh find-reference PRB-299
  query.sh find-author "John Smith"
  query.sh file-references "./src/utils.4gl"
  query.sh author-expertise "John Smith"
  query.sh recent-changes 7
EOF
}

# Create databases
create_dbs() {
    echo "Creating databases..."
    
    # Use current directory if files exist there, otherwise use project root
    WS_JSON="${WS_JSON:-workspace.json}"
    MOD_JSON="${MOD_JSON:-modules.json}"
    
    if [[ ! -f "$WS_JSON" && -f "$PROJECT_ROOT/workspace.json" ]]; then
        WS_JSON="$PROJECT_ROOT/workspace.json"
    fi
    if [[ ! -f "$MOD_JSON" && -f "$PROJECT_ROOT/modules.json" ]]; then
        MOD_JSON="$PROJECT_ROOT/modules.json"
    fi
    
    python3 "$PROJECT_ROOT/scripts/json_to_sqlite.py" signatures "$WS_JSON" "$SIGNATURES_DB"
    python3 "$PROJECT_ROOT/scripts/json_to_sqlite.py" modules "$MOD_JSON" "$MODULES_DB"
    echo "Done. Databases created:"
    ls -lh "$SIGNATURES_DB" "$MODULES_DB"
}

# Main command routing
if [ $# -eq 0 ]; then
    usage
    exit 1
fi

command="$1"
shift

case "$command" in
    find-function)
        python3 "$PROJECT_ROOT/scripts/query_db.py" find_function "$SIGNATURES_DB" "$@"
        ;;
    search-functions)
        python3 "$PROJECT_ROOT/scripts/query_db.py" search_functions "$SIGNATURES_DB" "$@"
        ;;
    list-file-functions)
        python3 "$PROJECT_ROOT/scripts/query_db.py" list_file_functions "$SIGNATURES_DB" "$@"
        ;;
    find-function-dependencies)
        python3 "$PROJECT_ROOT/scripts/query_db.py" find_function_dependencies "$SIGNATURES_DB" "$@"
        ;;
    find-function-dependents)
        python3 "$PROJECT_ROOT/scripts/query_db.py" find_function_dependents "$SIGNATURES_DB" "$@"
        ;;
    find-functions-in-module)
        python3 "$PROJECT_ROOT/scripts/query_db.py" find_functions_in_module "$MODULES_DB" "$SIGNATURES_DB" "$@"
        ;;
    find-module-for-function)
        python3 "$PROJECT_ROOT/scripts/query_db.py" find_module_for_function "$MODULES_DB" "$SIGNATURES_DB" "$@"
        ;;
    find-functions-calling-in-module)
        python3 "$PROJECT_ROOT/scripts/query_db.py" find_functions_calling_in_module "$MODULES_DB" "$SIGNATURES_DB" "$@"
        ;;
    find-module-dependencies)
        python3 "$PROJECT_ROOT/scripts/query_db.py" find_module_dependencies "$MODULES_DB" "$SIGNATURES_DB" "$@"
        ;;
    find-module)
        python3 "$PROJECT_ROOT/scripts/query_db.py" find_module "$MODULES_DB" "$@"
        ;;
    search-modules)
        python3 "$PROJECT_ROOT/scripts/query_db.py" search_modules "$MODULES_DB" "$@"
        ;;
    list-file-modules)
        python3 "$PROJECT_ROOT/scripts/query_db.py" list_file_modules "$MODULES_DB" "$@"
        ;;
    create-dbs)
        create_dbs
        ;;
    create-signatures-db)
        WS_JSON="${WS_JSON:-workspace.json}"
        if [[ ! -f "$WS_JSON" && -f "$PROJECT_ROOT/workspace.json" ]]; then
            WS_JSON="$PROJECT_ROOT/workspace.json"
        fi
        python3 "$PROJECT_ROOT/scripts/json_to_sqlite.py" signatures "$WS_JSON" "$SIGNATURES_DB"
        ;;
    create-modules-db)
        MOD_JSON="${MOD_JSON:-modules.json}"
        if [[ ! -f "$MOD_JSON" && -f "$PROJECT_ROOT/modules.json" ]]; then
            MOD_JSON="$PROJECT_ROOT/modules.json"
        fi
        python3 "$PROJECT_ROOT/scripts/json_to_sqlite.py" modules "$MOD_JSON" "$MODULES_DB"
        ;;
    find-reference)
        python3 "$PROJECT_ROOT/scripts/query_headers.py" find-reference "$SIGNATURES_DB" "$@"
        ;;
    find-author)
        python3 "$PROJECT_ROOT/scripts/query_headers.py" find-author "$SIGNATURES_DB" "$@"
        ;;
    file-references)
        python3 "$PROJECT_ROOT/scripts/query_headers.py" file-references "$SIGNATURES_DB" "$@"
        ;;
    file-authors)
        python3 "$PROJECT_ROOT/scripts/query_headers.py" file-authors "$SIGNATURES_DB" "$@"
        ;;
    author-expertise)
        python3 "$PROJECT_ROOT/scripts/query_headers.py" author-expertise "$SIGNATURES_DB" "$@"
        ;;
    recent-changes)
        python3 "$PROJECT_ROOT/scripts/query_headers.py" recent-changes "$SIGNATURES_DB" "$@"
        ;;
    search-references)
        python3 "$PROJECT_ROOT/scripts/query_headers.py" search-references "$SIGNATURES_DB" "$@"
        ;;
    *)
        echo "Unknown command: $command" >&2
        usage
        exit 1
        ;;
esac
