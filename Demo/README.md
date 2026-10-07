# Cortex Sense Demo

Baseline Agent (Semantic View only) vs Cortex Sense Agent — side-by-side comparison on SAP supply chain data.

**Result: Sense 10/10 vs Baseline 2/10 (5x gap)**

## Quick Start

### 1. Set up Snowflake objects

Run SQL scripts in order (use Snowsight or SnowSQL):

```sql
-- 1. Create database, schemas, warehouses, stages
@sql/00_create_schemas.sql

-- 2. Create and seed SAP tables (14 core + 4 long-tail)
@sql/01_create_sap_tables.sql

-- 3. Create and seed RAW_SOURCES tables (Ariba, D&B, etc.)
@sql/02_create_raw_sources.sql

-- 4. Seed query history (25 analyst queries)
@sql/04_seed_query_history.sql

-- 5. Create the Semantic View
@sql/05_create_semantic_view.sql

-- 6. Deploy Streamlit dashboard
-- First: PUT file://streamlit/supply_chain_dashboard.py @STREAMLIT_STAGE AUTO_COMPRESS=FALSE OVERWRITE=TRUE;
@sql/06_deploy_streamlit.sql

-- 7. Upload knowledge doc to stage
-- First: PUT file://stage_files/sap_supply_chain_knowledge.md @SENSE_SOURCES AUTO_COMPRESS=FALSE OVERWRITE=TRUE;
@sql/07_upload_stage_file.sql
```

### 2. Build Cortex Sense context

Follow the instructions in [cortex_sense_setup.md](cortex_sense_setup.md) using CoCo Desktop's `$cortex-sense` skill.

### 3. Create agents

```sql
@sql/08_create_agents.sql
```

### 4. Verify

```sql
@sql/09_test_queries.sql
```

### 5. Run the web app

```bash
# Terminal 1: Flask API
cd Demo/web
pip install -r requirements.txt
python api_server.py

# Terminal 2: Next.js UI
cd Demo/web
npm install
npm run dev -- -p 3000

# Open http://localhost:3000
```

## Prerequisites

- Snowflake account with **Cortex Sense** enabled (Private Preview)
- **ACCOUNTADMIN** role (or equivalent grants)
- **CoCo Desktop** for Cortex Sense context building
- Node.js 18+ and Python 3.10+
- Snowflake connection configured in `~/.snowflake/connections.toml`:

```toml
[tjia_demo_aws2]
account = "your-account"
user = "your-user"
authenticator = "externalbrowser"
database = "DB_ONTOLOGY_CONTROL_PLANE"
schema = "SAP_PRODUCTION"
warehouse = "ONTOLOGY_WH"
role = "ACCOUNTADMIN"
```

Update `connection_name` in `web/api_server.py` to match your connection name.

## Repo Structure

```
Demo/
├── sql/                          # Numbered SQL scripts (run in order)
│   ├── 00_create_schemas.sql     # Database, schemas, warehouses, stages
│   ├── 01_create_sap_tables.sql  # 18 SAP_PRODUCTION tables + data
│   ├── 02_create_raw_sources.sql # 18 RAW_SOURCES tables + data
│   ├── 04_seed_query_history.sql # 25 analyst queries for history
│   ├── 05_create_semantic_view.sql # SV with 14 tables, 12 relationships
│   ├── 06_deploy_streamlit.sql   # Dashboard deployment
│   ├── 07_upload_stage_file.sql  # Knowledge doc to stage
│   ├── 08_create_agents.sql      # Baseline + Sense agents
│   └── 09_test_queries.sql       # Validation
├── cortex_sense_setup.md         # CoCo prompt for building the context
├── DEMO_SCRIPT.md                # 15-minute demo walkthrough
├── setup_reference.md            # Complete DDL + config reference
├── docs/                         # Business knowledge documents
├── stage_files/                  # Knowledge doc uploaded to @SENSE_SOURCES
├── streamlit/                    # Dashboard source code
├── eval/                         # Eval definitions and results
└── web/                          # React + Flask comparison app
    ├── api_server.py             # Flask backend (port 5001)
    ├── requirements.txt          # Python dependencies
    ├── package.json              # Node.js dependencies
    └── app/components/lib/       # Next.js frontend (port 3000)
```

## What This Demo Shows

| Category | Questions | Baseline | Sense |
|----------|-----------|----------|-------|
| **Tie** | Active supplier count, OTD rate | 2/2 | 2/2 |
| **External Table Routing** | Ariba spend, D&B risk, Scorecards | 0/3 | 3/3 |
| **Business Knowledge** | COGS formula, Three-Strike Rule, SAP codes | 0/3 | 3/3 |
| **Cross-Domain Synthesis** | Spend+risk join, full supplier profile | 0/2 | 2/2 |
| **Total** | | **2/10** | **10/10** |

See [DEMO_SCRIPT.md](Demo/DEMO_SCRIPT.md) for the full walkthrough.
