-- =============================================================================
-- 09_test_queries.sql
-- Quick validation queries to confirm the setup is working.
-- =============================================================================

-- Test 1: Baseline agent - simple vendor count
SELECT LEFT(SNOWFLAKE.CORTEX.DATA_AGENT_RUN(
  'DB_ONTOLOGY_CONTROL_PLANE.SAP_PRODUCTION.BASELINE_SUPPLY_CHAIN_AGENT',
  $${"messages": [{"role": "user", "content": [{"type": "text", "text": "How many active suppliers do we have, excluding probationary vendors?"}]}]}$$
), 500) AS baseline_answer;

-- Test 2: Sense agent - same question
SELECT LEFT(SNOWFLAKE.CORTEX.DATA_AGENT_RUN(
  'DB_ONTOLOGY_CONTROL_PLANE.SAP_PRODUCTION.SAP_SUPPLY_CHAIN_AGENT',
  $${"messages": [{"role": "user", "content": [{"type": "text", "text": "How many active suppliers do we have, excluding probationary vendors?"}]}]}$$
), 500) AS sense_answer;

-- Test 3: Sense advantage - external table routing
SELECT LEFT(SNOWFLAKE.CORTEX.DATA_AGENT_RUN(
  'DB_ONTOLOGY_CONTROL_PLANE.SAP_PRODUCTION.SAP_SUPPLY_CHAIN_AGENT',
  $${"messages": [{"role": "user", "content": [{"type": "text", "text": "What is our Cost of Goods Sold?"}]}]}$$
), 500) AS sense_cogs;
