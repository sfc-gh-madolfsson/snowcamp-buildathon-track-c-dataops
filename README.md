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

**Your task:** Two systems have been describing the same prescribers for years and nobody trusts either one. Before fixing anything, quantify the damage — and work out exactly how the two sources disagree. That answer shapes everything you build next.

**Deliverable — what "done" looks like:**
- Defect counts per table: duplicates, nulls, orphans, out-of-range values.
- The number of distinct spellings for country, and the tier encodings in use.
- A written statement of how CRM and ERP disagree — keys, name format, country, tier.

**How to approach it** *(your prompts, your call)*:
1. Give Cortex Code `@SNOWCAMP_DATAOPS.RAW` and ask for a table inventory with row counts.
2. Ask for a count per defect type, per table — not just examples.
3. Put the two HCP sources side by side and sample a few rows of each.
4. Work out what it would take to join them at all.

> **Watch out:** Aggregate in SQL — these are millions of rows. And look very closely at the two key formats.

**Check yourself:** State, with numbers, the top defects in each table and exactly how the CRM and ERP sources disagree.

**Gate:** You can quantify the mess and describe how the two sources differ.

**Skills that help:** `/sql-author` `/data-quality`

### G2 · Build one version of the truth  ·  *14 min*

**Your task:** Downstream teams need a single trustworthy HCP master. Reconcile the two sources into one: make the keys joinable, unify the encodings, and collapse the duplicates using a rule you can defend. Land the result in ANALYTICS as your golden master.

**Deliverable — what "done" looks like:**
- A golden HCP master in `ANALYTICS` with exactly one row per HCP.
- A normalised join key that works across both sources.
- Country and tier each collapsed to a small standard set.
- A survivorship rule you can state in one sentence.

**How to approach it** *(your prompts, your call)*:
1. Normalise the keys on both sides so they can be joined.
2. Standardise country and tier into single canonical values.
3. Choose a survivorship rule — most recent wins, non-null wins, one source is the record — and apply it.
4. Verify one row per HCP, and that your standard sets are actually small.

> **Watch out:** CRM uses HCP_000123, ERP uses HCP-000123. Decide which source wins on conflicting attributes before you build, not after.

**Check yourself:** Show one row per HCP, and that country and tier each collapse to a small standard set.

**Gate:** A deduplicated, standardised golden HCP master exists in ANALYTICS.

**Skills that help:** `/snowpark-python` `/sql-author`

### G3 · Protect the people in the data  ·  *9 min*

**Your task:** There's real personal data in here — prescriber names, emails and phone numbers, plus patient names and national IDs. Find it, classify it, mask it, and then prove the mask holds by looking at the data as someone who shouldn't see it.

**Deliverable — what "done" looks like:**
- PII classified or tagged across the HCP and PATIENTS tables.
- Masking policies applied to names, emails, phone numbers and national IDs.
- Proof the mask works, tested from an unprivileged role.
- Optional: a row-access policy restricting rows by region.

**How to approach it** *(your prompts, your call)*:
1. Ask Cortex Code to find and classify the sensitive columns in both tables.
2. Describe the masking outcome you want and let it write and apply the policies.
3. Test as a role without access, then as yourself, and compare.

> **Watch out:** As ACCOUNTADMIN you always see raw values — test as another role or you've proven nothing.

**Check yourself:** Read the PII columns as a role without access, then as yourself, and compare.

**Gate:** PII is classified, masked, and you proved the mask works.

**Skills that help:** `/data-governance`

### G4 · Make the quality visible  ·  *9 min*

**Your task:** You know what's broken — now make Snowflake watch it for you, so those numbers become monitored metrics instead of a query you ran once and forgot.

**Deliverable — what "done" looks like:**
- Data metric functions attached to the relevant RAW tables — one per defect you found.
- Results showing counts that line up with your Gate 1 profiling.
- Optional: a schedule so they keep reporting.

**How to approach it** *(your prompts, your call)*:
1. List the defects from Gate 1 and choose a metric for each.
2. Attach the DMFs to the right tables and columns.
3. Run them and compare the results against your Gate 1 numbers.

> **Watch out:** If a DMF disagrees with your Gate 1 profiling, one of the two is measuring the wrong thing — find out which.

**Check yourself:** Run your DMFs and show they return counts matching what you profiled.

**Gate:** Quality is monitored by DMFs returning real defect counts.

**Skills that help:** `/data-quality`

### G5 · Keep it fresh without babysitting  ·  *12 min*

**Your task:** A clean table that goes stale is just a slower version of the problem. Build a pipeline that keeps a curated commercial mart current on its own, then confirm you can trace exactly where its data came from.

**Deliverable — what "done" looks like:**
- One or more dynamic tables producing a curated commercial mart.
- A target lag set, and evidence of an actual refresh.
- Lineage showing the mart deriving from RAW plus your golden master.

**How to approach it** *(your prompts, your call)*:
1. Define the mart you want — prescriptions joined to your golden master and territory data.
2. Build it as a dynamic table with a target lag.
3. Confirm it actually refreshes rather than assuming it will.
4. Trace the lineage back to its sources.

> **Watch out:** Feed the pipeline your cleaned and golden objects. A pipeline built over raw mess just automates the mess.

**Check yourself:** Show your dynamic table(s) refreshing, and the mart's lineage back to its sources.

**Gate:** A fresh curated mart with a working pipeline and verified lineage.

**Skills that help:** `/dynamic-tables` `/lineage` `/snowflake-tasks`

### GF · Show that it's trustworthy  ·  *8 min*

**Your task:** Trust is easier to believe when you can see it. Ship a Streamlit app on the container runtime (SPCS) that makes the state of your data obvious at a glance.

**Deliverable — what "done" looks like:**
- A Streamlit app on the container runtime with a working URL.
- A quality scorecard — defect counts plus the mart's freshness and row counts — or a fuller stewardship console with drill-downs.

**How to approach it** *(your prompts, your call)*:
1. Decide what a data steward would need to see first.
2. Describe it and let Cortex Code build the app over your DMF results and curated mart.
3. Deploy on the container runtime, open the URL, then improve one thing.

> **Watch out:** Deploy with RUNTIME_NAME='SYSTEM$ST_CONTAINER_RUNTIME_PY3_11', COMPUTE_POOL=SNOWCAMP_DATAOPS_POOL, QUERY_WAREHOUSE=SNOWCAMP_DATAOPS_WH.

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
