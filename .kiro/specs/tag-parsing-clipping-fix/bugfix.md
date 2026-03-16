# Bugfix Requirements Document

## Introduction

The tag parsing logic in the header parser is incorrectly truncating reference IDs. When parsing modification headers in code files, reference IDs with numeric suffixes (e.g., "EH100058-10") are being clipped to their base form (e.g., "EH100058"), losing the suffix information. This causes incomplete reference tracking and loss of critical change history data.

## Bug Analysis

### Current Behavior (Defect)

1.1 WHEN a reference_id contains a numeric suffix after a hyphen (e.g., "EH100058-10") THEN the system extracts only the base reference without the suffix (e.g., "EH100058")

1.2 WHEN a reference_id contains an alphanumeric suffix after a hyphen (e.g., "EH100512-9a") THEN the system extracts only the base reference without the suffix (e.g., "EH100512")

1.3 WHEN a reference_id is positioned at the start of a data row with variable spacing before the next column THEN the system clips the reference at the first detected column boundary instead of extracting the complete reference token

### Expected Behavior (Correct)

2.1 WHEN a reference_id contains a numeric suffix after a hyphen (e.g., "EH100058-10") THEN the system SHALL extract the complete reference including the suffix (e.g., "EH100058-10")

2.2 WHEN a reference_id contains an alphanumeric suffix after a hyphen (e.g., "EH100512-9a") THEN the system SHALL extract the complete reference including the suffix (e.g., "EH100512-9a")

2.3 WHEN a reference_id is positioned at the start of a data row with variable spacing before the next column THEN the system SHALL extract the complete reference token as a single unit without clipping at intermediate column boundaries

### Unchanged Behavior (Regression Prevention)

3.1 WHEN a reference_id has no suffix (e.g., "EH100512") THEN the system SHALL CONTINUE TO extract it correctly as "EH100512"

3.2 WHEN a reference_id is followed by whitespace and other columns THEN the system SHALL CONTINUE TO correctly identify the end of the reference token at the first whitespace boundary

3.3 WHEN parsing files with properly formatted modification headers THEN the system SHALL CONTINUE TO extract all other fields (author, date, description) correctly

3.4 WHEN processing files without modification sections THEN the system SHALL CONTINUE TO return None or empty results without errors
