# Functions with various whitespace patterns

FUNCTION spaced_function(param1, param2)
    DEFINE param1 INTEGER
    DEFINE param2 STRING
    DEFINE result CHAR(5)
    
    LET result = "OK"
    RETURN result
END FUNCTION

FUNCTION compact_function(a,b,c)
    DEFINE a INTEGER
    DEFINE b INTEGER
    DEFINE c INTEGER
    DEFINE sum INTEGER
    LET sum = a + b + c
    RETURN sum
END FUNCTION

FUNCTION tabbed_function(value)
    DEFINE value DECIMAL
    DEFINE output INTEGER
    
    LET output = 1
    RETURN	output
END FUNCTION

