--===================================
-- Loading data using Web Interface
--===================================
drop database PROJECT_DB;
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

-- table should be empty
SELECT * FROM CUSTOMER_DETAILS;

-- Now Load data into CUSTOMER_DETAILS
