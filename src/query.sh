#!/bin/bash
# Convenient wrapper for querying the codebase databases

set -euo pipefail

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Get the parent directory (project root)
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Default database files
SIGNATURES_DB="${SIGNATURES_DB:-workspace.db}"
MODULES_DB="${MODULES_DB:-modules.db}"

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

Database management:
  create-dbs                          Create both databases from JSON files
  create-signatures-db                Create workspace.db from workspace.json
  create-modules-db                   Create modules.db from modules.json

Examples:
  query.sh find-function my_function
  query.sh search-functions "get_*"
  query.sh find-function-dependencies my_function
  query.sh find-function-dependents my_function
  query.sh find-module core
  query.sh list-file-modules "util.4gl"
EOF
}

# Create databases
create_dbs() {
    echo "Creating databases..."
    python3 "$PROJECT_ROOT/scripts/json_to_sqlite.py" signatures "$PROJECT_ROOT/workspace.json" "$PROJECT_ROOT/$SIGNATURES_DB"
    python3 "$PROJECT_ROOT/scripts/json_to_sqlite.py" modules "$PROJECT_ROOT/modules.json" "$PROJECT_ROOT/$MODULES_DB"
    echo "Done. Databases created:"
    ls -lh "$PROJECT_ROOT/$SIGNATURES_DB" "$PROJECT_ROOT/$MODULES_DB"
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
        python3 "$PROJECT_ROOT/scripts/query_db.py" find_function "$PROJECT_ROOT/$SIGNATURES_DB" "$@"
        ;;
    search-functions)
        python3 "$PROJECT_ROOT/scripts/query_db.py" search_functions "$PROJECT_ROOT/$SIGNATURES_DB" "$@"
        ;;
    list-file-functions)
        python3 "$PROJECT_ROOT/scripts/query_db.py" list_file_functions "$PROJECT_ROOT/$SIGNATURES_DB" "$@"
        ;;
    find-function-dependencies)
        python3 "$PROJECT_ROOT/scripts/query_db.py" find_function_dependencies "$PROJECT_ROOT/$SIGNATURES_DB" "$@"
        ;;
    find-function-dependents)
        python3 "$PROJECT_ROOT/scripts/query_db.py" find_function_dependents "$PROJECT_ROOT/$SIGNATURES_DB" "$@"
        ;;
    find-module)
        python3 "$PROJECT_ROOT/scripts/query_db.py" find_module "$PROJECT_ROOT/$MODULES_DB" "$@"
        ;;
    search-modules)
        python3 "$PROJECT_ROOT/scripts/query_db.py" search_modules "$PROJECT_ROOT/$MODULES_DB" "$@"
        ;;
    list-file-modules)
        python3 "$PROJECT_ROOT/scripts/query_db.py" list_file_modules "$PROJECT_ROOT/$MODULES_DB" "$@"
        ;;
    create-dbs)
        create_dbs
        ;;
    create-signatures-db)
        python3 "$PROJECT_ROOT/scripts/json_to_sqlite.py" signatures "$PROJECT_ROOT/workspace.json" "$PROJECT_ROOT/$SIGNATURES_DB"
        ;;
    create-modules-db)
        python3 "$PROJECT_ROOT/scripts/json_to_sqlite.py" modules "$PROJECT_ROOT/modules.json" "$PROJECT_ROOT/$MODULES_DB"
        ;;
    *)
        echo "Unknown command: $command" >&2
        usage
        exit 1
        ;;
esac
