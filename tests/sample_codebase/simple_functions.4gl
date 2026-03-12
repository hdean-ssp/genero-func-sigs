# Simple functions with basic parameter and return types

FUNCTION add_numbers(a, b)
    DEFINE a INTEGER
    DEFINE b INTEGER
    DEFINE result INTEGER
    
    LET result = a + b
    # Call another function to validate result
    CALL validate_number(result)
    RETURN result
END FUNCTION

FUNCTION get_user_name(user_id)
    DEFINE user_id INTEGER
    DEFINE name STRING
    
    # Some logic here
    LET name = "John Doe"
    # Call library function to format name
    LET name = format_string(name)
    RETURN name
END FUNCTION

FUNCTION no_params_no_return()
    DISPLAY "Hello World"
    # Call utility function
    CALL log_message("Function executed")
END FUNCTION

FUNCTION display_message(msg)
    DEFINE msg STRING
    
    DISPLAY msg
    CALL log_message(msg)
END FUNCTION
