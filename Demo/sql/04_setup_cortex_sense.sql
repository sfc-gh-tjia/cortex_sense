-- =============================================================================
-- 04_setup_cortex_sense.sql
-- Sets up the Cortex Sense context that ingests all 5 data sources.
-- Two paths: CoCo skill (recommended) or manual SQL.
-- =============================================================================

-- =====================================================================
-- PREREQUISITES
-- =====================================================================

USE ROLE ACCOUNTADMIN;

-- Grant Cortex Sense database roles
GRANT DATABASE ROLE SNOWFLAKE.CORTEX_SENSE_USER    TO ROLE ACCOUNTADMIN;
GRANT DATABASE ROLE SNOWFLAKE.CORTEX_SENSE_BUILDER TO ROLE ACCOUNTADMIN;

-- Verify roles
SELECT CURRENT_ROLE();
-- Should be ACCOUNTADMIN with CORTEX_SENSE_BUILDER inherited

-- =====================================================================
-- PATH A: CoCo /cortex-sense skill (RECOMMENDED)
-- Run these commands in Cortex Code (CoCo) chat:
-- =====================================================================
--
--   /cortex-sense
--   set up cortex sense for SAP supply chain analytics
--
-- CoCo will:
--   1. Discover SAP_BASELINE_SV (semantic view)
--   2. Discover Business Ontology domains (SAP Purchasing, Finance, Sales, Supply Chain)
--   3. Discover the SAP_KNOWLEDGE_BASE_SEARCH Cortex Search service
--   4. Auto-crawl schema metadata for ALL tables in SAP_PRODUCTION
--      (including SUPPLIER_SCORECARDS, INCIDENT_LOG, DEMAND_FORECAST,
--       DNB_RISK_ASSESSMENTS, ARIBA_SUPPLIERS — the long-tail tables)
--   5. Pick up query history patterns from the seeded queries
--   6. Show a draft scope for your approval
--   7. Build the context
--
-- After the build completes, verify with:
--   "test the SAP supply chain context"
--   "what tables does the context cover?"

-- =====================================================================
-- PATH B: Manual setup (fallback if CoCo skill not available)
-- =====================================================================
-- Note: The exact API syntax may vary by private preview version.
-- Contact the Cortex Sense team (Rajhans Samdani / Abhinav Vadrevu)
-- for the latest API reference.

-- Step 1: Verify Cortex Sense is enabled on your account
-- The CORTEX_SENSE_BUILDER database role should exist:
SHOW DATABASE ROLES IN DATABASE SNOWFLAKE LIKE '%CORTEX_SENSE%';

-- Step 2: Verify your data sources are ready
-- Semantic View
SHOW SEMANTIC VIEWS IN SCHEMA DB_ONTOLOGY_CONTROL_PLANE.SAP_PRODUCTION;
-- Should see: SAP_BASELINE_SV

-- Business Ontology
SELECT SYSTEM$GET_GLOSSARY_SUMMARY();
-- Should show domains: SAP Purchasing (15 terms), SAP Finance (7), SAP Sales (7), Supply Chain (23)

-- Knowledge Base (Cortex Search)
SHOW CORTEX SEARCH SERVICES IN SCHEMA DB_ONTOLOGY_CONTROL_PLANE.SAP_PRODUCTION;
-- Should see: SAP_KNOWLEDGE_BASE_SEARCH

-- Long-tail tables
SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = 'SAP_PRODUCTION'
  AND TABLE_NAME IN ('SUPPLIER_SCORECARDS','INCIDENT_LOG','DEMAND_FORECAST',
                     'ARIBA_SUPPLIERS','DNB_RISK_ASSESSMENTS','MATERIAL_CATEGORIES')
ORDER BY TABLE_NAME;
-- Should see all 6 (3 tables + 3 views)

-- Step 3: Create the Cortex Sense context
-- (via CoCo — the /cortex-sense skill handles the API calls)
-- After creation, the context object lives in:
--   DB_ONTOLOGY_CONTROL_PLANE.SAP_PRODUCTION.<context_name>

-- =====================================================================
-- POST-SETUP VERIFICATION
-- =====================================================================

-- Test that Cortex Sense context is serving:
-- In CoCo, ask the Sense agent these validation questions:
--
-- 1. "How many suppliers do we have?" → Should answer 14 (ontology formula)
-- 2. "What is COGS?" → Should answer $1,290,020 (ontology + docs)
-- 3. "What is the geopolitical risk for Shenzhen Electronics?" → Should query DNB (long-tail)
-- 4. "What is our discount policy for orders over 10%?" → Should retrieve from knowledge base
-- 5. "How many critical incidents this year?" → Should query INCIDENT_LOG (long-tail)
