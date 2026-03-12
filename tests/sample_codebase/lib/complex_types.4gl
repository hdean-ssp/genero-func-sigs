# Functions with complex parameter types

FUNCTION process_record(rec, status_flag)
    DEFINE rec RECORD
        id INTEGER,
        name STRING,
        amount DECIMAL
    END RECORD
    DEFINE status_flag CHAR(1)
    DEFINE success SMALLINT
    
    LET success = 1
    RETURN success
END FUNCTION

FUNCTION get_date_range(start_date, end_date)
    DEFINE start_date DATE
    DEFINE end_date DATE
    DEFINE days_between INTEGER
    DEFINE is_valid SMALLINT
    
    LET days_between = 30
    LET is_valid = 1
    
    RETURN days_between, is_valid
END FUNCTION
