-- =============================================================================
-- 02_create_raw_sources.sql
-- Creates all RAW_SOURCES tables with seed data.
-- =============================================================================

USE SCHEMA DB_ONTOLOGY_CONTROL_PLANE.RAW_SOURCES;

-- ACTION_LOG
CREATE OR REPLACE TABLE ACTION_LOG (
	LOG_ID VARCHAR(16777216) NOT NULL DEFAULT UUID_STRING(),
	ACTION_TYPE_ID VARCHAR(16777216),
	STATUS VARCHAR(16777216) DEFAULT 'PROPOSED',
	SUBMITTED_BY VARCHAR(16777216),
	SUBMITTED_AT TIMESTAMP_NTZ(9) DEFAULT CURRENT_TIMESTAMP(),
	APPROVED_BY VARCHAR(16777216),
	APPROVED_AT TIMESTAMP_NTZ(9),
	PARAMETERS VARIANT,
	PRE_STATE VARIANT,
	POST_STATE VARIANT,
	VALIDATION_RESULT VARIANT,
	EXECUTION_RESULT VARIANT,
	SIMULATION_ID VARCHAR(16777216),
	NOTIFICATIONS VARIANT,
	AGENT_SESSION_ID VARCHAR(16777216),
	primary key (LOG_ID)
);

-- ACTION_TYPES
CREATE OR REPLACE TABLE ACTION_TYPES (
	ACTION_TYPE_ID VARCHAR(16777216) NOT NULL,
	ACTION_NAME VARCHAR(16777216) NOT NULL,
	DESCRIPTION VARCHAR(16777216),
	DOMAIN VARCHAR(16777216) DEFAULT 'SUPPLY_CHAIN',
	TARGET_ENTITY_TYPES ARRAY,
	PARAMETER_SCHEMA VARIANT,
	VALIDATION_RULES VARIANT,
	EFFECT_DECLARATIONS VARIANT,
	REQUIRED_ROLES ARRAY,
	REQUIRES_APPROVAL BOOLEAN DEFAULT TRUE,
	IS_ACTIVE BOOLEAN DEFAULT TRUE,
	CREATED_AT TIMESTAMP_NTZ(9) DEFAULT CURRENT_TIMESTAMP(),
	primary key (ACTION_TYPE_ID)
);

INSERT INTO ACTION_TYPES (ACTION_TYPE_ID, ACTION_NAME, DESCRIPTION, DOMAIN, TARGET_ENTITY_TYPES, PARAMETER_SCHEMA, VALIDATION_RULES, EFFECT_DECLARATIONS, REQUIRED_ROLES, REQUIRES_APPROVAL, IS_ACTIVE, CREATED_AT)
VALUES
  ('REROUTE_SHIPMENT', 'Reroute Shipment', 'Change the destination warehouse for an in-transit or delayed shipment.', 'SUPPLY_CHAIN', '[
  "Shipment",
  "Warehouse",
  "Carrier"
]', '{
  "properties": {
    "new_carrier_id": {
      "description": "Optional: new carrier ID",
      "type": "string"
    },
    "new_warehouse_id": {
      "description": "Destination warehouse ID",
      "type": "string"
    },
    "reason": {
      "description": "Business reason for the reroute",
      "type": "string"
    },
    "shipment_id": {
      "description": "The SHIPMENT_ID to reroute",
      "type": "string"
    }
  },
  "required": [
    "shipment_id",
    "new_warehouse_id",
    "reason"
  ],
  "type": "object"
}', '{
  "rules": [
    {
      "check_sql": "SELECT COUNT(*) FROM SHIPMENTS WHERE SHIPMENT_ID = :shipment_id",
      "expected": "> 0",
      "id": "shipment_exists",
      "message": "Shipment must exist"
    },
    {
      "check_sql": "SELECT STATUS FROM SHIPMENTS WHERE SHIPMENT_ID = :shipment_id",
      "expected": "!= Delivered",
      "id": "shipment_not_delivered",
      "message": "Cannot reroute a delivered shipment"
    },
    {
      "check_sql": "SELECT COUNT(*) FROM WAREHOUSES WHERE WAREHOUSE_ID = :new_warehouse_id",
      "expected": "> 0",
      "id": "warehouse_exists",
      "message": "Destination warehouse must exist"
    },
    {
      "check_sql": "SELECT CURRENT_UTILIZATION_PCT FROM WAREHOUSES WHERE WAREHOUSE_ID = :new_warehouse_id",
      "expected": "< 90",
      "id": "warehouse_has_capacity",
      "message": "Destination warehouse utilization must be below 90%"
    }
  ]
}', '{
  "effects": [
    {
      "operation": "UPDATE",
      "set": {
        "DESTINATION_PLANT_ID": "(SELECT PLANT_ID FROM WAREHOUSES WHERE WAREHOUSE_ID = :new_warehouse_id)",
        "ORIGIN_WAREHOUSE_ID": ":new_warehouse_id",
        "STATUS": "In Transit"
      },
      "table": "SHIPMENTS",
      "where": "SHIPMENT_ID = :shipment_id"
    }
  ],
  "notification_template": "Shipment :shipment_id rerouted to warehouse :new_warehouse_id. Reason: :reason",
  "snapshot_query": "SELECT * FROM SHIPMENTS WHERE SHIPMENT_ID = :shipment_id"
}', '[
  "SYSADMIN",
  "LOGISTICS_MANAGER",
  "ACCOUNTADMIN"
]', True, True, '2026-09-24 07:22:30.617000'),
  ('ESCALATE_SUPPLIER', 'Escalate Supplier to Probationary', 'Change a supplier account group to Probationary due to quality, delivery, or compliance issues.', 'SUPPLY_CHAIN', '[
  "Supplier"
]', '{
  "properties": {
    "reason": {
      "description": "Business justification for escalation",
      "type": "string"
    },
    "review_date": {
      "description": "Date to review probationary status (YYYY-MM-DD)",
      "type": "string"
    },
    "vendor_number": {
      "description": "The VENDOR_NUMBER to escalate",
      "type": "string"
    }
  },
  "required": [
    "vendor_number",
    "reason"
  ],
  "type": "object"
}', '{
  "rules": [
    {
      "check_sql": "SELECT COUNT(*) FROM SAP_VENDORS WHERE VENDOR_NUMBER = :vendor_number",
      "expected": "> 0",
      "id": "vendor_exists",
      "message": "Vendor must exist"
    },
    {
      "check_sql": "SELECT SUPPLIER_TIER FROM SAP_VENDORS WHERE VENDOR_NUMBER = :vendor_number",
      "expected": "!= Probationary",
      "id": "vendor_not_probationary",
      "message": "Vendor is already Probationary"
    }
  ]
}', '{
  "effects": [
    {
      "operation": "UPDATE",
      "set": {
        "SUPPLIER_TIER": "Probationary"
      },
      "table": "SAP_VENDORS",
      "where": "VENDOR_NUMBER = :vendor_number"
    }
  ],
  "notification_template": "Supplier :vendor_number escalated to Probationary. Reason: :reason",
  "snapshot_query": "SELECT * FROM SAP_VENDORS WHERE VENDOR_NUMBER = :vendor_number"
}', '[
  "SYSADMIN",
  "PROCUREMENT_MANAGER",
  "ACCOUNTADMIN"
]', True, True, '2026-09-24 07:22:42.259000'),
  ('APPROVE_ALTERNATE_SUPPLIER', 'Approve Alternate Supplier', 'Approve a pending supplier qualification for a material, enabling dual-sourcing.', 'SUPPLY_CHAIN', '[
  "Material",
  "Supplier"
]', '{
  "properties": {
    "material_id": {
      "description": "The MATERIAL_ID to qualify for",
      "type": "string"
    },
    "qualification_notes": {
      "description": "Notes on the qualification decision",
      "type": "string"
    },
    "vendor_number": {
      "description": "The VENDOR_NUMBER being approved",
      "type": "string"
    }
  },
  "required": [
    "material_id",
    "vendor_number"
  ],
  "type": "object"
}', '{
  "rules": [
    {
      "check_sql": "SELECT COUNT(*) FROM SAP_MATERIALS WHERE MATERIAL_ID = :material_id",
      "expected": "> 0",
      "id": "material_exists",
      "message": "Material must exist"
    },
    {
      "check_sql": "SELECT COUNT(*) FROM SAP_VENDORS WHERE VENDOR_NUMBER = :vendor_number",
      "expected": "> 0",
      "id": "vendor_exists",
      "message": "Vendor must exist"
    },
    {
      "check_sql": "SELECT QUAL_STATUS FROM QUAL_MATRIX WHERE MATNR = :material_id AND LIFNR = :vendor_number",
      "expected": "= PENDING",
      "id": "qualification_pending",
      "message": "Qualification must be PENDING to approve"
    }
  ]
}', '{
  "effects": [
    {
      "operation": "UPDATE",
      "set": {
        "QUAL_DATE": "CURRENT_DATE()",
        "QUAL_STATUS": "APPROVED"
      },
      "table": "QUAL_MATRIX",
      "where": "MATNR = :material_id AND LIFNR = :vendor_number"
    }
  ],
  "notification_template": "Alternate supplier :vendor_number approved for material :material_id.",
  "snapshot_query": "SELECT * FROM QUAL_MATRIX WHERE MATNR = :material_id AND LIFNR = :vendor_number"
}', '[
  "SYSADMIN",
  "QUALITY_ENGINEER",
  "ACCOUNTADMIN"
]', True, True, '2026-09-24 07:22:52.802000');

-- ARIBA_SUPPLIERS
CREATE OR REPLACE TABLE ARIBA_SUPPLIERS (
	SUPPLIER_PROFILE_ID VARCHAR(20) NOT NULL,
	SUPPLIER_NAME VARCHAR(100),
	DUNS_NUMBER VARCHAR(15),
	COMPLIANCE_STATUS VARCHAR(20),
	CERTIFICATION_EXPIRY DATE,
	CONTRACT_STATUS VARCHAR(20),
	ANNUAL_SPEND_USD NUMBER(12,2),
	primary key (SUPPLIER_PROFILE_ID)
);

INSERT INTO ARIBA_SUPPLIERS (SUPPLIER_PROFILE_ID, SUPPLIER_NAME, DUNS_NUMBER, COMPLIANCE_STATUS, CERTIFICATION_EXPIRY, CONTRACT_STATUS, ANNUAL_SPEND_USD)
VALUES
  ('ARIBA-SP-2001', 'Shenzhen Electronics Co.', '54-138-7209', 'Compliant', '2026-09-15', 'Active', '4250000.00'),
  ('ARIBA-SP-2002', 'Rhine Chemical GmbH', '31-592-4780', 'Compliant', '2026-12-01', 'Active', '3180000.00'),
  ('ARIBA-SP-2003', 'Pacific Metals Corp', '07-823-6541', 'Compliant', '2026-06-30', 'Active', '2750000.00'),
  ('ARIBA-SP-2004', 'Osaka Precision Instruments', '69-247-1058', 'Compliant', '2027-03-15', 'Active', '5100000.00'),
  ('ARIBA-SP-2005', 'Adv. Silicon Solutions', '15-738-2904', 'Pending', '2026-03-01', 'Under Review', '6800000.00'),
  ('ARIBA-SP-2006', 'Acme Logistics Inc', '09-284-5716', 'Compliant', '2026-11-20', 'Active', '1920000.00'),
  ('ARIBA-SP-2007', 'Nagoya Steel Works', '48-729-3061', 'Compliant', '2027-01-31', 'Active', '3450000.00'),
  ('ARIBA-SP-2008', 'Nordic Polymer Solutions AS', '92-157-3840', 'Compliant', '2026-08-15', 'Active', '1450000.00'),
  ('ARIBA-SP-2009', 'Sao Paulo Resinas Ltda', '85-320-6714', 'Non-Compliant', '2025-12-31', 'Suspended', '680000.00'),
  ('ARIBA-SP-2010', 'Great Lakes Fasteners LLC', '18-493-7256', 'Pending', '2026-04-30', 'Pending Approval', '520000.00');

-- BILL_OF_MATERIALS
CREATE OR REPLACE TABLE BILL_OF_MATERIALS (
	BOM_ID VARCHAR(10) NOT NULL,
	PARENT_MATERIAL_ID VARCHAR(10),
	CHILD_MATERIAL_ID VARCHAR(10),
	QUANTITY_PER_UNIT NUMBER(10,3),
	BOM_LEVEL NUMBER(38,0),
	primary key (BOM_ID)
);

INSERT INTO BILL_OF_MATERIALS (BOM_ID, PARENT_MATERIAL_ID, CHILD_MATERIAL_ID, QUANTITY_PER_UNIT, BOM_LEVEL)
VALUES
  ('BOM-001', 'ASSY-001', 'MAT-004', '2.000', 1),
  ('BOM-002', 'ASSY-001', 'MAT-001', '10.000', 1),
  ('BOM-003', 'ASSY-001', 'MAT-008', '1.000', 1),
  ('BOM-004', 'ASSY-001', 'MAT-012', '0.050', 1),
  ('BOM-005', 'ASSY-002', 'MAT-013', '4.000', 1),
  ('BOM-006', 'ASSY-002', 'MAT-001', '20.000', 1),
  ('BOM-007', 'ASSY-002', 'MAT-007', '0.500', 1),
  ('BOM-008', 'ASSY-003', 'MAT-003', '2.000', 1),
  ('BOM-009', 'ASSY-003', 'MAT-015', '0.300', 1),
  ('BOM-010', 'ASSY-003', 'MAT-019', '1.000', 1),
  ('BOM-011', 'ASSY-003', 'ASSY-001', '1.000', 1),
  ('BOM-012', 'ASSY-003', 'ASSY-002', '1.000', 1);

-- CARRIERS
CREATE OR REPLACE TABLE CARRIERS (
	CARRIER_ID VARCHAR(10),
	CARRIER_NAME VARCHAR(100),
	CARRIER_TYPE VARCHAR(20),
	HQ_COUNTRY VARCHAR(5),
	ON_TIME_RATE NUMBER(4,2),
	AVERAGE_TRANSIT_DAYS NUMBER(38,0)
);

INSERT INTO CARRIERS (CARRIER_ID, CARRIER_NAME, CARRIER_TYPE, HQ_COUNTRY, ON_TIME_RATE, AVERAGE_TRANSIT_DAYS)
VALUES
  ('CAR-001', 'TransGlobal Freight Inc.', 'Ocean', 'US', '0.87', 28),
  ('CAR-002', 'EuroHaul Logistics GmbH', 'FTL', 'DE', '0.94', 4),
  ('CAR-003', 'SkyBridge Air Cargo', 'Air', 'US', '0.96', 3),
  ('CAR-004', 'Pacific Intermodal Corp.', 'Intermodal', 'JP', '0.91', 18),
  ('CAR-005', 'MexLine Transportes S.A.', 'LTL', 'MX', '0.83', 6),
  ('CAR-006', 'Shenzhen Coastal Shipping Ltd.', 'Ocean', 'CN', '0.89', 22);

-- CONTRACTS
CREATE OR REPLACE TABLE CONTRACTS (
	CONTRACT_ID VARCHAR(10),
	SUPPLIER_ID VARCHAR(10),
	CONTRACT_TYPE VARCHAR(20),
	EFFECTIVE_DATE DATE,
	EXPIRATION_DATE DATE,
	ANNUAL_VALUE_USD NUMBER(12,2),
	PAYMENT_TERMS_DAYS NUMBER(38,0),
	AUTO_RENEW BOOLEAN,
	STATUS VARCHAR(20)
);

INSERT INTO CONTRACTS (CONTRACT_ID, SUPPLIER_ID, CONTRACT_TYPE, EFFECTIVE_DATE, EXPIRATION_DATE, ANNUAL_VALUE_USD, PAYMENT_TERMS_DAYS, AUTO_RENEW, STATUS)
VALUES
  ('CTR-001', 'V10045', 'Master', '2024-01-01', '2026-12-31', '4500000.00', 45, True, 'Active'),
  ('CTR-002', 'V10078', 'Master', '2023-07-01', '2026-06-30', '3200000.00', 30, True, 'Active'),
  ('CTR-003', 'V10089', 'Framework', '2024-04-01', '2026-03-31', '2800000.00', 30, False, 'Active'),
  ('CTR-004', 'V10098', 'Master', '2024-01-01', '2027-12-31', '5200000.00', 60, True, 'Active'),
  ('CTR-005', 'V10102', 'Framework', '2024-06-01', '2025-05-31', '450000.00', 30, False, 'Expired'),
  ('CTR-006', 'V10134', 'Master', '2024-03-01', '2027-02-28', '7000000.00', 45, True, 'Active'),
  ('CTR-007', 'V10156', 'Framework', '2024-01-01', '2025-12-31', '1200000.00', 30, True, 'Active'),
  ('CTR-008', 'V10167', 'Spot', '2024-10-01', '2025-09-30', '980000.00', 60, False, 'Active'),
  ('CTR-009', 'V10201', 'Master', '2023-04-01', '2026-03-31', '3800000.00', 45, True, 'Active'),
  ('CTR-010', 'V10245', 'Framework', '2024-01-01', '2025-12-31', '2000000.00', 30, False, 'Active'),
  ('CTR-011', 'V10278', 'Master', '2024-06-01', '2026-05-31', '1500000.00', 45, True, 'Active'),
  ('CTR-012', 'V10312', 'Framework', '2024-01-01', '2025-12-31', '800000.00', 30, False, 'Active'),
  ('CTR-013', 'V10334', 'Master', '2023-10-01', '2026-09-30', '3500000.00', 60, True, 'Active'),
  ('CTR-014', 'V10223', 'Spot', '2025-01-15', '2025-07-15', '250000.00', 30, False, 'Pending'),
  ('CTR-015', 'V10190', 'Framework', '2024-08-01', '2025-07-31', '600000.00', 30, False, 'Active');

-- DNB_RISK_ASSESSMENTS
CREATE OR REPLACE TABLE DNB_RISK_ASSESSMENTS (
	ASSESSMENT_ID VARCHAR(10) NOT NULL,
	SUPPLIER_NAME VARCHAR(100),
	COUNTRY VARCHAR(5),
	FINANCIAL_HEALTH_SCORE NUMBER(38,0),
	GEOPOLITICAL_RISK_SCORE NUMBER(38,0),
	WEATHER_RISK_SCORE NUMBER(38,0),
	OVERALL_RISK_SCORE NUMBER(38,0),
	ASSESSMENT_DATE DATE,
	RISK_FACTORS VARIANT,
	primary key (ASSESSMENT_ID)
);

INSERT INTO DNB_RISK_ASSESSMENTS (ASSESSMENT_ID, SUPPLIER_NAME, COUNTRY, FINANCIAL_HEALTH_SCORE, GEOPOLITICAL_RISK_SCORE, WEATHER_RISK_SCORE, OVERALL_RISK_SCORE, ASSESSMENT_DATE, RISK_FACTORS)
VALUES
  ('RSK-001', 'Shenzhen Electronics', 'CN', 7, 6, 5, 6, '2025-11-15', '[
  "US-China trade tensions",
  "Typhoon season exposure",
  "Currency volatility"
]'),
  ('RSK-002', 'Rhine Chemical', 'DE', 9, 2, 3, 2, '2025-11-15', '[
  "EU regulatory changes",
  "Rhine River low water levels"
]'),
  ('RSK-003', 'Pacific Metals', 'US', 8, 2, 4, 3, '2025-11-15', '[
  "Port congestion",
  "Raw material price volatility"
]'),
  ('RSK-004', 'Osaka Precision Instruments Co', 'JP', 9, 3, 6, 4, '2025-11-15', '[
  "Earthquake zone",
  "Aging workforce",
  "JPY depreciation"
]'),
  ('RSK-005', 'Monterrey Packaging', 'MX', 6, 4, 3, 4, '2025-11-15', '[
  "Cross-border logistics",
  "Labor market tightness"
]'),
  ('RSK-006', 'Advanced Silicon Solutions', 'US', 7, 2, 5, 3, '2025-11-15', '[
  "Semiconductor cycle volatility",
  "California wildfire risk"
]'),
  ('RSK-007', 'Bayern Kunststoffe', 'DE', 8, 2, 2, 2, '2025-11-15', '[
  "Energy cost inflation",
  "EU REACH compliance"
]'),
  ('RSK-008', 'Guangzhou Rare Earth', 'CN', 5, 7, 5, 7, '2025-11-15', '[
  "Export controls",
  "Single-source dependency",
  "Currency volatility",
  "Environmental regulations"
]'),
  ('RSK-009', 'Lone Star Industrial', 'US', 6, 1, 6, 4, '2025-11-15', '[
  "Hurricane season exposure",
  "Small company financial fragility"
]'),
  ('RSK-010', 'Tokyo Sensor Tech', 'JP', 8, 3, 6, 4, '2025-11-15', '[
  "Earthquake zone",
  "Semiconductor shortage spillover"
]'),
  ('RSK-011', 'Puebla Corrugated', 'MX', 4, 4, 3, 5, '2025-11-15', '[
  "Limited financial reserves",
  "Single-plant risk",
  "New supplier qualification"
]'),
  ('RSK-012', 'Jiangsu Copper Alloys', 'CN', 6, 6, 4, 6, '2025-11-15', '[
  "Trade tariffs",
  "Copper price volatility",
  "Environmental compliance"
]'),
  ('RSK-013', 'Schwarzwald Precision', 'DE', 7, 2, 2, 2, '2025-11-15', '[
  "Skilled labor shortage"
]'),
  ('RSK-014', 'Nagoya Steel', 'JP', 8, 3, 5, 3, '2025-11-15', '[
  "Earthquake zone",
  "Steel tariff exposure"
]'),
  ('RSK-015', 'Acme Logistics', 'US', 7, 1, 4, 3, '2025-11-15', '[
  "Midwest severe weather",
  "Driver shortage"
]');

-- INSPECTIONS
CREATE OR REPLACE TABLE INSPECTIONS (
	INSPECTION_ID VARCHAR(10),
	MATERIAL_ID VARCHAR(10),
	INSPECTION_DATE DATE,
	LOT_SIZE NUMBER(38,0),
	DEFECT_COUNT NUMBER(38,0),
	DEFECT_RATE NUMBER(6,3),
	DISPOSITION VARCHAR(30)
);

INSERT INTO INSPECTIONS (INSPECTION_ID, MATERIAL_ID, INSPECTION_DATE, LOT_SIZE, DEFECT_COUNT, DEFECT_RATE, DISPOSITION)
VALUES
  ('INS-001', 'MAT-001', '2024-11-15', 500, 3, '0.006', 'Accept'),
  ('INS-002', 'MAT-002', '2024-11-20', 200, 12, '0.060', 'Conditional Accept'),
  ('INS-003', 'MAT-003', '2024-12-01', 1000, 1, '0.001', 'Accept'),
  ('INS-004', 'MAT-004', '2024-12-05', 300, 45, '0.150', 'Reject'),
  ('INS-005', 'MAT-005', '2024-12-10', 750, 8, '0.011', 'Accept'),
  ('INS-006', 'MAT-006', '2024-12-15', 400, 2, '0.005', 'Accept'),
  ('INS-007', 'MAT-007', '2024-12-20', 600, 30, '0.050', 'Conditional Accept'),
  ('INS-008', 'MAT-008', '2025-01-05', 250, 0, '0.000', 'Accept'),
  ('INS-009', 'MAT-001', '2025-01-10', 500, 5, '0.010', 'Accept'),
  ('INS-010', 'MAT-003', '2025-01-15', 1000, 2, '0.002', 'Accept');

-- MATERIAL_CATEGORIES
CREATE OR REPLACE TABLE MATERIAL_CATEGORIES (
	CATEGORY_ID VARCHAR(20) NOT NULL,
	CATEGORY_NAME VARCHAR(50),
	PARENT_CATEGORY_ID VARCHAR(20),
	CATEGORY_LEVEL NUMBER(38,0),
	primary key (CATEGORY_ID)
);

INSERT INTO MATERIAL_CATEGORIES (CATEGORY_ID, CATEGORY_NAME, PARENT_CATEGORY_ID, CATEGORY_LEVEL)
VALUES
  ('CAT-ROOT', 'All Materials', NULL, 0),
  ('CAT-ELEC', 'Electronics', 'CAT-ROOT', 1),
  ('CAT-SEMI', 'Semiconductors', 'CAT-ELEC', 2),
  ('CAT-PASS', 'Passive Components', 'CAT-ELEC', 2),
  ('CAT-CHEM', 'Chemicals', 'CAT-ROOT', 1),
  ('CAT-SOLV', 'Solvents', 'CAT-CHEM', 2),
  ('CAT-ADHV', 'Adhesives and Compounds', 'CAT-CHEM', 2),
  ('CAT-METL', 'Metals', 'CAT-ROOT', 1),
  ('CAT-FERR', 'Ferrous Metals', 'CAT-METL', 2),
  ('CAT-NFER', 'Non-Ferrous Metals', 'CAT-METL', 2),
  ('CAT-RAWM', 'Raw Materials', 'CAT-ROOT', 1),
  ('CAT-PACK', 'Packaging', 'CAT-ROOT', 1),
  ('CAT-ASSY', 'Assemblies', 'CAT-ROOT', 1);

-- MATERIAL_CATEGORY_MAP
CREATE OR REPLACE TABLE MATERIAL_CATEGORY_MAP (
	MATERIAL_ID VARCHAR(10),
	CATEGORY_ID VARCHAR(20)
);

INSERT INTO MATERIAL_CATEGORY_MAP (MATERIAL_ID, CATEGORY_ID)
VALUES
  ('MAT-004', 'CAT-SEMI'),
  ('MAT-008', 'CAT-SEMI'),
  ('MAT-013', 'CAT-SEMI'),
  ('MAT-001', 'CAT-PASS'),
  ('MAT-016', 'CAT-PASS'),
  ('MAT-006', 'CAT-SOLV'),
  ('MAT-017', 'CAT-SOLV'),
  ('MAT-002', 'CAT-ADHV'),
  ('MAT-012', 'CAT-ADHV'),
  ('MAT-010', 'CAT-FERR'),
  ('MAT-003', 'CAT-NFER'),
  ('MAT-007', 'CAT-NFER'),
  ('MAT-015', 'CAT-NFER'),
  ('MAT-019', 'CAT-NFER'),
  ('MAT-011', 'CAT-RAWM'),
  ('MAT-018', 'CAT-RAWM'),
  ('MAT-005', 'CAT-PACK'),
  ('MAT-009', 'CAT-PACK'),
  ('MAT-014', 'CAT-PACK'),
  ('MAT-020', 'CAT-PACK'),
  ('ASSY-001', 'CAT-ASSY'),
  ('ASSY-002', 'CAT-ASSY'),
  ('ASSY-003', 'CAT-ASSY');

-- PLANTS
CREATE OR REPLACE TABLE PLANTS (
	PLANT_ID VARCHAR(10),
	PLANT_NAME VARCHAR(100),
	CITY VARCHAR(50),
	COUNTRY VARCHAR(5),
	REGION VARCHAR(20)
);

INSERT INTO PLANTS (PLANT_ID, PLANT_NAME, CITY, COUNTRY, REGION)
VALUES
  ('PLT-001', 'Austin Manufacturing Center', 'Austin', 'US', 'AMERICAS'),
  ('PLT-002', 'Stuttgart Assembly Plant', 'Stuttgart', 'DE', 'EMEA'),
  ('PLT-003', 'Shanghai Production Facility', 'Shanghai', 'CN', 'APAC'),
  ('PLT-004', 'Monterrey Operations Plant', 'Monterrey', 'MX', 'AMERICAS'),
  ('PLT-005', 'Nagoya Precision Works', 'Nagoya', 'JP', 'APAC');

-- SAP_MATERIALS
CREATE OR REPLACE TABLE SAP_MATERIALS (
	MATERIAL_ID VARCHAR(10),
	MATERIAL_NAME VARCHAR(100),
	MATERIAL_CATEGORY VARCHAR(30),
	UNIT_OF_MEASURE VARCHAR(5),
	STANDARD_COST_USD NUMBER(10,2),
	LEAD_TIME_DAYS NUMBER(38,0),
	SAFETY_STOCK_QTY NUMBER(38,0),
	REORDER_POINT NUMBER(38,0)
);

INSERT INTO SAP_MATERIALS (MATERIAL_ID, MATERIAL_NAME, MATERIAL_CATEGORY, UNIT_OF_MEASURE, STANDARD_COST_USD, LEAD_TIME_DAYS, SAFETY_STOCK_QTY, REORDER_POINT)
VALUES
  ('MAT-001', 'Multilayer Ceramic Capacitor 100nF', 'Electronics', 'EA', '0.12', 21, 50000, 75000),
  ('MAT-002', 'Epoxy Resin ER-4500', 'Chemicals', 'KG', '18.50', 14, 2000, 3500),
  ('MAT-003', 'Aluminum Sheet 6061-T6 2mm', 'Metals', 'SHT', '42.00', 10, 500, 800),
  ('MAT-004', 'MEMS Accelerometer IC', 'Electronics', 'EA', '3.75', 28, 10000, 15000),
  ('MAT-005', 'Corrugated Box 400x300x200mm', 'Packaging', 'EA', '1.85', 7, 8000, 12000),
  ('MAT-006', 'Isopropyl Alcohol 99.7%', 'Chemicals', 'L', '5.20', 10, 5000, 8000),
  ('MAT-007', 'Copper Alloy Strip C17200', 'Metals', 'KG', '28.90', 18, 1000, 1800),
  ('MAT-008', 'ARM Cortex-M4 Microcontroller', 'Electronics', 'EA', '6.40', 35, 5000, 8000),
  ('MAT-009', 'Anti-Static Foam Insert', 'Packaging', 'EA', '0.95', 5, 10000, 15000),
  ('MAT-010', 'Stainless Steel Rod 304L 10mm', 'Metals', 'M', '12.30', 12, 3000, 5000),
  ('MAT-011', 'Neodymium Rare Earth Magnet N52', 'Raw Materials', 'EA', '2.10', 25, 20000, 30000),
  ('MAT-012', 'Silicone Thermal Paste TG-7', 'Chemicals', 'KG', '85.00', 14, 200, 350),
  ('MAT-013', 'Power MOSFET IRF540N', 'Electronics', 'EA', '0.85', 18, 25000, 40000),
  ('MAT-014', 'Polyethylene Stretch Wrap 500mm', 'Packaging', 'RL', '14.50', 5, 400, 600),
  ('MAT-015', 'Titanium Alloy Ti-6Al-4V Plate', 'Metals', 'KG', '120.00', 30, 150, 250),
  ('MAT-016', 'Fiber Optic Transceiver SFP+ 10G', 'Electronics', 'EA', '22.00', 21, 2000, 3000),
  ('MAT-017', 'Hydrochloric Acid 37% ACS Grade', 'Chemicals', 'L', '8.75', 10, 3000, 5000),
  ('MAT-018', 'Precision Ball Bearing 6205-2RS', 'Raw Materials', 'EA', '4.50', 14, 5000, 8000),
  ('MAT-019', 'Carbon Fiber Sheet 3K Twill 2mm', 'Raw Materials', 'SHT', '65.00', 20, 200, 350),
  ('MAT-020', 'ESD Protective Bag 200x300mm', 'Packaging', 'EA', '0.35', 5, 30000, 45000),
  ('ASSY-001', 'Sensor Module Assembly', 'Assembly', 'EA', '45.00', 5, 1000, 2000),
  ('ASSY-002', 'Power Distribution Board', 'Assembly', 'EA', '32.00', 3, 2000, 3500),
  ('ASSY-003', 'Ruggedized Enclosure', 'Assembly', 'EA', '380.00', 10, 200, 400);

-- SAP_PURCHASE_ORDERS
CREATE OR REPLACE TABLE SAP_PURCHASE_ORDERS (
	PO_NUMBER VARCHAR(20),
	SUPPLIER_ID VARCHAR(10),
	MATERIAL_ID VARCHAR(10),
	QUANTITY NUMBER(38,0),
	UNIT_COST_USD NUMBER(10,2),
	TOTAL_COST_USD NUMBER(12,2),
	ORDER_DATE DATE,
	EXPECTED_DELIVERY_DATE DATE,
	PLANT_ID VARCHAR(10),
	STATUS VARCHAR(20)
);

INSERT INTO SAP_PURCHASE_ORDERS (PO_NUMBER, SUPPLIER_ID, MATERIAL_ID, QUANTITY, UNIT_COST_USD, TOTAL_COST_USD, ORDER_DATE, EXPECTED_DELIVERY_DATE, PLANT_ID, STATUS)
VALUES
  ('PO-2024-001', 'V10045', 'MAT-001', 100000, '0.11', '11000.00', '2024-09-15', '2024-10-06', 'PLT-003', 'Received'),
  ('PO-2024-002', 'V10078', 'MAT-002', 5000, '17.80', '89000.00', '2024-09-20', '2024-10-04', 'PLT-002', 'Received'),
  ('PO-2024-003', 'V10089', 'MAT-003', 1200, '40.50', '48600.00', '2024-10-01', '2024-10-11', 'PLT-001', 'Received'),
  ('PO-2024-004', 'V10098', 'MAT-004', 20000, '3.60', '72000.00', '2024-10-10', '2024-11-07', 'PLT-005', 'Received'),
  ('PO-2024-005', 'V10102', 'MAT-005', 15000, '1.75', '26250.00', '2024-10-15', '2024-10-22', 'PLT-004', 'Received'),
  ('PO-2024-006', 'V10134', 'MAT-008', 10000, '6.20', '62000.00', '2024-11-01', '2024-12-06', 'PLT-001', 'Received'),
  ('PO-2024-007', 'V10156', 'MAT-002', 3000, '19.10', '57300.00', '2024-11-10', '2024-11-24', 'PLT-002', 'Received'),
  ('PO-2024-008', 'V10167', 'MAT-011', 50000, '1.95', '97500.00', '2024-11-15', '2024-12-10', 'PLT-003', 'Received'),
  ('PO-2024-009', 'V10278', 'MAT-007', 2000, '27.50', '55000.00', '2024-12-01', '2024-12-19', 'PLT-003', 'Received'),
  ('PO-2024-010', 'V10334', 'MAT-010', 5000, '11.80', '59000.00', '2024-12-05', '2024-12-17', 'PLT-005', 'Received'),
  ('PO-2024-011', 'V10102', 'MAT-014', 800, '13.80', '11040.00', '2024-11-20', '2024-11-25', 'PLT-004', 'Received'),
  ('PO-2024-012', 'V10201', 'MAT-004', 8000, '3.80', '30400.00', '2024-12-10', '2025-01-07', 'PLT-001', 'Cancelled'),
  ('PO-2025-001', 'V10045', 'MAT-013', 50000, '0.82', '41000.00', '2025-01-10', '2025-01-28', 'PLT-003', 'Received'),
  ('PO-2025-002', 'V10201', 'MAT-016', 4000, '21.00', '84000.00', '2025-01-20', '2025-02-10', 'PLT-005', 'Received'),
  ('PO-2025-003', 'V10190', 'MAT-006', 10000, '4.90', '49000.00', '2025-02-01', '2025-02-11', 'PLT-001', 'Received'),
  ('PO-2025-004', 'V10312', 'MAT-018', 8000, '4.30', '34400.00', '2025-02-15', '2025-03-01', 'PLT-002', 'Received'),
  ('PO-2025-005', 'V10089', 'MAT-015', 300, '115.00', '34500.00', '2025-03-01', '2025-03-31', 'PLT-001', 'Received'),
  ('PO-2025-006', 'V10134', 'MAT-008', 15000, '6.20', '93000.00', '2025-03-15', '2025-04-19', 'PLT-001', 'Partial'),
  ('PO-2025-007', 'V10078', 'MAT-017', 8000, '8.40', '67200.00', '2025-04-01', '2025-04-11', 'PLT-002', 'Open'),
  ('PO-2025-008', 'V10223', 'MAT-005', 20000, '1.65', '33000.00', '2025-04-05', '2025-04-12', 'PLT-004', 'Open'),
  ('PO-2025-009', 'V10098', 'MAT-004', 25000, '3.60', '90000.00', '2025-04-10', '2025-05-08', 'PLT-005', 'Open'),
  ('PO-2025-010', 'V10167', 'MAT-011', 40000, '2.00', '80000.00', '2025-04-12', '2025-05-07', 'PLT-003', 'Open'),
  ('PO-2025-011', 'V10045', 'MAT-001', 200000, '0.11', '22000.00', '2025-04-15', '2025-05-06', 'PLT-001', 'Open'),
  ('PO-2025-012', 'V10278', 'MAT-007', 3000, '28.00', '84000.00', '2025-04-16', '2025-05-04', 'PLT-003', 'Open'),
  ('PO-2025-013', 'V10245', 'MAT-009', 25000, '0.90', '22500.00', '2025-03-01', '2025-03-06', 'PLT-001', 'Received');

-- SAP_VENDORS
CREATE OR REPLACE TABLE SAP_VENDORS (
	VENDOR_NUMBER VARCHAR(10) NOT NULL,
	LEGAL_NAME VARCHAR(100),
	STREET VARCHAR(100),
	CITY VARCHAR(50),
	COUNTRY_CODE VARCHAR(5),
	POSTAL_CODE VARCHAR(10),
	TAX_ID VARCHAR(30),
	DUNS_NUMBER VARCHAR(15),
	PAYMENT_TERMS VARCHAR(10),
	SUPPLIER_TIER VARCHAR(20),
	primary key (VENDOR_NUMBER)
);

INSERT INTO SAP_VENDORS (VENDOR_NUMBER, LEGAL_NAME, STREET, CITY, COUNTRY_CODE, POSTAL_CODE, TAX_ID, DUNS_NUMBER, PAYMENT_TERMS, SUPPLIER_TIER)
VALUES
  ('V10045', 'SHENZHEN ELECTRONICS CO. LTD', '88 Nanshan Technology Road', 'Shenzhen', 'CN', '518057', '91440300MA5FPQG72B', '54-138-7209', 'NET45', 'Standard'),
  ('V10102', 'RHINE CHEMICAL GMBH', 'Industriestrasse 14', 'Ludwigshafen', 'DE', '67063', 'DE283741956', '31-592-4780', 'NET30', 'Strategic'),
  ('V10078', 'PACIFIC METALS CORPORATION', '1200 Harbor Blvd', 'Long Beach', 'US', '90802', '95-4821073', '07-823-6541', 'NET30', 'Preferred'),
  ('V10156', 'OSAKA PRECISION INSTRUMENTS CO.', '3-14-7 Honmachi', 'Osaka', 'JP', '541-0053', 'JP8120001098765', '69-247-1058', 'NET60', 'Strategic'),
  ('V10201', 'MONTERREY PACKAGING S.A. DE C.V.', 'Av. Ruiz Cortines 4500', 'Monterrey', 'MX', '64700', 'MPS040512QR7', '82-461-3097', 'NET30', 'Approved'),
  ('V10089', 'ADVANCED SILICON SOLUTIONS INC.', '5500 Great America Parkway', 'Santa Clara', 'US', '95054', '77-3920184', '15-738-2904', 'NET45', 'Strategic'),
  ('V10134', 'BAYERN KUNSTSTOFFE AG', 'Werkstrasse 22', 'Munich', 'DE', '80339', 'DE192847563', '44-591-7823', 'NET30', 'Preferred'),
  ('V10167', 'GUANGZHOU RARE EARTH MATERIALS LTD', '12 Tianhe Industrial Zone', 'Guangzhou', 'CN', '510630', '91440101MA9URXG44N', '63-904-2175', 'NET60', 'Approved'),
  ('V10223', 'LONE STAR INDUSTRIAL SUPPLY CO.', '8700 Commerce Park Dr', 'Houston', 'US', '77036', '76-1948302', '28-617-4930', 'NET30', 'Approved'),
  ('V10098', 'TOKYO SENSOR TECHNOLOGIES K.K.', '2-8-1 Akihabara', 'Tokyo', 'JP', '101-0021', 'JP5010401098234', '71-385-6249', 'NET45', 'Preferred'),
  ('V10245', 'PUEBLA CORRUGATED PRODUCTS SA', 'Calle Industrial 230', 'Puebla', 'MX', '72430', 'PCP090318HV5', NULL, 'NET30', 'Probationary'),
  ('V10312', 'ACME LOGISTICS INC', '400 Freight Terminal Rd', 'Chicago', 'US', '60607', '36-4829107', '09-284-5716', 'NET30', 'Preferred'),
  ('V10278', 'JIANGSU COPPER ALLOYS CO. LTD', '58 Binjiang Road', 'Nanjing', 'CN', '210019', '91320100MA1MPKG28R', '56-813-4027', 'NET45', 'Approved'),
  ('V10190', 'SCHWARZWALD PRECISION TOOLS GMBH', 'Am Gewerbepark 5', 'Freiburg', 'DE', '79098', 'DE314725890', '37-462-8105', 'NET30', 'Approved'),
  ('V10334', 'NAGOYA STEEL WORKS LTD', '5-2-10 Minato-ku', 'Nagoya', 'JP', '455-0032', 'JP3180001054321', '48-729-3061', 'NET60', 'Preferred');

-- SAP_VENDOR_MAPPING
CREATE OR REPLACE TABLE SAP_VENDOR_MAPPING (
	SUPPLIER_ID VARCHAR(10),
	VENDOR_NUMBER VARCHAR(10)
);

INSERT INTO SAP_VENDOR_MAPPING (SUPPLIER_ID, VENDOR_NUMBER)
VALUES
  ('SUP-001', 'V10045'),
  ('SUP-002', 'V10078'),
  ('SUP-003', 'V10089'),
  ('SUP-004', 'V10098'),
  ('SUP-005', 'V10102'),
  ('SUP-006', 'V10134'),
  ('SUP-007', 'V10156'),
  ('SUP-008', 'V10167'),
  ('SUP-009', 'V10190'),
  ('SUP-010', 'V10201'),
  ('SUP-011', 'V10223'),
  ('SUP-012', 'V10245'),
  ('SUP-013', 'V10278'),
  ('SUP-014', 'V10312'),
  ('SUP-015', 'V10334');

-- SHIPMENTS
CREATE OR REPLACE TABLE SHIPMENTS (
	SHIPMENT_ID VARCHAR(10),
	TRACKING_NUMBER VARCHAR(30),
	CARRIER_ID VARCHAR(10),
	ORIGIN_WAREHOUSE_ID VARCHAR(10),
	DESTINATION_PLANT_ID VARCHAR(10),
	DESTINATION_WAREHOUSE_ID VARCHAR(10),
	MATERIAL_ID VARCHAR(10),
	QUANTITY NUMBER(38,0),
	SHIP_DATE DATE,
	EXPECTED_ARRIVAL DATE,
	ACTUAL_ARRIVAL DATE,
	FREIGHT_COST_USD NUMBER(10,2),
	STATUS VARCHAR(20)
);

INSERT INTO SHIPMENTS (SHIPMENT_ID, TRACKING_NUMBER, CARRIER_ID, ORIGIN_WAREHOUSE_ID, DESTINATION_PLANT_ID, DESTINATION_WAREHOUSE_ID, MATERIAL_ID, QUANTITY, SHIP_DATE, EXPECTED_ARRIVAL, ACTUAL_ARRIVAL, FREIGHT_COST_USD, STATUS)
VALUES
  ('SHP-001', 'TGF-2024-88412', 'CAR-006', 'WH-004', 'PLT-001', NULL, 'MAT-001', 100000, '2024-09-18', '2024-10-10', '2024-10-08', '2800.00', 'Delivered'),
  ('SHP-002', 'EHL-2024-33291', 'CAR-002', 'WH-003', 'PLT-002', NULL, 'MAT-002', 5000, '2024-09-22', '2024-09-26', '2024-09-25', '1200.00', 'Delivered'),
  ('SHP-003', 'SBA-2024-19847', 'CAR-003', 'WH-008', NULL, 'WH-001', 'MAT-003', 1200, '2024-10-03', '2024-10-06', '2024-10-06', '3500.00', 'Delivered'),
  ('SHP-004', 'PIC-2024-55603', 'CAR-004', 'WH-007', 'PLT-005', NULL, 'MAT-004', 20000, '2024-10-15', '2024-11-02', '2024-11-05', '4200.00', 'Delivered'),
  ('SHP-005', 'MLT-2024-70219', 'CAR-005', 'WH-006', 'PLT-004', NULL, 'MAT-005', 15000, '2024-10-17', '2024-10-23', '2024-10-22', '850.00', 'Delivered'),
  ('SHP-006', 'SBA-2024-22134', 'CAR-003', 'WH-001', NULL, 'WH-003', 'MAT-008', 10000, '2024-11-08', '2024-11-11', '2024-11-11', '5100.00', 'Delivered'),
  ('SHP-007', 'TGF-2024-91456', 'CAR-001', 'WH-004', NULL, 'WH-001', 'MAT-011', 50000, '2024-11-20', '2024-12-18', '2024-12-22', '3100.00', 'Delivered'),
  ('SHP-008', 'SCS-2024-44782', 'CAR-006', 'WH-005', NULL, 'WH-007', 'MAT-007', 2000, '2024-12-05', '2024-12-27', '2024-12-26', '1900.00', 'Delivered'),
  ('SHP-009', 'EHL-2024-38567', 'CAR-002', 'WH-003', 'PLT-002', NULL, 'MAT-018', 8000, '2025-02-18', '2025-02-22', '2025-02-21', '980.00', 'Delivered'),
  ('SHP-010', 'PIC-2025-12098', 'CAR-004', 'WH-007', NULL, 'WH-001', 'MAT-016', 4000, '2025-01-25', '2025-02-12', '2025-02-14', '3800.00', 'Delivered'),
  ('SHP-011', 'TGF-2025-15234', 'CAR-001', 'WH-008', NULL, 'WH-006', 'MAT-006', 10000, '2025-02-05', '2025-03-05', '2025-03-08', '2400.00', 'Delivered'),
  ('SHP-012', 'SBA-2025-08912', 'CAR-003', 'WH-001', 'PLT-001', NULL, 'MAT-015', 300, '2025-03-20', '2025-03-23', '2025-03-23', '1800.00', 'Delivered'),
  ('SHP-013', 'SCS-2025-27641', 'CAR-006', 'WH-004', 'PLT-003', NULL, 'MAT-013', 50000, '2025-01-15', '2025-02-06', '2025-02-04', '2200.00', 'Delivered'),
  ('SHP-014', 'MLT-2025-31890', 'CAR-005', 'WH-006', 'PLT-004', NULL, 'MAT-014', 800, '2024-11-22', '2024-11-28', '2024-11-30', '450.00', 'Delivered'),
  ('SHP-015', 'EHL-2025-42178', 'CAR-002', 'WH-003', 'PLT-002', NULL, 'MAT-002', 3000, '2025-03-25', '2025-03-29', '2025-03-28', '1100.00', 'Delivered'),
  ('SHP-016', 'TGF-2025-51023', 'CAR-001', 'WH-005', NULL, 'WH-001', 'MAT-011', 40000, '2025-04-14', '2025-05-12', NULL, '3050.00', 'In Transit'),
  ('SHP-017', 'PIC-2025-60345', 'CAR-004', 'WH-007', 'PLT-005', NULL, 'MAT-004', 25000, '2025-04-15', '2025-05-03', NULL, '4500.00', 'In Transit'),
  ('SHP-018', 'SBA-2025-18493', 'CAR-003', 'WH-001', NULL, 'WH-003', 'MAT-008', 8000, '2025-04-10', '2025-04-13', NULL, '4800.00', 'Delayed'),
  ('SHP-019', 'SCS-2025-72841', 'CAR-006', 'WH-004', NULL, 'WH-008', 'MAT-007', 3000, '2025-04-18', '2025-05-10', NULL, '2600.00', 'In Transit'),
  ('SHP-020', 'MLT-2025-83291', 'CAR-005', 'WH-001', 'PLT-001', NULL, 'MAT-005', 20000, '2025-04-08', '2025-04-14', NULL, '920.00', 'In Transit');

-- SIMULATION_LOG
CREATE OR REPLACE TABLE SIMULATION_LOG (
	SIMULATION_ID VARCHAR(16777216) NOT NULL,
	BRANCH_SCHEMA VARCHAR(16777216) NOT NULL,
	LABEL VARCHAR(16777216),
	DESCRIPTION VARCHAR(16777216),
	CREATED_BY VARCHAR(16777216),
	CREATED_AT TIMESTAMP_NTZ(9) DEFAULT CURRENT_TIMESTAMP(),
	STATUS VARCHAR(16777216) DEFAULT 'ACTIVE',
	ACTIONS_APPLIED VARIANT,
	COMPARISON_METRICS VARIANT,
	PROMOTED_AT TIMESTAMP_NTZ(9),
	DROPPED_AT TIMESTAMP_NTZ(9),
	primary key (SIMULATION_ID)
);

INSERT INTO SIMULATION_LOG (SIMULATION_ID, BRANCH_SCHEMA, LABEL, DESCRIPTION, CREATED_BY, CREATED_AT, STATUS, ACTIONS_APPLIED, COMPARISON_METRICS, PROMOTED_AT, DROPPED_AT)
VALUES
  ('SIM_20260924_6CCE', 'SIM_20260924_6CCE', 'Reroute SHP-017 to Monterrey Cross-Dock Facility', 'Simulation branch with 1 actions applied', 'TJIA', '2026-09-24 15:47:11.566000', 'DROPPED', '[
  {
    "actionTypeId": "REROUTE_SHIPMENT",
    "parameters": {
      "new_warehouse_id": "WH-006",
      "reason": "Auto-analyze: reduce WH-007 utilization from 91.7%",
      "shipment_id": "SHP-017"
    },
    "status": "APPLIED"
  }
]', '{
  "delayedShipments": 1,
  "maxUtilization": 88.3,
  "openPoValue": 376200,
  "warehouseUtilization": {
    "WH-001": 72.5,
    "WH-002": 61,
    "WH-003": 88.3,
    "WH-004": 55.2,
    "WH-005": 79.8,
    "WH-006": 45.6,
    "WH-007": 88.2,
    "WH-008": 67.4
  }
}', NULL, '2026-09-30 11:50:44.273000'),
  ('SIM_20260924_8850', 'SIM_20260924_8850', 'Reroute SHP-017 to Shanghai Bonded Warehouse', 'Simulation branch with 1 actions applied', 'TJIA', '2026-09-24 15:47:31.300000', 'DROPPED', '[
  {
    "actionTypeId": "REROUTE_SHIPMENT",
    "parameters": {
      "new_warehouse_id": "WH-004",
      "reason": "Auto-analyze: reduce WH-007 utilization from 91.7%",
      "shipment_id": "SHP-017"
    },
    "status": "APPLIED"
  }
]', '{
  "delayedShipments": 1,
  "maxUtilization": 88.3,
  "openPoValue": 376200,
  "warehouseUtilization": {
    "WH-001": 72.5,
    "WH-002": 61,
    "WH-003": 88.3,
    "WH-004": 58.7,
    "WH-005": 79.8,
    "WH-006": 42.1,
    "WH-007": 88.2,
    "WH-008": 67.4
  }
}', NULL, '2026-09-30 11:50:43.392000'),
  ('SIM_20260924_94DE', 'SIM_20260924_94DE', 'Reroute SHP-017 to Monterrey Cross-Dock Facility', 'Simulation branch with 1 actions applied', 'TJIA', '2026-09-24 16:13:43.575000', 'DROPPED', '[
  {
    "actionTypeId": "REROUTE_SHIPMENT",
    "parameters": {
      "new_warehouse_id": "WH-006",
      "reason": "Auto-analyze: reduce WH-007 utilization from 91.7%",
      "shipment_id": "SHP-017"
    },
    "status": "APPLIED"
  }
]', '{
  "delayedShipments": 1,
  "maxUtilization": 88.3,
  "openPoValue": 376200,
  "warehouseUtilization": {
    "WH-001": 72.5,
    "WH-002": 61,
    "WH-003": 88.3,
    "WH-004": 55.2,
    "WH-005": 79.8,
    "WH-006": 45.6,
    "WH-007": 88.2,
    "WH-008": 67.4
  }
}', NULL, '2026-09-30 11:50:42.238000'),
  ('SIM_20260924_D055', 'SIM_20260924_D055', 'Reroute SHP-017 to Shanghai Bonded Warehouse', 'Simulation branch with 1 actions applied', 'TJIA', '2026-09-24 16:14:01.752000', 'ACTIVE', '[
  {
    "actionTypeId": "REROUTE_SHIPMENT",
    "parameters": {
      "new_warehouse_id": "WH-004",
      "reason": "Auto-analyze: reduce WH-007 utilization from 91.7%",
      "shipment_id": "SHP-017"
    },
    "status": "APPLIED"
  }
]', '{
  "delayedShipments": 1,
  "maxUtilization": 88.3,
  "openPoValue": 376200,
  "warehouseUtilization": {
    "WH-001": 72.5,
    "WH-002": 61,
    "WH-003": 88.3,
    "WH-004": 58.7,
    "WH-005": 79.8,
    "WH-006": 42.1,
    "WH-007": 88.2,
    "WH-008": 67.4
  }
}', NULL, NULL),
  ('SIM_20260924_FE71', 'SIM_20260924_FE71', 'Reroute SHP-018 via Austin Finished Goods Depot', 'Simulation branch with 1 actions applied', 'TJIA', '2026-09-24 16:22:50.848000', 'ACTIVE', '[
  {
    "actionTypeId": "REROUTE_SHIPMENT",
    "parameters": {
      "new_warehouse_id": "WH-002",
      "reason": "Auto-analyze: reroute via Austin Finished Goods Depot",
      "shipment_id": "SHP-018"
    },
    "status": "APPLIED"
  }
]', '{
  "delayedShipments": 0,
  "maxUtilization": 91.7,
  "openPoValue": 376200,
  "warehouseUtilization": {
    "WH-001": 69,
    "WH-002": 64.5,
    "WH-003": 88.3,
    "WH-004": 55.2,
    "WH-005": 79.8,
    "WH-006": 42.1,
    "WH-007": 91.7,
    "WH-008": 67.4
  }
}', NULL, NULL),
  ('SIM_20260924_A78E', 'SIM_20260924_A78E', 'Reroute SHP-018 via Shanghai Bonded Warehouse', 'Simulation branch with 1 actions applied', 'TJIA', '2026-09-24 16:23:10.146000', 'ACTIVE', '[
  {
    "actionTypeId": "REROUTE_SHIPMENT",
    "parameters": {
      "new_warehouse_id": "WH-004",
      "reason": "Auto-analyze: reroute via Shanghai Bonded Warehouse",
      "shipment_id": "SHP-018"
    },
    "status": "APPLIED"
  }
]', '{
  "delayedShipments": 0,
  "maxUtilization": 91.7,
  "openPoValue": 376200,
  "warehouseUtilization": {
    "WH-001": 69,
    "WH-002": 61,
    "WH-003": 88.3,
    "WH-004": 58.7,
    "WH-005": 79.8,
    "WH-006": 42.1,
    "WH-007": 91.7,
    "WH-008": 67.4
  }
}', NULL, NULL),
  ('SIM_20260930_4C8E', 'SIM_20260930_4C8E', 'Reroute SHP-017 to Monterrey Cross-Dock Facility', 'Simulation branch with 1 actions applied', 'TJIA', '2026-09-30 11:50:06.503000', 'ACTIVE', '[
  {
    "actionTypeId": "REROUTE_SHIPMENT",
    "parameters": {
      "new_warehouse_id": "WH-006",
      "reason": "Auto-analyze: reduce WH-007 utilization from 91.7%",
      "shipment_id": "SHP-017"
    },
    "status": "APPLIED"
  }
]', '{
  "delayedShipments": 1,
  "maxUtilization": 88.3,
  "openPoValue": 376200,
  "warehouseUtilization": {
    "WH-001": 72.5,
    "WH-002": 61,
    "WH-003": 88.3,
    "WH-004": 55.2,
    "WH-005": 79.8,
    "WH-006": 45.6,
    "WH-007": 88.2,
    "WH-008": 67.4
  }
}', NULL, NULL),
  ('SIM_20260930_5FE9', 'SIM_20260930_5FE9', 'Reroute SHP-017 to Shanghai Bonded Warehouse', 'Simulation branch with 1 actions applied', 'TJIA', '2026-09-30 11:50:26.403000', 'ACTIVE', '[
  {
    "actionTypeId": "REROUTE_SHIPMENT",
    "parameters": {
      "new_warehouse_id": "WH-004",
      "reason": "Auto-analyze: reduce WH-007 utilization from 91.7%",
      "shipment_id": "SHP-017"
    },
    "status": "APPLIED"
  }
]', '{
  "delayedShipments": 1,
  "maxUtilization": 88.3,
  "openPoValue": 376200,
  "warehouseUtilization": {
    "WH-001": 72.5,
    "WH-002": 61,
    "WH-003": 88.3,
    "WH-004": 58.7,
    "WH-005": 79.8,
    "WH-006": 42.1,
    "WH-007": 88.2,
    "WH-008": 67.4
  }
}', NULL, NULL),
  ('SIM_20260930_D462', 'SIM_20260930_D462', 'Reroute Shipment: SHP-018, WH-002', 'Simulation branch with 1 actions applied', 'TJIA', '2026-09-30 11:50:40.296000', 'ACTIVE', '[
  {
    "actionTypeId": "REROUTE_SHIPMENT",
    "parameters": {
      "new_warehouse_id": "WH-002",
      "reason": "",
      "shipment_id": "SHP-018"
    },
    "status": "APPLIED"
  }
]', '{
  "delayedShipments": 0,
  "maxUtilization": 91.7,
  "openPoValue": 376200,
  "warehouseUtilization": {
    "WH-001": 69,
    "WH-002": 64.5,
    "WH-003": 88.3,
    "WH-004": 55.2,
    "WH-005": 79.8,
    "WH-006": 42.1,
    "WH-007": 91.7,
    "WH-008": 67.4
  }
}', NULL, NULL),
  ('SIM_20260930_F75D', 'SIM_20260930_F75D', 'Reroute SHP-018 via Austin Finished Goods Depot', 'Simulation branch with 1 actions applied', 'TJIA', '2026-09-30 11:52:29.253000', 'DROPPED', '[
  {
    "actionTypeId": "REROUTE_SHIPMENT",
    "parameters": {
      "new_warehouse_id": "WH-002",
      "reason": "Auto-analyze: reroute via Austin Finished Goods Depot",
      "shipment_id": "SHP-018"
    },
    "status": "APPLIED"
  }
]', '{
  "delayedShipments": 0,
  "maxUtilization": 91.7,
  "openPoValue": 376200,
  "warehouseUtilization": {
    "WH-001": 69,
    "WH-002": 64.5,
    "WH-003": 88.3,
    "WH-004": 55.2,
    "WH-005": 79.8,
    "WH-006": 42.1,
    "WH-007": 91.7,
    "WH-008": 67.4
  }
}', NULL, '2026-09-30 12:06:41.050000'),
  ('SIM_20260930_F330', 'SIM_20260930_F330', 'Reroute SHP-018 via Shanghai Bonded Warehouse', 'Simulation branch with 1 actions applied', 'TJIA', '2026-09-30 11:52:49.484000', 'DROPPED', '[
  {
    "actionTypeId": "REROUTE_SHIPMENT",
    "parameters": {
      "new_warehouse_id": "WH-004",
      "reason": "Auto-analyze: reroute via Shanghai Bonded Warehouse",
      "shipment_id": "SHP-018"
    },
    "status": "APPLIED"
  }
]', '{
  "delayedShipments": 0,
  "maxUtilization": 91.7,
  "openPoValue": 376200,
  "warehouseUtilization": {
    "WH-001": 69,
    "WH-002": 61,
    "WH-003": 88.3,
    "WH-004": 58.7,
    "WH-005": 79.8,
    "WH-006": 42.1,
    "WH-007": 91.7,
    "WH-008": 67.4
  }
}', NULL, '2026-09-30 11:56:46.274000');

-- WAREHOUSES
CREATE OR REPLACE TABLE WAREHOUSES (
	WAREHOUSE_ID VARCHAR(10),
	WAREHOUSE_NAME VARCHAR(100),
	PLANT_ID VARCHAR(10),
	CITY VARCHAR(50),
	COUNTRY VARCHAR(5),
	CAPACITY_UNITS NUMBER(38,0),
	CURRENT_UTILIZATION_PCT NUMBER(5,1)
);

INSERT INTO WAREHOUSES (WAREHOUSE_ID, WAREHOUSE_NAME, PLANT_ID, CITY, COUNTRY, CAPACITY_UNITS, CURRENT_UTILIZATION_PCT)
VALUES
  ('WH-001', 'Austin Raw Materials Hub', 'PLT-001', 'Austin', 'US', 50000, '72.5'),
  ('WH-002', 'Austin Finished Goods Depot', 'PLT-001', 'Austin', 'US', 35000, '61.0'),
  ('WH-003', 'Stuttgart Inbound Logistics Center', 'PLT-002', 'Stuttgart', 'DE', 40000, '88.3'),
  ('WH-004', 'Shanghai Bonded Warehouse', 'PLT-003', 'Shanghai', 'CN', 60000, '55.2'),
  ('WH-005', 'Shanghai Distribution Center', 'PLT-003', 'Shanghai', 'CN', 45000, '79.8'),
  ('WH-006', 'Monterrey Cross-Dock Facility', 'PLT-004', 'Monterrey', 'MX', 30000, '42.1'),
  ('WH-007', 'Nagoya JIT Storage', 'PLT-005', 'Nagoya', 'JP', 25000, '91.7'),
  ('WH-008', 'Houston Regional Distribution Hub', 'PLT-001', 'Houston', 'US', 55000, '67.4');

