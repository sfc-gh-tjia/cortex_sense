-- =============================================================================
-- 03_create_knowledge_base.sql
-- SUPERSEDED: This file created a Cortex Search service over knowledge base docs.
-- That approach is no longer used. Business knowledge is now delivered via a stage
-- file (stage_files/sap_supply_chain_knowledge.md) that Cortex Sense ingests
-- directly through its stage_files source. The Cortex Search service and
-- KNOWLEDGE_BASE_DOCS table have been dropped.
-- =============================================================================
-- Original: Uploads the unstructured documents to Snowflake and creates a Cortex Search
-- service over them. This is the "knowledge base" that Cortex Sense ingests.
-- =============================================================================

USE DATABASE DB_ONTOLOGY_CONTROL_PLANE;
USE SCHEMA SAP_PRODUCTION;
USE WAREHOUSE ONTOLOGY_WH;

-- 1. Create a stage for the documents
CREATE OR REPLACE STAGE KNOWLEDGE_BASE_STAGE
    DIRECTORY = (ENABLE = TRUE)
    COMMENT = 'Supply chain policy documents, SOPs, and reference guides';

-- 2. Upload documents (run from SnowSQL or CoCo terminal):
-- PUT file:///path/to/demo/docs/procurement_policy.md @KNOWLEDGE_BASE_STAGE AUTO_COMPRESS=FALSE;
-- PUT file:///path/to/demo/docs/supplier_qualification.md @KNOWLEDGE_BASE_STAGE AUTO_COMPRESS=FALSE;
-- PUT file:///path/to/demo/docs/warehouse_operations.md @KNOWLEDGE_BASE_STAGE AUTO_COMPRESS=FALSE;
-- PUT file:///path/to/demo/docs/sap_field_guide.md @KNOWLEDGE_BASE_STAGE AUTO_COMPRESS=FALSE;
-- PUT file:///path/to/demo/docs/metric_definitions.md @KNOWLEDGE_BASE_STAGE AUTO_COMPRESS=FALSE;

-- 3. Create the documents table with chunked content
CREATE OR REPLACE TABLE KNOWLEDGE_BASE_DOCS (
    DOC_ID       VARCHAR(50)   PRIMARY KEY,
    FILE_NAME    VARCHAR(200)  NOT NULL,
    DOC_TITLE    VARCHAR(200),
    DOC_CATEGORY VARCHAR(50),   -- Policy / SOP / Reference / Metrics
    SECTION      VARCHAR(200),
    CONTENT      VARCHAR(16000) NOT NULL,
    CREATED_AT   TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

-- 4. Insert document chunks (manually chunked by section for better retrieval)
-- Procurement Policy
INSERT INTO KNOWLEDGE_BASE_DOCS (DOC_ID, FILE_NAME, DOC_TITLE, DOC_CATEGORY, SECTION, CONTENT) VALUES
('PP-001','procurement_policy.md','Procurement Policy Manual','Policy','Discount Approval Authority','Discount approval thresholds: 0-5% auto-approved by Buyer. 5.01-10% requires Procurement Manager approval within 24 hours. 10.01-20% requires VP Procurement approval within 48 hours with written justification including competitive pricing evidence. Above 20% requires CFO plus VP Procurement approval within 72 hours.'),
('PP-002','procurement_policy.md','Procurement Policy Manual','Policy','Sole-Source Policy','Critical materials must not be single-sourced. If a material has only one qualified supplier, the procurement team must: (1) initiate qualification for at least one backup supplier within 90 days, (2) maintain 6 weeks of safety stock instead of standard 2-4 weeks, (3) report the single-source risk to the Supply Chain Risk Committee quarterly. Exception: materials with annual spend below $50,000 are exempt.'),
('PP-003','procurement_policy.md','Procurement Policy Manual','Policy','Payment Terms','Payment terms by supplier classification: ZSTR Strategic suppliers get Net-30 standard, Net-60 available with VP approval. ZSTD Standard suppliers get Net-30 only. ZPRB Probationary suppliers get Net-15 prepay only. Strategic suppliers with 3+ years history and zero critical incidents may qualify for Net-60.'),
('PP-004','procurement_policy.md','Procurement Policy Manual','Policy','Three-Strike Rule','Any supplier accumulating 3 critical quality incidents within a rolling 12-month period is automatically placed on ZPRB Probationary status. All new POs are suspended pending a full audit. The supplier must pass a comprehensive re-qualification audit to be reinstated.'),
('PP-005','procurement_policy.md','Procurement Policy Manual','Policy','Emergency Procurement','Emergency procurement for production-critical shortages: SVP Operations sign-off required within 4 hours. Maximum emergency PO value $100,000 without competitive bidding. Expedite premium up to 25% above standard pricing authorized. Post-emergency review within 5 business days. Tag with reason code EMRG in SAP.');

-- Supplier Qualification
INSERT INTO KNOWLEDGE_BASE_DOCS (DOC_ID, FILE_NAME, DOC_TITLE, DOC_CATEGORY, SECTION, CONTENT) VALUES
('SQ-001','supplier_qualification.md','Supplier Qualification Handbook','SOP','Vendor Account Group Codes','KTOKK vendor account group codes: ZSTR = Strategic (top-tier, executive relationship, unlimited PO value). ZSTD = Standard (qualified, passed probation, max $500K per order). ZPRB = Probationary (new or demoted, enhanced monitoring, max $25K per order). When counting active or qualified suppliers, ZPRB vendors must be EXCLUDED. Canonical count uses KTOKK IN (ZSTR, ZSTD).'),
('SQ-002','supplier_qualification.md','Supplier Qualification Handbook','SOP','Qualification Matrix','Supplier qualification criteria by tier: ZSTR requires defect rate below 1%, on-time above 95%, D&B financial health score 7 or higher. ZSTD requires defect rate below 2%, on-time above 85%, D&B score 5 or higher. ZPRB requires defect rate below 5%, on-time above 70%, D&B score 3 or higher.'),
('SQ-003','supplier_qualification.md','Supplier Qualification Handbook','SOP','Probationary Rules','ZPRB probationary period: minimum 90 days, extendable to 180 days. PO limit $25,000 per order, no blanket POs. 100% incoming inspection required. Monthly quality reviews. Exit requires 3 consecutive passing quality audits with defect rate below 2%. If 2 audits fail during probation, the supplier is de-qualified.'),
('SQ-004','supplier_qualification.md','Supplier Qualification Handbook','SOP','Re-Qualification Schedule','Re-qualification frequency: ZSTR Strategic every 18 months (full supply chain audit plus financial review). ZSTD Standard every 12 months (quality audit plus delivery review). ZPRB Probationary every 90 days (full quality audit plus corrective action verification). Tracked by CERTIFICATION_EXPIRY in ARIBA_SUPPLIERS.'),
('SQ-005','supplier_qualification.md','Supplier Qualification Handbook','Reference','Cross-System Entity Resolution','Same supplier appears under different IDs: SAP uses LIFNR (e.g. V10045), Ariba uses SUPPLIER_PROFILE_ID (e.g. ARIBA-SP-2001), D&B Risk uses SUPPLIER_NAME (e.g. Shenzhen Electronics). The SAP_VENDOR_MAPPING table links SUP-xxx to LIFNR. Name matching is unreliable due to abbreviations.');

-- Warehouse Operations
INSERT INTO KNOWLEDGE_BASE_DOCS (DOC_ID, FILE_NAME, DOC_TITLE, DOC_CATEGORY, SECTION, CONTENT) VALUES
('WH-001','warehouse_operations.md','Warehouse Operations SOP','SOP','Capacity Utilization Targets','Warehouse capacity targets: Below 60% is under-utilized (consider consolidation). 60-85% is optimal. 85-90% is elevated (monitor daily, prepare overflow). 90-95% triggers rebalancing alert (shift inventory). Above 95% is critical (no new inbound receipts until below 90%, escalate to VP Operations). LKAPA field in T320 stores current capacity percentage.'),
('WH-002','warehouse_operations.md','Warehouse Operations SOP','SOP','Hazardous Material Rules','Hazmat rules: Maximum 30% of any location capacity may be hazmat. Chemical solvents (MATKL 044, including IPA) require ventilation and spill containment. Hazmat must be segregated from food-grade and electronics. MSDS/SDS must be current.'),
('WH-003','warehouse_operations.md','Warehouse Operations SOP','SOP','Temperature-Sensitive Storage','Climate-controlled storage only at WH-003 and WH-007: 15-25 degrees C, humidity below 45%. Required for MEMS sensors (MAT-004, MAT-013), ceramic capacitors (MAT-001), epoxy resins (MAT-002). All other locations are ambient temperature only.'),
('WH-004','warehouse_operations.md','Warehouse Operations SOP','SOP','Shipment Status Codes','LIKP shipment status codes: DLVD = Delivered (goods received). INTR = In Transit (shipped, not received). PEND = Pending (confirmed, not shipped). CNCL = Cancelled. PART = Partially delivered.');

-- SAP Field Guide
INSERT INTO KNOWLEDGE_BASE_DOCS (DOC_ID, FILE_NAME, DOC_TITLE, DOC_CATEGORY, SECTION, CONTENT) VALUES
('FG-001','sap_field_guide.md','SAP Field Code Reference','Reference','BSCHL Posting Keys','BSCHL posting key codes in BSEG: 31 = Vendor Invoice (include in COGS as positive). 34 = Credit Memo (subtract from COGS). COGS formula: SUM(DMBTR WHERE BSCHL=31) minus SUM(DMBTR WHERE BSCHL=34). Common mistake: only including 31 without subtracting 34 overstates COGS by $63,670.'),
('FG-002','sap_field_guide.md','SAP Field Code Reference','Reference','MATKL Material Groups','MATKL material group codes: 043 = Electronics (semiconductors, sensors, MCUs). 044 = Chemicals (solvents, adhesives, resins). 045 = Metals (aluminum, copper, steel). 046 = Packaging (boxes, foam, inserts).'),
('FG-003','sap_field_guide.md','SAP Field Code Reference','Reference','KSCHL Condition Types','KSCHL pricing condition types in KONV: K007 = Customer Discount (revenue loss). KF00 = Freight Surcharge (cost, not revenue loss). When calculating revenue lost to discounts, use K007 only. Do NOT include KF00.'),
('FG-004','sap_field_guide.md','SAP Field Code Reference','Reference','On-Time Delivery Calculation','On-time delivery: use WADAT (actual goods issue date) vs LFDAT (promised delivery date) from LIKP where STATU = DLVD. A shipment is on-time when WADAT <= LFDAT. Do NOT use OTRAT from LFA2 carrier table — that is carrier self-reported and inflated.');

-- Metric Definitions
INSERT INTO KNOWLEDGE_BASE_DOCS (DOC_ID, FILE_NAME, DOC_TITLE, DOC_CATEGORY, SECTION, CONTENT) VALUES
('MD-001','metric_definitions.md','Official Metric Definitions','Metrics','COGS Definition','Cost of Goods Sold (COGS): total invoiced minus credit memos. Formula: SUM(DMBTR WHERE BSCHL=31) - SUM(DMBTR WHERE BSCHL=34). Correct answer: $1,542,520. Common error: $1,606,190 from ignoring credit memos.'),
('MD-002','metric_definitions.md','Official Metric Definitions','Metrics','On-Time Delivery Definition','On-Time Delivery Rate: percentage of delivered shipments where WADAT <= LFDAT. Correct answer: 66.7%. Common error: 90% from using carrier self-reported OTRAT field. Use operational dates, not carrier metrics.'),
('MD-003','metric_definitions.md','Official Metric Definitions','Metrics','Supply Risk Score','Weighted Supply Risk Score: 0.4 * single_source_flag + 0.3 * defect_rate + 0.3 * (1 - on_time_rate). Weights are 40/30/30. Highest risk: MAT-006 at 0.70. Common error: using 40/35/25 weights.'),
('MD-004','metric_definitions.md','Official Metric Definitions','Metrics','Gross Margin Definition','Gross Margin: revenue minus BOM-rolled-up material cost. Use recursive BOM from STPO with component quantities times STPRS from MARA. Do NOT use assembly STPRS — that is inventory valuation, not true cost. Example: ASSY-004 has STPRS $520 but true BOM cost $286.60.'),
('MD-005','metric_definitions.md','Official Metric Definitions','Metrics','Discount Revenue Loss','Revenue lost to discounts: SUM(KWERT) FROM KONV WHERE KSCHL = K007 only. Correct: $34,085. Exclude KF00 freight surcharges. KF00 is cost, not revenue loss.');

-- 5. Create Cortex Search service
CREATE OR REPLACE CORTEX SEARCH SERVICE SAP_KNOWLEDGE_BASE_SEARCH
    ON CONTENT
    ATTRIBUTES DOC_TITLE, DOC_CATEGORY, SECTION, FILE_NAME
    WAREHOUSE = ONTOLOGY_WH
    TARGET_LAG = '1 hour'
    AS (
        SELECT
            DOC_ID,
            FILE_NAME,
            DOC_TITLE,
            DOC_CATEGORY,
            SECTION,
            CONTENT
        FROM KNOWLEDGE_BASE_DOCS
    );

-- 6. Verify
SELECT COUNT(*) AS doc_count FROM KNOWLEDGE_BASE_DOCS;
-- Expected: 23 documents
