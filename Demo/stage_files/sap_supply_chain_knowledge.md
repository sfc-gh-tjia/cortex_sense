# SAP Supply Chain Business Knowledge
## Business Ontology Export + Operational Policies + SAP Field Reference
## Source: Business Ontology (Supply Chain + SAP Purchasing domains) + Internal Documentation

---

# SECTION 1: METRIC DEFINITIONS

## Cost of Goods Sold (COGS)
- **Kind**: METRIC
- **Formula**: `SUM(DMBTR WHERE BSCHL = '31') - SUM(DMBTR WHERE BSCHL = '34')` from BSEG table
- BSCHL 31 = Vendor invoices (add to COGS)
- BSCHL 34 = Credit memos / returns (subtract from COGS)
- **Correct answer**: $1,542,520
- **Common error**: Using SUM(DMBTR) without separating posting keys overstates COGS to ~$1,606,190

## On-Time Delivery Rate
- **Kind**: METRIC
- **Formula**: `COUNT(WADAT <= LFDAT) / COUNT(*) WHERE STATU = 'D'` from LIKP table
- **Correct answer**: 66.7% (operational)
- **WARNING**: Do NOT use LFA2.OTRAT (carrier self-reported, shows ~90%). Use operational definition from LIKP actual vs promised dates.

## Canonical Supplier Count
- **Kind**: METRIC
- **Formula**: `COUNT(DISTINCT LIFNR) FROM LFA1 WHERE KTOKK IN ('ZSTR', 'ZSTD')`
- **Correct answer**: 14 (excludes ZPRB probationary vendors)
- **Common error**: Including ZPRB gives 15. Probationary vendors are excluded from the active supply base.

## Annual Supplier Spend
- **Kind**: METRIC
- There are TWO competing sources: (1) SAP Purchase Order totals — SUM of EKPO.NETWR, represents transactional spend. (2) Ariba annual_spend_usd — the procurement-system-of-record for contracted spend analytics.
- ALWAYS use Ariba annual_spend_usd for supplier spend analytics. SAP PO totals are operational, not authoritative for spend reporting.

## Total Procurement Spend
- **Kind**: METRIC
- **Formula**: `SUM(NETWR) FROM EKPO`
- Use EKPO.NETWR only. NOT LFB1.JWERT (contract annual values represent commitments, not actual spend).

## Weighted Supply Risk Score
- **Kind**: METRIC
- **Formula**: `0.4 * single_source_flag + 0.3 * defect_rate + 0.3 * (1 - on_time_rate)`
- single_source_flag: 1.0 if material has only one qualified supplier (KTOKK in ZSTR/ZSTD), else 0.0
- defect_rate: Average QAESSION from QALS for that material
- on_time_rate: Fraction of shipments where WADAT <= LFDAT
- **Highest risk material**: MAT-006 at 0.70
- Weights are FIXED business policy (40/30/30). Do NOT change.

## BOM Cost Rollup
- **Kind**: METRIC
- Recursive BOM explosion downward with quantity multiplication, JOIN MARA.STPRS for leaf material costs.
- For ASSY-004: $286.60/unit. Do NOT use the assembly STPRS ($520) — that is the selling price, not the material cost.

## BOM Explosion
- **Kind**: METRIC
- Full bill of materials explosion for an assembly — lists ALL raw materials including those nested inside sub-assemblies.
- The BILL_OF_MATERIALS table only shows direct parent-child relationships (BOM_LEVEL=1). To get the FULL BOM, you must RECURSIVELY traverse: if a child is itself an assembly, explode its children too.

## Gross Margin
- **Kind**: METRIC
- **Formula**: `SUM(VBAP.NETWR) - SUM(BOM_component_qty * component_STPRS)` for each assembly
- Revenue comes from VBAP (sales orders). Cost must use recursive BOM rollup from STPO.
- **Common error**: Using the assembly's own STPRS as cost instead of BOM rollup.

## Revenue Lost to Discounts
- **Kind**: METRIC
- **Formula**: `SUM(KWERT) FROM KONV WHERE KSCHL = 'K007'`
- **Correct answer**: $34,085
- Do NOT include KF00 (freight surcharges).

## Semiconductor Material
- **Kind**: METRIC
- Materials classified as semiconductors — a SUB-CATEGORY of Electronics (MATKL=043).
- Specifically: MAT-004 (MEMS Accelerometer IC), MAT-005 (RF Transceiver Module), MAT-006 (Power Management IC).

## Single-Sourced Material
- **Kind**: METRIC
- A material with only one supplier based on PO history. Represents supply chain risk.

## High-Risk Supplier
- **Kind**: METRIC
- OVERALL_RISK_SCORE >= 5 on DNB assessment. DNB_RISK_ASSESSMENTS uses SUPPLIER_NAME (text), NOT joinable to SAP vendor numbers directly.

## Delivery Chain
- **Kind**: METRIC
- Full path: Supplier -> Material (via PURCHASE_ORDERS) -> Shipment (via SHIPMENTS.MATERIAL_ID) -> Origin Warehouse -> Destination Plant.

## Supplier Disruption Impact
- **Kind**: METRIC
- To assess: 1) Find materials the supplier provides from SAP_PURCHASE_ORDERS. 2) Find open POs for those materials. 3) Check for alternative suppliers. 4) Calculate total exposure.

## Warehouse Offline Impact
- **Kind**: METRIC
- Assess: 1) Which shipments originate from this warehouse. 2) Which materials are in those shipments. 3) Which suppliers provide those materials. 4) Are there alternative warehouses?

## Cost Center Allocation
- **Kind**: METRIC
- **Formula**: `SUM(WRTBTR) FROM COEP WHERE OBJNR = '<cost_object_id>'`
- For US Manufacturing: OBJNR = 'KS-MFG-US', result = $419,750.

---

# SECTION 2: ENTITY DEFINITIONS

## Supplier
- **Table**: DB_ONTOLOGY_CONTROL_PLANE.RAW_SOURCES.SAP_VENDORS (15 rows, PK: VENDOR_NUMBER)
- Also in: DB_ONTOLOGY_CONTROL_PLANE.RAW_SOURCES.ARIBA_SUPPLIERS (10 rows, PK: ARIBA_PROFILE_ID)
- SAP and Ariba are DIFFERENT systems with different IDs. Cross-reference via DUNS_NUMBER. 7 suppliers appear in both. Canonical count = 18 unique (15 + 10 - 7).

## Material
- **Table**: DB_ONTOLOGY_CONTROL_PLANE.RAW_SOURCES.SAP_MATERIALS (23 rows including 3 assemblies)
- Key columns: MATERIAL_ID (PK), MATERIAL_NAME, MATERIAL_CATEGORY, STANDARD_PRICE_USD

## Purchase Order
- **Table**: DB_ONTOLOGY_CONTROL_PLANE.RAW_SOURCES.SAP_PURCHASE_ORDERS (25 rows)
- Key columns: PO_NUMBER (PK), SUPPLIER_ID (FK to SAP_VENDORS.VENDOR_NUMBER), MATERIAL_ID, PLANT_ID, NET_VALUE_USD

## Shipment
- **Table**: DB_ONTOLOGY_CONTROL_PLANE.RAW_SOURCES.SHIPMENTS (20 rows)
- Key columns: SHIPMENT_ID (PK), CARRIER_ID, ORIGIN_WAREHOUSE_ID, MATERIAL_ID

## Carrier
- **Table**: DB_ONTOLOGY_CONTROL_PLANE.RAW_SOURCES.CARRIERS (6 rows)
- WARNING: ON_TIME_RATE is carrier self-reported and unreliable (~90%). Use operational OTD from LIKP instead.

## Plant
- **Table**: DB_ONTOLOGY_CONTROL_PLANE.RAW_SOURCES.PLANTS (5 rows)
- Warehouses belong to plants via PLANT_ID.

## Warehouse
- **Table**: DB_ONTOLOGY_CONTROL_PLANE.RAW_SOURCES.WAREHOUSES (8 rows)
- Key columns: WAREHOUSE_ID, PLANT_ID, CAPACITY_UNITS, CURRENT_UTILIZATION_PCT

## Contract
- **Table**: DB_ONTOLOGY_CONTROL_PLANE.RAW_SOURCES.CONTRACTS (15 rows)
- Key columns: CONTRACT_ID, SUPPLIER_ID, CONTRACT_TYPE (Master/Framework/Spot), ANNUAL_VALUE_USD

## Inspection
- **Table**: DB_ONTOLOGY_CONTROL_PLANE.RAW_SOURCES.INSPECTIONS (10 rows)
- Key columns: INSPECTION_ID, MATERIAL_ID, DEFECT_RATE, DISPOSITION (Accept/Conditional Accept/Reject)

## Assembly
- **Table**: DB_ONTOLOGY_CONTROL_PLANE.RAW_SOURCES.SAP_MATERIALS WHERE MATERIAL_CATEGORY = 'Assembly'
- 3 assemblies: ASSY-001 ($45), ASSY-002 ($32), ASSY-003 ($28)

## AP Line Item (Accounting)
- **Table**: DB_ONTOLOGY_CONTROL_PLANE.SAP_PRODUCTION.SAP_BSEG (38 rows)
- Key columns: BELNR, HKONT (GL account), BSCHL (posting key: 31=Invoice, 34=Credit Memo), DMBTR (amount)

## Sales Order
- **Table**: DB_ONTOLOGY_CONTROL_PLANE.SAP_PRODUCTION.SAP_VBAP (13 rows)
- 4 finished assemblies sold to 5 customers across 3 sales orgs.

---

# SECTION 3: SAP FIELD CODE REFERENCE

## KTOKK (Vendor Account Group)
- ZSTR = Strategic partner
- ZSTD = Standard vendor
- ZPRB = Probationary (EXCLUDE from canonical supplier count)

## MATKL (Material Group)
- 043 = Electronics
- 044 = Chemicals
- 045 = Metals
- 046 = Packaging
- 047 = Raw Materials
- 048 = Assembly

## BSCHL (Posting Key)
- 31 = Vendor Invoice (ADD to COGS)
- 34 = Credit Memo (SUBTRACT from COGS)

## STATU codes (LIKP Shipments)
- D = Delivered
- T = In Transit
- X = Cancelled

## STATU codes (EKPO Purchase Orders)
- O = Open
- C = Closed
- R = Returned

---

# SECTION 4: PROCUREMENT POLICIES

## Discount Approval Thresholds
- < 5%: Buyer can approve
- 5-10%: Category Manager approval
- 10-15%: Procurement Director approval
- > 15%: VP Procurement + CFO approval

## Sole-Source Policy
- Annual spend > $100K requires documented justification
- Must be reviewed quarterly
- Emergency procurement: 72-hour temporary approval, retroactive PO required within 5 business days

## Three-Strike Rule
- 3 consecutive quarterly scores below C = automatic probation (KTOKK changed to ZPRB)
- Probationary vendors: restricted to existing POs only, no new contracts
- Recovery: 2 consecutive B+ ratings to return to ZSTD

## Payment Terms Policy
- Strategic (ZSTR): Net 60 standard, eligible for dynamic discounting
- Standard (ZSTD): Net 30 standard
- Probationary (ZPRB): Prepay or Net 15 only
