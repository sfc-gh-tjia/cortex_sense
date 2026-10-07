# Cortex Sense Demo

Baseline Agent (Semantic View only) vs Cortex Sense Agent — side-by-side comparison on SAP supply chain data.

**Result: Sense 10/10 vs Baseline 2/10 (5x gap)**

## Quick Start

### 1. Set up Snowflake objects

Run SQL scripts in order. Use **SnowSQL** (required for PUT commands) or Snowsight worksheets (for SQL statements).

```bash
# cd into the Demo directory first — all paths are relative to here
cd Demo
```

```sql
-- 00. Create database, schemas, warehouses, stages
-- Run: sql/00_create_schemas.sql

-- 01. Create and seed SAP tables (18 tables)
-- Run: sql/01_create_sap_tables.sql

-- 02. Create and seed RAW_SOURCES tables (18 tables)
-- Run: sql/02_create_raw_sources.sql

-- 03. Seed query history (25 analyst queries)
-- Run: sql/03_seed_query_history.sql

-- 04. Create the Semantic View
-- Run: sql/04_create_semantic_view.sql
```

### 2. Deploy Streamlit dashboard and upload knowledge doc

These steps require **SnowSQL** (PUT does not work in Snowsight worksheets):

```bash
# From the Demo/ directory:
snowsql -c <your_connection> -q "PUT file://streamlit/supply_chain_dashboard.py @DB_ONTOLOGY_CONTROL_PLANE.SAP_PRODUCTION.STREAMLIT_STAGE AUTO_COMPRESS=FALSE OVERWRITE=TRUE"
snowsql -c <your_connection> -q "PUT file://stage_files/sap_supply_chain_knowledge.md @DB_ONTOLOGY_CONTROL_PLANE.SAP_PRODUCTION.SENSE_SOURCES AUTO_COMPRESS=FALSE OVERWRITE=TRUE"
```

Then run in Snowsight:
```sql
-- 05. Create the Streamlit app
-- Run: sql/05_deploy_streamlit.sql

-- 06. Verify stage file upload
-- Run: sql/06_upload_stage_file.sql
```

### 3. Build Cortex Sense context

Follow the instructions in [cortex_sense_setup.md](cortex_sense_setup.md) using CoCo Desktop's `$cortex-sense` skill.

### 4. Create agents

```sql
-- 07. Create both agents (baseline + sense)
-- Run: sql/07_create_agents.sql
```

### 5. Verify

```sql
-- 08. Test both agents
-- Run: sql/08_test_queries.sql
```

### 6. Run the web app

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
connection_name="tjia_demo_aws2"  # Change to your connection name
```

## Prerequisites

- Snowflake account with **Cortex Sense** enabled (Private Preview)
- **ACCOUNTADMIN** role (or equivalent grants)
- **CoCo Desktop** for Cortex Sense context building
- **SnowSQL** for PUT commands (stage file and Streamlit upload)
- Node.js 18+ and Python 3.10+
- Snowflake connection configured in `~/.snowflake/connections.toml`:

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
├── cortex_sense_setup.md             # CoCo prompt for building the context
├── DEMO_SCRIPT.md                    # 15-minute demo walkthrough
├── setup_reference.md                # Complete DDL + config reference
├── docs/                             # Business knowledge documents
├── stage_files/                      # Knowledge doc uploaded to @SENSE_SOURCES
├── streamlit/                        # Dashboard source code
├── eval/                             # Eval definitions and results
└── web/                              # React + Flask comparison app
    ├── api_server.py                 # Flask backend (port 5001)
    ├── requirements.txt              # Python dependencies
    ├── package.json                  # Node.js dependencies
    └── app/components/lib/           # Next.js frontend (port 3000)
```

## What This Demo Shows

| Category | Questions | Baseline | Sense |
|----------|-----------|----------|-------|
| **Tie** | Active supplier count, OTD rate | 2/2 | 2/2 |
| **External Table Routing** | Ariba spend, D&B risk, Scorecards | 0/3 | 3/3 |
| **Business Knowledge** | COGS formula, Three-Strike Rule, SAP codes | 0/3 | 3/3 |
| **Cross-Domain Synthesis** | Spend+risk join, full supplier profile | 0/2 | 2/2 |
| **Total** | | **2/10** | **10/10** |

See [DEMO_SCRIPT.md](DEMO_SCRIPT.md) for the full walkthrough.
