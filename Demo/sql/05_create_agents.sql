-- =============================================================================
-- 05_create_agents.sql
-- SUPERSEDED: Agents are now created via the $cortex-sense skill:
--   $cortex-sense create an agent for SAP_SUPPLY_CHAIN
-- The BASELINE agent can still be created manually using the spec below.
-- =============================================================================
-- Original: Creates two agents for side-by-side comparison:
--   BASELINE_SUPPLY_CHAIN_AGENT  — Semantic View only (what you can do today)
--   SENSE_SUPPLY_CHAIN_AGENT     — Cortex Sense (SV + ontology + schema + KB + history)
--
-- KEY DIFFERENCE:
--   Baseline: explicit cortex_analyst_text_to_sql tool bound to one SV
--   Sense:    EnableCortexSense flag → agent gets cortex_sense + system_execute_sql
--             implicitly, can query ANY table, not just SV-covered ones
-- =============================================================================

USE DATABASE DB_ONTOLOGY_CONTROL_PLANE;
USE SCHEMA SAP_PRODUCTION;
USE WAREHOUSE ONTOLOGY_WH;

-- =====================================================================
-- AGENT 1: BASELINE (Semantic View only)
-- One declared tool: cortex_analyst_text_to_sql bound to SAP_BASELINE_SV.
-- Can only answer questions about the 14 tables in the SV.
-- No cortex_sense, no knowledge base, no ontology awareness.
-- =====================================================================
CREATE OR REPLACE AGENT BASELINE_SUPPLY_CHAIN_AGENT
COMMENT = 'Baseline: SV only. No Cortex Sense.'
FROM SPECIFICATION $$
models:
  orchestration: auto
orchestration:
  budget:
    seconds: 60
    tokens: 16000
instructions:
  response: >
    You are a supply chain analytics agent. Answer questions using the
    SAP production data available through the semantic view. If you cannot
    find the data needed, say so clearly.
  orchestration: "Use query_sap for all data questions."
tools:
  - tool_spec:
      type: cortex_analyst_text_to_sql
      name: query_sap
      description: "Query SAP data: procurement, logistics, finance, sales."
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

-- =====================================================================
-- AGENT 2: SENSE (Cortex Sense powered)
-- Uses EnableCortexSense experimental flag.
-- This gives the agent these tools IMPLICITLY (do NOT declare them):
--   - cortex_sense      → retrieves context from the built context object
--   - system_execute_sql → runs SQL against ANY table (not just SV)
--   - table_details      → column metadata lookup
--
-- Only data_to_chart needs to be declared explicitly.
--
-- The cortex_sense tool returns: metric definitions, entity relationships,
-- business rules, SAP field decoders, policy documents, query patterns —
-- everything the build indexed from schema metadata, SVs, ontology,
-- knowledge base, and query history.
-- =====================================================================
CREATE OR REPLACE AGENT SENSE_SUPPLY_CHAIN_AGENT
COMMENT = 'Cortex Sense agent: full context stack via cortex_sense tool.'
FROM SPECIFICATION $$
models:
  orchestration: auto

experimental:
  EnableCortexSense: true

tools:
  - tool_spec:
      type: data_to_chart
      name: data_to_chart

instructions:
  response: >
    You are a supply chain analytics agent powered by Cortex Sense.
    You have access to the full SAP supply chain context: semantic views,
    business ontology definitions, procurement policies, warehouse SOPs,
    metric definitions, and schema metadata for all tables.
    Always call cortex_sense first to retrieve relevant context before
    answering. Use the context to determine correct metric formulas,
    entity relationships, and business rules.
  orchestration: >
    WORKFLOW for every question:
    1. Call cortex_sense to retrieve relevant context.
    2. Use returned context for metric definitions, table relationships,
       business rules, SAP field code meanings.
    3. Write and execute SQL via system_execute_sql against actual tables.
    4. Present results with reasoning grounded in context.
    If cortex_sense returns metric formulas, use them exactly.
    If cortex_sense returns policy or SOP info, cite it.
    You can query ANY table in SAP_PRODUCTION, not just SV-covered ones.
$$;

-- =====================================================================
-- VERIFY
-- =====================================================================
-- Test baseline:
SELECT SNOWFLAKE.CORTEX.DATA_AGENT_RUN(
  'DB_ONTOLOGY_CONTROL_PLANE.SAP_PRODUCTION.BASELINE_SUPPLY_CHAIN_AGENT',
  $${"messages": [{"role": "user", "content": [{"type": "text", "text": "How many purchase orders do we have?"}]}]}$$
) AS response;

-- Test sense (will call cortex_sense tool → needs build to complete):
SELECT SNOWFLAKE.CORTEX.DATA_AGENT_RUN(
  'DB_ONTOLOGY_CONTROL_PLANE.SAP_PRODUCTION.SENSE_SUPPLY_CHAIN_AGENT',
  $${"messages": [{"role": "user", "content": [{"type": "text", "text": "How many purchase orders do we have?"}]}]}$$
) AS response;
