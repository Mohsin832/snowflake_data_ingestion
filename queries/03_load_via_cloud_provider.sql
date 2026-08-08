--===================================
-- Loading data using Cloud Provider
--===================================

-- tesla table
CREATE OR REPLACE TABLE TESLA_STOCKS(
    date DATE,
    open_value DOUBLE,
    high_vlaue DOUBLE,
    low_value DOUBLE,
    close_vlaue DOUBLE,
    adj_close_value DOUBLE,
    volume BIGINT
);

-- should be empty
SELECT * FROM TESLA_STOCKS;

-- external stage creation
CREATE OR REPLACE STAGE BULK_COPY_TESLA_STOCKS
URL = "s3://snowflake-class-project/input-data/TSLA.csv"
CREDENTIALS = (AWS_KEY_ID='', AWS_SECRET_KEY='');

-- list stage
LIST @BULK_COPY_TESLA_STOCKS;

-- copy data from stage to table
COPY INTO TESLA_STOCKS
	FROM @BULK_COPY_TESLA_STOCKS
	file_format = (TYPE = 'CSV', FIELD_DELIMITER=',', SKIP_HEADER=1)
    on_error = 'skip_file';

-- data should be there
SELECT * FROM TESLA_STOCKS;

------------------------
-- Storage Integration
------------------------

-- giving privileges
USE ROLE ACCOUNTADMIN;
GRANT CREATE INTEGRATION ON ACCOUNT TO SYSADMIN;
USE ROLE SYSADMIN;

-- storage integration
CREATE OR REPLACE STORAGE INTEGRATION S3_INTEGRATION
  TYPE = EXTERNAL_STAGE
  STORAGE_PROVIDER = 'S3'
  STORAGE_AWS_ROLE_ARN = '----------role arn --------------'
  ENABLED = TRUE
  STORAGE_ALLOWED_LOCATIONS = ('s3://snowflake-class-project');

-- giving privileges
USE ROLE ACCOUNTADMIN;
GRANT USAGE ON INTEGRATION S3_INTEGRATION TO ROLE SYSADMIN;
USE ROLE SYSADMIN;

-- valdating integration
DESC INTEGRATION S3_INTEGRATION;

-- Grant SYSADMIN usage and create privileges on the database and schema
USE ROLE ACCOUNTADMIN;
GRANT USAGE ON DATABASE PROJECT_DB TO ROLE SYSADMIN;
GRANT USAGE ON SCHEMA PROJECT_DB.PUBLIC TO ROLE SYSADMIN;
GRANT CREATE STAGE ON SCHEMA PROJECT_DB.PUBLIC TO ROLE SYSADMIN;

-- Switch back to SYSADMIN
USE ROLE SYSADMIN;


-- creating stage
CREATE OR REPLACE STAGE S3_INTEGRATEION_BULK_COPY_TESLA_STOCKS
  STORAGE_INTEGRATION = S3_INTEGRATION
  URL = 's3://snowflake-class-project/input-data/TSLA.csv'
  FILE_FORMAT = (TYPE = 'CSV', FIELD_DELIMITER=',', SKIP_HEADER=1);

-- validating integration
LIST @S3_INTEGRATEION_BULK_COPY_TESLA_STOCKS;

-- Need to give the snowflake ARN & ID

-- Making sure the table is empty
TRUNCATE TABLE TESLA_STOCKS;
SELECT * FROM TESLA_STOCKS;

-- Copy data using integration
COPY INTO TESLA_STOCKS FROM @S3_INTEGRATEION_BULK_COPY_TESLA_STOCKS;

-- data should be there
SELECT * FROM TESLA_STOCKS;
