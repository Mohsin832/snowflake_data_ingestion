--==============================
-- Loading data using Snow Pipe
--===============================

-- 1. Stage the data
-- 2. Test the copy command
-- 3. Create pipe
-- 4. Configure cloud event / call snow pipe rest API

-- truncating data again
TRUNCATE TABLE TESLA_STOCKS;

-- dropping previously create integration & stage
DROP STORAGE INTEGRATION S3_INTEGRATION;
DROP STAGE S3_INTEGRATEION_BULK_COPY_TESLA_STOCKS;

-- HELP: https://docs.snowflake.com/en/user-guide/data-load-s3-config-storage-integration
-- Step 1: Configure access permissions (policy) for the S3 bucket
-- Step 2: Create the IAM Role in AWS and attach above policy you created.

-- Step 3: Create a Cloud Storage Integration in Snowflake
CREATE OR REPLACE STORAGE INTEGRATION S3_TESLA_INTEGRATION
  TYPE = EXTERNAL_STAGE
  STORAGE_PROVIDER = 'S3'
  STORAGE_AWS_ROLE_ARN = '-------role arn-----------'
  ENABLED = TRUE
  STORAGE_ALLOWED_LOCATIONS = ('s3://snowflake-class-project');

-- Step 4: Retrieve the AWS IAM User for your Snowflake Account
DESC INTEGRATION S3_TESLA_INTEGRATION;

-- Step 5: Grant the IAM User Permissions to Access Bucket Objects
-- STORAGE_AWS_ROLE_ARN
-- STORAGE_AWS_EXTERNAL_ID

-- Step 6: Create file format for external stage
CREATE OR REPLACE FILE FORMAT S3_TESLA_STAGE_FORMAT
    TYPE= 'CSV'
    FIELD_DELIMITER=','
    SKIP_HEADER=1;

drop

-- Step 6: Create an external stage using file format createbavove
CREATE or replace STAGE S3_TESLA_STAGE
  STORAGE_INTEGRATION = S3_TESLA_INTEGRATION
  URL = 's3://snowflake-class-project/input-data/'
  FILE_FORMAT = S3_TESLA_STAGE_FORMAT;


-- Step 7: Create a COPY Into Command
-- HELP: https://docs.snowflake.com/en/user-guide/data-load-s3-copy

COPY INTO TESLA_STOCKS FROM @S3_TESLA_STAGE;

-- validating & dropping again for pip
SELECT * FROM TESLA_STOCKS;
TRUNCATE TABLE TESLA_STOCKS;

--  Creating Pipe
CREATE OR REPLACE PIPE S3_TESLA_PIPE --name
AUTO_INGEST=TRUE
AS
COPY INTO TESLA_STOCKS FROM @S3_TESLA_STAGE;

-- Configure cloud event / call snow pipe rest API (S3_TESLA_EVENT_NOTICTATION)
SHOW PIPES;

-- Data should be there auotmatically
SELECT * FROM TESLA_STOCKS;

-- DROPPING PIPE
DROP PIPE S3_TESLA_PIPE;
