# snowflake_data_ingestion

# SQL Data Ingestion Guide

Data ingestion is the process of collecting raw data from various sources and moving it into a central place for storage and analysis. It serves as the foundational step in any data pipeline.

---

## 4 Ways to Ingest Data in SQL

| Method | Best For | Description |
| :--- | :--- | :--- |
| **1. Web Interface** | One-time manual uploads | Upload small files directly via the cloud console UI. |
| **2. SnowSQL (CLI)** | Local automation & scripting | Load data from local files using command-line interface commands like `PUT` and `COPY INTO`. |
| **3. Cloud Storage (S3)** | High-volume batch loading | Transfer large files directly from AWS S3, Google Cloud Storage, or Azure Blob. |
| **4. Snowpipe** | Near real-time streaming | Automate ingestion continuously as soon as new files arrive in cloud storage. |

---

## Ingesting from AWS S3 into Snowflake — 3 Approaches

The diagram below compares three ways to connect AWS S3 to Snowflake for loading data into a target table.

![Snowflake S3 ingestion methods: access keys vs S3 integration (manual) vs S3 integration with Snowpipe](./image.png)

- **Method 1 — Directly using Access Keys and Secret Access Key**
  An IAM user with an attached policy grants an AWS-S3 access key and secret access key. These credentials are used directly in a Snowflake stage (`SF-Stage`), which then loads data via `COPY INTO` the target table.

- **Method 2 — Using S3 Integration (Manual Copying)**
  A Snowflake storage integration is created with an ARN and trust relationship to a dedicated AWS IAM role (rather than raw keys), scoped to a specific S3 bucket. The integration feeds a stage, and data is loaded manually with `COPY INTO`.

- **Method 2 — Using S3 Integration (Using Snowpipe for Copying)**
  Same trust relationship / IAM role setup as above, but instead of manual `COPY INTO`, a Snowpipe (`PIPE (COPY)`) listens on a notification channel and automatically loads new files as they land in S3 — enabling near real-time ingestion.

**Key takeaway:** Access keys are simplest but least secure (long-lived credentials); S3 integration with an IAM role is more secure via a trust relationship; adding Snowpipe on top automates the loading step for continuous, low-latency ingestion.

---

## Scripts in This Repo

Each numbered script is a hands-on, runnable walkthrough of one ingestion method. Run them **in order**, since later scripts build on objects (database, table, integration) created by earlier ones.

| # | Script | What it demonstrates |
| :-- | :--- | :--- |
| 1 | `01_load_via_web_interface.sql` | Creating a database/table and a pipe-delimited file format for uploading a file through the Snowflake web UI. |
| 2 | `02_load_via_snowcli.sql` | Loading local files with SnowSQL: `PUT` to a stage, then `COPY INTO` a table. |
| 3 | `03_load_via_cloud_provider.sql` | Bulk-loading from an S3 bucket, first with raw AWS keys, then with a Storage Integration + IAM role. |
| 4 | `04_load_via_snowpipe.sql` | Automating continuous ingestion from S3 with Snowpipe (`AUTO_INGEST`). |
| 5 | `05_time_travel.sql` | Using Time Travel to undo a dropped table and query data as it existed before an update. |

---

### 1. Load via Web Interface — `01_load_via_web_interface.sql`

**Use when:** you just need to get a small file into Snowflake once, without any scripting.

Steps:
1. Run the script to create `PROJECT_DB` and the `CUSTOMER_DETAILS` table.
2. Create the `FILE_FORMAT_UI` file format (pipe-delimited CSV, header skipped).
3. In the Snowflake web UI, go to **Data → Add Data → Load files into a Stage**, select the file format created above, and load your CSV into `CUSTOMER_DETAILS`.
4. Run `SELECT * FROM CUSTOMER_DETAILS;` to confirm the load.

---

### 2. Load via SnowSQL (CLI) — `02_load_via_snowcli.sql`

**Use when:** you want to script/automate loading local files.

Prerequisites: [SnowSQL](https://docs.snowflake.com/en/user-guide/snowsql-install-config) installed and configured.

Steps:
1. `USE WAREHOUSE data_ingestion_wh;` — switch to (or create) a warehouse.
2. Log in from your terminal: `snowsql -a <account_identifier> -u <username>`.
3. Create the file format (`FILE_FORMAT_CLI`) and the internal stage (`SNOW_CLI_STAGE`).
4. `PUT` your local CSV file into the stage — **update the file path** to point at your own file instead of the sample Windows path in the script.
5. `LIST @SNOW_CLI_STAGE;` to confirm the file uploaded.
6. If the warehouse isn't set to auto-resume, run `ALTER WAREHOUSE <name> RESUME;` (replace `<name>` with your warehouse).
7. `COPY INTO CUSTOMER_DETAILS ...` to load the staged file into the table.
8. Verify with `SELECT * FROM CUSTOMER_DETAILS;`.

> The last `COPY INTO mycsvtable ...` block is just an example of using a `pattern` to load multiple matching files at once — replace `mycsvtable` / `mycsvstage` with real object names before running it.

---

### 3. Load via Cloud Provider (S3) — `03_load_via_cloud_provider.sql`

**Use when:** your data already lives in cloud storage (S3 here) and you want to bulk-load it, optionally without exposing long-lived AWS keys.

Part A — direct AWS keys:
1. Creates the `TESLA_STOCKS` table.
2. Creates an external stage pointing at an S3 URL, authenticated with `AWS_KEY_ID` / `AWS_SECRET_KEY` — **fill in your own credentials**.
3. `COPY INTO TESLA_STOCKS` loads the CSV from the stage.

Part B — Storage Integration (recommended over raw keys):
1. As `ACCOUNTADMIN`, grant `SYSADMIN` permission to create integrations.
2. Create `S3_INTEGRATION` with your S3 bucket and IAM role ARN — **replace the placeholder ARN** with your role's ARN.
3. Grant `USAGE` on the integration to `SYSADMIN`.
4. `DESC INTEGRATION S3_INTEGRATION;` — copy the returned `STORAGE_AWS_IAM_USER_ARN` and `STORAGE_AWS_EXTERNAL_ID` into your AWS IAM role's trust policy so Snowflake is allowed to assume it.
5. Grant `SYSADMIN` usage/create rights on the database and schema.
6. Create a stage that uses the integration instead of raw keys, then `COPY INTO TESLA_STOCKS` from it.

---

### 4. Load via Snowpipe — `04_load_via_snowpipe.sql`

**Use when:** you want new files landing in S3 to be ingested automatically, without a manual `COPY INTO`.

Steps:
1. Truncate the table and drop the previous integration/stage to start clean.
2. In AWS: create/attach an S3 bucket policy, then an IAM role that uses it (see the linked Snowflake docs comment in the script).
3. Create a new storage integration (`S3_TESLA_INTEGRATION`) with your role ARN.
4. `DESC INTEGRATION S3_TESLA_INTEGRATION;` and use the returned IAM user/external ID to finish trusting Snowflake in AWS.
5. Create the file format and external stage (`S3_TESLA_STAGE`) for the bucket.
6. Test ingestion manually once with `COPY INTO TESLA_STOCKS FROM @S3_TESLA_STAGE;` to make sure the stage/format are correct.
7. Truncate again, then create the pipe:
   ```sql
   CREATE OR REPLACE PIPE S3_TESLA_PIPE
   AUTO_INGEST=TRUE
   AS
   COPY INTO TESLA_STOCKS FROM @S3_TESLA_STAGE;
   ```
8. In AWS, configure an S3 event notification (on object creation) pointing at the SQS ARN Snowflake gives you for this pipe (`SHOW PIPES;` shows the notification channel).
9. Drop a new file into the S3 bucket — it should load into `TESLA_STOCKS` automatically. Verify with `SELECT * FROM TESLA_STOCKS;`.
10. `DROP PIPE S3_TESLA_PIPE;` when you're done experimenting, to stop ingestion.

---

### 5. Time Travel — `05_time_travel.sql`

**Use when:** you accidentally dropped a table or need to see data as it was before a change.

Steps:
1. `DROP TABLE TESLA_STOCKS;` then `UNDROP TABLE TESLA_STOCKS;` restores a dropped table.
2. Run an `UPDATE` (as in the script) to change some data.
3. Find the statement ID of that update (e.g. from the Snowflake **Query History** UI, or `SELECT LAST_QUERY_ID();` right after running it).
4. Query the pre-update state with:
   ```sql
   SELECT * FROM TESLA_STOCKS BEFORE (statement => '<statement_id>') ORDER BY DATE DESC;
   ```
   replacing `<statement_id>` with the ID you found.

> Time Travel only works within your account's retention period (1 day by default on Standard edition, configurable up to 90 days on Enterprise+).

---

## Prerequisites

- A Snowflake account with a role that can create databases, warehouses, stages, integrations, and pipes (e.g. `SYSADMIN`, with `ACCOUNTADMIN` for the integration-granting steps).
- An AWS account with an S3 bucket, if you're running scripts 3–4.
- [SnowSQL](https://docs.snowflake.com/en/user-guide/snowsql-install-config) installed, if you're running script 2.
- Before running scripts 3 and 4, replace every placeholder (AWS keys, role ARNs, bucket names, file paths) with your own values — none of the credentials in these scripts are real.
