# Future Enhancements

## Module Dependency Mapping (.m3 files)

### Goal
Generate a JSON index of Genero modules (.m3 files) and their dependencies to enable context-aware function lookup.

### Use Case
When working in a specific module, narrow down function searches to only the 4GL files that are:
- Part of the current module (e.g., module.4gl, module1.4gl, module2.4gl)
- Library dependencies (e.g., lib_str.4gl, lib_math.4gl)

### Proposed Implementation

1. **Parse .m3 files** to extract:
   - Module name
   - List of dependent .4gl files
   - Distinguish between module files and library files

2. **Generate modules.json** with structure like:
```json
{
  "module_name": {
    "m3_file": "./path/to/module.m3",
    "module_files": [
      "./path/to/module.4gl",
      "./path/to/module1.4gl",
      "./path/to/module2.4gl"
    ],
    "library_files": [
      "./lib/lib_str.4gl",
      "./lib/lib_math.4gl"
    ]
  }
}
```

3. **Integration with workspace.json**:
   - Cross-reference function signatures with module dependencies
   - Enable queries like: "Show all functions available in module X"
   - Filter function search results based on current module context

### Benefits
- Faster, more relevant function lookups
- Understand module boundaries and dependencies
- Detect missing dependencies
- Generate module-specific documentation
- Build call graphs within module scope

### Next Steps
- [ ] Obtain example .m3 file format
- [ ] Analyze .m3 file structure and parsing requirements
- [ ] Design modules.json schema
- [ ] Implement .m3 parser script
- [ ] Integrate with existing signature generation
- [ ] Add tests for module parsing
- [ ] Update documentation

### Notes
- .m3 files define makefile generation for each module
- Contains mix of module-specific and shared library 4GL files
- Need to understand how to distinguish module files from library files in .m3 format
