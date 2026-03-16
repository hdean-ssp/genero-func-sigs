# Implementation Plan

## Phase 1: Exploratory Testing (Bug Condition)

- [x] 1. Write bug condition exploration test
  - **Property 1: Bug Condition** - Reference ID Suffix Truncation
  - **CRITICAL**: This test MUST FAIL on unfixed code - failure confirms the bug exists
  - **DO NOT attempt to fix the test or the code when it fails**
  - **NOTE**: This test encodes the expected behavior - it will validate the fix when it passes after implementation
  - **GOAL**: Surface counterexamples that demonstrate the bug exists
  - **Scoped PBT Approach**: For deterministic bugs, scope the property to the concrete failing case(s) to ensure reproducibility
  - Test implementation details from Bug Condition in design (isBugCondition: reference contains pattern `[A-Z]+\d+-[0-9a-zA-Z]+`)
  - The test assertions should match the Expected Behavior Properties from design (complete reference including suffix should be extracted)
  - Test cases:
    - Numeric suffix: "EH100058-10" should extract as "EH100058-10" (not "EH100058")
    - Alphanumeric suffix: "EH100512-9a" should extract as "EH100512-9a" (not "EH100512")
    - Multiple hyphens: "EH100058-10-beta" should extract as "EH100058-10-beta"
  - Run test on UNFIXED code
  - **EXPECTED OUTCOME**: Test FAILS (this is correct - it proves the bug exists)
  - Document counterexamples found to understand root cause
  - Mark task complete when test is written, run, and failure is documented
  - _Requirements: 1.1, 1.2, 1.3_

## Phase 2: Preservation Testing (Non-Buggy Behavior)

- [-] 2. Write preservation property tests (BEFORE implementing fix)
  - **Property 2: Preservation** - Non-Suffixed References and Other Fields
  - **IMPORTANT**: Follow observation-first methodology
  - Observe behavior on UNFIXED code for non-buggy inputs (where isBugCondition returns false)
  - Write property-based tests capturing observed behavior patterns from Preservation Requirements
  - Test cases:
    - References without suffixes: "EH100512" should extract as "EH100512" (unchanged)
    - Author extraction: Author names should be correctly extracted after reference
    - Date extraction: Dates should be correctly extracted and normalized to ISO 8601
    - Description extraction: Descriptions should be correctly extracted after author
    - Multi-line descriptions: Continuation lines should be correctly appended to description
  - Property-based testing generates many test cases for stronger guarantees
  - Run tests on UNFIXED code
  - **EXPECTED OUTCOME**: Tests PASS (this confirms baseline behavior to preserve)
  - Mark task complete when tests are written, run, and passing on unfixed code
  - _Requirements: 3.1, 3.2, 3.3, 3.4_

## Phase 3: Implementation

- [-] 3. Fix reference extraction logic in parse_headers.py

  - [x] 3.1 Implement the fix
    - Update `_parse_row` method in `HeaderParser` class (lines 217-289)
    - Replace naive regex pattern `(\S+)` with enhanced pattern that captures complete reference tokens including hyphenated suffixes
    - New pattern should match: `([A-Za-z0-9]+(?:-[A-Za-z0-9]+)*)`
    - This pattern matches:
      - Base reference: alphanumeric characters (letters and digits)
      - Optional suffix: hyphen followed by one or more alphanumeric characters
      - Multiple suffixes: pattern repeats for multiple hyphenated segments
    - Update reference extraction section (lines 233-241) to use enhanced pattern
    - Ensure extraction logic correctly identifies end of reference token at first whitespace AFTER complete reference
    - Add validation to verify extracted reference matches expected format before returning
    - _Bug_Condition: isBugCondition(input) where input contains reference matching [A-Z]+\d+-[0-9a-zA-Z]+_
    - _Expected_Behavior: Complete reference including suffix should be extracted as single token_
    - _Preservation: References without suffixes and all other fields must continue to be extracted correctly_
    - _Requirements: 2.1, 2.2, 2.3, 3.1, 3.2, 3.3, 3.4_

  - [x] 3.2 Verify bug condition exploration test now passes
    - **Property 1: Expected Behavior** - Reference ID Suffix Extraction
    - **IMPORTANT**: Re-run the SAME test from task 1 - do NOT write a new test
    - The test from task 1 encodes the expected behavior
    - When this test passes, it confirms the expected behavior is satisfied
    - Run bug condition exploration test from step 1
    - **EXPECTED OUTCOME**: Test PASSES (confirms bug is fixed)
    - Verify all counterexamples from step 1 now produce correct results
    - _Requirements: 2.1, 2.2, 2.3_

  - [x] 3.3 Verify preservation tests still pass
    - **Property 2: Preservation** - Non-Suffixed References and Other Fields
    - **IMPORTANT**: Re-run the SAME tests from task 2 - do NOT write new tests
    - Run preservation property tests from step 2
    - **EXPECTED OUTCOME**: Tests PASS (confirms no regressions)
    - Confirm all tests still pass after fix (no regressions)
    - Verify references without suffixes continue to extract correctly
    - Verify author, date, and description extraction unchanged
    - _Requirements: 3.1, 3.2, 3.3, 3.4_

## Phase 4: Integration Testing

- [-] 4. Run integration tests
  - Execute existing test suite to verify no regressions: `python3 -m pytest tests/test_header_parser.sh -v`
  - Test full file parsing with modification headers containing references with suffixes
  - Verify parsed references are correctly stored in output JSON
  - Test multiple files with various reference formats are parsed correctly
  - Verify fix doesn't break existing file parsing workflows
  - Document any issues found and resolve them
  - _Requirements: 2.1, 2.2, 2.3, 3.1, 3.2, 3.3, 3.4_

- [x] 5. Checkpoint - Ensure all tests pass
  - Ensure all tests pass (exploration, preservation, and integration)
  - Ask the user if questions arise
  - Mark complete when all tests pass and no regressions detected
