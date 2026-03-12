# Functions with various whitespace patterns

FUNCTION spaced_function(param1, param2)
	DEFINE param1 INTEGER
	DEFINE param2 STRING
	DEFINE result CHAR(5)
	
	LET result = "OK"
	CALL validate_params(param1, param2)
	RETURN result
END FUNCTION

FUNCTION compact_function(a,b,c)
	DEFINE a INTEGER
	DEFINE b INTEGER
	DEFINE c INTEGER
	DEFINE sum INTEGER
	LET sum = a + b + c
	CALL log_sum(sum)
	RETURN sum
END FUNCTION

FUNCTION tabbed_function(value)
	DEFINE value DECIMAL
	DEFINE output INTEGER
	
	LET output = 1
	CALL process_value(value)
	RETURN	output
END FUNCTION

FUNCTION mixed_whitespace(x, y)
	DEFINE x INTEGER
	DEFINE y INTEGER
	DEFINE z INTEGER
	
	LET z = x + y
	CALL	log_calculation(x, y, z)
	LET z = adjust_value(z)
	RETURN z
END FUNCTION
