# Simple functions with basic parameter and return types

FUNCTION add_numbers(a, b)
    DEFINE a INTEGER
    DEFINE b INTEGER
    DEFINE result INTEGER
    
    LET result = a + b
    RETURN result
END FUNCTION

FUNCTION get_user_name(user_id)
    DEFINE user_id INTEGER
    DEFINE name STRING
    
    # Some logic here
    LET name = "John Doe"
    RETURN name
END FUNCTION

FUNCTION no_params_no_return()
    DISPLAY "Hello World"
END FUNCTION
