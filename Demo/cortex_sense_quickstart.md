# Cortex Sense Quickstart — End-to-End Setup

A practical guide to setting up Cortex Sense from scratch, based on a real SAP supply chain deployment. Covers context creation, manifest authoring, build monitoring, agent creation, evaluation, and feedback-driven improvement.

---

## Prerequisites

- Snowflake account with Cortex Sense enabled (PrPr feature — contact your account team)
- ACCOUNTADMIN or a role with CREATE AGENT, CREATE SEMANTIC VIEW, and CORTEX SENSE privileges
- Existing tables you want the agent to reason over
- A warehouse for the Sense build process

---

## Step 1: Understand Your Data Estate

Before building a context, map what you have.

```sql
-- What schemas and tables exist?
SHOW TABLES IN SCHEMA MY_DB.MY_SCHEMA;

-- How many rows in each?
SELECT TABLE_NAME, ROW_COUNT
FROM MY_DB.INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = 'MY_SCHEMA'
ORDER BY ROW_COUNT DESC;

-- Do you have a semantic view already?
SHOW SEMANTIC VIEWS IN SCHEMA MY_DB.MY_SCHEMA;

-- Do you have a business ontology?
SELECT PARSE_JSON(SYSTEM$GET_GLOSSARY_TERM_LIST());
```

Identify:
- **Core tables** the agent should query (these go in the manifest)
- **External/enrichment tables** outside the main schema (Ariba, D&B, etc.)
- **Documentation** with business rules, metric formulas, field code references
- **Semantic views** that define table relationships and verified queries

---

## Step 2: Create a Semantic View (if you don't have one)

A semantic view gives Cortex Analyst structured metadata about your tables. Even if the Sense agent won't use Cortex Analyst directly, the SV enriches the Sense context with relationship and terminology information.

```sql
CREATE OR REPLACE SEMANTIC VIEW MY_DB.MY_SCHEMA.MY_BASELINE_SV
  tables (
    MY_DB.MY_SCHEMA.CUSTOMERS   primary key (CUSTOMER_ID)  comment='Customer master data',
    MY_DB.MY_SCHEMA.ORDERS      primary key (ORDER_ID)      comment='Sales orders',
    MY_DB.MY_SCHEMA.PRODUCTS    primary key (PRODUCT_ID)    comment='Product catalog'
  )
  relationships (
    ORDERS_TO_CUSTOMERS as ORDERS(CUSTOMER_ID) references CUSTOMERS(CUSTOMER_ID),
    ORDERS_TO_PRODUCTS  as ORDERS(PRODUCT_ID)  references PRODUCTS(PRODUCT_ID)
  )
  facts (
    ORDERS.AMOUNT    as AMOUNT    comment='Order amount in USD',
    ORDERS.QUANTITY  as QUANTITY  comment='Units ordered',
    PRODUCTS.PRICE   as PRICE    comment='Unit price'
  )
  dimensions (
    CUSTOMERS.NAME   as NAME   comment='Customer name',
    CUSTOMERS.REGION as REGION comment='Geographic region',
    PRODUCTS.CATEGORY as CATEGORY comment='Product category'
  )
  comment='Baseline sales data model';
```

---

## Step 3: Upload Business Documentation (Optional but High-Value)

Create a stage and upload knowledge documents — metric definitions, business rules, field code references, policies. These get indexed by Sense and served as context.

```sql
-- Create a stage for knowledge docs
CREATE STAGE IF NOT EXISTS MY_DB.MY_SCHEMA.SENSE_SOURCES;

-- Upload from local (via SnowSQL or Snowsight)
PUT file:///path/to/my_business_knowledge.md
  @MY_DB.MY_SCHEMA.SENSE_SOURCES/
  AUTO_COMPRESS = FALSE
  OVERWRITE = TRUE;
```

**What to put in the knowledge doc:**
- Metric formulas with correct table + column + filter logic
- Common errors to avoid (e.g., "Do NOT use TABLE_X for this metric")
- Business policies (approval thresholds, escalation rules)
- Field code decode tables (status codes, category codes)
- Entity definitions with primary keys and cross-system join logic

---

## Step 4: Author the Manifest (scope.yaml)

The manifest defines what Cortex Sense indexes. Write it as YAML.

```yaml
name: MY_CONTEXT_NAME
description: >-
  Brief description of the domain this context covers.
  Be specific — this helps Sense retrieval.
warehouse: MY_WAREHOUSE
sources:
  # 1. Tables and views to index
  - name: catalog_objects
    type: snowflake_metadata
    enabled: true
    rules:
      - type: include
        pattern: MY_DB.MY_SCHEMA.*          # Include all tables in this schema
      - type: include
        pattern: MY_DB.RAW_SOURCES.*        # Include external/enrichment tables
      - type: exclude
        pattern: MY_DB.STAGING.*            # Exclude staging/temp tables
      - type: exclude
        pattern: MY_DB.MY_SCHEMA.TMP_*      # Exclude temp tables by prefix

  # 2. Semantic views (relationships, verified queries, terminology)
  - name: semantic_views
    type: snowflake_metadata
    enabled: true
    rules:
      - type: include
        pattern: MY_DB.MY_SCHEMA.MY_BASELINE_SV

  # 3. Business documentation from stages
  - name: stage_files
    type: snowflake_metadata
    enabled: true
    rules:
      - type: include
        file: '@MY_DB.MY_SCHEMA.SENSE_SOURCES/my_business_knowledge.md'

  # 4. Query history (learns from how tables are actually used)
  - name: query_history
    type: snowflake_metadata
    enabled: true

  # 5. Business ontology (if you have one)
  - name: business_ontology
    type: snowflake_metadata
    enabled: true
    rules:
      - type: include
        domain: My Domain Name

  # 6. Streamlit apps (optional)
  - name: streamlit_apps
    type: snowflake_metadata
    enabled: true
    rules:
      - type: include
        pattern: MY_DB.MY_SCHEMA.MY_DASHBOARD
```

**Manifest rules of thumb:**
- Include generously, exclude specifically — Sense handles large scopes well
- Exclude staging, simulation, and temp tables to reduce noise
- Always include your semantic views — they provide the richest metadata
- Include business ontology if you have one — it provides entity definitions and metric formulas

---

## Step 5: Create and Build the Context

### 5a. Create the context

```sql
SELECT SYSTEM$CORTEX_AGENT_CORTEX_CONTEXT_BUILDER($${
  "action": "create-context",
  "parameters": {
    "name": "MY_CONTEXT_NAME",
    "database_name": "MY_DB",
    "schema_name": "MY_SCHEMA",
    "target_lag": "1h0m0s"
  }
}$$);
```

This creates the context object and an internal stage `CORTEX_CONTEXT$MY_CONTEXT_NAME`.

### 5b. Upload the manifest

```sql
SELECT SYSTEM$CORTEX_AGENT_CORTEX_CONTEXT_BUILDER($${
  "action": "put-stage-file",
  "parameters": {
    "name": "MY_CONTEXT_NAME",
    "database_name": "MY_DB",
    "schema_name": "MY_SCHEMA",
    "file_name": "scope.yaml",
    "file_content": "<paste your YAML here, escaped as a JSON string>"
  }
}$$);
```

> **Tip**: Use `$$` dollar-quoting for the outer call and escape the YAML content as a JSON string inside `file_content`. Alternatively, upload via CoCo CLI which handles the escaping.

### 5c. Trigger the build

```sql
SELECT SYSTEM$CORTEX_AGENT_CORTEX_CONTEXT_BUILDER($${
  "action": "force-reprocess",
  "parameters": {
    "name": "MY_CONTEXT_NAME",
    "database_name": "MY_DB",
    "schema_name": "MY_SCHEMA"
  }
}$$);
```

### 5d. Monitor build status

```sql
-- Check context status (repeat until last_processed_at updates)
SELECT PARSE_JSON(SYSTEM$CORTEX_AGENT_CORTEX_CONTEXT_BUILDER($${
  "action": "get-context",
  "parameters": {
    "name": "MY_CONTEXT_NAME",
    "database_name": "MY_DB",
    "schema_name": "MY_SCHEMA"
  }
}$$)):response_structured AS status;
```

**Build timing**: The build daemon cycles through accounts on a ~30 minute cadence (prod3). The `target_lag` doesn't control initial build speed — it controls refresh frequency after the first build. Expect 15–45 minutes for the first build to complete.

**What "built" looks like**: The `last_processed_at` field updates from null to a timestamp.

---

## Step 6: Test the Context

Before creating an agent, verify Sense returns useful context for your domain.

### Using the cortex_sense MCP tool (from CoCo)

```
-- In CoCo, the cortex_sense tool queries the context directly
cortex_sense(
  query="How many customers do we have?",
  context_names=["MY_DB.MY_SCHEMA.MY_CONTEXT_NAME"]
)
```

### Using SQL

```sql
-- Query the context via Cortex Sense API
SELECT PARSE_JSON(SYSTEM$CORTEX_AGENT_CORTEX_CONTEXT_BUILDER($${
  "action": "query-context",
  "parameters": {
    "name": "MY_CONTEXT_NAME",
    "database_name": "MY_DB",
    "schema_name": "MY_SCHEMA",
    "query": "How many customers do we have?"
  }
}$$));
```

**What to check:**
- Are the right tables showing up in the response?
- Are table descriptions, columns, and join patterns accurate?
- Are ontology nodes and semantic view metadata present?
- Is the stage file content being retrieved for relevant queries?

---

## Step 7: Create the Sense-Powered Agent

```sql
CREATE OR REPLACE AGENT MY_DB.MY_SCHEMA.MY_SENSE_AGENT
  COMMENT = 'Agent grounded by Cortex Sense context MY_CONTEXT_NAME'
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

**Key settings:**
- `EnableCortexSense: true` — this is what activates the `cortex_sense` tool on the agent
- No `cortex_analyst_text_to_sql` tool needed — the agent uses `system_execute_sql` (auto-provisioned) guided by Sense context
- Keep instructions minimal — the agent should get business logic from Sense, not from hardcoded instructions

---

## Step 8: Create a Baseline Agent (for comparison)

To demonstrate Sense's value, create a control agent that uses only the semantic view.

```sql
CREATE OR REPLACE AGENT MY_DB.MY_SCHEMA.MY_BASELINE_AGENT
  COMMENT = 'Baseline agent: Semantic View only. No Cortex Sense.'
  FROM SPECIFICATION $$
  models:
    orchestration: "auto"
  instructions:
    response: >
      Answer questions using the data available through the semantic view.
      If you cannot find the data needed, say so clearly.
    orchestration: >
      Use the query_data tool to answer all data questions.
  tools:
    - tool_spec:
        type: cortex_analyst_text_to_sql
        name: query_data
        description: "Query the data model."
    - tool_spec:
        type: data_to_chart
        name: data_to_chart
  tool_resources:
    query_data:
      semantic_view: "MY_DB.MY_SCHEMA.MY_BASELINE_SV"
      execution_environment:
        type: warehouse
        warehouse: MY_WAREHOUSE
  $$;
```

---

## Step 9: Run Both Agents

```sql
-- Sense agent
SELECT TRY_PARSE_JSON(
  SNOWFLAKE.CORTEX.DATA_AGENT_RUN(
    'MY_DB.MY_SCHEMA.MY_SENSE_AGENT',
    $${"messages": [{"role": "user", "content": [
      {"type": "text", "text": "How many customers do we have?"}
    ]}]}$$
  )
):content AS sense_answer;

-- Baseline agent
SELECT TRY_PARSE_JSON(
  SNOWFLAKE.CORTEX.DATA_AGENT_RUN(
    'MY_DB.MY_SCHEMA.MY_BASELINE_AGENT',
    $${"messages": [{"role": "user", "content": [
      {"type": "text", "text": "How many customers do we have?"}
    ]}]}$$
  )
):content AS baseline_answer;
```

---

## Step 10: Evaluate and Find Gaps

Design eval questions that test different Sense capabilities:

| Category | What it tests | Example |
|---|---|---|
| **External table routing** | Can the agent find tables outside the SV? | "What is our annual Ariba spend?" |
| **Business knowledge** | Does the agent apply the correct formula/policy? | "What is our COGS?" |
| **Cross-domain synthesis** | Can the agent join across multiple systems? | "Which high-risk suppliers have the largest spend?" |
| **Institutional knowledge** | Can the agent answer policy/rule questions? | "What happens after 3 bad quarters?" |
| **Source selection** | Does the agent pick the right table over a plausible wrong one? | "What is our actual OTD rate?" (operational vs. self-reported) |

Run each question against both agents. Grade on a 0-1-2 scale:
- **0** = wrong answer or no answer
- **1** = partial (right direction, wrong number or missing context)
- **2** = correct answer with source attribution

---

## Step 11: Fix Gaps with Feedback Corrections

Feedback corrections are the single most important mechanism for improving a Cortex Sense agent after the initial build. They let you inject business knowledge, fix wrong table routing, and correct metric formulas — all at query time, with no rebuild, no agent spec change, and no semantic view modification.

### How feedback works at runtime

When the agent calls `cortex_sense`, the response contains two sections:

```json
{
  "corrections": [                    // ← Feedback corrections (injected rules)
    {
      "doc_type": "correction",
      "markdown": "For annual spend, use ARIBA_SUPPLIERS.ANNUAL_SPEND_USD..."
    }
  ],
  "documents": [                      // ← Indexed context (tables, ontology, queries)
    { "doc_type": "table_entity", ... },
    { "doc_type": "ontology_node", ... }
  ]
}
```

The agent reads BOTH. Corrections take priority — they override what the documents suggest. This is how a correction that says "use ARIBA_SUPPLIERS, not BSEG" wins even when the indexed documents prominently feature BSEG.

### The feedback lifecycle

```
  Record                    Approve                    Query fires
  (needs_feedback)    →     (active + indexed)    →    (injected at runtime)
       │                         │                          │
  Anyone with USAGE         Builder role only         Matches by semantic
  on the context            reviews and approves      similarity to the
                                                      indexed_text field
```

- **Record**: Anyone with USAGE privilege on the context can submit feedback
- **Approve**: A builder (typically the context owner) reviews and activates it
- **Serve**: The correction is embedded and matched against incoming queries by semantic similarity to the `indexed_text` — no keyword matching, no regex

### Anatomy of a feedback correction

Every correction has 5 key fields:

| Field | Purpose | Writing guidance |
|---|---|---|
| `feedback_rule` | **The instruction injected into the agent's context.** This is what the agent reads and follows. | Write as a direct imperative: "For X questions, use TABLE_Y. Do NOT use TABLE_Z." Be specific about table FQNs, column names, filter conditions, and join keys. |
| `indexed_text` | **The semantic matching text.** Controls WHEN this correction fires. Written as a description of the question, not the answer. | Write as "When asking about..." — describe the kinds of questions this should match, using natural language synonyms. Do NOT include table names or SQL. |
| `raw_feedback` | **The original observation.** Stored unchanged for audit. | Describe what went wrong: "Agent used EKPO.NETWR for spend but the correct source is ARIBA_SUPPLIERS." |
| `targets.entity_keys` | **Table FQNs this correction relates to.** Optional but improves matching precision. | Use fully qualified names: `["MY_DB.MY_SCHEMA.MY_TABLE"]` |
| `targets.query_pattern` | **Keyword phrases for additional matching.** | Comma-separated keywords: `"annual spend, supplier spend, how much do we spend"` |

### Three categories of corrections (with real examples)

#### Category 1: Table Routing

**When to use**: The agent queries the wrong table, or can't find a table that exists but isn't surfaced by the indexed context.

**Diagnosis**: The agent returned data from TABLE_A when the correct source is TABLE_B. Or the agent said "I can't find that data" when the table exists.

**Real example from our eval** — The agent used `EKPO.NETWR` (SAP purchase order values) for annual spend, but the correct source is `ARIBA_SUPPLIERS.ANNUAL_SPEND_USD` (Ariba procurement system-of-record):

```sql
SELECT SYSTEM$CORTEX_AGENT_CORTEX_CONTEXT_BUILDER($${
  "action": "record-feedback",
  "parameters": {
    "name": "SAP_SUPPLY_CHAIN",
    "database_name": "DB_ONTOLOGY_CONTROL_PLANE",
    "schema_name": "SAP_PRODUCTION",
    "feedback": {
      "type": "retrieval_steer",
      "feedback_rule": "For supplier annual spend or contracted spend questions, query DB_ONTOLOGY_CONTROL_PLANE.RAW_SOURCES.ARIBA_SUPPLIERS.ANNUAL_SPEND_USD as the authoritative source, not SAP BSEG or EKPO.",
      "indexed_text": "When asking about annual supplier spend, contracted spend analytics, or how much we spend with a supplier, the answer should come from the Ariba procurement platform table rather than SAP accounting or purchasing document tables.",
      "raw_feedback": "Agent used EKPO.NETWR for spend but the correct source is ARIBA_SUPPLIERS.ANNUAL_SPEND_USD.",
      "targets": {
        "entity_keys": ["DB_ONTOLOGY_CONTROL_PLANE.RAW_SOURCES.ARIBA_SUPPLIERS"],
        "query_pattern": "annual spend, supplier spend, how much do we spend with"
      }
    }
  }
}$$);
```

**Other table routing examples we recorded:**

| Problem | Correction |
|---|---|
| Agent can't find supplier risk scores | "For supplier risk scores, query `DNB_RISK_ASSESSMENTS`. High-risk = `OVERALL_RISK_SCORE >= 5`. Join to vendors by `SUPPLIER_NAME` text match." |
| Agent can't find supplier scorecards | "For Supplier Health Index questions, query `SUPPLIER_SCORECARDS`. Join to `LFA1` via `LIFNR`. Scores are delivery, quality, responsiveness on a 1-5 scale." |

#### Category 2: Metric Formula

**When to use**: The agent queries the right table but computes the metric wrong — naive SUM instead of conditional aggregation, wrong filter, wrong join, missing exclusion.

**Diagnosis**: The agent returned a number, but it doesn't match the business-defined formula. Usually the agent is "close but wrong" — it found the right table but applied the wrong logic.

**Real example from our eval** — The agent computed COGS as `SUM(COEP.WRTBTR)` = $1,327,550 (SAP controlling cost). The business-defined COGS formula is `SUM(DMBTR WHERE BSCHL='31') - SUM(DMBTR WHERE BSCHL='34')` from BSEG = $1,542,520:

```sql
SELECT SYSTEM$CORTEX_AGENT_CORTEX_CONTEXT_BUILDER($${
  "action": "record-feedback",
  "parameters": {
    "name": "SAP_SUPPLY_CHAIN",
    "database_name": "DB_ONTOLOGY_CONTROL_PLANE",
    "schema_name": "SAP_PRODUCTION",
    "feedback": {
      "type": "retrieval_steer",
      "feedback_rule": "For Cost of Goods Sold (COGS), use DB_ONTOLOGY_CONTROL_PLANE.SAP_PRODUCTION.BSEG with posting key logic: COGS = SUM(DMBTR WHERE BSCHL = '31') - SUM(DMBTR WHERE BSCHL = '34'). BSCHL 31 = vendor invoices (add), BSCHL 34 = credit memos (subtract). The correct answer is $1,542,520. Do NOT use naive SUM(DMBTR) which overstates to $1,669,860, and do NOT use COEP (that is controlling cost, not COGS).",
      "indexed_text": "When asking about cost of goods sold, COGS, or the total cost of vendor invoices minus credit memos, the answer requires separating accounting document line items by posting key to distinguish invoices from credits rather than summing all amounts naively or using the controlling cost table.",
      "raw_feedback": "COGS must be calculated from BSEG using posting keys: SUM(DMBTR WHERE BSCHL='31') minus SUM(DMBTR WHERE BSCHL='34'). Correct answer is $1,542,520. Do not use COEP or naive SUM(DMBTR).",
      "targets": {
        "entity_keys": ["DB_ONTOLOGY_CONTROL_PLANE.SAP_PRODUCTION.BSEG"],
        "query_pattern": "cost of goods sold, COGS, vendor invoice total, posting key 31 34"
      }
    }
  }
}$$);
```

**Key pattern for metric formula corrections:**
- State the exact formula with table, column, and filter conditions
- State what the correct answer is (so the agent can validate)
- Explicitly say what NOT to do ("Do NOT use naive SUM", "Do NOT use COEP")

#### Category 3: Business Knowledge

**When to use**: The question isn't about data — it's about a business rule, policy, process, or definition that lives in documentation rather than tables.

**Diagnosis**: The agent said "I can't answer that from the available data" or hallucinated a policy. The answer exists in your knowledge docs but wasn't retrieved by Sense.

**Real example from our eval** — The agent couldn't answer "What happens to a supplier that scores below C for three consecutive quarters?" because the Three-Strike Rule is a procurement policy, not a database record:

```sql
SELECT SYSTEM$CORTEX_AGENT_CORTEX_CONTEXT_BUILDER($${
  "action": "record-feedback",
  "parameters": {
    "name": "SAP_SUPPLY_CHAIN",
    "database_name": "DB_ONTOLOGY_CONTROL_PLANE",
    "schema_name": "SAP_PRODUCTION",
    "feedback": {
      "type": "retrieval_steer",
      "feedback_rule": "Three-Strike Rule (supplier governance policy): If a supplier scores below C (roughly below 3.0 on the 1-5 scorecard scale) for 3 consecutive quarters, they are automatically placed on probation — their SAP account group (KTOKK) is changed to ZPRB. Probationary vendors are restricted to existing POs only with no new contracts allowed. Payment terms change to prepay or Net 15 only. Recovery requires 2 consecutive B+ ratings (above 4.0) to return to ZSTD status.",
      "indexed_text": "When asking about what happens to underperforming suppliers, the consequence of repeated low scores on quarterly reviews, supplier probation policies, the three-strike rule, or how vendors get placed on probation status, the answer involves a governance policy where consecutive poor quarterly scorecard ratings trigger automatic probation with restricted purchasing and tighter payment terms.",
      "raw_feedback": "Three-Strike Rule: 3 consecutive quarterly scores below C = automatic probation (KTOKK changed to ZPRB). Probationary vendors restricted to existing POs only, no new contracts. Payment terms become prepay or Net 15. Recovery requires 2 consecutive B+ ratings to return to ZSTD.",
      "targets": {
        "entity_keys": [],
        "query_pattern": "three-strike rule, supplier probation, consecutive poor scores, underperforming supplier consequence"
      }
    }
  }
}$$);
```

**Key pattern for business knowledge corrections:**
- The `feedback_rule` IS the answer — the agent reads it and relays it directly
- No `entity_keys` needed if the question doesn't involve querying a table
- Write `indexed_text` with many synonyms for how people might ask the question

### Approving feedback

Feedback starts in `needs_feedback` state. It won't fire until approved.

```sql
-- Approve a single correction (use the feedback_id from the record response)
SELECT SYSTEM$CORTEX_AGENT_CORTEX_CONTEXT_BUILDER($${
  "action": "approve-feedback",
  "parameters": {
    "name": "SAP_SUPPLY_CHAIN",
    "database_name": "DB_ONTOLOGY_CONTROL_PLANE",
    "schema_name": "SAP_PRODUCTION",
    "feedback_id": "fb:488515:125059860:01a113af-0fd8-75af-afb7-d47b10b29ff1"
  }
}$$);
```

The response confirms the correction is `active` and `indexed: true`:
```json
{
  "feedback_id": "fb:488515:125059860:01a113af-0fd8-75af-afb7-d47b10b29ff1",
  "lifecycle_state": "active",
  "indexed": true,
  "approved_by": "125059884"
}
```

### Listing all feedback

```sql
SELECT PARSE_JSON(SYSTEM$CORTEX_AGENT_CORTEX_CONTEXT_BUILDER($${
  "action": "list-feedback",
  "parameters": {
    "name": "SAP_SUPPLY_CHAIN",
    "database_name": "DB_ONTOLOGY_CONTROL_PLANE",
    "schema_name": "SAP_PRODUCTION"
  }
}$$)):response_structured AS feedback;
```

### How many corrections is normal?

From our SAP supply chain deployment:

| Phase | Corrections added | What they fixed |
|---|---|---|
| After initial build | 0 | Build indexes tables, ontology, SV — may be sufficient for basic questions |
| After first eval (10 questions) | 3 | Table routing: agent couldn't find ARIBA, DNB, SCORECARDS tables |
| After second eval pass | 3 | Business knowledge: COGS formula, Three-Strike Rule, SAP code decode |
| **Total** | **6** | Score went from 2/10 → 10/10 |

A mature context typically has 5–20 active corrections. Each one is a precise, testable fix for a specific failure mode. More is fine — they don't interfere with each other.

### Writing effective indexed_text (the matching key)

The `indexed_text` field controls when a correction fires. It's matched by semantic similarity, not keywords. Write it as a natural-language description of the question the user would ask.

**Good indexed_text** (describes the question):
> "When asking about annual supplier spend, contracted spend analytics, or how much we spend with a supplier, the answer should come from the Ariba procurement platform table."

**Bad indexed_text** (describes the answer):
> "Use DB_ONTOLOGY_CONTROL_PLANE.RAW_SOURCES.ARIBA_SUPPLIERS for ANNUAL_SPEND_USD column."

The good version matches questions like "What's our annual spend with Shenzhen?", "How much do we spend on procurement?", "Total contracted spend?". The bad version only matches if someone literally asks about ARIBA_SUPPLIERS by name.

### The feedback improvement loop in practice

Here's what one cycle looked like in our eval:

```
1. Ran: "What is our Cost of Goods Sold?"
2. Sense agent called cortex_sense, got table context for BSEG and COEP
3. Agent chose COEP (controlling cost) → returned $1,327,550 (WRONG)
4. Correct answer: $1,542,520 from BSEG with BSCHL 31-34 logic
5. Recorded feedback with the exact formula
6. Approved feedback → active + indexed
7. Re-ran the same question
8. Sense agent called cortex_sense, got table context + the NEW correction
9. Agent read correction: "use BSEG with BSCHL 31-34"
10. Agent ran: SUM(DMBTR WHERE BSCHL='31') - SUM(DMBTR WHERE BSCHL='34')
11. Returned $1,542,520 ✓ — citing the correction as source
```

Total time: ~3 minutes. No rebuild. No code change. No redeployment.

---

## Step 12: Iterate

The Cortex Sense improvement loop:

```
  Ask question → Agent answers → Grade answer
                                    │
                         ┌──────────┴──────────┐
                         │                     │
                      Correct              Wrong/Partial
                         │                     │
                       Done              Record feedback
                                               │
                                         Approve feedback
                                               │
                                         Re-test question
                                               │
                                            Correct ✓
```

Each feedback correction is:
- **Immediate** — no rebuild, no redeployment
- **Targeted** — fires only on matching query patterns
- **Cumulative** — corrections stack; the agent gets smarter over time
- **Auditable** — each correction has an ID, author, approval status, and timestamp

---

## Common Gotchas

| Issue | Cause | Fix |
|---|---|---|
| Build never completes | Daemon hasn't cycled to your account yet | Wait ~30 min. Check `get-context` for `last_processed_at` update. |
| `cortex_sense` tool not available on agent | Missing `EnableCortexSense: true` | Add to `experimental` block in agent spec. |
| Agent ignores feedback | Feedback still in `needs_feedback` state | Approve it with `approve-feedback` action. |
| Agent uses wrong table despite feedback | Indexed text doesn't match query pattern | Edit the `indexed_text` and `query_pattern` to better match the question wording. |
| Stage file content not retrieved | Content not chunked/indexed well, or query doesn't match | Record a feedback correction that injects the key content directly. |
| `put-stage-file` fails with JSON error | Single quotes in YAML content | Use `$$` dollar-quoting for the outer SQL call. |
| Context shows `description: ""` | `ALTER CORTEX SENSE SET DESCRIPTION` not supported | Non-blocking — description is set in the manifest, not the context object. |

---

## File Reference

| File | Purpose |
|---|---|
| `scope.yaml` | Manifest defining what Sense indexes (uploaded to context stage) |
| `my_business_knowledge.md` | Business rules, metric formulas, field codes (uploaded to your stage) |
| `eval.yaml` | Eval question set with expected answers and grading criteria |
| `eval_results.md` | Eval results comparing Sense vs Baseline |

---

## Quick Reference — All Cortex Sense API Actions

```sql
-- Create a context
"action": "create-context"

-- Upload manifest or files to the context stage
"action": "put-stage-file"

-- Force a rebuild
"action": "force-reprocess"

-- Check build status
"action": "get-context"

-- List all contexts in a schema
"action": "list-contexts"

-- Record a feedback correction
"action": "record-feedback"

-- Approve a feedback correction
"action": "approve-feedback"

-- List all feedback for a context
"action": "list-feedback"

-- Delete a context
"action": "delete-context"
```

All actions are called via:
```sql
SELECT SYSTEM$CORTEX_AGENT_CORTEX_CONTEXT_BUILDER($${ "action": "...", "parameters": { ... } }$$);
```
