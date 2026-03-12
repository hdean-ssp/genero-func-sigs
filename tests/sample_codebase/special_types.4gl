# Functions with special and advanced types

FUNCTION process_interval(time_span)
	DEFINE time_span INTERVAL DAY TO HOUR
	DEFINE result INTEGER
	
	LET result = 24
	CALL log_interval(time_span)
	RETURN result
END FUNCTION

FUNCTION handle_text_blob(content)
	DEFINE content TEXT
	DEFINE status SMALLINT
	DEFINE row_count INTEGER
	
	LET status = 1
	LET row_count = 0
	CALL process_blob(content)
	RETURN status, row_count
END FUNCTION

FUNCTION calculate_money(amount1, amount2)
	DEFINE amount1 MONEY(10,2)
	DEFINE amount2 MONEY(10,2)
	DEFINE total MONEY(10,2)
	DEFINE tax DECIMAL(5,2)
	
	LET total = amount1 + amount2
	LET tax = 0.15
	CALL validate_amount(total)
	LET tax = calculate_tax(total)
	RETURN total, tax
END FUNCTION

FUNCTION get_serial_value()
	DEFINE new_id SERIAL
	DEFINE success BOOLEAN
	
	LET new_id = 1001
	LET success = TRUE
	CALL log_serial(new_id)
	RETURN new_id, success
END FUNCTION

FUNCTION process_dynamic_array(data)
	DEFINE data DYNAMIC ARRAY OF RECORD
		field1 INTEGER,
		field2 STRING
	END RECORD
	DEFINE count INTEGER
	
	LET count = 10
	CALL validate_array(data)
	CALL process_records(data)
	RETURN count
END FUNCTION

FUNCTION handle_boolean_logic(flag1, flag2)
	DEFINE flag1 BOOLEAN
	DEFINE flag2 BOOLEAN
	DEFINE result BOOLEAN
	
	LET result = flag1 AND flag2
	CALL log_boolean(result)
	RETURN result
END FUNCTION
