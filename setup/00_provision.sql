/* =====================================================================
   Snow Camp 2026 — BUILDATHON · Track C (Data Engineering & Governance)
   PROVISION  (repo file 00)  —  run this FIRST, then 01_data.sql
   ---------------------------------------------------------------------
   Problem: turn messy, multi-source commercial data at scale into a
   governed, monitored, analytics-ready mart (standardize + dedupe,
   classify + mask PII, DMFs, a dynamic-table pipeline, lineage).

   Run as ACCOUNTADMIN (or your admin-like role). Creates account settings,
   a warehouse, and a compute pool for the final Streamlit-on-SPCS gate.
   01_data.sql creates the database + data.
   ===================================================================== */

USE ROLE ACCOUNTADMIN;

-- Environment for Track. Plain SQL, runs top to bottom.
-- 01_data.sql also creates the database and warehouse, so if you only run
-- 01_data.sql you still get a working data lab. This file adds the Cortex
-- grants and the compute pool used by the final Streamlit-on-SPCS step.

CREATE WAREHOUSE IF NOT EXISTS SNOWCAMP_DATAOPS_WH
  WAREHOUSE_SIZE = 'XSMALL' AUTO_SUSPEND = 120 AUTO_RESUME = TRUE INITIALLY_SUSPENDED = FALSE;

CREATE DATABASE IF NOT EXISTS SNOWCAMP_DATAOPS;
CREATE SCHEMA IF NOT EXISTS SNOWCAMP_DATAOPS.RAW;
CREATE SCHEMA IF NOT EXISTS SNOWCAMP_DATAOPS.ANALYTICS;
CREATE SCHEMA IF NOT EXISTS SNOWCAMP_DATAOPS.APP;

-- Cortex access for the agent / Analyst / Search work.
GRANT DATABASE ROLE SNOWFLAKE.CORTEX_USER TO ROLE ACCOUNTADMIN;

-- Compute pool for the final Streamlit-in-Snowflake app on SPCS (container
-- runtime, no Docker). Not needed until the app step.
CREATE COMPUTE POOL IF NOT EXISTS SNOWCAMP_DATAOPS_POOL
  MIN_NODES = 1 MAX_NODES = 1 INSTANCE_FAMILY = CPU_X64_XS AUTO_SUSPEND_SECS = 300;

-- Verify.
SHOW WAREHOUSES LIKE 'SNOWCAMP_DATAOPS_WH';
SHOW DATABASES  LIKE 'SNOWCAMP_DATAOPS';
-- Next: run 01_data.sql, then open a Workspace and start on the requirements.
