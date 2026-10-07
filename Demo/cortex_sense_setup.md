# Cortex Sense Setup via CoCo

## Prerequisites
- Cortex Sense enabled on your account (Private Preview)
- CoCo Desktop connected to the account
- All SQL scripts (00-07) already executed

## Step 1: Open CoCo and invoke the skill

Paste this into CoCo:

```
$cortex-sense setup a new context called SAP_SUPPLY_CHAIN in DB_ONTOLOGY_CONTROL_PLANE.SAP_PRODUCTION

Scope:
- catalog_objects: include DB_ONTOLOGY_CONTROL_PLANE.RAW_SOURCES.* and DB_ONTOLOGY_CONTROL_PLANE.SAP_PRODUCTION.*
- semantic_views: include DB_ONTOLOGY_CONTROL_PLANE.SAP_PRODUCTION.SAP_BASELINE_SV
- streamlit_apps: include DB_ONTOLOGY_CONTROL_PLANE.SAP_PRODUCTION.SUPPLY_CHAIN_DASHBOARD
- stage_files: include @DB_ONTOLOGY_CONTROL_PLANE.SAP_PRODUCTION.SENSE_SOURCES/sap_supply_chain_knowledge.md
- query_history: enabled
- business_ontology: include Supply Chain and SAP Purchasing domains

Exclude patterns:
- DB_ONTOLOGY_CONTROL_PLANE.SUPPLY_CHAIN.*
- DB_ONTOLOGY_CONTROL_PLANE.CURATED.*
- SUPPLY_CHAIN.ONTOLOGY.SC_BASE (semantic view)

Warehouse: COMPUTE_WH
```

## Step 2: Review the manifest

CoCo will show you a manifest (scope.yaml). Verify it includes:
- 6 source types: catalog_objects, semantic_views, streamlit_apps, stage_files, query_history, business_ontology
- Correct include/exclude patterns
- Warehouse set to COMPUTE_WH

Approve the manifest when prompted.

## Step 3: Wait for the build

CoCo will queue the build. You can check status:

```
$cortex-sense check build status for SAP_SUPPLY_CHAIN
```

Build typically takes 2-5 minutes. When complete you'll see:
- `last_processed` timestamp updated
- All sources showing as indexed

## Step 4: Create the Sense agent

After the build completes:

```
$cortex-sense create an agent for SAP_SUPPLY_CHAIN
```

Or run `sql/08_create_agents.sql` manually for both agents.

## Step 5: Record feedback corrections (optional but recommended)

These corrections improve accuracy on specific question types:

```
$cortex-sense feedback for SAP_SUPPLY_CHAIN:
- For annual supplier spend questions, use ARIBA_SUPPLIERS.ANNUAL_SPEND_USD, not SAP BSEG or EKPO
- For supplier risk score questions, use DNB_RISK_ASSESSMENTS. High-risk = OVERALL_RISK_SCORE >= 5. Join by SUPPLIER_NAME
- For scorecard/health index questions, use SUPPLIER_SCORECARDS. Join to LFA1 via LIFNR
- COGS = SUM(DMBTR WHERE BSCHL='31') - SUM(DMBTR WHERE BSCHL='34'). Do NOT use naive SUM or COEP
- Three-Strike Rule: 3 consecutive quarterly scores below C = automatic probation (KTOKK to ZPRB). Existing POs only, prepay/Net15. Recovery: 2 consecutive B+ to return to ZSTD
- KTOKK codes: ZSTR = Strategic (Net 60), ZSTD = Standard (Net 30), ZPRB = Probationary (Prepay/Net 15). Only ZSTR + ZSTD = active suppliers
```

Record each as a separate feedback item. Approve them when prompted.

## Step 6: Verify

Run `sql/09_test_queries.sql` to confirm both agents respond correctly.
