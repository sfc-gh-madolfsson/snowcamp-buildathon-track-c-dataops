# A Trusted Customer Foundation
**Track C · Data Engineering & Governance**

> **Snow Camp 2026 — Cortex Code Buildathon.** Everything runs inside Snowsight — **nothing to download.** Open each SQL file below, click the **copy icon** (top-right), paste into a Snowsight **SQL worksheet**, and **Run All**.

---

## Setup (run these first)

1. Open a **Snowsight SQL worksheet**, paste [`setup/00_provision.sql`](setup/00_provision.sql), **Run All**.
2. New worksheet, paste [`setup/01_data.sql`](setup/01_data.sql), **Run All** (~1–3 min).
3. Open a **Workspace** and start building with Cortex Code.

New to prompting Cortex Code? [Prompting primer](shared/prompting-primer.md) ·
Deploying the app: [Streamlit on SPCS](shared/streamlit-spcs-deploy.md)

---

## The brief

You are working in the data foundation team. Two systems disagree about who our customers are: the CRM
and the ERP each hold their own version of every prescriber, with different keys, different name formats
and different ways of writing the same country. Nobody is wrong on purpose, but every report downstream
inherits the argument, and the business has stopped trusting the numbers. You have been asked to produce
one customer master everyone can rely on — and, just as importantly, to show that it can be relied on.
There is patient data in scope too, which brings its own governance obligations. The result needs to land
in a Streamlit in Snowflake application that gives the business a clear view of how trustworthy this
foundation is.

## What you're given

Database `SNOWCAMP_DATAOPS`, schema `RAW`:

| Table | Rows | What it is |
|---|---|---|
| `HCP_MASTER_CRM` | 80k | The CRM's view of prescribers. Contains PII. |
| `HCP_MASTER_ERP` | 50k | The ERP's view of the same prescribers, keyed and formatted differently. |
| `PRESCRIPTIONS` | ~6M | What was prescribed, by whom, when, how much. |
| `PATIENTS` | 500k | Enrolled patients. Contains sensitive personal data. |
| `MEDICATION_ADHERENCE` | ~2M | Adherence and refill history per patient. |
| `TERRITORY_PERFORMANCE` | 300 | Addressable patients, penetration and rep count per territory. |

Work out what's actually in there before you build on it.

## Here are the requirements for the foundation and application

1. Work out how the two source systems relate to each other and reconcile them into a single customer
   master with one row per prescriber. Where the two disagreed, be able to explain which version won and
   why.
2. Standardise the values that mean the same thing but are written differently, so the business can group
   and filter on them without surprises.
3. Find the PII across both the prescriber and patient data, classify it, and protect it with **masking
   policies** — and leave behind something someone else can run to confirm the protection works.
4. Attach **data metric functions** to the master so quality is checked automatically rather than living
   in someone's ad-hoc queries, and problems surface as the data changes.
5. Make the whole thing keep itself current as new data arrives, and be able to show where any figure in
   the master came from.
6. Build a **Streamlit in Snowflake** application that shows all of the above requirements are met and
   gives the business a clear, honest view of how trustworthy this data is, in a highly visual and
   appealing way.

## Nice to have

- Apply the protection by tag, so new sensitive columns are covered automatically.
- Alert someone when a quality check starts failing.
- Visualise the lineage from source system to the master.
- Let someone ask about data quality in natural language.
- Turn what you built into a reusable skill so the next person runs it in one command.

## Toolbox

Skills that are relevant here. No particular order — use them if they help.

`/data-governance` · `/data-quality` · `/dynamic-tables` · `/lineage` · `/sql-author` ·
`/developing-with-streamlit-in-snowflake` · `/snowflake-tasks` · `/skill-development`

## Watch out

The two systems don't share a key format, one of them has duplicate rows for the same prescriber, and
some records describe people who can't exist. Joining them naively will look like it worked.

---

**Objects:** DB `SNOWCAMP_DATAOPS` · Warehouse `SNOWCAMP_DATAOPS_WH` · Compute pool `SNOWCAMP_DATAOPS_POOL`
