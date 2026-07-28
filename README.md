# Track C — Data Engineering & Governance · "Trusted Commercial Foundation"

> **Snow Camp 2026 - Cortex Code Buildathon.** Everything runs inside Snowsight - **nothing to download.** Open each SQL file below, click the **copy icon** (top-right), paste into a Snowsight **SQL worksheet**, and **Run All**.

**Setup - run in order:**
1. [`setup/00_provision.sql`](setup/00_provision.sql)
2. [`setup/01_data.sql`](setup/01_data.sql)

**Gate tracker:** [open it live](https://htmlpreview.github.io/?https://raw.githubusercontent.com/sfc-gh-madolfsson/snowcamp-buildathon-track-c-dataops/main/tracker.html) - or [view the file](tracker.html) &nbsp;|&nbsp; **Primer:** [how to prompt Cortex Code](shared/prompting-primer.md) &nbsp;|&nbsp; **Skills:** [skills map](shared/skills-map.md)

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

---

## Gates

### G1 · Find out how bad it is  ·  *8 min*
**Your task:** Two systems have been describing the same prescribers for years and nobody trusts either one. Before fixing anything, quantify the damage. Profile the big raw tables and put real numbers on it — how many duplicates, nulls, orphaned records and impossible values, and how many different ways is the same country spelled? Then compare the two HCP sources and work out exactly how they disagree. That answer shapes everything you build next.

**Hints:**
- Point Cortex Code at @SNOWCAMP_DATAOPS.RAW and ask for counts per defect, not just examples.
- Look closely at the two HCP keys — CRM and ERP don't format them the same way.
- These are millions of rows: aggregate in SQL rather than pulling data down.

**Check yourself:** State, with numbers, the top defects in each table and exactly how the CRM and ERP sources disagree.

**Gate:** You can quantify the mess and describe how the two sources differ.

**Skills that help:** `/sql-author` `/data-quality`

### G2 · Build one version of the truth  ·  *14 min*
**Your task:** Downstream teams need a single trustworthy HCP master. Reconcile the two sources into one: normalise the keys so they can be joined at all, unify the country and tier encodings down to a small standard set, and collapse the duplicates using a survivorship rule you can explain — most recent wins? non-null wins? one source is the record? Land the result in ANALYTICS as your golden master.

**Hints:**
- CRM uses HCP_000123, ERP uses HCP-000123 — normalise before you join.
- Choose your survivorship rule deliberately and be able to justify it. That decision is the whole game.
- Twelve spellings of a handful of countries should end up as a handful of values.

**Check yourself:** Show one row per HCP, and that country and tier each collapse to a small standard set.

**Gate:** A deduplicated, standardised golden HCP master exists in ANALYTICS.

**Skills that help:** `/snowpark-python` `/sql-author`

### G3 · Protect the people in the data  ·  *9 min*
**Your task:** There's real personal data in here — prescriber names, emails and phone numbers, plus patient names and national IDs. Find it, classify it, and mask it so only you can see raw values. Then prove the mask holds by looking at the data as someone who shouldn't see it. Feeling ambitious? Restrict rows by region too.

**Hints:**
- Ask it to find the sensitive columns first, then describe the outcome you want and let it write the policy.
- A masking policy you haven't tested is a masking policy you don't have.

**Check yourself:** Read the PII columns as a role without access, then as yourself, and compare.

**Gate:** PII is classified, masked, and you proved the mask works.

**Skills that help:** `/data-governance`

### G4 · Make the quality visible  ·  *9 min*
**Your task:** You know what's broken — now make Snowflake watch it for you. Attach data metric functions for the specific defects you found in Gate 1 (null and duplicate keys, negative quantities, adherence outside 0-100, orphaned patients) and run them, so those numbers become monitored metrics instead of a query you ran once and forgot.

**Hints:**
- One check per defect you actually found — the counts should line up with your Gate 1 profiling.
- If you have time, schedule them so they keep reporting.

**Check yourself:** Run your DMFs and show they return counts matching what you profiled.

**Gate:** Quality is monitored by DMFs returning real defect counts.

**Skills that help:** `/data-quality`

### G5 · Keep it fresh without babysitting  ·  *12 min*
**Your task:** A clean table that goes stale is just a slower version of the problem. Build a pipeline that keeps a curated commercial mart current on its own — prescriptions joined to your golden master and territory data, refreshing on a target lag with dynamic tables. Then confirm you can trace exactly where the mart's data came from.

**Hints:**
- Set a target lag and confirm it actually refreshes — don't just create it and assume.
- Ask where the mart comes from; lineage should show RAW plus your golden master.
- This is the difference between a clean-up and a data product.

**Check yourself:** Show your dynamic table(s) refreshing, and the mart's lineage back to its sources.

**Gate:** A fresh curated mart with a working pipeline and verified lineage.

**Skills that help:** `/dynamic-tables` `/lineage` `/snowflake-tasks`

### GF · Show that it's trustworthy  ·  *8 min*
**Your task:** Trust is easier to believe when you can see it. Ship a Streamlit app on the container runtime (SPCS): either a focused results view — a data quality scorecard with your defect counts plus the mart's freshness and row counts — or a fuller stewardship console where someone can drill into the problem records. Deploy it and open the URL.

**Hints:**
- Container runtime: RUNTIME_NAME='SYSTEM$ST_CONTAINER_RUNTIME_PY3_11', COMPUTE_POOL=SNOWCAMP_DATAOPS_POOL, QUERY_WAREHOUSE=SNOWCAMP_DATAOPS_WH.
- Picture a data steward opening this on Monday — what should they see first?
- First launch may lag while the compute pool starts.

**Check yourself:** Open the app and confirm the quality/mart view renders.

**Gate:** App is live on the container runtime showing the quality and mart state.

**Skills that help:** `/developing-with-streamlit-in-snowflake`

---

## Stretch (fast finishers)
- Add an alert (or DMF-driven task) that flags when a defect count crosses a threshold.
- Certify the curated mart (tag it) and add a description so it's discoverable.

## Bonus — capture it as a reusable skill
Finished early? Take the whole workflow you just built — profile → reconcile + dedupe → govern PII → DMFs → dynamic-table pipeline → Streamlit — and ask Cortex Code to turn it into a **custom skill**, so you can re-run this data-foundation build on a new source with one command. Try: *"Create a skill that encodes the steps we just did, then invoke it on a fresh RAW schema and show me the plan."*
**Skills:** `/skill-development` `/skill-architect`
