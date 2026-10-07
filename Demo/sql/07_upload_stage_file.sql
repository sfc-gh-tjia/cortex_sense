-- =============================================================================
-- 07_upload_stage_file.sql
-- Uploads the knowledge document to the Cortex Sense stage.
-- =============================================================================

USE SCHEMA DB_ONTOLOGY_CONTROL_PLANE.SAP_PRODUCTION;

-- Upload the knowledge doc
-- Run this from SnowSQL or CoCo:
-- PUT file://stage_files/sap_supply_chain_knowledge.md @SENSE_SOURCES AUTO_COMPRESS=FALSE OVERWRITE=TRUE;

-- Verify upload
LIST @SENSE_SOURCES;
