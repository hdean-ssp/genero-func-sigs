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
	CALL validate_record(rec)
	CALL check_status(status_flag)
	RETURN success
END FUNCTION

FUNCTION get_date_range(start_date, end_date)
	DEFINE start_date DATE
	DEFINE end_date DATE
	DEFINE days_between INTEGER
	DEFINE is_valid SMALLINT
	
	LET days_between = 30
	LET is_valid = 1
	
	CALL validate_dates(start_date, end_date)
	LET days_between = calculate_days(start_date, end_date)
	
	RETURN days_between, is_valid
END FUNCTION

FUNCTION transform_data(input_rec)
	DEFINE input_rec RECORD
		field1 STRING,
		field2 INTEGER
	END RECORD
	DEFINE output_rec RECORD
		result STRING,
		status INTEGER
	END RECORD
	
	CALL preprocess_record(input_rec)
	LET output_rec.result = format_field(input_rec.field1)
	LET output_rec.status = 0
	
	RETURN output_rec
END FUNCTION
