# Cortex Sense Demo — Complete Setup Reference

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────┐
│                    SAP Supply Chain Data Estate                      │
│                                                                     │
│  DB_ONTOLOGY_CONTROL_PLANE.SAP_PRODUCTION (18 tables)               │
│    LFA1, MARA, EKPO, LIKP, T001W, T320, STPO, LFB1, QALS,        │
│    LFA2, BSEG, COEP, VBAP, KONV,                                   │
│    SUPPLIER_SCORECARDS, DEMAND_FORECAST, INCIDENT_LOG, QUAL_MATRIX  │
│                                                                     │
│  DB_ONTOLOGY_CONTROL_PLANE.RAW_SOURCES (multi-source)               │
│    ARIBA_SUPPLIERS, DNB_RISK_ASSESSMENTS, SAP_VENDORS,              │
│    SAP_MATERIALS, SAP_PURCHASE_ORDERS, SHIPMENTS, CARRIERS,         │
│    WAREHOUSES, PLANTS, CONTRACTS, INSPECTIONS, BILL_OF_MATERIALS    │
│                                                                     │
│  Business Ontology: Supply Chain (23 nodes), SAP Purchasing (15)    │
│  Knowledge Doc: sap_supply_chain_knowledge.md (8.5 KB)              │
└─────────────────────────────────────────────────────────────────────┘
          │                                    │
          ▼                                    ▼
┌─────────────────────┐          ┌────────────────────────────────────┐
│  BASELINE AGENT      │          │  SENSE AGENT                       │
│  (SV-only control)   │          │  (Cortex Sense + feedback)         │
│                      │          │                                    │
│  Tool: query_sap     │          │  Tool: cortex_sense                │
│    └→ SAP_BASELINE_SV│          │    └→ SAP_SUPPLY_CHAIN context     │
│       (14 tables)    │          │       (all tables + ontology +     │
│                      │          │        knowledge doc + 6 feedback  │
│  Tool: data_to_chart │          │        corrections)                │
│                      │          │  Tool: system_execute_sql          │
│  Score: 4/20         │          │  Tool: data_to_chart               │
└─────────────────────┘          │                                    │
                                  │  Score: 20/20                      │
                                  └────────────────────────────────────┘
```

---

## 1. Semantic View (shared by both agents)

```sql
-- 14 SAP tables, 12 relationships, 18 facts, 66 dimensions
-- This is the ONLY data source the baseline agent can access

CREATE OR REPLACE SEMANTIC VIEW DB_ONTOLOGY_CONTROL_PLANE.SAP_PRODUCTION.SAP_BASELINE_SV
  tables (
    DB_ONTOLOGY_CONTROL_PLANE.SAP_PRODUCTION.LFA1  primary key (LIFNR)       comment='Vendor master data',
    DB_ONTOLOGY_CONTROL_PLANE.SAP_PRODUCTION.MARA  primary key (MATNR)       comment='Material master data',
    DB_ONTOLOGY_CONTROL_PLANE.SAP_PRODUCTION.EKPO  primary key (EBELN,EBELP) comment='Purchasing document items',
    DB_ONTOLOGY_CONTROL_PLANE.SAP_PRODUCTION.LIKP  primary key (TKNUM)       comment='Shipment data',
    DB_ONTOLOGY_CONTROL_PLANE.SAP_PRODUCTION.T001W primary key (WERKS)       comment='Plant data',
    DB_ONTOLOGY_CONTROL_PLANE.SAP_PRODUCTION.T320  primary key (LGORT)       comment='Storage location data',
    DB_ONTOLOGY_CONTROL_PLANE.SAP_PRODUCTION.STPO  primary key (STLNR,IDNRK) comment='BOM items',
    DB_ONTOLOGY_CONTROL_PLANE.SAP_PRODUCTION.LFB1  primary key (LIFNR,VKONT) comment='Vendor contract data',
    DB_ONTOLOGY_CONTROL_PLANE.SAP_PRODUCTION.QALS  primary key (PRUEFLOS)    comment='Inspection lot data',
    DB_ONTOLOGY_CONTROL_PLANE.SAP_PRODUCTION.LFA2  primary key (TDLNR)       comment='Forwarding agent data',
    DB_ONTOLOGY_CONTROL_PLANE.SAP_PRODUCTION.BSEG  primary key (BELNR,BUZEI) comment='Accounting document line items',
    DB_ONTOLOGY_CONTROL_PLANE.SAP_PRODUCTION.COEP                            comment='Cost element line items',
    DB_ONTOLOGY_CONTROL_PLANE.SAP_PRODUCTION.VBAP  primary key (VBELN,POSNR) comment='Sales document items',
    DB_ONTOLOGY_CONTROL_PLANE.SAP_PRODUCTION.KONV                            comment='Pricing condition records'
  )
  relationships (
    EKPO_TO_LFA1   as EKPO(LIFNR)    references LFA1(LIFNR),
    EKPO_TO_MARA   as EKPO(MATNR)    references MARA(MATNR),
    EKPO_TO_T001W  as EKPO(WERKS)    references T001W(WERKS),
    LIKP_TO_LFA2   as LIKP(TDLNR)    references LFA2(TDLNR),
    LIKP_TO_T001W  as LIKP(WERKS_DST) references T001W(WERKS),
    LIKP_TO_T320   as LIKP(LGORT_SRC) references T320(LGORT),
    T320_TO_T001W  as T320(WERKS)    references T001W(WERKS),
    LFB1_TO_LFA1   as LFB1(LIFNR)    references LFA1(LIFNR),
    QALS_TO_MARA   as QALS(MATNR)    references MARA(MATNR),
    BSEG_TO_EKPO   as BSEG(EBELN)    references EKPO(EBELN),
    BSEG_TO_LFA1   as BSEG(LIFNR)    references LFA1(LIFNR),
    VBAP_TO_MARA   as VBAP(MATNR)    references MARA(MATNR)
  )
  facts (
    MARA.STPRS     as STPRS     comment='Standard price',
    EKPO.MENGE     as MENGE     comment='Purchase order quantity',
    EKPO.NETWR     as NETWR     comment='Net order value',
    LIKP.MENGE     as MENGE     comment='Delivery quantity',
    LIKP.FRTCO     as FRTCO     comment='Freight cost',
    T320.LKAPA     as LKAPA     comment='Storage location capacity',
    STPO.MENGE     as MENGE     comment='Component quantity',
    STPO.STUFE     as STUFE     comment='BOM level',
    LFB1.JWERT     as JWERT     comment='Annual contract value',
    QALS.QAESSION  as QAESSION  comment='Defect rate',
    LFA2.LZEIT     as LZEIT     comment='Transit time',
    LFA2.OTRAT     as OTRAT     comment='On-time delivery rate',
    BSEG.DMBTR     as DMBTR     comment='Amount in local currency',
    COEP.WRTBTR    as WRTBTR    comment='Value in reporting currency',
    VBAP.KWMENG    as KWMENG    comment='Order quantity',
    VBAP.NETWR     as NETWR     comment='Net value',
    KONV.KBETR     as KBETR     comment='Rate',
    KONV.KWERT     as KWERT     comment='Condition value'
  )
  dimensions (
    -- LFA1 (6)
    LFA1.LIFNR  as LIFNR  comment='Vendor number',
    LFA1.NAME1  as NAME1  comment='Vendor name',
    LFA1.ORT01  as ORT01  comment='City',
    LFA1.LAND1  as LAND1  comment='Country code',
    LFA1.KTOKK  as KTOKK  comment='Account group',
    LFA1.ZTERM  as ZTERM  comment='Payment terms key',
    -- MARA (3)
    MARA.MATNR  as MATNR  comment='Material number',
    MARA.MAKTX  as MAKTX  comment='Material description',
    MARA.MATKL  as MATKL  comment='Material group',
    -- EKPO (6)
    EKPO.EBELN  as EBELN  comment='Purchasing document number',
    EKPO.EBELP  as EBELP  comment='Item number',
    EKPO.LIFNR  as LIFNR  comment='Vendor number',
    EKPO.MATNR  as MATNR  comment='Material number',
    EKPO.WERKS  as WERKS  comment='Plant',
    EKPO.STATU  as STATU  comment='Status',
    EKPO.BEDAT  as BEDAT  comment='Purchasing document date',
    -- LIKP (7)
    LIKP.TKNUM     as TKNUM     comment='Shipment number',
    LIKP.TDLNR     as TDLNR     comment='Forwarding agent',
    LIKP.LGORT_SRC as LGORT_SRC comment='Source storage location',
    LIKP.WERKS_DST as WERKS_DST comment='Destination plant',
    LIKP.MATNR     as MATNR     comment='Material number',
    LIKP.STATU     as STATU     comment='Delivery status',
    LIKP.LFDAT     as LFDAT     comment='Delivery date',
    LIKP.WADAT     as WADAT     comment='Goods issue date',
    -- T001W (3), T320 (3), STPO (2), LFB1 (4), QALS (3), LFA2 (3)
    -- BSEG (9), COEP (5), VBAP (6), KONV (5) — omitted for brevity
    -- [full DDL has all 66 dimensions]
  )
  comment='SAP production data covering procurement, logistics, finance, and sales';
```

---

## 2. Baseline Agent (Control — SV Only)

```sql
CREATE OR REPLACE AGENT DB_ONTOLOGY_CONTROL_PLANE.SAP_PRODUCTION.BASELINE_SUPPLY_CHAIN_AGENT
  COMMENT = 'Baseline agent: Semantic View only. No Cortex Sense.'
  FROM SPECIFICATION $$
  models:
    orchestration: "auto"
  instructions:
    response: >
      You are a supply chain analytics agent. Answer questions using
      the SAP production data available through the semantic view.
      If you cannot find the data needed, say so clearly.
    orchestration: >
      Use the query_sap tool to answer all data questions.
  tools:
    - tool_spec:
        type: cortex_analyst_text_to_sql
        name: query_sap
        description: "Query SAP enterprise data."
    - tool_spec:
        type: data_to_chart
        name: data_to_chart
  tool_resources:
    query_sap:
      semantic_view: "DB_ONTOLOGY_CONTROL_PLANE.SAP_PRODUCTION.SAP_BASELINE_SV"
      execution_environment:
        type: warehouse
        warehouse: ONTOLOGY_WH
  $$;
```

**What baseline can access**: Only the 14 tables declared in `SAP_BASELINE_SV`. The `cortex_analyst_text_to_sql` tool generates SQL constrained to the semantic view's tables, relationships, facts, and dimensions.

**What baseline cannot access**: ARIBA_SUPPLIERS, DNB_RISK_ASSESSMENTS, SUPPLIER_SCORECARDS, business ontology definitions, knowledge documents, or any table not in the SV.

---

## 3. Cortex Sense Context

### Context metadata
| Property | Value |
|---|---|
| **Name** | `SAP_SUPPLY_CHAIN` |
| **Location** | `DB_ONTOLOGY_CONTROL_PLANE.SAP_PRODUCTION` |
| **Context ID** | 125059860 |
| **Target lag** | 1m0s |
| **Last processed** | 2026-10-06T20:19:56Z |
| **Status** | Built and active |

### Manifest (scope.yaml)

```yaml
name: SAP_SUPPLY_CHAIN
description: >-
  SAP supply chain procurement and logistics context covering vendor
  master data, purchase orders, shipments, contracts, quality inspections,
  BOM structures, financial postings, plus Ariba spend, D&B risk
  assessments, and supplier scorecards.
warehouse: COMPUTE_WH
sources:
  - name: catalog_objects
    type: snowflake_metadata
    enabled: true
    rules:
      - type: include
        pattern: DB_ONTOLOGY_CONTROL_PLANE.RAW_SOURCES.*
      - type: include
        pattern: DB_ONTOLOGY_CONTROL_PLANE.SAP_PRODUCTION.*
      - type: exclude
        pattern: DB_ONTOLOGY_CONTROL_PLANE.SUPPLY_CHAIN.*
      - type: exclude
        pattern: DB_ONTOLOGY_CONTROL_PLANE.CURATED.*
      - type: exclude
        pattern: DB_ONTOLOGY_CONTROL_PLANE.SIM_*
      - type: exclude
        pattern: SUPPLY_CHAIN.SIM_*

  - name: semantic_views
    type: snowflake_metadata
    enabled: true
    rules:
      - type: include
        pattern: DB_ONTOLOGY_CONTROL_PLANE.SAP_PRODUCTION.SAP_BASELINE_SV
      - type: exclude
        pattern: SUPPLY_CHAIN.ONTOLOGY.SC_BASE

  - name: streamlit_apps
    type: snowflake_metadata
    enabled: true
    rules:
      - type: include
        pattern: DB_ONTOLOGY_CONTROL_PLANE.SAP_PRODUCTION.SUPPLY_CHAIN_DASHBOARD

  - name: stage_files
    type: snowflake_metadata
    enabled: true
    rules:
      - type: include
        file: '@DB_ONTOLOGY_CONTROL_PLANE.SAP_PRODUCTION.SENSE_SOURCES/sap_supply_chain_knowledge.md'

  - name: query_history
    type: snowflake_metadata
    enabled: true

  - name: business_ontology
    type: snowflake_metadata
    enabled: true
    rules:
      - type: include
        domain: Supply Chain
      - type: include
        domain: SAP Purchasing
```

### What Cortex Sense indexes
| Source type | Content |
|---|---|
| **Catalog objects** | All tables in RAW_SOURCES + SAP_PRODUCTION (columns, types, comments, row profiles) |
| **Semantic views** | SAP_BASELINE_SV structure (tables, relationships, facts, dimensions, join patterns) |
| **Business ontology** | Supply Chain domain (23 nodes, 16 relationships) + SAP Purchasing (15 nodes, 4 relationships) |
| **Stage files** | `sap_supply_chain_knowledge.md` — metric formulas, entity definitions, SAP field codes, procurement policies |
| **Query history** | Recent queries against these schemas |

---

## 4. Sense Agent (Cortex Sense-Powered)

```sql
CREATE OR REPLACE AGENT DB_ONTOLOGY_CONTROL_PLANE.SAP_PRODUCTION.SAP_SUPPLY_CHAIN_AGENT
  COMMENT = 'Supply chain agent grounded by Cortex Sense context SAP_SUPPLY_CHAIN'
  PROFILE = '{"display_name": "SAP Supply Chain Assistant", "color": "blue"}'
  FROM SPECIFICATION $$
  models:
    orchestration: auto
  tools:
    - tool_spec:
        type: data_to_chart
        name: data_to_chart
  experimental:
    EnableCortexSense: true
  instructions:
    orchestration: |
      For every question, call cortex_sense first to retrieve
      context about tables, metrics, and business definitions.
      Use the returned context to select the correct tables
      and write SQL. Do not guess metric formulas or business
      rules — always defer to what cortex_sense returns.
    response: |
      Answer concisely with data. Include the source table(s)
      used. Offer to chart results when appropriate.
  $$;
```

**Key differences from baseline**:
- `EnableCortexSense: true` — activates the `cortex_sense` tool automatically
- `system_execute_sql` — auto-provisioned, can query ANY table the role has access to
- No `cortex_analyst_text_to_sql` tool — the agent writes SQL directly, guided by Sense context
- No `tool_resources` block — not locked to a specific semantic view

**How Sense agent answers a question**:
1. Calls `cortex_sense` with the user's query
2. Receives: table schemas + ontology nodes + query patterns + **feedback corrections**
3. Reads the corrections (e.g., "use ARIBA_SUPPLIERS for spend")
4. Writes and executes SQL via `system_execute_sql` against the correct table
5. Returns the answer with source attribution

---

## 5. Feedback Corrections (6 active)

These are injected at query time as `corrections` in the `cortex_sense` response. No rebuild needed.

### Table routing corrections (3)

```
┌───┬──────────────────────────┬────────────────────────────────────────────────┐
│ # │ Target table             │ Rule                                           │
├───┼──────────────────────────┼────────────────────────────────────────────────┤
│ 1 │ ARIBA_SUPPLIERS          │ For annual supplier spend, use                 │
│   │ (RAW_SOURCES)            │ ARIBA_SUPPLIERS.ANNUAL_SPEND_USD —             │
│   │                          │ not SAP BSEG or EKPO.                          │
├───┼──────────────────────────┼────────────────────────────────────────────────┤
│ 2 │ DNB_RISK_ASSESSMENTS     │ For supplier risk scores, use                  │
│   │ (RAW_SOURCES)            │ DNB_RISK_ASSESSMENTS. High-risk =              │
│   │                          │ OVERALL_RISK_SCORE >= 5. Join by               │
│   │                          │ SUPPLIER_NAME text match.                      │
├───┼──────────────────────────┼────────────────────────────────────────────────┤
│ 3 │ SUPPLIER_SCORECARDS      │ For scorecard/health index questions,          │
│   │ (SAP_PRODUCTION)         │ use SUPPLIER_SCORECARDS. Join to               │
│   │                          │ LFA1 via LIFNR. Scores: delivery,             │
│   │                          │ quality, responsiveness (1-5 scale).           │
└───┴──────────────────────────┴────────────────────────────────────────────────┘
```

### Business knowledge corrections (3)

```
┌───┬──────────────────────────┬────────────────────────────────────────────────┐
│ # │ Knowledge type           │ Rule                                           │
├───┼──────────────────────────┼────────────────────────────────────────────────┤
│ 4 │ Metric formula           │ COGS = SUM(DMBTR WHERE BSCHL='31') -          │
│   │ (targets BSEG)           │ SUM(DMBTR WHERE BSCHL='34').                   │
│   │                          │ BSCHL 31=invoices, 34=credit memos.           │
│   │                          │ Do NOT use naive SUM or COEP.                  │
├───┼──────────────────────────┼────────────────────────────────────────────────┤
│ 5 │ Business policy           │ Three-Strike Rule: 3 consecutive              │
│   │ (no table target)        │ quarterly scores below C → automatic           │
│   │                          │ probation (KTOKK → ZPRB). Existing            │
│   │                          │ POs only, prepay/Net15. Recovery:              │
│   │                          │ 2 consecutive B+ to return to ZSTD.           │
├───┼──────────────────────────┼────────────────────────────────────────────────┤
│ 6 │ Field reference          │ KTOKK codes: ZSTR = Strategic (Net 60,        │
│   │ (targets LFA1)           │ dynamic discounting). ZSTD = Standard          │
│   │                          │ (Net 30). ZPRB = Probationary (Prepay/         │
│   │                          │ Net 15, restricted POs). Only ZSTR +           │
│   │                          │ ZSTD = active suppliers.                       │
└───┴──────────────────────────┴────────────────────────────────────────────────┘
```

### Feedback SQL (for reproduction)

```sql
-- Record feedback (requires USAGE on the context)
SELECT SYSTEM$CORTEX_AGENT_CORTEX_CONTEXT_BUILDER($${
  "action": "record-feedback",
  "parameters": {
    "name": "SAP_SUPPLY_CHAIN",
    "database_name": "DB_ONTOLOGY_CONTROL_PLANE",
    "schema_name": "SAP_PRODUCTION",
    "feedback": {
      "type": "retrieval_steer",
      "feedback_rule": "<the rule text>",
      "indexed_text": "<semantic description for matching>",
      "raw_feedback": "<original observation>",
      "targets": {
        "entity_keys": ["<DB.SCHEMA.TABLE>"],
        "query_pattern": "<keyword patterns>"
      }
    }
  }
}$$);

-- Approve feedback (requires builder role)
SELECT SYSTEM$CORTEX_AGENT_CORTEX_CONTEXT_BUILDER($${
  "action": "approve-feedback",
  "parameters": {
    "name": "SAP_SUPPLY_CHAIN",
    "database_name": "DB_ONTOLOGY_CONTROL_PLANE",
    "schema_name": "SAP_PRODUCTION",
    "feedback_id": "<feedback_id>"
  }
}$$);
```

---

## 6. How to Run the Eval

```sql
-- Run a question against the Sense agent
SELECT TRY_PARSE_JSON(
  SNOWFLAKE.CORTEX.DATA_AGENT_RUN(
    'DB_ONTOLOGY_CONTROL_PLANE.SAP_PRODUCTION.SAP_SUPPLY_CHAIN_AGENT',
    $${"messages": [{"role": "user", "content": [
      {"type": "text", "text": "What is our Cost of Goods Sold?"}
    ]}]}$$
  )
):content AS content;

-- Run the same question against the Baseline agent
SELECT TRY_PARSE_JSON(
  SNOWFLAKE.CORTEX.DATA_AGENT_RUN(
    'DB_ONTOLOGY_CONTROL_PLANE.SAP_PRODUCTION.BASELINE_SUPPLY_CHAIN_AGENT',
    $${"messages": [{"role": "user", "content": [
      {"type": "text", "text": "What is our Cost of Goods Sold?"}
    ]}]}$$
  )
):content AS content;
```

---

## 7. Grant Access (for other users to run the demo)

```sql
-- Grant access to the Cortex Sense context
GRANT USAGE ON CORTEX SENSE DB_ONTOLOGY_CONTROL_PLANE.SAP_PRODUCTION.SAP_SUPPLY_CHAIN
  TO ROLE <demo_role>;

-- Grant access to both agents
GRANT USAGE ON AGENT DB_ONTOLOGY_CONTROL_PLANE.SAP_PRODUCTION.SAP_SUPPLY_CHAIN_AGENT
  TO ROLE <demo_role>;
GRANT USAGE ON AGENT DB_ONTOLOGY_CONTROL_PLANE.SAP_PRODUCTION.BASELINE_SUPPLY_CHAIN_AGENT
  TO ROLE <demo_role>;

-- Grant access to the semantic view (baseline agent needs this)
GRANT USAGE ON SEMANTIC VIEW DB_ONTOLOGY_CONTROL_PLANE.SAP_PRODUCTION.SAP_BASELINE_SV
  TO ROLE <demo_role>;

-- Grant SELECT on underlying tables
GRANT USAGE ON DATABASE DB_ONTOLOGY_CONTROL_PLANE TO ROLE <demo_role>;
GRANT USAGE ON SCHEMA DB_ONTOLOGY_CONTROL_PLANE.SAP_PRODUCTION TO ROLE <demo_role>;
GRANT USAGE ON SCHEMA DB_ONTOLOGY_CONTROL_PLANE.RAW_SOURCES TO ROLE <demo_role>;
GRANT SELECT ON ALL TABLES IN SCHEMA DB_ONTOLOGY_CONTROL_PLANE.SAP_PRODUCTION TO ROLE <demo_role>;
GRANT SELECT ON ALL TABLES IN SCHEMA DB_ONTOLOGY_CONTROL_PLANE.RAW_SOURCES TO ROLE <demo_role>;

-- Grant warehouse access
GRANT USAGE ON WAREHOUSE COMPUTE_WH TO ROLE <demo_role>;
GRANT USAGE ON WAREHOUSE ONTOLOGY_WH TO ROLE <demo_role>;
```
