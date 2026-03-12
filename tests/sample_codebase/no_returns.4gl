# Functions without return values (procedures)

FUNCTION display_message(msg)
    DEFINE msg STRING
    
    DISPLAY msg
END FUNCTION

FUNCTION update_database(id, value)
    DEFINE id INTEGER
    DEFINE value STRING
    
    # Update logic here
    DISPLAY "Updated record ", id
END FUNCTION

FUNCTION log_error(error_code, error_text)
    DEFINE error_code INTEGER
    DEFINE error_text VARCHAR(100)
    
    CALL write_to_log(error_code, error_text)
END FUNCTION

FUNCTION initialize_system()
    DISPLAY "System initialized"
END FUNCTION

