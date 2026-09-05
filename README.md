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
