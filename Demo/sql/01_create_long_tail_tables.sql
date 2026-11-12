-- =============================================================================
-- 01_create_long_tail_tables.sql
-- Creates tables NOT covered by the Semantic View (SAP_BASELINE_SV).
-- Cortex Sense discovers these through schema metadata alone.
-- =============================================================================

USE DATABASE DB_ONTOLOGY_CONTROL_PLANE;
USE SCHEMA SAP_PRODUCTION;
USE WAREHOUSE ONTOLOGY_WH;

-- =====================================================================
-- 1. SUPPLIER_SCORECARDS — Quarterly performance reviews (text + scores)
--    Links to SAP vendors via LIFNR. Contains reviewer notes (free text).
--    NOT in the SV. Demonstrates: schema discovery + unstructured text in tables.
-- =====================================================================
CREATE OR REPLACE TABLE SUPPLIER_SCORECARDS (
    REVIEW_ID       VARCHAR(15)   PRIMARY KEY,
    LIFNR           VARCHAR(10)   NOT NULL,  -- SAP vendor number
    REVIEW_QUARTER  VARCHAR(6)    NOT NULL,  -- e.g. '2025Q4'
    DELIVERY_SCORE  NUMBER(3,1),             -- 1.0 to 5.0
    QUALITY_SCORE   NUMBER(3,1),
    RESPONSIVENESS  NUMBER(3,1),
    OVERALL_RATING  VARCHAR(15),             -- Excellent/Good/Acceptable/Poor
    REVIEWER        VARCHAR(50),
    REVIEWER_NOTES  VARCHAR(2000)            -- Free text — the gold here
);

INSERT INTO SUPPLIER_SCORECARDS VALUES
('SCR-001','V10045','2025Q4',4.5,4.2,4.8,'Excellent','J. Martinez','Shenzhen Electronics continues to be our most reliable strategic partner. Zero missed deliveries in Q4. Recommended for expanded capacity agreement. NOTE: monitor US-China trade policy changes.'),
('SCR-002','V10045','2025Q3',4.2,3.8,4.5,'Good','J. Martinez','Minor quality dip in Sept batch (ceramic caps). Root cause identified — humidity in shipping. Corrective action verified.'),
('SCR-003','V10102','2025Q4',4.0,4.5,3.5,'Good','A. Schmidt','Rhine Chemical quality is consistently top-tier. Responsiveness has declined — 72hr avg response vs 24hr SLA. Escalated to account manager.'),
('SCR-004','V10078','2025Q4',3.8,4.0,4.2,'Good','R. Chen','Pacific Metals solid performer. Price increases above market for copper alloy — negotiate at next QBR.'),
('SCR-005','V10156','2025Q4',4.8,4.9,4.7,'Excellent','T. Nakamura','Osaka Precision is our gold-standard supplier. Zero defects for 6 consecutive quarters. Sole source for MEMS sensors — document backup plan per procurement policy.'),
('SCR-006','V10201','2025Q4',3.2,3.5,3.0,'Acceptable','M. Gonzalez','Monterrey Packaging — 2 late deliveries this quarter. Customs delays cited. Exploring backup corrugated supplier in Texas.'),
('SCR-007','V10089','2025Q4',4.3,4.0,4.5,'Good','R. Chen','Adv. Silicon Solutions — strong partner for semiconductor supply. Lead time creeping up from 8 to 12 weeks. May need to increase safety stock.'),
('SCR-008','V10134','2025Q4',3.5,4.2,3.8,'Good','A. Schmidt','Bayern Kunststoffe reliable on quality. Price competitiveness declining vs Asian alternatives.'),
('SCR-009','V10167','2025Q4',3.0,2.5,3.2,'Acceptable','J. Martinez','Guangzhou Rare Earth — quality issues with last 2 batches. Placed on enhanced monitoring. Consider qualification of backup supplier.'),
('SCR-010','V10223','2025Q4',4.0,4.1,4.3,'Good','R. Chen','Lone Star Industrial — dependable domestic source. Premium pricing offset by shorter lead times and no customs risk.'),
('SCR-011','V10245','2025Q4',2.0,1.5,2.5,'Poor','M. Gonzalez','Puebla Corrugated — PROBATIONARY STATUS. Failed 2 of 3 quality audits. Do not issue new POs until re-qualification complete. See incident INC-018.'),
('SCR-012','V10098','2025Q4',4.1,4.3,3.9,'Good','T. Nakamura','Tokyo Sensor Tech — good secondary source for sensors. Pricing 15% above Osaka but provides geographic diversification.'),
('SCR-013','V10312','2025Q3',3.8,4.0,4.0,'Good','R. Chen','Acme Logistics — reliable carrier for domestic routes. GPS tracking integration pending.'),
('SCR-014','V10278','2025Q4',3.3,3.0,3.5,'Acceptable','J. Martinez','Jiangsu Copper — acceptable quality but 3 shipments with incorrect documentation this quarter. Training requested.'),
('SCR-015','V10190','2025Q4',4.4,4.6,4.2,'Excellent','A. Schmidt','Schwarzwald Precision — exceptional quality. Recommended for expanded scope into next-gen tooling program.');

-- =====================================================================
-- 2. INCIDENT_LOG — Quality incidents linked to suppliers + materials
--    Cross-references SAP vendor LIFNR and material MATNR.
--    NOT in the SV. Demonstrates: operational data discovery.
-- =====================================================================
CREATE OR REPLACE TABLE INCIDENT_LOG (
    INCIDENT_ID     VARCHAR(10)   PRIMARY KEY,
    INCIDENT_DATE   DATE          NOT NULL,
    SEVERITY        VARCHAR(10)   NOT NULL,  -- CRITICAL / HIGH / MEDIUM / LOW
    LIFNR           VARCHAR(10),             -- SAP vendor involved
    MATNR           VARCHAR(10),             -- Material involved
    PLANT           VARCHAR(10),             -- Plant where detected
    CATEGORY        VARCHAR(30),             -- Quality / Delivery / Documentation / Safety
    ROOT_CAUSE      VARCHAR(200),
    RESOLUTION      VARCHAR(200),
    STATUS          VARCHAR(15),             -- Open / Investigating / Resolved / Closed
    DAYS_TO_RESOLVE NUMBER(5,0),
    CORRECTIVE_ACTION VARCHAR(500)
);

INSERT INTO INCIDENT_LOG VALUES
('INC-001','2025-07-15','CRITICAL','V10167','MAT-010','P-002','Quality','Contaminated stainless steel batch — carbon content 0.12% vs spec max 0.08%','Batch quarantined and returned. Replacement shipment expedited.','Closed',5,'Supplier required to implement incoming raw material testing. Added carbon content to receiving inspection checklist.'),
('INC-002','2025-08-03','HIGH','V10045','MAT-001','P-001','Quality','Ceramic capacitor lot failure — 3.2% defect rate vs 0.5% spec','Defective lot isolated. Supplier credited. Root cause: humidity exposure during ocean transit.','Closed',8,'Switched to moisture-barrier packaging for all ceramic component shipments. Added humidity indicator cards.'),
('INC-003','2025-08-20','MEDIUM','V10201','MAT-005','P-003','Delivery','Corrugated boxes arrived 6 days late — customs hold at Laredo border crossing','Expedited clearance arranged. Production schedule adjusted.','Closed',6,'Pre-cleared customs documentation now required 48hrs before shipment. Added backup US-based corrugated supplier.'),
('INC-004','2025-09-01','LOW','V10278','MAT-007','P-001','Documentation','Copper alloy CoC (Certificate of Conformance) missing mill test report page 3','Supplier faxed missing page within 4 hours. No production impact.','Closed',1,'Updated supplier portal to require all CoC pages uploaded before shipment release.'),
('INC-005','2025-09-10','HIGH','V10167','MAT-013','P-002','Quality','MEMS sensor lot — 8 of 200 units failed vibration testing. Suspect soldering defect.','Lot returned. Replacement from Osaka Precision (V10156) used.','Closed',12,'Supplier placed on enhanced monitoring. Next 3 lots require 100% incoming inspection.'),
('INC-006','2025-09-25','CRITICAL','V10245','MAT-005','P-003','Quality','Corrugated box structural failure — 2 pallets collapsed during warehouse stacking','Damaged inventory scrapped ($4,200 loss). Emergency order to Lone Star Industrial.','Closed',3,'Puebla Corrugated placed on PROBATIONARY status (ZPRB). Must pass 3 consecutive audits for reinstatement.'),
('INC-007','2025-10-05','MEDIUM','V10089','MAT-004','P-001','Delivery','Silicon wafer shipment delayed 10 days — fab capacity constraints at supplier','Buffer stock absorbed delay. No line stoppage.','Closed',10,'Increased safety stock from 2-week to 4-week for all semiconductor components.'),
('INC-008','2025-10-12','LOW','V10134','MAT-002','P-002','Documentation','Epoxy resin SDS (Safety Data Sheet) not updated to GHS Rev 8 format','Updated SDS received within 48 hours. No safety impact.','Closed',2,'Added SDS revision check to receiving process.'),
('INC-009','2025-10-28','HIGH','V10167','MAT-010','P-002','Quality','Second contamination incident — chromium content out of spec','Batch rejected. Supplier given final warning before de-qualification.','Resolved',15,'Supplier must submit third-party lab certification for next 6 shipments. Qualification review scheduled for 2026-Q1.'),
('INC-010','2025-11-05','MEDIUM','V10201','MAT-009','P-003','Delivery','Anti-static foam inserts wrong dimension — 380x280mm vs spec 400x300mm','Supplier reshipped correct size. Original lot usable for smaller product variant.','Closed',4,'Added dimensional verification step to supplier quality plan.'),
('INC-011','2025-11-15','LOW','V10102','MAT-006','P-001','Documentation','IPA purity certificate showed 99.5% vs our spec of 99.7% minimum','Supplier confirmed lab error on certificate. Actual purity 99.8% per re-test.','Closed',3,'Supplier to implement dual-sign-off on all purity certificates.'),
('INC-012','2025-11-22','CRITICAL','V10245','MAT-005','P-001','Quality','Second structural failure — box burst strength 150 PSI vs 200 PSI minimum','All Puebla inventory quarantined. Full supplier audit triggered.','Investigating',NULL,'Audit scheduled 2026-01-15. All new POs suspended per probationary policy. See scorecard SCR-011.'),
('INC-013','2025-12-01','MEDIUM','V10078','MAT-003','P-002','Delivery','Aluminum sheet delivery 4 days late — truck breakdown en route','Carrier (Acme Logistics) arranged replacement vehicle. Minor schedule impact.','Closed',4,'Added GPS tracking requirement for all high-value metal shipments.'),
('INC-014','2025-12-10','HIGH','V10045','MAT-008','P-001','Delivery','Microcontroller shipment held at port — new export license requirement from China','Shipment cleared after 7 days. Safety stock depleted to 3-day coverage.','Closed',7,'Legal team reviewing export control changes. Evaluating dual-source strategy with US-based fab.'),
('INC-015','2025-12-18','LOW','V10312','MAT-005','P-003','Delivery','Carrier (Acme Logistics) — wrong delivery dock. Shipment re-routed internally.','No material impact. Delivery completed same day.','Closed',0,'Updated delivery instructions in carrier portal.'),
('INC-016','2026-01-08','MEDIUM','V10134','MAT-002','P-002','Quality','Epoxy resin viscosity out of spec — 12,500 cP vs 10,000-11,500 cP range','Batch quarantined. Production used alternate lot from safety stock.','Closed',5,'Supplier root cause: temperature excursion during transport. Added thermal monitoring requirement.'),
('INC-017','2026-01-20','HIGH','V10167','MAT-013','P-002','Quality','Third quality incident in 6 months for Guangzhou Rare Earth. Sensor calibration drift.','Lot rejected. Backup supplier (Tokyo Sensor) fulfilled order.','Resolved',10,'Formal supplier improvement plan required. If Q1 audit fails, de-qualification recommended.'),
('INC-018','2026-02-01','CRITICAL','V10245','MAT-005','P-003','Quality','Third quality failure. Full audit found systemic issues: no SPC on burst strength, outdated calibration on test equipment.','All remaining inventory scrapped. Supplier suspended.','Open',NULL,'De-qualification proceeding. Seeking permanent replacement. See procurement policy section 4.3 — three-strike rule.'),
('INC-019','2026-02-15','MEDIUM','V10089','MAT-008','P-001','Delivery','Microcontroller lead time extended to 16 weeks (was 12). Global chip shortage impact.','Placed additional buffer orders. Evaluating second source.','Open',NULL,'Demand planning to increase forecast buffer by 20% for all semiconductor components.'),
('INC-020','2026-03-01','LOW','V10223','MAT-011','P-001','Documentation','Lone Star Industrial — packaging label missing lot number on 3 of 50 cartons','Supplier relabeled at their facility before next shipment.','Closed',1,'Added barcode scanning verification to outbound process at supplier.');

-- =====================================================================
-- 3. DEMAND_FORECAST — Monthly demand forecast by material
--    Links to MARA via MATNR. Planning team owns this, never in the SV.
--    NOT in the SV. Demonstrates: undocumented planning data discovery.
-- =====================================================================
CREATE OR REPLACE TABLE DEMAND_FORECAST (
    FORECAST_ID   VARCHAR(15)   PRIMARY KEY,
    MATNR         VARCHAR(10)   NOT NULL,
    FORECAST_MONTH DATE         NOT NULL,
    PLANNED_QTY   NUMBER(10,0),
    ACTUAL_QTY    NUMBER(10,0),
    VARIANCE_PCT  NUMBER(6,2),
    CONFIDENCE     VARCHAR(10),  -- High / Medium / Low
    NOTES         VARCHAR(500)
);

INSERT INTO DEMAND_FORECAST VALUES
('FC-001','MAT-001','2025-10-01',5000,4800,-4.00,'High','Stable demand for ceramic capacitors'),
('FC-002','MAT-001','2025-11-01',5200,5100,-1.92,'High',NULL),
('FC-003','MAT-001','2025-12-01',4800,5500,14.58,'High','Holiday surge unexpected — need safety stock review'),
('FC-004','MAT-004','2025-10-01',800,750,-6.25,'Medium','MEMS sensor demand tracking below forecast'),
('FC-005','MAT-004','2025-11-01',850,820,-3.53,'Medium',NULL),
('FC-006','MAT-004','2025-12-01',900,1100,22.22,'Low','New automotive customer order not in forecast — major miss'),
('FC-007','MAT-008','2025-10-01',2000,1950,-2.50,'High','Microcontroller demand steady'),
('FC-008','MAT-008','2025-11-01',2100,2050,-2.38,'High',NULL),
('FC-009','MAT-008','2025-12-01',2200,2800,27.27,'Medium','Chip shortage causing customer pull-forward orders'),
('FC-010','MAT-003','2025-10-01',3000,2900,-3.33,'High','Aluminum sheet — predictable demand'),
('FC-011','MAT-003','2025-11-01',3100,3050,-1.61,'High',NULL),
('FC-012','MAT-003','2025-12-01',2800,2700,-3.57,'High',NULL),
('FC-013','MAT-005','2025-10-01',10000,9800,-2.00,'High','Corrugated box demand tracks shipments'),
('FC-014','MAT-005','2025-11-01',10500,10200,-2.86,'High',NULL),
('FC-015','MAT-005','2025-12-01',11000,12500,13.64,'Medium','Holiday shipping surge — under-forecast again'),
('FC-016','MAT-006','2025-10-01',400,380,-5.00,'Medium','IPA consumption follows production volume'),
('FC-017','MAT-006','2025-11-01',420,410,-2.38,'Medium',NULL),
('FC-018','MAT-006','2025-12-01',380,450,18.42,'Low','Unplanned cleaning cycle for new product line'),
('FC-019','MAT-002','2025-10-01',600,580,-3.33,'High','Epoxy resin — stable'),
('FC-020','MAT-002','2025-11-01',620,600,-3.23,'High',NULL),
('FC-021','MAT-002','2025-12-01',650,700,7.69,'Medium','Slight over-consumption for rework'),
('FC-022','MAT-007','2025-10-01',1500,1450,-3.33,'High','Copper alloy strip demand predictable'),
('FC-023','MAT-007','2025-11-01',1550,1500,-3.23,'High',NULL),
('FC-024','MAT-007','2025-12-01',1400,1600,14.29,'Medium','Unexpected connector assembly order'),
('FC-025','MAT-010','2025-10-01',2500,2400,-4.00,'High','Stainless steel rod steady'),
('FC-026','MAT-010','2025-11-01',2600,2550,-1.92,'High',NULL),
('FC-027','MAT-010','2025-12-01',2400,2200,-8.33,'High','Planned maintenance reduced consumption'),
('FC-028','MAT-013','2025-10-01',500,480,-4.00,'Medium','Rare earth sensors — niche demand'),
('FC-029','MAT-013','2025-11-01',520,500,-3.85,'Medium',NULL),
('FC-030','MAT-013','2025-12-01',550,700,27.27,'Low','Autonomous vehicle program accelerated — major forecast miss');

-- =====================================================================
-- 4. Ensure existing long-tail tables are accessible cross-schema
--    These already exist in RAW_SOURCES. Create views in SAP_PRODUCTION
--    so Cortex Sense can discover them in the same schema scope.
-- =====================================================================
CREATE OR REPLACE VIEW SAP_PRODUCTION.ARIBA_SUPPLIERS AS
SELECT * FROM RAW_SOURCES.ARIBA_SUPPLIERS;

CREATE OR REPLACE VIEW SAP_PRODUCTION.DNB_RISK_ASSESSMENTS AS
SELECT * FROM RAW_SOURCES.DNB_RISK_ASSESSMENTS;

CREATE OR REPLACE VIEW SAP_PRODUCTION.MATERIAL_CATEGORIES AS
SELECT * FROM RAW_SOURCES.MATERIAL_CATEGORIES;

CREATE OR REPLACE VIEW SAP_PRODUCTION.MATERIAL_CATEGORY_MAP AS
SELECT * FROM RAW_SOURCES.MATERIAL_CATEGORY_MAP;

CREATE OR REPLACE VIEW SAP_PRODUCTION.SAP_VENDOR_MAPPING AS
SELECT * FROM RAW_SOURCES.SAP_VENDOR_MAPPING;

-- Verify
SELECT 'SUPPLIER_SCORECARDS' AS TBL, COUNT(*) AS ROWS FROM SUPPLIER_SCORECARDS
UNION ALL SELECT 'INCIDENT_LOG', COUNT(*) FROM INCIDENT_LOG
UNION ALL SELECT 'DEMAND_FORECAST', COUNT(*) FROM DEMAND_FORECAST
UNION ALL SELECT 'ARIBA_SUPPLIERS', COUNT(*) FROM ARIBA_SUPPLIERS
UNION ALL SELECT 'DNB_RISK_ASSESSMENTS', COUNT(*) FROM DNB_RISK_ASSESSMENTS
UNION ALL SELECT 'MATERIAL_CATEGORIES', COUNT(*) FROM MATERIAL_CATEGORIES;
