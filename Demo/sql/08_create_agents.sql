-- =============================================================================
-- 08_create_agents.sql
-- Creates both agents: baseline (SV-only) and Sense-powered.
-- Run AFTER Cortex Sense context is built (see cortex_sense_setup.md).
-- =============================================================================

USE SCHEMA DB_ONTOLOGY_CONTROL_PLANE.SAP_PRODUCTION;

-- Baseline agent: locked to the Semantic View
CREATE OR REPLACE AGENT BASELINE_SUPPLY_CHAIN_AGENT
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

-- Sense agent: powered by Cortex Sense context
CREATE OR REPLACE AGENT SAP_SUPPLY_CHAIN_AGENT
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
      rules - always defer to what cortex_sense returns.
    response: |
      Answer concisely with data. Include the source table(s)
      used. Offer to chart results when appropriate.
  $$;
