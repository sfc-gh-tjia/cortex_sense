-- =============================================================================
-- 06_deploy_streamlit.sql
-- Deploys the Streamlit dashboard to Snowflake.
-- Before running: PUT the streamlit/supply_chain_dashboard.py to the stage.
-- =============================================================================

USE SCHEMA DB_ONTOLOGY_CONTROL_PLANE.SAP_PRODUCTION;

-- Upload the dashboard file
-- Run this from SnowSQL or CoCo:
-- PUT file://streamlit/supply_chain_dashboard.py @STREAMLIT_STAGE AUTO_COMPRESS=FALSE OVERWRITE=TRUE;

CREATE OR REPLACE STREAMLIT SUPPLY_CHAIN_DASHBOARD
  ROOT_LOCATION = '@STREAMLIT_STAGE'
  MAIN_FILE = 'supply_chain_dashboard.py'
  QUERY_WAREHOUSE = ONTOLOGY_WH
  COMMENT = 'Supply chain analytics dashboard with Supplier Health Index, Concentration Risk, and warehouse zone thresholds';
