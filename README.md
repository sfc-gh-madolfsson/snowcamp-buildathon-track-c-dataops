# Track C — Data Engineering & Governance · "Trusted Commercial Foundation"

> **Snow Camp 2026 - Cortex Code Buildathon.** Everything runs inside Snowsight - **nothing to download.** Open each SQL file below, click the **copy icon** (top-right), paste into a Snowsight **SQL worksheet**, and **Run All**.

**Setup - run in order:**
1. [`setup/00_provision.sql`](setup/00_provision.sql)
2. [`setup/01_data.sql`](setup/01_data.sql)

**Gate tracker:** [open it live](https://htmlpreview.github.io/?https://raw.githubusercontent.com/sfc-gh-madolfsson/snowcamp-buildathon-track-c-dataops/main/tracker.html) - or [view the file](tracker.html) &nbsp;|&nbsp; **Primer:** [how to prompt Cortex Code](shared/prompting-primer.md) &nbsp;|&nbsp; **AGENTS.md (optional):** [shared/AGENTS.starter.md](shared/AGENTS.starter.md)

---

**Time:** ~60 minutes · **Database:** `SNOWCAMP_DATAOPS` · **Warehouse:** `SNOWCAMP_DATAOPS_WH` · **Pool:** `SNOWCAMP_DATAOPS_POOL`

> Build-your-own challenge. Gates say **what** to achieve and hint at **skills**; you decide **how** to prompt Cortex Code. Read [shared/prompting-primer.md](shared/prompting-primer.md) first.

## The objective
Two source systems disagree about the same Novo Nordisk HCPs, the facts are millions of rows deep and full of defects, and there's PII everywhere. Turn this mess into a **governed, monitored, analytics-ready commercial mart**: reconcile + dedupe a golden HCP master, classify + mask the PII, monitor quality with DMFs, and keep a curated mart fresh with a dynamic-table pipeline — then **surface a data-quality/mart dashboard as a Streamlit app on SPCS**.

**Definition of done:** a golden `ANALYTICS` HCP master (deduped, standardized), PII masked and classified, DMFs reporting the defect counts, a dynamic-table pipeline feeding a curated mart, and a Streamlit app on the container runtime showing the quality/mart state.

## Your data (`SNOWCAMP_DATAOPS.RAW`)
| Table | Rows | The mess |
|---|---|---|
| `HCP_MASTER_CRM` | ~80k | CRM source. PII (name/email/phone). ~3% null names, **15k duplicate IDs**, country/tier spelling drift. Key like `HCP_000123` |
| `HCP_MASTER_ERP` | ~50k | ERP source, **same HCPs, different formats**: key `HCP-000123` (dash), ISO country codes, `Tier N`, `LASTNAME, FIRSTNAME` |
| `PRESCRIPTIONS` | ~6M | null/orphan HCP, ~1% negatives, product case drift, **100k duplicate rows** |
| `PATIENTS` | 500k | **PII**: names, national IDs. ~3% impossible ages, gender encoding drift |
| `MEDICATION_ADHERENCE` | ~2M | ~4% adherence > 100%, ~3% orphan patients |
| `TERRITORY_PERFORMANCE` | 300 | ~5% market penetration > 1 |

## Setup (once)
Run [setup/00_provision.sql](setup/00_provision.sql) then [setup/01_data.sql](setup/01_data.sql) — open each file, copy, paste into a Snowsight SQL worksheet, and Run All.

> **Tip (optional):** you can set conventions once in an `AGENTS.md` at your Workspace root (start from [shared/AGENTS.starter.md](shared/AGENTS.starter.md)) so Cortex Code always uses your database/warehouse, fully-qualifies objects, and protects PII. Not required — skip it and just tell Cortex Code your rules as you go.

---

## Gates

### G1 · Profile at scale
**Achieve:** you start in **ACCOUNTADMIN** by default — no role switch needed. Quantify the problems across the big raw tables (dupes, nulls, orphans, spelling variants, out-of-range values).
**Validate:** you can state, with numbers, the top defects in each table and how the two HCP sources differ.
**Skills:** `/sql-author` `/snowflake-diagnostics`

### G2 · Standardize & dedupe (golden HCP master)
**Achieve:** a clean `ANALYTICS` HCP master that reconciles CRM + ERP (normalize the key `HCP_000123` vs `HCP-000123`, unify country and tier encodings) and dedupes with a survivorship rule (e.g., most recent, non-null wins).
**Validate:** one row per HCP; country and tier each collapse to a small standard set; row count is sensible vs the raw dupes.
**Skills:** `/snowpark-python` `/sql-author`

### G3 · Govern PII
**Achieve:** classify + tag the PII (HCP name/email/phone; patient name/national ID), apply a masking policy so only your admin role sees raw values. Optionally add a row-access policy (e.g., by region).
**Validate:** the PII columns return masked values for a role without access and real values for you.
**Skills:** `/data-governance`

### G4 · Monitor quality (DMFs)
**Achieve:** attach Data Metric Functions for the planted defects (null/duplicate HCP_ID, negative quantities, adherence out of 0-100, orphan patients) and run them; optionally schedule them.
**Validate:** the DMFs return non-zero counts that match the defects you profiled in G1.
**Skills:** `/data-quality`

### G5 · Build the pipeline (+ lineage)
**Achieve:** a dynamic-table pipeline from RAW to a curated commercial mart (e.g., prescriptions joined to the golden HCP master + territory) with a target lag, so it stays fresh as RAW changes. Verify where the mart comes from.
**Validate:** the dynamic table(s) exist and refresh; lineage shows the mart deriving from RAW + the golden master.
**Skills:** `/dynamic-tables` `/snowflake-tasks` `/lineage`

### GF · Ship it — Streamlit on SPCS
**Achieve:** a Streamlit-in-Snowflake app on the **container runtime** — your choice: a **results view** (data-quality scorecard + mart freshness/row counts) or a **full app** (a stewardship console with drill-downs into defects). Deploy per [shared/streamlit-spcs-deploy.md](shared/streamlit-spcs-deploy.md).
**Validate:** the app is live on the container runtime and renders the quality/mart state.
**Skills:** `/developing-with-streamlit-in-snowflake` `/cortex-chart-customization`

---

## Stretch (fast finishers)
- Add an alert (or DMF-driven task) that flags when a defect count crosses a threshold.
- Certify the curated mart (tag it) and add a description so it's discoverable.

## Bonus — capture it as a reusable skill
Finished early? Take the whole workflow you just built — profile → reconcile + dedupe → govern PII → DMFs → dynamic-table pipeline → Streamlit — and ask Cortex Code to turn it into a **custom skill**, so you can re-run this data-foundation build on a new source with one command. Try: *"Create a skill that encodes the steps we just did, then invoke it on a fresh RAW schema and show me the plan."*
**Skills:** `/skill-development` `/skill-architect`
