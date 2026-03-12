# Edge cases and special scenarios

FUNCTION function_with_long_params(param1, param2, param3, param4, param5)
    DEFINE param1 VARCHAR(255)
    DEFINE param2 DECIMAL(10,2)
    DEFINE param3 DATETIME YEAR TO SECOND
    DEFINE param4 MONEY(16,2)
    DEFINE param5 BYTE
    DEFINE result INTEGER
    
    LET result = 0
    RETURN result
END FUNCTION

FUNCTION inline_return()
    DEFINE status INTEGER
    LET status = 1
    RETURN status
END FUNCTION

FUNCTION function_with_comments(value)
    DEFINE value INTEGER
    DEFINE result STRING
    
    # Another comment
    LET result = "test"
    RETURN result  # Return comment
END FUNCTION

FUNCTION mixed_case_FUNCTION(MixedParam)
    DEFINE MixedParam CHAR(10)
    DEFINE Output_Value SMALLINT
    
    LET Output_Value = 1
    RETURN Output_Value
END FUNCTION

