-- =============================================================================
-- 06_test_queries.sql
-- Quick validation queries to confirm setup is working.
-- Run after all setup scripts are complete.
-- =============================================================================

USE DATABASE DB_ONTOLOGY_CONTROL_PLANE;
USE SCHEMA SAP_PRODUCTION;

-- 1. Verify all tables exist
SELECT 'Core SAP (in SV)' AS category, COUNT(*) AS tables
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = 'SAP_PRODUCTION'
  AND TABLE_NAME IN ('LFA1','MARA','EKPO','LIKP','T001W','T320','STPO','LFB1','QALS','LFA2','BSEG','COEP','VBAP','KONV')
UNION ALL
SELECT 'Long-tail (not in SV)', COUNT(*)
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = 'SAP_PRODUCTION'
  AND TABLE_NAME IN ('SUPPLIER_SCORECARDS','INCIDENT_LOG','DEMAND_FORECAST','ARIBA_SUPPLIERS','DNB_RISK_ASSESSMENTS','MATERIAL_CATEGORIES')
UNION ALL
SELECT 'Knowledge base', COUNT(*)
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = 'SAP_PRODUCTION' AND TABLE_NAME = 'KNOWLEDGE_BASE_DOCS';
-- Expected: Core SAP = 14, Long-tail = 6, Knowledge base = 1

-- 2. Verify Semantic View
SHOW SEMANTIC VIEWS LIKE 'SAP_BASELINE_SV' IN SCHEMA SAP_PRODUCTION;

-- 3. Verify Cortex Search service
SHOW CORTEX SEARCH SERVICES LIKE 'SAP_KNOWLEDGE_BASE%' IN SCHEMA SAP_PRODUCTION;

-- 4. Verify Business Ontology
SELECT SYSTEM$GET_GLOSSARY_SUMMARY();

-- 5. Verify knowledge base doc count
SELECT DOC_CATEGORY, COUNT(*) AS docs FROM KNOWLEDGE_BASE_DOCS GROUP BY DOC_CATEGORY;
-- Expected: Policy=5, SOP=7, Reference=6, Metrics=5 = 23 total

-- 6. Test a quick Cortex Search query
SELECT PARSE_JSON(
    SNOWFLAKE.CORTEX.SEARCH_PREVIEW(
        'DB_ONTOLOGY_CONTROL_PLANE.SAP_PRODUCTION.SAP_KNOWLEDGE_BASE_SEARCH',
        '{"query": "discount approval policy", "columns": ["DOC_TITLE","SECTION","CONTENT"], "limit": 2}'
    )
);

-- 7. Test baseline agent
SELECT SYSTEM$CORTEX_AGENT_INVOKE(
    'BASELINE_SUPPLY_CHAIN_AGENT',
    '{"messages": [{"role": "user", "content": "How many purchase orders do we have?"}]}'
);

-- 8. Test sense agent
SELECT SYSTEM$CORTEX_AGENT_INVOKE(
    'SENSE_SUPPLY_CHAIN_AGENT',
    '{"messages": [{"role": "user", "content": "How many purchase orders do we have?"}]}'
);
