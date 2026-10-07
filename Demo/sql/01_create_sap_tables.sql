-- =============================================================================
-- 01_create_sap_tables.sql
-- Creates all SAP_PRODUCTION tables with seed data.
-- =============================================================================

USE SCHEMA DB_ONTOLOGY_CONTROL_PLANE.SAP_PRODUCTION;

-- BSEG
CREATE OR REPLACE TABLE BSEG (
	BELNR VARCHAR(10) NOT NULL,
	BUZEI VARCHAR(3) NOT NULL,
	EBELN VARCHAR(20),
	LIFNR VARCHAR(10),
	HKONT VARCHAR(15),
	DMBTR NUMBER(12,2),
	BUDAT DATE,
	BSCHL VARCHAR(3),
	GJAHR NUMBER(4,0),
	MONAT NUMBER(2,0),
	primary key (BELNR, BUZEI)
);

INSERT INTO BSEG (BELNR, BUZEI, EBELN, LIFNR, HKONT, DMBTR, BUDAT, BSCHL, GJAHR, MONAT)
VALUES
  ('5100000001', '001', 'PO-2024-001', 'V10045', '0040100000', '11000.00', '2024-10-15', '31', 2024, 10),
  ('5100000002', '001', 'PO-2024-002', 'V10078', '0040100000', '89000.00', '2024-10-20', '31', 2024, 10),
  ('5100000003', '001', 'PO-2024-003', 'V10089', '0040100000', '48600.00', '2024-11-01', '31', 2024, 11),
  ('5100000004', '001', 'PO-2024-004', 'V10098', '0040100000', '72000.00', '2024-11-10', '31', 2024, 11),
  ('5100000005', '001', 'PO-2024-005', 'V10102', '0040100000', '26250.00', '2024-11-15', '31', 2024, 11),
  ('5100000006', '001', 'PO-2024-006', 'V10134', '0040100000', '62000.00', '2024-12-01', '31', 2024, 12),
  ('5100000007', '001', 'PO-2024-007', 'V10156', '0040100000', '57300.00', '2024-12-10', '31', 2024, 12),
  ('5100000008', '001', 'PO-2024-008', 'V10167', '0040100000', '97500.00', '2024-12-15', '31', 2024, 12),
  ('5100000009', '001', 'PO-2024-009', 'V10278', '0040100000', '55000.00', '2025-01-01', '31', 2025, 1),
  ('5100000010', '001', 'PO-2024-010', 'V10334', '0040100000', '59000.00', '2025-01-05', '31', 2025, 1),
  ('5100000011', '001', 'PO-2024-011', 'V10102', '0040100000', '11040.00', '2024-12-20', '31', 2024, 12),
  ('5100000012', '001', 'PO-2024-012', 'V10201', '0040100000', '30400.00', '2025-01-10', '31', 2025, 1),
  ('5100000013', '001', 'PO-2025-001', 'V10045', '0040100000', '41000.00', '2025-02-10', '31', 2025, 2),
  ('5100000014', '001', 'PO-2025-002', 'V10201', '0040100000', '84000.00', '2025-02-20', '31', 2025, 2),
  ('5100000015', '001', 'PO-2025-003', 'V10190', '0040100000', '49000.00', '2025-03-01', '31', 2025, 3),
  ('5100000016', '001', 'PO-2025-004', 'V10312', '0040100000', '34400.00', '2025-03-15', '31', 2025, 3),
  ('5100000017', '001', 'PO-2025-005', 'V10089', '0040100000', '34500.00', '2025-04-01', '31', 2025, 4),
  ('5100000018', '001', 'PO-2025-006', 'V10134', '0040100000', '93000.00', '2025-04-15', '31', 2025, 4),
  ('5100000019', '001', 'PO-2025-007', 'V10078', '0040100000', '67200.00', '2025-05-01', '31', 2025, 5),
  ('5100000020', '001', 'PO-2025-008', 'V10223', '0040100000', '33000.00', '2025-05-05', '31', 2025, 5),
  ('5100000021', '001', 'PO-2025-009', 'V10098', '0040100000', '90000.00', '2025-05-10', '31', 2025, 5),
  ('5100000022', '001', 'PO-2025-010', 'V10167', '0040100000', '80000.00', '2025-05-12', '31', 2025, 5),
  ('5100000023', '001', 'PO-2025-011', 'V10045', '0040100000', '22000.00', '2025-05-15', '31', 2025, 5),
  ('5100000024', '001', 'PO-2025-012', 'V10278', '0040100000', '84000.00', '2025-05-16', '31', 2025, 5),
  ('5100000025', '001', 'PO-2025-013', 'V10245', '0040100000', '22500.00', '2025-04-01', '31', 2025, 4),
  ('5100000030', '001', 'PO-2024-003', 'V10089', '0040100000', '12150.00', '2024-12-01', '34', 2024, 12),
  ('5100000031', '001', 'PO-2024-008', 'V10167', '0040100000', '19500.00', '2025-01-15', '34', 2025, 1),
  ('5100000032', '001', 'PO-2025-003', 'V10190', '0040100000', '9800.00', '2025-04-01', '34', 2025, 4),
  ('5100000033', '001', 'PO-2025-007', 'V10078', '0040100000', '6720.00', '2025-06-01', '34', 2025, 6),
  ('5100000034', '001', 'PO-2024-006', 'V10134', '0040100000', '15500.00', '2025-02-01', '34', 2025, 2),
  ('5100000040', '001', 'PO-2024-001', 'V10045', '0040200000', '2200.00', '2024-10-20', '31', 2024, 10),
  ('5100000041', '001', 'PO-2024-004', 'V10098', '0040200000', '8500.00', '2024-11-15', '31', 2024, 11),
  ('5100000042', '001', 'PO-2025-002', 'V10201', '0040200000', '12600.00', '2025-03-01', '31', 2025, 3),
  ('5100000043', '001', 'PO-2025-009', 'V10098', '0040200000', '11000.00', '2025-05-15', '31', 2025, 5),
  ('5100000044', '001', 'PO-2025-006', 'V10134', '0040200000', '5500.00', '2025-04-20', '31', 2025, 4),
  ('5100000050', '001', 'PO-2024-001', 'V10045', '0021100000', '13200.00', '2024-10-15', '31', 2024, 10),
  ('5100000051', '001', 'PO-2025-009', 'V10098', '0021100000', '101000.00', '2025-05-10', '31', 2025, 5),
  ('5100000052', '001', 'PO-2025-006', 'V10134', '0021100000', '98500.00', '2025-04-15', '31', 2025, 4);

-- COEP
CREATE OR REPLACE TABLE COEP (
	OBJNR VARCHAR(20),
	KSTAR VARCHAR(15),
	WRTBTR NUMBER(12,2),
	GJAHR NUMBER(4,0),
	PERIO NUMBER(2,0),
	MATNR VARCHAR(10)
);

INSERT INTO COEP (OBJNR, KSTAR, WRTBTR, GJAHR, PERIO, MATNR)
VALUES
  ('KS-MFG-US', '0040100000', '172550.00', 2025, 1, 'MAT-003'),
  ('KS-MFG-US', '0040100000', '127500.00', 2025, 2, 'MAT-004'),
  ('KS-MFG-US', '0040100000', '93000.00', 2025, 3, 'MAT-008'),
  ('KS-MFG-US', '0047000000', '18500.00', 2025, 1, NULL),
  ('KS-MFG-US', '0048000000', '8200.00', 2025, 1, NULL),
  ('KS-MFG-EU', '0040100000', '213500.00', 2025, 1, 'MAT-002'),
  ('KS-MFG-EU', '0040100000', '67200.00', 2025, 2, 'MAT-017'),
  ('KS-MFG-EU', '0040100000', '34400.00', 2025, 3, 'MAT-018'),
  ('KS-MFG-EU', '0047000000', '22300.00', 2025, 1, NULL),
  ('KS-MFG-EU', '0048000000', '11500.00', 2025, 2, NULL),
  ('KS-MFG-AP', '0040100000', '177500.00', 2025, 1, 'MAT-011'),
  ('KS-MFG-AP', '0040100000', '139000.00', 2025, 2, 'MAT-007'),
  ('KS-MFG-AP', '0040100000', '74000.00', 2025, 3, 'MAT-001'),
  ('KS-MFG-AP', '0047000000', '31200.00', 2025, 1, NULL),
  ('KS-MFG-AP', '0048000000', '14800.00', 2025, 2, NULL),
  ('KS-LOG', '0047000000', '39800.00', 2025, 1, NULL),
  ('KS-LOG', '0047000000', '42100.00', 2025, 2, NULL),
  ('KS-QA', '0048000000', '22000.00', 2025, 1, NULL),
  ('KS-QA', '0048000000', '18500.00', 2025, 2, NULL);

-- DEMAND_FORECAST
CREATE OR REPLACE TABLE DEMAND_FORECAST (
	FORECAST_ID VARCHAR(15) NOT NULL,
	MATNR VARCHAR(10) NOT NULL,
	FORECAST_MONTH DATE NOT NULL,
	PLANNED_QTY NUMBER(10,0),
	ACTUAL_QTY NUMBER(10,0),
	VARIANCE_PCT NUMBER(6,2),
	CONFIDENCE VARCHAR(10),
	NOTES VARCHAR(500),
	primary key (FORECAST_ID)
);

INSERT INTO DEMAND_FORECAST (FORECAST_ID, MATNR, FORECAST_MONTH, PLANNED_QTY, ACTUAL_QTY, VARIANCE_PCT, CONFIDENCE, NOTES)
VALUES
  ('FC-001', 'MAT-001', '2025-10-01', 5000, 4800, '-4.00', 'High', 'Stable demand for ceramic capacitors'),
  ('FC-002', 'MAT-001', '2025-11-01', 5200, 5100, '-1.92', 'High', NULL),
  ('FC-003', 'MAT-001', '2025-12-01', 4800, 5500, '14.58', 'High', 'Holiday surge unexpected'),
  ('FC-004', 'MAT-004', '2025-10-01', 800, 750, '-6.25', 'Medium', 'MEMS sensor demand below forecast'),
  ('FC-005', 'MAT-004', '2025-11-01', 850, 820, '-3.53', 'Medium', NULL),
  ('FC-006', 'MAT-004', '2025-12-01', 900, 1100, '22.22', 'Low', 'New automotive customer not in forecast'),
  ('FC-007', 'MAT-008', '2025-10-01', 2000, 1950, '-2.50', 'High', 'Microcontroller demand steady'),
  ('FC-008', 'MAT-008', '2025-11-01', 2100, 2050, '-2.38', 'High', NULL),
  ('FC-009', 'MAT-008', '2025-12-01', 2200, 2800, '27.27', 'Medium', 'Chip shortage causing pull-forward'),
  ('FC-010', 'MAT-003', '2025-10-01', 3000, 2900, '-3.33', 'High', 'Aluminum sheet predictable'),
  ('FC-011', 'MAT-003', '2025-11-01', 3100, 3050, '-1.61', 'High', NULL),
  ('FC-012', 'MAT-003', '2025-12-01', 2800, 2700, '-3.57', 'High', NULL),
  ('FC-013', 'MAT-005', '2025-10-01', 10000, 9800, '-2.00', 'High', 'Corrugated box demand tracks shipments'),
  ('FC-014', 'MAT-005', '2025-11-01', 10500, 10200, '-2.86', 'High', NULL),
  ('FC-015', 'MAT-005', '2025-12-01', 11000, 12500, '13.64', 'Medium', 'Holiday shipping surge'),
  ('FC-016', 'MAT-006', '2025-10-01', 400, 380, '-5.00', 'Medium', 'IPA follows production volume'),
  ('FC-017', 'MAT-006', '2025-11-01', 420, 410, '-2.38', 'Medium', NULL),
  ('FC-018', 'MAT-006', '2025-12-01', 380, 450, '18.42', 'Low', 'Unplanned cleaning cycle'),
  ('FC-019', 'MAT-002', '2025-10-01', 600, 580, '-3.33', 'High', 'Epoxy resin stable'),
  ('FC-020', 'MAT-002', '2025-11-01', 620, 600, '-3.23', 'High', NULL),
  ('FC-021', 'MAT-002', '2025-12-01', 650, 700, '7.69', 'Medium', 'Slight over-consumption for rework'),
  ('FC-022', 'MAT-007', '2025-10-01', 1500, 1450, '-3.33', 'High', 'Copper alloy strip predictable'),
  ('FC-023', 'MAT-007', '2025-11-01', 1550, 1500, '-3.23', 'High', NULL),
  ('FC-024', 'MAT-007', '2025-12-01', 1400, 1600, '14.29', 'Medium', 'Unexpected connector assembly order'),
  ('FC-025', 'MAT-010', '2025-10-01', 2500, 2400, '-4.00', 'High', 'Stainless steel rod steady'),
  ('FC-026', 'MAT-010', '2025-11-01', 2600, 2550, '-1.92', 'High', NULL),
  ('FC-027', 'MAT-010', '2025-12-01', 2400, 2200, '-8.33', 'High', 'Planned maintenance reduced consumption'),
  ('FC-028', 'MAT-013', '2025-10-01', 500, 480, '-4.00', 'Medium', 'Rare earth sensors niche demand'),
  ('FC-029', 'MAT-013', '2025-11-01', 520, 500, '-3.85', 'Medium', NULL),
  ('FC-030', 'MAT-013', '2025-12-01', 550, 700, '27.27', 'Low', 'Autonomous vehicle program accelerated');

-- EKPO
CREATE OR REPLACE TABLE EKPO (
	EBELN VARCHAR(20) NOT NULL,
	EBELP VARCHAR(5) NOT NULL,
	LIFNR VARCHAR(10),
	MATNR VARCHAR(10),
	WERKS VARCHAR(10),
	BEDAT DATE,
	MENGE NUMBER(38,0),
	NETWR NUMBER(12,2),
	STATU VARCHAR(5),
	primary key (EBELN, EBELP)
);

INSERT INTO EKPO (EBELN, EBELP, LIFNR, MATNR, WERKS, BEDAT, MENGE, NETWR, STATU)
VALUES
  ('PO-2024-001', '10', 'V10045', 'MAT-001', 'PLT-003', '2024-09-15', 100000, '11000.00', 'R'),
  ('PO-2024-002', '10', 'V10078', 'MAT-002', 'PLT-002', '2024-09-20', 5000, '89000.00', 'R'),
  ('PO-2024-003', '10', 'V10089', 'MAT-003', 'PLT-001', '2024-10-01', 1200, '48600.00', 'R'),
  ('PO-2024-004', '10', 'V10098', 'MAT-004', 'PLT-005', '2024-10-10', 20000, '72000.00', 'R'),
  ('PO-2024-005', '10', 'V10102', 'MAT-005', 'PLT-004', '2024-10-15', 15000, '26250.00', 'R'),
  ('PO-2024-006', '10', 'V10134', 'MAT-008', 'PLT-001', '2024-11-01', 10000, '62000.00', 'R'),
  ('PO-2024-007', '10', 'V10156', 'MAT-002', 'PLT-002', '2024-11-10', 3000, '57300.00', 'R'),
  ('PO-2024-008', '10', 'V10167', 'MAT-011', 'PLT-003', '2024-11-15', 50000, '97500.00', 'R'),
  ('PO-2024-009', '10', 'V10278', 'MAT-007', 'PLT-003', '2024-12-01', 2000, '55000.00', 'R'),
  ('PO-2024-010', '10', 'V10334', 'MAT-010', 'PLT-005', '2024-12-05', 5000, '59000.00', 'R'),
  ('PO-2024-011', '10', 'V10102', 'MAT-014', 'PLT-004', '2024-11-20', 800, '11040.00', 'R'),
  ('PO-2024-012', '10', 'V10201', 'MAT-004', 'PLT-001', '2024-12-10', 8000, '30400.00', 'O'),
  ('PO-2025-001', '10', 'V10045', 'MAT-013', 'PLT-003', '2025-01-10', 50000, '41000.00', 'R'),
  ('PO-2025-002', '10', 'V10201', 'MAT-016', 'PLT-005', '2025-01-20', 4000, '84000.00', 'R'),
  ('PO-2025-003', '10', 'V10190', 'MAT-006', 'PLT-001', '2025-02-01', 10000, '49000.00', 'R'),
  ('PO-2025-004', '10', 'V10312', 'MAT-018', 'PLT-002', '2025-02-15', 8000, '34400.00', 'R'),
  ('PO-2025-005', '10', 'V10089', 'MAT-015', 'PLT-001', '2025-03-01', 300, '34500.00', 'R'),
  ('PO-2025-006', '10', 'V10134', 'MAT-008', 'PLT-001', '2025-03-15', 15000, '93000.00', 'O'),
  ('PO-2025-007', '10', 'V10078', 'MAT-017', 'PLT-002', '2025-04-01', 8000, '67200.00', 'O'),
  ('PO-2025-008', '10', 'V10223', 'MAT-005', 'PLT-004', '2025-04-05', 20000, '33000.00', 'O'),
  ('PO-2025-009', '10', 'V10098', 'MAT-004', 'PLT-005', '2025-04-10', 25000, '90000.00', 'O'),
  ('PO-2025-010', '10', 'V10167', 'MAT-011', 'PLT-003', '2025-04-12', 40000, '80000.00', 'O'),
  ('PO-2025-011', '10', 'V10045', 'MAT-001', 'PLT-001', '2025-04-15', 200000, '22000.00', 'O'),
  ('PO-2025-012', '10', 'V10278', 'MAT-007', 'PLT-003', '2025-04-16', 3000, '84000.00', 'O'),
  ('PO-2025-013', '10', 'V10245', 'MAT-009', 'PLT-001', '2025-03-01', 25000, '22500.00', 'R');

-- INCIDENT_LOG
CREATE OR REPLACE TABLE INCIDENT_LOG (
	INCIDENT_ID VARCHAR(10) NOT NULL,
	INCIDENT_DATE DATE NOT NULL,
	SEVERITY VARCHAR(10) NOT NULL,
	LIFNR VARCHAR(10),
	MATNR VARCHAR(10),
	PLANT VARCHAR(10),
	CATEGORY VARCHAR(30),
	ROOT_CAUSE VARCHAR(200),
	RESOLUTION VARCHAR(200),
	STATUS VARCHAR(15),
	DAYS_TO_RESOLVE NUMBER(5,0),
	CORRECTIVE_ACTION VARCHAR(500),
	primary key (INCIDENT_ID)
);

INSERT INTO INCIDENT_LOG (INCIDENT_ID, INCIDENT_DATE, SEVERITY, LIFNR, MATNR, PLANT, CATEGORY, ROOT_CAUSE, RESOLUTION, STATUS, DAYS_TO_RESOLVE, CORRECTIVE_ACTION)
VALUES
  ('INC-001', '2025-07-15', 'CRITICAL', 'V10167', 'MAT-010', 'P-002', 'Quality', 'Contaminated stainless steel batch — carbon content 0.12% vs spec max 0.08%', 'Batch quarantined and returned. Replacement shipment expedited.', 'Closed', 5, 'Supplier required to implement incoming raw material testing. Added carbon content to receiving inspection checklist.'),
  ('INC-002', '2025-08-03', 'HIGH', 'V10045', 'MAT-001', 'P-001', 'Quality', 'Ceramic capacitor lot failure — 3.2% defect rate vs 0.5% spec', 'Defective lot isolated. Supplier credited. Root cause: humidity exposure during ocean transit.', 'Closed', 8, 'Switched to moisture-barrier packaging for all ceramic component shipments.'),
  ('INC-003', '2025-08-20', 'MEDIUM', 'V10201', 'MAT-005', 'P-003', 'Delivery', 'Corrugated boxes arrived 6 days late — customs hold at Laredo border crossing', 'Expedited clearance arranged. Production schedule adjusted.', 'Closed', 6, 'Pre-cleared customs documentation now required 48hrs before shipment.'),
  ('INC-004', '2025-09-01', 'LOW', 'V10278', 'MAT-007', 'P-001', 'Documentation', 'Copper alloy CoC missing mill test report page 3', 'Supplier faxed missing page within 4 hours. No production impact.', 'Closed', 1, 'Updated supplier portal to require all CoC pages uploaded before shipment release.'),
  ('INC-005', '2025-09-10', 'HIGH', 'V10167', 'MAT-013', 'P-002', 'Quality', 'MEMS sensor lot — 8 of 200 units failed vibration testing', 'Lot returned. Replacement from Osaka Precision used.', 'Closed', 12, 'Supplier placed on enhanced monitoring. Next 3 lots require 100% incoming inspection.'),
  ('INC-006', '2025-09-25', 'CRITICAL', 'V10245', 'MAT-005', 'P-003', 'Quality', 'Corrugated box structural failure — 2 pallets collapsed during warehouse stacking', 'Damaged inventory scrapped ($4,200 loss). Emergency order to Lone Star Industrial.', 'Closed', 3, 'Puebla Corrugated placed on PROBATIONARY status (ZPRB).'),
  ('INC-007', '2025-10-05', 'MEDIUM', 'V10089', 'MAT-004', 'P-001', 'Delivery', 'Silicon wafer shipment delayed 10 days — fab capacity constraints', 'Buffer stock absorbed delay. No line stoppage.', 'Closed', 10, 'Increased safety stock from 2-week to 4-week for all semiconductor components.'),
  ('INC-008', '2025-10-12', 'LOW', 'V10134', 'MAT-002', 'P-002', 'Documentation', 'Epoxy resin SDS not updated to GHS Rev 8 format', 'Updated SDS received within 48 hours.', 'Closed', 2, 'Added SDS revision check to receiving process.'),
  ('INC-009', '2025-10-28', 'HIGH', 'V10167', 'MAT-010', 'P-002', 'Quality', 'Second contamination incident — chromium content out of spec', 'Batch rejected. Supplier given final warning.', 'Resolved', 15, 'Supplier must submit third-party lab certification for next 6 shipments.'),
  ('INC-010', '2025-11-05', 'MEDIUM', 'V10201', 'MAT-009', 'P-003', 'Delivery', 'Anti-static foam inserts wrong dimension — 380x280mm vs spec 400x300mm', 'Supplier reshipped correct size.', 'Closed', 4, 'Added dimensional verification step to supplier quality plan.'),
  ('INC-011', '2025-11-15', 'LOW', 'V10102', 'MAT-006', 'P-001', 'Documentation', 'IPA purity certificate showed 99.5% vs 99.7% spec', 'Supplier confirmed lab error. Actual purity 99.8% per re-test.', 'Closed', 3, 'Supplier to implement dual-sign-off on purity certificates.'),
  ('INC-012', '2025-11-22', 'CRITICAL', 'V10245', 'MAT-005', 'P-001', 'Quality', 'Second structural failure — box burst strength 150 PSI vs 200 PSI minimum', 'All Puebla inventory quarantined. Full supplier audit triggered.', 'Investigating', NULL, 'Audit scheduled 2026-01-15. All new POs suspended per probationary policy.'),
  ('INC-013', '2025-12-01', 'MEDIUM', 'V10078', 'MAT-003', 'P-002', 'Delivery', 'Aluminum sheet delivery 4 days late — truck breakdown', 'Carrier arranged replacement vehicle.', 'Closed', 4, 'Added GPS tracking requirement for high-value metal shipments.'),
  ('INC-014', '2025-12-10', 'HIGH', 'V10045', 'MAT-008', 'P-001', 'Delivery', 'Microcontroller shipment held at port — new export license requirement', 'Shipment cleared after 7 days. Safety stock depleted to 3-day coverage.', 'Closed', 7, 'Legal reviewing export control changes. Evaluating dual-source strategy.'),
  ('INC-015', '2025-12-18', 'LOW', 'V10312', 'MAT-005', 'P-003', 'Delivery', 'Carrier wrong delivery dock. Re-routed internally.', 'No material impact.', 'Closed', 0, 'Updated delivery instructions in carrier portal.'),
  ('INC-016', '2026-01-08', 'MEDIUM', 'V10134', 'MAT-002', 'P-002', 'Quality', 'Epoxy resin viscosity out of spec — 12,500 cP vs 10,000-11,500 cP', 'Batch quarantined. Used alternate lot from safety stock.', 'Closed', 5, 'Added thermal monitoring requirement for transport.'),
  ('INC-017', '2026-01-20', 'HIGH', 'V10167', 'MAT-013', 'P-002', 'Quality', 'Third quality incident in 6 months. Sensor calibration drift.', 'Lot rejected. Tokyo Sensor fulfilled order.', 'Resolved', 10, 'Formal supplier improvement plan required.'),
  ('INC-018', '2026-02-01', 'CRITICAL', 'V10245', 'MAT-005', 'P-003', 'Quality', 'Third quality failure. Systemic issues found in full audit.', 'All remaining inventory scrapped. Supplier suspended.', 'Open', NULL, 'De-qualification proceeding. See procurement policy section 4.3.'),
  ('INC-019', '2026-02-15', 'MEDIUM', 'V10089', 'MAT-008', 'P-001', 'Delivery', 'Microcontroller lead time extended to 16 weeks. Global chip shortage.', 'Placed additional buffer orders.', 'Open', NULL, 'Demand planning to increase forecast buffer by 20%.'),
  ('INC-020', '2026-03-01', 'LOW', 'V10223', 'MAT-011', 'P-001', 'Documentation', 'Packaging label missing lot number on 3 of 50 cartons', 'Supplier relabeled.', 'Closed', 1, 'Added barcode scanning verification.');

-- KONV
CREATE OR REPLACE TABLE KONV (
	KNUMV VARCHAR(10) NOT NULL,
	KPOSN VARCHAR(5) NOT NULL,
	KSCHL VARCHAR(5) NOT NULL,
	KBETR NUMBER(8,2),
	KWERT NUMBER(12,2),
	MATNR VARCHAR(10),
	KUNNR VARCHAR(10),
	primary key (KNUMV, KPOSN, KSCHL)
);

INSERT INTO KONV (KNUMV, KPOSN, KSCHL, KBETR, KWERT, MATNR, KUNNR)
VALUES
  ('KN-001', '010', 'PR00', '1200.00', '60000.00', 'ASSY-004', 'C-1001'),
  ('KN-002', '010', 'PR00', '1200.00', '96000.00', 'ASSY-004', 'C-1002'),
  ('KN-003', '010', 'PR00', '1200.00', '36000.00', 'ASSY-004', 'C-1003'),
  ('KN-004', '010', 'PR00', '1200.00', '144000.00', 'ASSY-004', 'C-1001'),
  ('KN-005', '010', 'PR00', '1200.00', '54000.00', 'ASSY-004', 'C-1004'),
  ('KN-001', '020', 'PR00', '850.00', '85000.00', 'ASSY-003', 'C-1001'),
  ('KN-002', '020', 'PR00', '850.00', '51000.00', 'ASSY-003', 'C-1002'),
  ('KN-006', '010', 'PR00', '850.00', '63750.00', 'ASSY-003', 'C-1005'),
  ('KN-007', '010', 'PR00', '850.00', '34000.00', 'ASSY-003', 'C-1003'),
  ('KN-008', '010', 'PR00', '120.00', '24000.00', 'ASSY-001', 'C-1001'),
  ('KN-009', '010', 'PR00', '120.00', '60000.00', 'ASSY-001', 'C-1004'),
  ('KN-010', '010', 'PR00', '85.00', '25500.00', 'ASSY-002', 'C-1002'),
  ('KN-011', '010', 'PR00', '85.00', '12750.00', 'ASSY-002', 'C-1005'),
  ('KN-001', '010', 'K007', '5.00', '-3000.00', 'ASSY-004', 'C-1001'),
  ('KN-002', '010', 'K007', '8.00', '-7680.00', 'ASSY-004', 'C-1002'),
  ('KN-004', '010', 'K007', '5.00', '-7200.00', 'ASSY-004', 'C-1001'),
  ('KN-005', '010', 'K007', '3.00', '-1620.00', 'ASSY-004', 'C-1004'),
  ('KN-001', '020', 'K007', '5.00', '-4250.00', 'ASSY-003', 'C-1001'),
  ('KN-006', '010', 'K007', '4.00', '-2550.00', 'ASSY-003', 'C-1005'),
  ('KN-009', '010', 'K007', '10.00', '-6000.00', 'ASSY-001', 'C-1004'),
  ('KN-010', '010', 'K007', '7.00', '-1785.00', 'ASSY-002', 'C-1002'),
  ('KN-003', '010', 'KF00', '2.00', '720.00', 'ASSY-004', 'C-1003'),
  ('KN-007', '010', 'KF00', '3.00', '1020.00', 'ASSY-003', 'C-1003'),
  ('KN-008', '010', 'KF00', '2.00', '480.00', 'ASSY-001', 'C-1001'),
  ('KN-011', '010', 'KF00', '3.00', '382.50', 'ASSY-002', 'C-1005');

-- LFA1
CREATE OR REPLACE TABLE LFA1 (
	LIFNR VARCHAR(10) NOT NULL,
	NAME1 VARCHAR(100),
	ORT01 VARCHAR(50),
	LAND1 VARCHAR(5),
	STCD1 VARCHAR(30),
	KRAUS VARCHAR(15),
	KTOKK VARCHAR(10),
	ZTERM VARCHAR(10),
	primary key (LIFNR)
);

INSERT INTO LFA1 (LIFNR, NAME1, ORT01, LAND1, STCD1, KRAUS, KTOKK, ZTERM)
VALUES
  ('V10045', 'SHENZHEN ELECTRONICS CO. LTD', 'Shenzhen', 'CN', '91440300MA5FPQG72B', '54-138-7209', 'ZSTR', 'NET45'),
  ('V10102', 'RHINE CHEMICAL GMBH', 'Ludwigshafen', 'DE', 'DE283741956', '31-592-4780', 'ZSTR', 'NET30'),
  ('V10078', 'PACIFIC METALS CORPORATION', 'Long Beach', 'US', '95-4821073', '07-823-6541', 'ZSTD', 'NET30'),
  ('V10156', 'OSAKA PRECISION INSTRUMENTS CO.', 'Osaka', 'JP', 'JP8120001098765', '69-247-1058', 'ZSTR', 'NET60'),
  ('V10201', 'MONTERREY PACKAGING S.A. DE C.V.', 'Monterrey', 'MX', 'MPS040512QR7', '82-461-3097', 'ZSTD', 'NET30'),
  ('V10089', 'ADVANCED SILICON SOLUTIONS INC.', 'Santa Clara', 'US', '77-3920184', '15-738-2904', 'ZSTR', 'NET45'),
  ('V10134', 'BAYERN KUNSTSTOFFE AG', 'Munich', 'DE', 'DE192847563', '44-591-7823', 'ZSTD', 'NET30'),
  ('V10167', 'GUANGZHOU RARE EARTH MATERIALS LTD', 'Guangzhou', 'CN', '91440101MA9URXG44N', '63-904-2175', 'ZSTD', 'NET60'),
  ('V10223', 'LONE STAR INDUSTRIAL SUPPLY CO.', 'Houston', 'US', '76-1948302', '28-617-4930', 'ZSTD', 'NET30'),
  ('V10098', 'TOKYO SENSOR TECHNOLOGIES K.K.', 'Tokyo', 'JP', 'JP5010401098234', '71-385-6249', 'ZSTD', 'NET45'),
  ('V10245', 'PUEBLA CORRUGATED PRODUCTS SA', 'Puebla', 'MX', 'PCP090318HV5', NULL, 'ZPRB', 'NET30'),
  ('V10312', 'ACME LOGISTICS INC', 'Chicago', 'US', '36-4829107', '09-284-5716', 'ZSTD', 'NET30'),
  ('V10278', 'JIANGSU COPPER ALLOYS CO. LTD', 'Nanjing', 'CN', '91320100MA1MPKG28R', '56-813-4027', 'ZSTD', 'NET45'),
  ('V10190', 'SCHWARZWALD PRECISION TOOLS GMBH', 'Freiburg', 'DE', 'DE314725890', '37-462-8105', 'ZSTD', 'NET30'),
  ('V10334', 'NAGOYA STEEL WORKS LTD', 'Nagoya', 'JP', 'JP3180001054321', '48-729-3061', 'ZSTD', 'NET60');

-- LFA2
CREATE OR REPLACE TABLE LFA2 (
	TDLNR VARCHAR(10) NOT NULL,
	NAME1 VARCHAR(100),
	VSART VARCHAR(5),
	LZEIT NUMBER(38,0),
	OTRAT NUMBER(4,2),
	primary key (TDLNR)
);

INSERT INTO LFA2 (TDLNR, NAME1, VSART, LZEIT, OTRAT)
VALUES
  ('CAR-001', 'TransGlobal Freight Inc.', '01', 28, '0.87'),
  ('CAR-002', 'EuroHaul Logistics GmbH', '02', 4, '0.94'),
  ('CAR-003', 'SkyBridge Air Cargo', '03', 3, '0.96'),
  ('CAR-004', 'Pacific Intermodal Corp.', '04', 18, '0.91'),
  ('CAR-005', 'MexLine Transportes S.A.', '05', 6, '0.83'),
  ('CAR-006', 'Shenzhen Coastal Shipping Ltd.', '01', 22, '0.89');

-- LFB1
CREATE OR REPLACE TABLE LFB1 (
	LIFNR VARCHAR(10) NOT NULL,
	VKONT VARCHAR(10) NOT NULL,
	VTART VARCHAR(5),
	DTEND DATE,
	JWERT NUMBER(12,2),
	primary key (LIFNR, VKONT)
);

INSERT INTO LFB1 (LIFNR, VKONT, VTART, DTEND, JWERT)
VALUES
  ('V10045', 'CTR-001', 'M', '2026-12-31', '4500000.00'),
  ('V10078', 'CTR-002', 'M', '2026-06-30', '3200000.00'),
  ('V10089', 'CTR-003', 'F', '2026-03-31', '2800000.00'),
  ('V10098', 'CTR-004', 'M', '2027-12-31', '5200000.00'),
  ('V10102', 'CTR-005', 'F', '2025-05-31', '450000.00'),
  ('V10134', 'CTR-006', 'M', '2027-02-28', '7000000.00'),
  ('V10156', 'CTR-007', 'F', '2025-12-31', '1200000.00'),
  ('V10167', 'CTR-008', 'S', '2025-09-30', '980000.00'),
  ('V10201', 'CTR-009', 'M', '2026-03-31', '3800000.00'),
  ('V10245', 'CTR-010', 'F', '2025-12-31', '2000000.00'),
  ('V10278', 'CTR-011', 'M', '2026-05-31', '1500000.00'),
  ('V10312', 'CTR-012', 'F', '2025-12-31', '800000.00'),
  ('V10334', 'CTR-013', 'M', '2026-09-30', '3500000.00'),
  ('V10223', 'CTR-014', 'S', '2025-07-15', '250000.00'),
  ('V10190', 'CTR-015', 'F', '2025-07-31', '600000.00');

-- LIKP
CREATE OR REPLACE TABLE LIKP (
	TKNUM VARCHAR(10) NOT NULL,
	TDLNR VARCHAR(10),
	LGORT_SRC VARCHAR(10),
	WERKS_DST VARCHAR(10),
	MATNR VARCHAR(10),
	MENGE NUMBER(38,0),
	LFDAT DATE,
	WADAT DATE,
	FRTCO NUMBER(10,2),
	STATU VARCHAR(5),
	primary key (TKNUM)
);

INSERT INTO LIKP (TKNUM, TDLNR, LGORT_SRC, WERKS_DST, MATNR, MENGE, LFDAT, WADAT, FRTCO, STATU)
VALUES
  ('SHP-001', 'CAR-006', 'WH-004', 'PLT-001', 'MAT-001', 100000, '2024-10-10', '2024-10-08', '2800.00', 'D'),
  ('SHP-002', 'CAR-002', 'WH-003', 'PLT-002', 'MAT-002', 5000, '2024-09-26', '2024-09-25', '1200.00', 'D'),
  ('SHP-003', 'CAR-003', 'WH-008', NULL, 'MAT-003', 1200, '2024-10-06', '2024-10-06', '3500.00', 'D'),
  ('SHP-004', 'CAR-004', 'WH-007', 'PLT-005', 'MAT-004', 20000, '2024-11-02', '2024-11-05', '4200.00', 'D'),
  ('SHP-005', 'CAR-005', 'WH-006', 'PLT-004', 'MAT-005', 15000, '2024-10-23', '2024-10-22', '850.00', 'D'),
  ('SHP-006', 'CAR-003', 'WH-001', NULL, 'MAT-008', 10000, '2024-11-11', '2024-11-11', '5100.00', 'D'),
  ('SHP-007', 'CAR-001', 'WH-004', NULL, 'MAT-011', 50000, '2024-12-18', '2024-12-22', '3100.00', 'D'),
  ('SHP-008', 'CAR-006', 'WH-005', NULL, 'MAT-007', 2000, '2024-12-27', '2024-12-26', '1900.00', 'D'),
  ('SHP-009', 'CAR-002', 'WH-003', 'PLT-002', 'MAT-018', 8000, '2025-02-22', '2025-02-21', '980.00', 'D'),
  ('SHP-010', 'CAR-004', 'WH-007', NULL, 'MAT-016', 4000, '2025-02-12', '2025-02-14', '3800.00', 'D'),
  ('SHP-011', 'CAR-001', 'WH-008', NULL, 'MAT-006', 10000, '2025-03-05', '2025-03-08', '2400.00', 'D'),
  ('SHP-012', 'CAR-003', 'WH-001', 'PLT-001', 'MAT-015', 300, '2025-03-23', '2025-03-23', '1800.00', 'D'),
  ('SHP-013', 'CAR-006', 'WH-004', 'PLT-003', 'MAT-013', 50000, '2025-02-06', '2025-02-04', '2200.00', 'D'),
  ('SHP-014', 'CAR-005', 'WH-006', 'PLT-004', 'MAT-014', 800, '2024-11-28', '2024-11-30', '450.00', 'D'),
  ('SHP-015', 'CAR-002', 'WH-003', 'PLT-002', 'MAT-002', 3000, '2025-03-29', '2025-03-28', '1100.00', 'D'),
  ('SHP-016', 'CAR-001', 'WH-005', NULL, 'MAT-011', 40000, '2025-05-12', NULL, '3050.00', 'T'),
  ('SHP-017', 'CAR-004', 'WH-007', 'PLT-005', 'MAT-004', 25000, '2025-05-03', NULL, '4500.00', 'T'),
  ('SHP-018', 'CAR-003', 'WH-001', NULL, 'MAT-008', 8000, '2025-04-13', NULL, '4800.00', 'X'),
  ('SHP-019', 'CAR-006', 'WH-004', NULL, 'MAT-007', 3000, '2025-05-10', NULL, '2600.00', 'T'),
  ('SHP-020', 'CAR-005', 'WH-006', 'PLT-004', 'MAT-005', 20000, '2025-04-14', NULL, '920.00', 'X');

-- MARA
CREATE OR REPLACE TABLE MARA (
	MATNR VARCHAR(10) NOT NULL,
	MAKTX VARCHAR(100),
	MATKL VARCHAR(5),
	STPRS NUMBER(10,2),
	primary key (MATNR)
);

INSERT INTO MARA (MATNR, MAKTX, MATKL, STPRS)
VALUES
  ('MAT-001', 'Multilayer Ceramic Capacitor 100nF', '043', '0.12'),
  ('MAT-002', 'Epoxy Resin ER-4500', '044', '18.50'),
  ('MAT-003', 'Aluminum Sheet 6061-T6 2mm', '045', '42.00'),
  ('MAT-004', 'MEMS Accelerometer IC', '043', '3.75'),
  ('MAT-005', 'Corrugated Box 400x300x200mm', '046', '1.85'),
  ('MAT-006', 'Isopropyl Alcohol 99.7%', '044', '5.20'),
  ('MAT-007', 'Copper Alloy Strip C17200', '045', '28.90'),
  ('MAT-008', 'ARM Cortex-M4 Microcontroller', '043', '6.40'),
  ('MAT-009', 'Anti-Static Foam Insert', '046', '0.95'),
  ('MAT-010', 'Stainless Steel Rod 304L 10mm', '045', '12.30'),
  ('MAT-011', 'Neodymium Rare Earth Magnet N52', '047', '2.10'),
  ('MAT-012', 'Silicone Thermal Paste TG-7', '044', '85.00'),
  ('MAT-013', 'Power MOSFET IRF540N', '043', '0.85'),
  ('MAT-014', 'Polyethylene Stretch Wrap 500mm', '046', '14.50'),
  ('MAT-015', 'Titanium Alloy Ti-6Al-4V Plate', '045', '120.00'),
  ('MAT-016', 'Fiber Optic Transceiver SFP+ 10G', '043', '22.00'),
  ('MAT-017', 'Hydrochloric Acid 37% ACS Grade', '044', '8.75'),
  ('MAT-018', 'Precision Ball Bearing 6205-2RS', '047', '4.50'),
  ('MAT-019', 'Carbon Fiber Sheet 3K Twill 2mm', '047', '65.00'),
  ('MAT-020', 'ESD Protective Bag 200x300mm', '046', '0.35'),
  ('ASSY-001', 'Sensor Module Assembly', '048', '45.00'),
  ('ASSY-002', 'Power Distribution Board', '048', '32.00'),
  ('ASSY-003', 'Ruggedized Enclosure', '048', '380.00'),
  ('ASSY-004', 'Integrated System Module', '048', '520.00');

-- QALS
CREATE OR REPLACE TABLE QALS (
	PRUEFLOS VARCHAR(10) NOT NULL,
	MATNR VARCHAR(10),
	QAESSION NUMBER(6,3),
	VCODE VARCHAR(5),
	primary key (PRUEFLOS)
);

INSERT INTO QALS (PRUEFLOS, MATNR, QAESSION, VCODE)
VALUES
  ('INS-001', 'MAT-001', '0.006', 'A'),
  ('INS-002', 'MAT-002', '0.060', 'C'),
  ('INS-003', 'MAT-003', '0.001', 'A'),
  ('INS-004', 'MAT-004', '0.150', 'A'),
  ('INS-005', 'MAT-005', '0.011', 'A'),
  ('INS-006', 'MAT-006', '0.005', 'A'),
  ('INS-007', 'MAT-007', '0.050', 'C'),
  ('INS-008', 'MAT-008', '0.000', 'A'),
  ('INS-009', 'MAT-001', '0.010', 'A'),
  ('INS-010', 'MAT-003', '0.002', 'A');

-- QUAL_MATRIX
CREATE OR REPLACE TABLE QUAL_MATRIX (
	MATNR VARCHAR(10) NOT NULL,
	LIFNR VARCHAR(10) NOT NULL,
	QUAL_STATUS VARCHAR(10),
	QUAL_DATE DATE,
	primary key (MATNR, LIFNR)
);

INSERT INTO QUAL_MATRIX (MATNR, LIFNR, QUAL_STATUS, QUAL_DATE)
VALUES
  ('MAT-001', 'V10045', 'APPROVED', '2023-06-15'),
  ('MAT-001', 'V10048', 'APPROVED', '2024-01-20'),
  ('MAT-001', 'V10052', 'PENDING', '2025-03-01'),
  ('MAT-013', 'V10045', 'APPROVED', '2023-06-15'),
  ('MAT-008', 'V10055', 'APPROVED', '2024-05-10'),
  ('MAT-008', 'V10045', 'EXPIRED', '2022-12-01'),
  ('MAT-004', 'V10055', 'APPROVED', '2023-09-01'),
  ('MAT-004', 'V10057', 'APPROVED', '2024-07-15'),
  ('MAT-011', 'V10050', 'APPROVED', '2023-08-01'),
  ('MAT-003', 'V10053', 'APPROVED', '2023-04-01'),
  ('MAT-003', 'V10060', 'APPROVED', '2024-11-01'),
  ('MAT-007', 'V10051', 'APPROVED', '2023-05-20'),
  ('MAT-015', 'V10053', 'APPROVED', '2023-10-15'),
  ('MAT-015', 'V10058', 'PENDING', '2025-06-01'),
  ('MAT-002', 'V10054', 'APPROVED', '2023-07-01'),
  ('MAT-002', 'V10056', 'APPROVED', '2024-03-10'),
  ('MAT-005', 'V10059', 'APPROVED', '2023-11-01'),
  ('MAT-005', 'V10057', 'APPROVED', '2024-08-20'),
  ('MAT-006', 'V10049', 'APPROVED', '2023-06-01'),
  ('MAT-009', 'V10057', 'APPROVED', '2024-02-15'),
  ('MAT-010', 'V10055', 'APPROVED', '2023-12-01'),
  ('MAT-012', 'V10049', 'APPROVED', '2023-05-01'),
  ('MAT-012', 'V10054', 'APPROVED', '2024-04-15'),
  ('MAT-014', 'V10057', 'APPROVED', '2023-08-20'),
  ('MAT-016', 'V10057', 'APPROVED', '2024-01-10'),
  ('MAT-017', 'V10049', 'APPROVED', '2023-09-01'),
  ('MAT-018', 'V10055', 'APPROVED', '2023-07-15'),
  ('MAT-019', 'V10049', 'APPROVED', '2023-06-01');

-- STPO
CREATE OR REPLACE TABLE STPO (
	STLNR VARCHAR(10) NOT NULL,
	IDNRK VARCHAR(10) NOT NULL,
	MENGE NUMBER(10,3),
	STUFE NUMBER(38,0),
	primary key (STLNR, IDNRK)
);

INSERT INTO STPO (STLNR, IDNRK, MENGE, STUFE)
VALUES
  ('ASSY-001', 'MAT-004', '2.000', 1),
  ('ASSY-001', 'MAT-001', '10.000', 1),
  ('ASSY-001', 'MAT-008', '1.000', 1),
  ('ASSY-001', 'MAT-012', '0.050', 1),
  ('ASSY-002', 'MAT-013', '4.000', 1),
  ('ASSY-002', 'MAT-001', '20.000', 1),
  ('ASSY-002', 'MAT-007', '0.500', 1),
  ('ASSY-003', 'MAT-003', '2.000', 1),
  ('ASSY-003', 'MAT-015', '0.300', 1),
  ('ASSY-003', 'MAT-019', '1.000', 1),
  ('ASSY-003', 'ASSY-001', '1.000', 1),
  ('ASSY-003', 'ASSY-002', '1.000', 1),
  ('ASSY-004', 'ASSY-003', '1.000', 1),
  ('ASSY-004', 'MAT-016', '2.000', 1),
  ('ASSY-004', 'MAT-018', '4.000', 1);

-- SUPPLIER_SCORECARDS
CREATE OR REPLACE TABLE SUPPLIER_SCORECARDS (
	REVIEW_ID VARCHAR(15) NOT NULL,
	LIFNR VARCHAR(10) NOT NULL,
	REVIEW_QUARTER VARCHAR(6) NOT NULL,
	DELIVERY_SCORE NUMBER(3,1),
	QUALITY_SCORE NUMBER(3,1),
	RESPONSIVENESS NUMBER(3,1),
	OVERALL_RATING VARCHAR(15),
	REVIEWER VARCHAR(50),
	REVIEWER_NOTES VARCHAR(2000),
	primary key (REVIEW_ID)
);

INSERT INTO SUPPLIER_SCORECARDS (REVIEW_ID, LIFNR, REVIEW_QUARTER, DELIVERY_SCORE, QUALITY_SCORE, RESPONSIVENESS, OVERALL_RATING, REVIEWER, REVIEWER_NOTES)
VALUES
  ('SCR-001', 'V10045', '2025Q4', '4.5', '4.2', '4.8', 'Excellent', 'J. Martinez', 'Shenzhen Electronics continues to be our most reliable strategic partner. Zero missed deliveries in Q4. Recommended for expanded capacity agreement. NOTE: monitor US-China trade policy changes.'),
  ('SCR-002', 'V10045', '2025Q3', '4.2', '3.8', '4.5', 'Good', 'J. Martinez', 'Minor quality dip in Sept batch (ceramic caps). Root cause identified — humidity in shipping. Corrective action verified.'),
  ('SCR-003', 'V10102', '2025Q4', '4.0', '4.5', '3.5', 'Good', 'A. Schmidt', 'Rhine Chemical quality is consistently top-tier. Responsiveness has declined — 72hr avg response vs 24hr SLA. Escalated to account manager.'),
  ('SCR-004', 'V10078', '2025Q4', '3.8', '4.0', '4.2', 'Good', 'R. Chen', 'Pacific Metals solid performer. Price increases above market for copper alloy — negotiate at next QBR.'),
  ('SCR-005', 'V10156', '2025Q4', '4.8', '4.9', '4.7', 'Excellent', 'T. Nakamura', 'Osaka Precision is our gold-standard supplier. Zero defects for 6 consecutive quarters. Sole source for MEMS sensors — document backup plan per procurement policy.'),
  ('SCR-006', 'V10201', '2025Q4', '3.2', '3.5', '3.0', 'Acceptable', 'M. Gonzalez', 'Monterrey Packaging — 2 late deliveries this quarter. Customs delays cited. Exploring backup corrugated supplier in Texas.'),
  ('SCR-007', 'V10089', '2025Q4', '4.3', '4.0', '4.5', 'Good', 'R. Chen', 'Adv. Silicon Solutions — strong partner for semiconductor supply. Lead time creeping up from 8 to 12 weeks. May need to increase safety stock.'),
  ('SCR-008', 'V10134', '2025Q4', '3.5', '4.2', '3.8', 'Good', 'A. Schmidt', 'Bayern Kunststoffe reliable on quality. Price competitiveness declining vs Asian alternatives.'),
  ('SCR-009', 'V10167', '2025Q4', '3.0', '2.5', '3.2', 'Acceptable', 'J. Martinez', 'Guangzhou Rare Earth — quality issues with last 2 batches. Placed on enhanced monitoring. Consider qualification of backup supplier.'),
  ('SCR-010', 'V10223', '2025Q4', '4.0', '4.1', '4.3', 'Good', 'R. Chen', 'Lone Star Industrial — dependable domestic source. Premium pricing offset by shorter lead times and no customs risk.'),
  ('SCR-011', 'V10245', '2025Q4', '2.0', '1.5', '2.5', 'Poor', 'M. Gonzalez', 'Puebla Corrugated — PROBATIONARY STATUS. Failed 2 of 3 quality audits. Do not issue new POs until re-qualification complete. See incident INC-018.'),
  ('SCR-012', 'V10098', '2025Q4', '4.1', '4.3', '3.9', 'Good', 'T. Nakamura', 'Tokyo Sensor Tech — good secondary source for sensors. Pricing 15% above Osaka but provides geographic diversification.'),
  ('SCR-013', 'V10312', '2025Q3', '3.8', '4.0', '4.0', 'Good', 'R. Chen', 'Acme Logistics — reliable carrier for domestic routes. GPS tracking integration pending.'),
  ('SCR-014', 'V10278', '2025Q4', '3.3', '3.0', '3.5', 'Acceptable', 'J. Martinez', 'Jiangsu Copper — acceptable quality but 3 shipments with incorrect documentation this quarter. Training requested.'),
  ('SCR-015', 'V10190', '2025Q4', '4.4', '4.6', '4.2', 'Excellent', 'A. Schmidt', 'Schwarzwald Precision — exceptional quality. Recommended for expanded scope into next-gen tooling program.');

-- T001W
CREATE OR REPLACE TABLE T001W (
	WERKS VARCHAR(10) NOT NULL,
	NAME1 VARCHAR(100),
	REGIO VARCHAR(20),
	primary key (WERKS)
);

INSERT INTO T001W (WERKS, NAME1, REGIO)
VALUES
  ('PLT-001', 'Austin Manufacturing Center', 'AMERICAS'),
  ('PLT-002', 'Stuttgart Assembly Plant', 'EMEA'),
  ('PLT-003', 'Shanghai Production Facility', 'APAC'),
  ('PLT-004', 'Monterrey Operations Plant', 'AMERICAS'),
  ('PLT-005', 'Nagoya Precision Works', 'APAC');

-- T320
CREATE OR REPLACE TABLE T320 (
	LGORT VARCHAR(10) NOT NULL,
	LGOBE VARCHAR(100),
	WERKS VARCHAR(10),
	LKAPA NUMBER(5,1),
	primary key (LGORT)
);

INSERT INTO T320 (LGORT, LGOBE, WERKS, LKAPA)
VALUES
  ('WH-001', 'Austin Raw Materials Hub', 'PLT-001', '72.5'),
  ('WH-002', 'Austin Finished Goods Depot', 'PLT-001', '61.0'),
  ('WH-003', 'Stuttgart Inbound Logistics Center', 'PLT-002', '88.3'),
  ('WH-004', 'Shanghai Bonded Warehouse', 'PLT-003', '55.2'),
  ('WH-005', 'Shanghai Distribution Center', 'PLT-003', '79.8'),
  ('WH-006', 'Monterrey Cross-Dock Facility', 'PLT-004', '42.1'),
  ('WH-007', 'Nagoya JIT Storage', 'PLT-005', '91.7'),
  ('WH-008', 'Houston Regional Distribution Hub', 'PLT-001', '67.4');

-- VBAP
CREATE OR REPLACE TABLE VBAP (
	VBELN VARCHAR(10) NOT NULL,
	POSNR VARCHAR(5) NOT NULL,
	MATNR VARCHAR(10),
	KWMENG NUMBER(10,0),
	NETWR NUMBER(12,2),
	KUNNR VARCHAR(10),
	ERDAT DATE,
	VKORG VARCHAR(5),
	primary key (VBELN, POSNR)
);

INSERT INTO VBAP (VBELN, POSNR, MATNR, KWMENG, NETWR, KUNNR, ERDAT, VKORG)
VALUES
  ('SO-001', '010', 'ASSY-004', 50, '60000.00', 'C-1001', '2025-01-15', '1000'),
  ('SO-002', '010', 'ASSY-004', 80, '96000.00', 'C-1002', '2025-02-10', '2000'),
  ('SO-003', '010', 'ASSY-004', 30, '36000.00', 'C-1003', '2025-03-01', '3000'),
  ('SO-004', '010', 'ASSY-004', 120, '144000.00', 'C-1001', '2025-04-01', '1000'),
  ('SO-005', '010', 'ASSY-004', 45, '54000.00', 'C-1004', '2025-04-15', '2000'),
  ('SO-001', '020', 'ASSY-003', 100, '85000.00', 'C-1001', '2025-01-15', '1000'),
  ('SO-002', '020', 'ASSY-003', 60, '51000.00', 'C-1002', '2025-02-10', '2000'),
  ('SO-006', '010', 'ASSY-003', 75, '63750.00', 'C-1005', '2025-03-20', '1000'),
  ('SO-007', '010', 'ASSY-003', 40, '34000.00', 'C-1003', '2025-05-01', '3000'),
  ('SO-008', '010', 'ASSY-001', 200, '24000.00', 'C-1001', '2025-02-01', '1000'),
  ('SO-009', '010', 'ASSY-001', 500, '60000.00', 'C-1004', '2025-04-10', '2000'),
  ('SO-010', '010', 'ASSY-002', 300, '25500.00', 'C-1002', '2025-03-05', '2000'),
  ('SO-011', '010', 'ASSY-002', 150, '12750.00', 'C-1005', '2025-05-10', '1000');

