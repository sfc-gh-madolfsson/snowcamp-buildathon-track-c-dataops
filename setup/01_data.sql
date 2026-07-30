/* =====================================================================
   Snow Camp 2026 — BUILDATHON · Track C (Data Engineering & Governance)
   SYNTHETIC DATA  (repo file 01)  —  run AFTER 00_provision.sql
   ---------------------------------------------------------------------
   Creates database SNOWCAMP_DATAOPS (RAW / ANALYTICS / APP) with the
   messiest, largest dataset of the buildathon — TWO source systems that
   disagree, plus multi-million-row facts:

     RAW.HCP_MASTER_CRM   ~80k  CRM source: PII, dup IDs, spelling/tier drift, key 'HCP_000123'
     RAW.HCP_MASTER_ERP   ~50k  ERP source: SAME HCPs, DIFFERENT formats, key 'HCP-000123'
     RAW.PRESCRIPTIONS    ~6M   Rx fact: null/orphan HCP, negatives, product drift, dup rows
     RAW.PATIENTS         500k  patient PII: names, national IDs, impossible ages, gender drift
     RAW.MEDICATION_ADHERENCE ~2M  adherence: >100%, orphan patients
     RAW.TERRITORY_PERFORMANCE 300  penetration > 1

   Your job: standardize + dedupe into a golden HCP master, govern the PII,
   monitor with DMFs, and build a fresh curated mart with lineage.
   All objects FULLY QUALIFIED. LARGE gen warehouse, dropped at the end.
   ===================================================================== */

USE ROLE ACCOUNTADMIN;

-- Environment: warehouse, database, schemas. Plain SQL, runs top to bottom.
CREATE WAREHOUSE IF NOT EXISTS SNOWCAMP_DATAOPS_WH
  WAREHOUSE_SIZE = 'XSMALL' AUTO_SUSPEND = 120 AUTO_RESUME = TRUE INITIALLY_SUSPENDED = FALSE;
USE WAREHOUSE SNOWCAMP_DATAOPS_WH;

CREATE DATABASE IF NOT EXISTS SNOWCAMP_DATAOPS;
USE DATABASE SNOWCAMP_DATAOPS;
CREATE SCHEMA IF NOT EXISTS SNOWCAMP_DATAOPS.RAW;
CREATE SCHEMA IF NOT EXISTS SNOWCAMP_DATAOPS.ANALYTICS;
CREATE SCHEMA IF NOT EXISTS SNOWCAMP_DATAOPS.APP;
USE SCHEMA SNOWCAMP_DATAOPS.RAW;

/* ===================== SOURCE 1: CRM (65k + 15k dup = 80k) =====================
   INCONSISTENCY: ~3% null names; 15k duplicate HCP_IDs; country + tier drift; PII */
CREATE OR REPLACE TABLE SNOWCAMP_DATAOPS.RAW.HCP_MASTER_CRM AS
SELECT
  'HCP_' || LPAD(SEQ4()::string, 6, '0')                                 AS HCP_ID,
  CASE WHEN UNIFORM(1,100,RANDOM()) <= 3 THEN NULL
       ELSE GET(ARRAY_CONSTRUCT('Dr. Anna Sorensen','Dr. Lars Nielsen','Dr. Mette Jensen',
              'Dr. Erik Larsson','Dr. Sofia Berg','Dr. Johan Andersson','Dr. Karin Holm',
              'Dr. Peter Madsen','Dr. Elin Lund','Dr. Nils Pedersen','Dr. Freja Dahl','Dr. Anders Kjaer'),
              UNIFORM(0,11,RANDOM()))::string END                        AS HCP_FULL_NAME,
  LOWER('hcp' || SEQ4() || '@example-health.eu')                          AS EMAIL,          -- PII
  '+45 ' || UNIFORM(10000000,99999999,RANDOM())::string                   AS PHONE,          -- PII
  GET(ARRAY_CONSTRUCT('Denmark','denmark','DK ','Danmark','Sweden','sweden',
      'Norway','norway',' Finland','finland','Iceland','iceland'), UNIFORM(0,11,RANDOM()))::string AS COUNTRY,
  GET(ARRAY_CONSTRUCT('A','Tier 1','tier1','1','B','Tier 2','tier2','2','C','Tier 3'),
      UNIFORM(0,9,RANDOM()))::string                                     AS HCP_TIER,
  GET(ARRAY_CONSTRUCT('Endocrinology','Cardiology','General Practice','Diabetology',
      'Internal Medicine','Nephrology'), UNIFORM(0,5,RANDOM()))::string  AS SPECIALTY,
  DATEADD('day', -UNIFORM(0,900,RANDOM()), CURRENT_TIMESTAMP())          AS LAST_UPDATED
FROM TABLE(GENERATOR(ROWCOUNT => 65000));

-- 15k duplicate HCP_IDs (survivorship problem)
INSERT INTO SNOWCAMP_DATAOPS.RAW.HCP_MASTER_CRM
SELECT * FROM SNOWCAMP_DATAOPS.RAW.HCP_MASTER_CRM
WHERE HCP_ID IN (SELECT HCP_ID FROM SNOWCAMP_DATAOPS.RAW.HCP_MASTER_CRM ORDER BY HCP_ID LIMIT 15000);

/* ===================== SOURCE 2: ERP (50k) =====================
   SAME HCPs (numeric range overlaps CRM 0-49999) but DASH key + ISO countries +
   'Tier N' scheme + LASTNAME, FIRSTNAME formatting -> reconciliation required */
CREATE OR REPLACE TABLE SNOWCAMP_DATAOPS.RAW.HCP_MASTER_ERP AS
SELECT
  'HCP-' || LPAD(SEQ4()::string, 6, '0')                                 AS HCP_ID_ERP,      -- dash, not underscore
  GET(ARRAY_CONSTRUCT('SORENSEN, ANNA','NIELSEN, LARS','JENSEN, METTE','LARSSON, ERIK',
      'BERG, SOFIA','ANDERSSON, JOHAN','HOLM, KARIN','MADSEN, PETER','LUND, ELIN',
      'PEDERSEN, NILS','DAHL, FREJA','KJAER, ANDERS'), UNIFORM(0,11,RANDOM()))::string AS HCP_NAME_LASTFIRST,
  GET(ARRAY_CONSTRUCT('DK','SE','NO','FI','IS'), UNIFORM(0,4,RANDOM()))::string        AS COUNTRY_CODE,
  GET(ARRAY_CONSTRUCT('Tier 1','Tier 2','Tier 3'), UNIFORM(0,2,RANDOM()))::string      AS TIER,
  GET(ARRAY_CONSTRUCT('Nordics','DACH','Benelux','Iberia','UK & Ireland'), UNIFORM(0,4,RANDOM()))::string AS REGION,
  DATEADD('day', -UNIFORM(0,900,RANDOM()), CURRENT_TIMESTAMP())          AS LAST_MODIFIED
FROM TABLE(GENERATOR(ROWCOUNT => 50000));

/* ===================== PRESCRIPTIONS (~6M + 100k dup) =====================
   INCONSISTENCY: ~2% null HCP_ID; ~3% orphan HCP; ~1% negative QTY; product case drift; dup rows */
CREATE OR REPLACE TABLE SNOWCAMP_DATAOPS.RAW.PRESCRIPTIONS AS
SELECT
  'RX_' || UUID_STRING()                                                 AS PRESCRIPTION_ID,
  CASE
    WHEN UNIFORM(1,100,RANDOM()) <= 2 THEN NULL
    WHEN UNIFORM(1,100,RANDOM()) <= 3 THEN 'HCP_' || LPAD(UNIFORM(900000,999999,RANDOM())::string,6,'0')
    ELSE 'HCP_' || LPAD(UNIFORM(0,64999,RANDOM())::string, 6, '0')
  END                                                                    AS HCP_ID,
  GET(ARRAY_CONSTRUCT('Ozempic','ozempic','Wegovy','wegovy','Rybelsus',
      'Victoza','Saxenda','Levemir','Tresiba','NovoRapid'), UNIFORM(0,9,RANDOM()))::string AS PRODUCT,
  DATEADD('day', -UNIFORM(0,730,RANDOM()), CURRENT_DATE())               AS PRESCRIPTION_DATE,
  CASE WHEN UNIFORM(1,100,RANDOM()) <= 1 THEN -1 * UNIFORM(1,5,RANDOM())
       ELSE UNIFORM(1,60,RANDOM()) END                                   AS QUANTITY,
  ROUND(UNIFORM(20,400,RANDOM()) + UNIFORM(0,99,RANDOM())/100.0, 2)       AS COPAY_AMOUNT
FROM TABLE(GENERATOR(ROWCOUNT => 6000000));

-- 100k exact duplicate rows
INSERT INTO SNOWCAMP_DATAOPS.RAW.PRESCRIPTIONS
SELECT * FROM SNOWCAMP_DATAOPS.RAW.PRESCRIPTIONS SAMPLE (100000 ROWS);

/* ===================== PATIENTS (500k) — heavy PII =====================
   INCONSISTENCY: ~3% impossible ages; gender encoding drift; national IDs are PII */
CREATE OR REPLACE TABLE SNOWCAMP_DATAOPS.RAW.PATIENTS AS
SELECT
  'PAT_' || LPAD(SEQ4()::string, 7, '0')                                 AS PATIENT_ID,
  GET(ARRAY_CONSTRUCT('Emma Hansen','Noah Berg','Olivia Lind','William Aas','Ella Vik',
      'Liam Moen','Maja Fossen','Oscar Haugen','Nora Dahl','Elias Bakke'), UNIFORM(0,9,RANDOM()))::string AS PATIENT_NAME, -- PII
  LPAD(UNIFORM(1,9999999999,RANDOM())::string,10,'0')                     AS NATIONAL_ID,    -- PII (SSN-like)
  CASE WHEN UNIFORM(1,100,RANDOM()) <= 3 THEN GET(ARRAY_CONSTRUCT(-2,0,142,175), UNIFORM(0,3,RANDOM()))::int
       ELSE UNIFORM(18,89,RANDOM()) END                                  AS PATIENT_AGE,
  GET(ARRAY_CONSTRUCT('Female','Male','F','M','Other','Unknown','f','m'), UNIFORM(0,7,RANDOM()))::string AS PATIENT_GENDER,
  GET(ARRAY_CONSTRUCT('Nordics','DACH','Benelux','Iberia','UK & Ireland'), UNIFORM(0,4,RANDOM()))::string AS REGION,
  GET(ARRAY_CONSTRUCT('Obesity Care','Diabetes Care','Growth Disorders','Rare Disease'), UNIFORM(0,3,RANDOM()))::string AS PROGRAM,
  DATEADD('day', -UNIFORM(0,900,RANDOM()), CURRENT_DATE())               AS ENROLLMENT_DATE
FROM TABLE(GENERATOR(ROWCOUNT => 500000));

/* ===================== MEDICATION_ADHERENCE (~2M) =====================
   INCONSISTENCY: ~4% adherence > 100; ~3% orphan patient */
CREATE OR REPLACE TABLE SNOWCAMP_DATAOPS.RAW.MEDICATION_ADHERENCE AS
SELECT
  'ADH_' || UUID_STRING()                                                AS ADHERENCE_ID,
  CASE WHEN UNIFORM(1,100,RANDOM()) <= 3 THEN 'PAT_' || LPAD(UNIFORM(9000000,9999999,RANDOM())::string,7,'0')
       ELSE 'PAT_' || LPAD(UNIFORM(0,499999,RANDOM())::string, 7, '0') END AS PATIENT_ID,
  GET(ARRAY_CONSTRUCT('Ozempic','Wegovy','Rybelsus','Victoza','Saxenda'), UNIFORM(0,4,RANDOM()))::string AS MEDICATION_NAME,
  CASE WHEN UNIFORM(1,100,RANDOM()) <= 4 THEN UNIFORM(101,130,RANDOM())
       ELSE UNIFORM(20,100,RANDOM()) END                                 AS ADHERENCE_PERCENTAGE,
  UNIFORM(0,20,RANDOM())                                                 AS MISSED_DOSES_COUNT,
  DATEADD('day', -UNIFORM(0,365,RANDOM()), CURRENT_DATE())               AS LAST_REFILL_DATE
FROM TABLE(GENERATOR(ROWCOUNT => 2000000));

/* ===================== TERRITORY_PERFORMANCE (300) ===================== */
CREATE OR REPLACE TABLE SNOWCAMP_DATAOPS.RAW.TERRITORY_PERFORMANCE AS
SELECT
  'TERR_' || LPAD(SEQ4()::string, 3, '0')                                AS TERRITORY_ID,
  GET(ARRAY_CONSTRUCT('Nordics','DACH','Benelux','Iberia','UK & Ireland'), UNIFORM(0,4,RANDOM()))::string AS REGION,
  UNIFORM(50000, 400000, RANDOM())                                       AS ADDRESSABLE_PATIENTS,
  CASE WHEN UNIFORM(1,100,RANDOM()) <= 5 THEN ROUND(UNIFORM(101,140,RANDOM())/100.0, 3)
       ELSE ROUND(UNIFORM(5,85,RANDOM())/100.0, 3) END                   AS MARKET_PENETRATION,
  UNIFORM(3, 25, RANDOM())                                               AS ACTIVE_REPS,
  DATE_TRUNC('quarter', CURRENT_DATE())                                  AS REPORT_QUARTER
FROM TABLE(GENERATOR(ROWCOUNT => 300));

/* ===================== profile ===================== */
SELECT 'HCP_MASTER_CRM' AS tbl, COUNT(*) AS row_count FROM SNOWCAMP_DATAOPS.RAW.HCP_MASTER_CRM
UNION ALL SELECT 'HCP_MASTER_ERP', COUNT(*) FROM SNOWCAMP_DATAOPS.RAW.HCP_MASTER_ERP
UNION ALL SELECT 'PRESCRIPTIONS', COUNT(*) FROM SNOWCAMP_DATAOPS.RAW.PRESCRIPTIONS
UNION ALL SELECT 'PATIENTS', COUNT(*) FROM SNOWCAMP_DATAOPS.RAW.PATIENTS
UNION ALL SELECT 'MEDICATION_ADHERENCE', COUNT(*) FROM SNOWCAMP_DATAOPS.RAW.MEDICATION_ADHERENCE
UNION ALL SELECT 'TERRITORY_PERFORMANCE', COUNT(*) FROM SNOWCAMP_DATAOPS.RAW.TERRITORY_PERFORMANCE
ORDER BY row_count DESC;

