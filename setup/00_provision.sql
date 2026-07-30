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
-- 1. Database + schemas. Created here too, so 00 and 01 can run in any
--    order and neither depends on the other.
------------------------------------------------------------------------
CREATE DATABASE IF NOT EXISTS SNOWCAMP_DATAOPS;
CREATE SCHEMA   IF NOT EXISTS SNOWCAMP_DATAOPS.RAW;
CREATE SCHEMA   IF NOT EXISTS SNOWCAMP_DATAOPS.ANALYTICS;
CREATE SCHEMA   IF NOT EXISTS SNOWCAMP_DATAOPS.APP;

------------------------------------------------------------------------
-- 2. Warehouse. MEDIUM, falling back to XSMALL if the account caps size.
------------------------------------------------------------------------
EXECUTE IMMEDIATE $$
BEGIN
  CREATE WAREHOUSE IF NOT EXISTS SNOWCAMP_DATAOPS_WH WAREHOUSE_SIZE = 'MEDIUM'
    AUTO_SUSPEND = 60 AUTO_RESUME = TRUE INITIALLY_SUSPENDED = FALSE;
  RETURN 'warehouse SNOWCAMP_DATAOPS_WH ready (MEDIUM)';
EXCEPTION WHEN OTHER THEN
  BEGIN
    CREATE WAREHOUSE IF NOT EXISTS SNOWCAMP_DATAOPS_WH WAREHOUSE_SIZE = 'XSMALL'
      AUTO_SUSPEND = 60 AUTO_RESUME = TRUE INITIALLY_SUSPENDED = FALSE;
    RETURN 'warehouse SNOWCAMP_DATAOPS_WH ready (XSMALL fallback)';
  EXCEPTION WHEN OTHER THEN
    RETURN 'could not create SNOWCAMP_DATAOPS_WH: ' || SQLERRM;
  END;
END;
$$;

------------------------------------------------------------------------
-- 3. Optional account settings for Cortex. Each is wrapped so that a
--    policy restriction or a role that is not available in this region
--    reports a message instead of stopping the script.
------------------------------------------------------------------------
EXECUTE IMMEDIATE $$
BEGIN
  ALTER ACCOUNT SET CORTEX_ENABLED_CROSS_REGION = 'ANY_REGION';
  RETURN 'cross-region inference enabled';
EXCEPTION WHEN OTHER THEN RETURN 'cross-region not set (fine): ' || SQLERRM;
END;
$$;

EXECUTE IMMEDIATE $$
BEGIN
  GRANT DATABASE ROLE SNOWFLAKE.CORTEX_USER TO ROLE SYSADMIN;
  RETURN 'CORTEX_USER granted to SYSADMIN';
EXCEPTION WHEN OTHER THEN RETURN 'CORTEX_USER grant skipped: ' || SQLERRM;
END;
$$;

EXECUTE IMMEDIATE $$
BEGIN
  GRANT DATABASE ROLE SNOWFLAKE.CORTEX_AGENT_USER TO ROLE SYSADMIN;
  RETURN 'CORTEX_AGENT_USER granted to SYSADMIN';
EXCEPTION WHEN OTHER THEN RETURN 'CORTEX_AGENT_USER grant skipped: ' || SQLERRM;
END;
$$;

------------------------------------------------------------------------
-- 4. Compute pool for the final Streamlit-on-SPCS step. Wrapped because
--    SPCS is not enabled on every account; the data lab works without it.
------------------------------------------------------------------------
EXECUTE IMMEDIATE $$
BEGIN
  CREATE COMPUTE POOL IF NOT EXISTS SNOWCAMP_DATAOPS_POOL
    MIN_NODES = 1 MAX_NODES = 1 INSTANCE_FAMILY = CPU_X64_XS AUTO_SUSPEND_SECS = 300;
  RETURN 'compute pool SNOWCAMP_DATAOPS_POOL ready';
EXCEPTION WHEN OTHER THEN RETURN 'compute pool skipped: ' || SQLERRM;
END;
$$;

------------------------------------------------------------------------
-- 5. Verify — every row below should come back populated.
------------------------------------------------------------------------
SHOW WAREHOUSES LIKE 'SNOWCAMP_DATAOPS_WH';
SHOW DATABASES  LIKE 'SNOWCAMP_DATAOPS';
-- Next: run 01_data.sql, then open a Workspace and start on the requirements.
