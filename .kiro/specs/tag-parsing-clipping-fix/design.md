# Tag Parsing Clipping Fix - Bugfix Design

## Overview

The header parser in `scripts/parse_headers.py` is incorrectly truncating reference IDs with numeric or alphanumeric suffixes (e.g., "EH100058-10" becomes "EH100058"). The bug occurs in the `_parse_row` method where reference extraction uses a naive regex pattern that stops at the first whitespace, failing to account for hyphenated suffixes that are part of the complete reference token. This design outlines the root cause analysis, fix approach, and testing strategy to restore complete reference extraction while preserving existing behavior for references without suffixes.

## Glossary

- **Bug_Condition (C)**: The condition that triggers the bug - when a reference ID contains a hyphenated numeric or alphanumeric suffix (e.g., "EH100058-10", "EH100512-9a")
- **Property (P)**: The desired behavior when the bug condition is met - the complete reference including suffix should be extracted as a single token
- **Preservation**: Existing behavior for references without suffixes and other parsing functionality that must remain unchanged
- **Reference Token**: A complete reference ID including any hyphenated suffix (e.g., "EH100058-10" is a single token, not "EH100058" + "10")
- **_parse_row**: The method in `HeaderParser` class (line 217-289 in `scripts/parse_headers.py`) that extracts fields from a single modification row
- **ref_section**: The substring extracted from the line starting at the Ref column position

## Bug Details

### Bug Condition

The bug manifests when a reference ID contains a hyphenated suffix (numeric or alphanumeric) and the `_parse_row` method attempts to extract it. The current implementation uses a naive regex pattern `(\S+)` that matches the first non-whitespace sequence, which correctly stops at whitespace but fails to recognize that hyphens followed by alphanumeric characters are part of the same token.

**Formal Specification:**
```
FUNCTION isBugCondition(input)
  INPUT: input of type string (a data row from modifications section)
  OUTPUT: boolean
  
  RETURN input CONTAINS a reference token matching pattern [A-Z]+\d+-[0-9a-zA-Z]+
         AND the reference is positioned at the Ref column
         AND the reference is followed by whitespace
END FUNCTION
```

### Examples

- **Example 1 - Numeric Suffix**: Input row: `"EH100058-10    01/02/2024  John  Fixed issue"` → Current output: `"EH100058"` → Expected output: `"EH100058-10"`
- **Example 2 - Alphanumeric Suffix**: Input row: `"EH100512-9a    15/03/2024  Jane  Updated logic"` → Current output: `"EH100512"` → Expected output: `"EH100512-9a"`
- **Example 3 - No Suffix (Preservation)**: Input row: `"EH100512    15/03/2024  Jane  Updated logic"` → Current output: `"EH100512"` → Expected output: `"EH100512"` (unchanged)
- **Example 4 - Multiple Hyphens**: Input row: `"EH100058-10-beta    01/02/2024  John  Fixed issue"` → Current output: `"EH100058"` → Expected output: `"EH100058-10-beta"`

## Expected Behavior

### Preservation Requirements

**Unchanged Behaviors:**
- References without suffixes (e.g., "EH100512") must continue to be extracted correctly
- References followed by whitespace must continue to be correctly identified at the whitespace boundary
- All other fields (author, date, description) must continue to be extracted correctly
- Files without modification sections must continue to return None or empty results
- Multi-line descriptions must continue to be handled correctly
- Date normalization must continue to work as before

**Scope:**
All inputs that do NOT involve reference IDs with hyphenated suffixes should be completely unaffected by this fix. This includes:
- References without any suffix
- References with other formats (if any exist)
- All non-reference fields (author, date, description)
- File parsing logic outside of reference extraction

## Hypothesized Root Cause

Based on the bug description and code analysis, the most likely issues are:

1. **Naive Regex Pattern**: The current regex pattern `(\S+)` in line 237 matches any non-whitespace sequence, which correctly stops at whitespace but doesn't account for the semantic meaning of hyphens in reference IDs. The pattern treats "EH100058-10" as "EH100058" because it stops at the first whitespace after the hyphen-suffix combination.

2. **Incorrect Token Boundary Detection**: The code assumes that the first whitespace marks the end of the reference token, but doesn't recognize that hyphens followed by alphanumeric characters are part of the same logical token. The pattern should match the complete reference including hyphenated suffixes.

3. **Missing Suffix Pattern Recognition**: The reference extraction logic doesn't have a pattern that explicitly recognizes and includes hyphenated numeric or alphanumeric suffixes as part of the reference token.

## Correctness Properties

Property 1: Bug Condition - Complete Reference Extraction with Suffixes

_For any_ input where a reference ID contains a hyphenated numeric or alphanumeric suffix (isBugCondition returns true), the fixed _parse_row function SHALL extract the complete reference including the suffix as a single token.

**Validates: Requirements 2.1, 2.2, 2.3**

Property 2: Preservation - References Without Suffixes and Other Fields

_For any_ input where the bug condition does NOT hold (isBugCondition returns false), the fixed _parse_row function SHALL produce the same result as the original function, preserving extraction of references without suffixes, author names, dates, and descriptions.

**Validates: Requirements 3.1, 3.2, 3.3, 3.4**

## Fix Implementation

### Changes Required

Assuming our root cause analysis is correct:

**File**: `scripts/parse_headers.py`

**Function**: `_parse_row` (lines 217-289)

**Specific Changes**:

1. **Enhanced Reference Pattern**: Replace the naive regex pattern `(\S+)` with a more sophisticated pattern that explicitly matches reference tokens including hyphenated suffixes. The new pattern should match:
   - Base reference: alphanumeric characters (typically letters followed by digits)
   - Optional suffix: hyphen followed by one or more alphanumeric characters
   - Pattern: `([A-Za-z0-9]+(?:-[A-Za-z0-9]+)*)`

2. **Reference Extraction Logic**: Update the reference extraction section (lines 233-241) to use the enhanced pattern that captures complete reference tokens including all hyphenated suffixes.

3. **Token Boundary Recognition**: Ensure the extraction logic correctly identifies the end of the reference token at the first whitespace AFTER the complete reference (including any suffixes), not at intermediate boundaries.

4. **Validation**: Add logic to verify that the extracted reference matches the expected format before returning it.

## Testing Strategy

### Validation Approach

The testing strategy follows a two-phase approach: first, surface counterexamples that demonstrate the bug on unfixed code, then verify the fix works correctly and preserves existing behavior.

### Exploratory Bug Condition Checking

**Goal**: Surface counterexamples that demonstrate the bug BEFORE implementing the fix. Confirm or refute the root cause analysis. If we refute, we will need to re-hypothesize.

**Test Plan**: Write tests that simulate modification rows with various reference formats and assert that the reference field is correctly extracted. Run these tests on the UNFIXED code to observe failures and understand the root cause.

**Test Cases**:
1. **Numeric Suffix Test**: Parse row with reference "EH100058-10" and verify extraction (will fail on unfixed code)
2. **Alphanumeric Suffix Test**: Parse row with reference "EH100512-9a" and verify extraction (will fail on unfixed code)
3. **Multiple Suffix Test**: Parse row with reference "EH100058-10-beta" and verify extraction (will fail on unfixed code)
4. **No Suffix Test**: Parse row with reference "EH100512" and verify extraction (should pass on unfixed code)

**Expected Counterexamples**:
- References with numeric suffixes are truncated at the hyphen
- References with alphanumeric suffixes are truncated at the hyphen
- Possible causes: regex pattern doesn't account for hyphenated suffixes, token boundary detection is incorrect

### Fix Checking

**Goal**: Verify that for all inputs where the bug condition holds, the fixed function produces the expected behavior.

**Pseudocode:**
```
FOR ALL input WHERE isBugCondition(input) DO
  result := _parse_row_fixed(input, columns, all_lines, line_idx, header_idx)
  ASSERT result['reference'] MATCHES pattern [A-Z]+\d+-[0-9a-zA-Z]+
  ASSERT result['reference'] CONTAINS complete suffix
END FOR
```

### Preservation Checking

**Goal**: Verify that for all inputs where the bug condition does NOT hold, the fixed function produces the same result as the original function.

**Pseudocode:**
```
FOR ALL input WHERE NOT isBugCondition(input) DO
  ASSERT _parse_row_original(input, columns, all_lines, line_idx, header_idx) 
       = _parse_row_fixed(input, columns, all_lines, line_idx, header_idx)
END FOR
```

**Testing Approach**: Property-based testing is recommended for preservation checking because:
- It generates many test cases automatically across the input domain
- It catches edge cases that manual unit tests might miss
- It provides strong guarantees that behavior is unchanged for all non-buggy inputs

**Test Plan**: Observe behavior on UNFIXED code first for references without suffixes and other fields, then write property-based tests capturing that behavior.

**Test Cases**:
1. **No Suffix Preservation**: Verify references without suffixes continue to be extracted correctly
2. **Author Extraction Preservation**: Verify author names are extracted correctly after fix
3. **Date Extraction Preservation**: Verify dates are extracted and normalized correctly after fix
4. **Description Extraction Preservation**: Verify descriptions are extracted correctly after fix
5. **Multi-line Description Preservation**: Verify multi-line descriptions continue to work correctly

### Unit Tests

- Test reference extraction with numeric suffixes (e.g., "EH100058-10")
- Test reference extraction with alphanumeric suffixes (e.g., "EH100512-9a")
- Test reference extraction with multiple hyphens (e.g., "EH100058-10-beta")
- Test reference extraction without suffixes (e.g., "EH100512")
- Test edge cases (very long suffixes, unusual formats)
- Test that author, date, and description extraction continues to work correctly

### Property-Based Tests

- Generate random reference formats and verify complete extraction including suffixes
- Generate random modification rows and verify all fields are extracted correctly
- Generate random column configurations and verify references are extracted correctly
- Test that non-buggy inputs produce identical results before and after fix

### Integration Tests

- Test full file parsing with modification headers containing references with suffixes
- Test that parsed references are correctly stored in the output JSON
- Test that multiple files with various reference formats are parsed correctly
- Test that the fix doesn't break existing file parsing workflows
