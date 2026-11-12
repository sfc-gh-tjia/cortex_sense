# Cortex Sense Demo

## What This Demo Shows

Side-by-side comparison of a **plain Semantic View agent** vs a **Cortex Sense agent** using the same SAP supply chain data. The Cortex Sense agent discovers and grounds answers across sources the SV alone cannot access:

| Source | How it reaches Cortex Sense | Example |
|--------|---------------------------|---------|
| Semantic View | `semantic_views` source (auto-discovered) | "Total procurement spend?" |
| Catalog Objects | `catalog_objects` source (schema metadata for all tables) | "Geopolitical risk for Chinese suppliers?" (DNB_RISK_ASSESSMENTS) |
| Query History | `query_history` source (account-wide, 30 days) | Auto-applies ZPRB exclusion filter |
| Stage File (Business Knowledge) | `stage_files` source — `sap_supply_chain_knowledge.md` | Metric formulas, SAP field codes, procurement policies, entity definitions |

The stage file is an export of Business Ontology terms + operational docs. This workaround is needed because the `business_ontology` source is not yet indexed by the Cortex Sense build.

## Prerequisites

- Snowflake account with Cortex Sense private preview enabled
- `CORTEX_SENSE_BUILDER` and `CORTEX_SENSE_USER` database roles granted to ACCOUNTADMIN
- Cortex Code (CoCo) for the `$cortex-sense` setup flow
- Existing data: `DB_ONTOLOGY_CONTROL_PLANE.SAP_PRODUCTION` with SAP tables and `SAP_BASELINE_SV` semantic view

## Setup (run in order)

```bash
# Step 1: Create long-tail tables (new data not in the SV)
sql/01_create_long_tail_tables.sql

# Step 2: Seed query history (run these queries so Cortex Sense learns patterns)
sql/02_seed_query_history.sql

# Step 3: Verify the stage file is uploaded
LIST @DB_ONTOLOGY_CONTROL_PLANE.SAP_PRODUCTION.SENSE_SOURCES;
# Should show: sap_supply_chain_knowledge.md (~10KB)
# If missing, re-upload:
#   PUT 'file:///.../demo/stage_files/sap_supply_chain_knowledge.md'
#       @DB_ONTOLOGY_CONTROL_PLANE.SAP_PRODUCTION.SENSE_SOURCES
#       AUTO_COMPRESS=FALSE OVERWRITE=TRUE;

# Step 4: Set up Cortex Sense context (in CoCo):
#   $cortex-sense set up Cortex Sense for SAP supply chain
#   → DB_ONTOLOGY_CONTROL_PLANE.SAP_PRODUCTION
#   → include DB_ONTOLOGY_CONTROL_PLANE.RAW_SOURCES.*
#   → include SUPPLIER_SCORECARDS, INCIDENT_LOG, DEMAND_FORECAST
#   → business docs at @DB_ONTOLOGY_CONTROL_PLANE.SAP_PRODUCTION.SENSE_SOURCES/sap_supply_chain_knowledge.md
#   → build

# Step 5: Wait for build to complete (check with: $cortex-sense resume SAP_SUPPLY_CHAIN → check build)

# Step 6: Grant access and create agents (via $cortex-sense skill or manually)
#   GRANT USAGE ON CORTEX SENSE DB_ONTOLOGY_CONTROL_PLANE.SAP_PRODUCTION."SAP_SUPPLY_CHAIN" TO ROLE ACCOUNTADMIN;
#   $cortex-sense create an agent for SAP_SUPPLY_CHAIN
```

## Running the Demo

1. Follow `DEMO_SCRIPT.md` for the presentation narrative
2. Use `eval/questions.json` for the full 17-question eval across 6 tiers
3. Or run individual agent queries via SQL:
   ```sql
   SELECT SNOWFLAKE.CORTEX.DATA_AGENT_RUN(
     'DB_ONTOLOGY_CONTROL_PLANE.SAP_PRODUCTION.<AGENT_NAME>',
     $${"messages": [{"role": "user", "content": [{"type": "text", "text": "<question>"}]}]}$$
   );
   ```

## File Structure

```
demo/
├── README.md                 ← You are here
├── DEMO_SCRIPT.md            ← Presentation script
├── sql/
│   ├── 01_create_long_tail_tables.sql
│   ├── 02_seed_query_history.sql
│   ├── 03_create_knowledge_base.sql   ← SUPERSEDED by stage_files approach
│   ├── 04_setup_cortex_sense.sql      ← Reference only; use $cortex-sense skill
│   ├── 05_create_agents.sql           ← Reference only; agents created via skill
│   └── 06_test_queries.sql
├── docs/                     ← Source documents (exported to stage file)
│   ├── procurement_policy.md
│   ├── supplier_qualification.md
│   ├── warehouse_operations.md
│   ├── sap_field_guide.md
│   └── metric_definitions.md
├── stage_files/              ← Uploaded to @SENSE_SOURCES for Cortex Sense ingestion
│   └── sap_supply_chain_knowledge.md
├── streamlit/
│   └── supply_chain_dashboard.py
├── eval/
│   ├── questions.json
│   └── run_eval.py
└── app/
    └── app_comparison.py
```
