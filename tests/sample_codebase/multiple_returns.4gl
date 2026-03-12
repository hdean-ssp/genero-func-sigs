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
	
	# Call validation function
	CALL validate_number(total)
	
	RETURN total, average, count
END FUNCTION

FUNCTION validate_user(username, password)
	DEFINE username STRING
	DEFINE password STRING
	DEFINE is_valid SMALLINT
	DEFINE error_msg STRING
	
	LET is_valid = 1
	LET error_msg = ""
	
	# Call library functions
	CALL check_username(username)
	LET error_msg = format_error(error_msg)
	
	RETURN is_valid, error_msg
END FUNCTION

FUNCTION process_data(input_data)
	DEFINE input_data STRING
	DEFINE result_code INTEGER
	DEFINE result_message STRING
	DEFINE result_data STRING
	
	# Process and validate
	CALL validate_input(input_data)
	LET result_code = 0
	LET result_message = "Success"
	LET result_data = transform_data(input_data)
	
	RETURN result_code, result_message, result_data
END FUNCTION
