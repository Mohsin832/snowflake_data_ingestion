--===================================
-- Loading data using Web Interface
--===================================
-- Creating a testing database
CREATE DATABASE PROJECT_DB;
USE DATABASE PROJECT_DB;

-- customer table
CREATE TABLE CUSTOMER_DETAILS (
    first_name STRING,
    last_name STRING,
    address STRING,
    city STRING,
    state STRING
);

-- create file format seperated by ("|")
create or replace file format file_format_ui
type = "CSV"
field_delimiter = "|"
skip_header = 1;

-- copy data from stage to table 
create or replace file format file_format_ui
type = "CSV"
field_delimiter = "|"
skip_header = 1;

-- table should be empty
SELECT * FROM CUSTOMER_DETAILS;