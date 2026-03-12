# Functions with multiple return values

FUNCTION calculate_stats(values)
    DEFINE values ARRAY OF DECIMAL
    DEFINE total DECIMAL
    DEFINE average DECIMAL
    DEFINE count INTEGER
    
    # Calculate statistics
    LET total = 100.50
    LET average = 25.125
    LET count = 4
    
    RETURN total, average, count
END FUNCTION

FUNCTION validate_user(username, password)
    DEFINE username STRING
    DEFINE password STRING
    DEFINE is_valid SMALLINT
    DEFINE error_msg STRING
    
    LET is_valid = 1
    LET error_msg = ""
    
    RETURN is_valid, error_msg
END FUNCTION
