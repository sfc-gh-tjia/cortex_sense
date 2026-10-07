# Cortex Sense Demo

Baseline Agent (Semantic View only) vs Cortex Sense Agent — side-by-side comparison on SAP supply chain data.

**Result: Sense 10/10 vs Baseline 2/10 (5x gap)**

| Category | Questions | Baseline | Sense |
|----------|-----------|----------|-------|
| **Tie** | Active supplier count, OTD rate | 2/2 | 2/2 |
| **External Table Routing** | Ariba spend, D&B risk, Scorecards | 0/3 | 3/3 |
| **Business Knowledge** | COGS formula, Three-Strike Rule, SAP codes | 0/3 | 3/3 |
| **Cross-Domain Synthesis** | Spend+risk join, full supplier profile | 0/2 | 2/2 |
| **Total** | | **2/10** | **10/10** |

## Prerequisites

- Snowflake account with **Cortex Sense** enabled (Private Preview)
- **ACCOUNTADMIN** role (or equivalent grants)
- **CoCo Desktop** for Cortex Sense context building
- **SnowSQL** for PUT commands (stage file and Streamlit upload)
- Node.js 18+ and Python 3.10+
- Snowflake connection in `~/.snowflake/connections.toml`:

```toml
[my_connection]
account = "your-account"
user = "your-user"
authenticator = "externalbrowser"
database = "DB_ONTOLOGY_CONTROL_PLANE"
schema = "SAP_PRODUCTION"
warehouse = "ONTOLOGY_WH"
role = "ACCOUNTADMIN"
```

---

## Setup (Step by Step)

All paths are relative to `Demo/`. Run `cd Demo` first.

### Step 1: Create Snowflake objects (SQL)

Run these scripts in Snowsight or SnowSQL:

```
sql/00_create_schemas.sql         -- Database, schemas, warehouses, stages
sql/01_create_sap_tables.sql      -- 18 SAP_PRODUCTION tables + data
sql/02_create_raw_sources.sql     -- 18 RAW_SOURCES tables + data
sql/03_seed_query_history.sql     -- 25 analyst queries for Sense to learn from
sql/04_create_semantic_view.sql   -- Semantic View (14 tables, 12 relationships)
```

### Step 2: Deploy Streamlit + upload knowledge doc (SnowSQL)

PUT commands require **SnowSQL** (they don't work in Snowsight worksheets):

```bash
snowsql -c <your_connection> -q "PUT file://streamlit/supply_chain_dashboard.py @DB_ONTOLOGY_CONTROL_PLANE.SAP_PRODUCTION.STREAMLIT_STAGE AUTO_COMPRESS=FALSE OVERWRITE=TRUE"
snowsql -c <your_connection> -q "PUT file://stage_files/sap_supply_chain_knowledge.md @DB_ONTOLOGY_CONTROL_PLANE.SAP_PRODUCTION.SENSE_SOURCES AUTO_COMPRESS=FALSE OVERWRITE=TRUE"
```

Then run in Snowsight:
```
sql/05_deploy_streamlit.sql       -- CREATE STREAMLIT
sql/06_upload_stage_file.sql      -- Verify stage upload
```

### Step 3: Build Cortex Sense context (CoCo Desktop)

Open CoCo Desktop and paste:

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

CoCo will generate a manifest. Review it and approve. Build takes 2-5 minutes. Check status:

```
$cortex-sense check build status for SAP_SUPPLY_CHAIN
```

### Step 4: Create agents

```
sql/07_create_agents.sql          -- Baseline + Sense agents
```

### Step 5: Record feedback corrections (recommended)

In CoCo, record each correction separately with `$cortex-sense feedback for SAP_SUPPLY_CHAIN`:

1. For annual supplier spend questions, use `ARIBA_SUPPLIERS.ANNUAL_SPEND_USD`, not SAP BSEG or EKPO
2. For supplier risk score questions, use `DNB_RISK_ASSESSMENTS`. High-risk = `OVERALL_RISK_SCORE >= 5`. Join by SUPPLIER_NAME
3. For scorecard/health index questions, use `SUPPLIER_SCORECARDS`. Join to LFA1 via LIFNR
4. COGS = `SUM(DMBTR WHERE BSCHL='31') - SUM(DMBTR WHERE BSCHL='34')`. Do NOT use naive SUM or COEP
5. Three-Strike Rule: 3 consecutive quarterly scores below C = automatic probation (KTOKK to ZPRB). Existing POs only, prepay/Net15. Recovery: 2 consecutive B+ to return to ZSTD
6. KTOKK codes: ZSTR = Strategic (Net 60), ZSTD = Standard (Net 30), ZPRB = Probationary (Prepay/Net 15). Only ZSTR + ZSTD = active suppliers

Approve each when prompted by CoCo.

### Step 6: Verify

```
sql/08_test_queries.sql           -- Tests both agents
```

### Step 7: Run the web app

```bash
# Terminal 1: Flask API (port 5001)
cd Demo/web
pip install -r requirements.txt
python api_server.py

# Terminal 2: Next.js UI (port 3000)
cd Demo/web
npm install
npm run dev -- -p 3000

# Open http://localhost:3000
```

**Important**: Update the connection name in `web/api_server.py` line 40:
```python
connection_name="my_connection"  # Update to match your connections.toml
```

Also update the Streamlit URL in `web/components/context/ContextView.tsx` line 5 — replace `<org>/<account>` with your Snowsight org/account path.

---

## Repo Structure

```
Demo/
├── sql/                              # Numbered SQL scripts (run 00-08 in order)
│   ├── 00_create_schemas.sql         # Database, schemas, warehouses, stages
│   ├── 01_create_sap_tables.sql      # 18 SAP_PRODUCTION tables + data
│   ├── 02_create_raw_sources.sql     # 18 RAW_SOURCES tables + data
│   ├── 03_seed_query_history.sql     # 25 analyst queries for history
│   ├── 04_create_semantic_view.sql   # SV with 14 tables, 12 relationships
│   ├── 05_deploy_streamlit.sql       # Dashboard deployment
│   ├── 06_upload_stage_file.sql      # Knowledge doc to stage
│   ├── 07_create_agents.sql          # Baseline + Sense agents
│   └── 08_test_queries.sql           # Validation
├── stage_files/                      # Knowledge doc uploaded to @SENSE_SOURCES
├── streamlit/                        # Dashboard source code
├── eval/                             # Eval definitions and results
└── web/                              # React + Flask comparison app
    ├── api_server.py                 # Flask backend (port 5001)
    ├── requirements.txt              # Python dependencies
    ├── package.json                  # Node.js dependencies
    └── app/components/lib/           # Next.js frontend (port 3000)
```
