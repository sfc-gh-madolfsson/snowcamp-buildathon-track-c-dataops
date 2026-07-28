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

USE ROLE ACCOUNTADMIN;   -- or your admin-like role

------------------------------------------------------------------------
-- 1. Account settings for Cortex Code / Cortex AI
------------------------------------------------------------------------
ALTER ACCOUNT SET CORTEX_ENABLED_CROSS_REGION = 'AWS_EU';   -- broaden per your residency policy
GRANT DATABASE ROLE SNOWFLAKE.COPILOT_USER      TO ROLE SYSADMIN;
GRANT DATABASE ROLE SNOWFLAKE.CORTEX_USER       TO ROLE SYSADMIN;
GRANT DATABASE ROLE SNOWFLAKE.CORTEX_AGENT_USER TO ROLE SYSADMIN;
-- MANUAL (one-time, UI): Snowsight > AI/ML > Agents > Settings > enable Web search.

------------------------------------------------------------------------
-- 2. Warehouse — profiling, cleansing, DMFs, dynamic-table pipeline.
--    MEDIUM is fine; bump to LARGE if profiling the big tables is slow.
------------------------------------------------------------------------
CREATE WAREHOUSE IF NOT EXISTS SNOWCAMP_DATAOPS_WH
  WAREHOUSE_SIZE = 'MEDIUM' AUTO_SUSPEND = 60 AUTO_RESUME = TRUE INITIALLY_SUSPENDED = FALSE;

------------------------------------------------------------------------
-- 3. Compute pool — runs the final Streamlit-in-Snowflake app on SPCS
--    (container runtime, no Docker).
------------------------------------------------------------------------
CREATE COMPUTE POOL IF NOT EXISTS SNOWCAMP_DATAOPS_POOL
  MIN_NODES = 1 MAX_NODES = 1 INSTANCE_FAMILY = CPU_X64_XS AUTO_SUSPEND_SECS = 300;

------------------------------------------------------------------------
-- 4. Verify
------------------------------------------------------------------------
SHOW COMPUTE POOLS LIKE 'SNOWCAMP_DATAOPS_POOL';   -- expect STARTING then ACTIVE/IDLE
SHOW WAREHOUSES LIKE 'SNOWCAMP_DATAOPS_WH';
-- Next: run 01_data.sql, then open a Workspace and start the mission brief.
