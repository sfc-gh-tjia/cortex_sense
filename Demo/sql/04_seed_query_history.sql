-- =============================================================================
-- 02_seed_query_history.sql
-- Runs 25 realistic analyst queries to build query history patterns.
-- Cortex Sense auto-ingests these to learn popular joins, filters, and patterns.
-- RUN THIS BEFORE setting up Cortex Sense so the history is available at build time.
-- =============================================================================

USE DATABASE DB_ONTOLOGY_CONTROL_PLANE;
USE SCHEMA SAP_PRODUCTION;
USE WAREHOUSE ONTOLOGY_WH;

-- =====================================================================
-- PATTERN 1: Spend by vendor EXCLUDING probationary (run 5x variants)
-- Teaches Sense: always filter KTOKK != 'ZPRB' for spend analysis
-- =====================================================================

-- 1a: Total spend by vendor (standard pattern)
SELECT l.LIFNR, l.NAME1 AS vendor_name, SUM(e.NETWR) AS total_spend
FROM EKPO e JOIN LFA1 l ON e.LIFNR = l.LIFNR
WHERE l.KTOKK != 'ZPRB'
GROUP BY l.LIFNR, l.NAME1
ORDER BY total_spend DESC;

-- 1b: Spend by vendor and material group
SELECT l.NAME1, m.MATKL, SUM(e.NETWR) AS spend
FROM EKPO e JOIN LFA1 l ON e.LIFNR = l.LIFNR JOIN MARA m ON e.MATNR = m.MATNR
WHERE l.KTOKK IN ('ZSTR','ZSTD')
GROUP BY l.NAME1, m.MATKL
ORDER BY spend DESC;

-- 1c: Top 5 vendors by spend (qualified only)
SELECT l.LIFNR, l.NAME1, l.KTOKK, SUM(e.NETWR) AS total_spend
FROM EKPO e JOIN LFA1 l ON e.LIFNR = l.LIFNR
WHERE l.KTOKK != 'ZPRB'
GROUP BY l.LIFNR, l.NAME1, l.KTOKK
ORDER BY total_spend DESC
LIMIT 5;

-- 1d: Spend by country (excluding probationary)
SELECT l.LAND1 AS country, COUNT(DISTINCT l.LIFNR) AS vendor_count, SUM(e.NETWR) AS total_spend
FROM EKPO e JOIN LFA1 l ON e.LIFNR = l.LIFNR
WHERE l.KTOKK != 'ZPRB'
GROUP BY l.LAND1
ORDER BY total_spend DESC;

-- 1e: Monthly spend trend (qualified vendors)
SELECT DATE_TRUNC('month', e.BEDAT) AS month, SUM(e.NETWR) AS spend
FROM EKPO e JOIN LFA1 l ON e.LIFNR = l.LIFNR
WHERE l.KTOKK IN ('ZSTR','ZSTD')
GROUP BY month ORDER BY month;

-- =====================================================================
-- PATTERN 2: On-time delivery using operational definition (run 3x)
-- Teaches Sense: use WADAT <= LFDAT, NOT the OTRAT field
-- =====================================================================

-- 2a: Overall on-time rate (operational)
SELECT
    COUNT(*) AS total_shipments,
    SUM(CASE WHEN s.WADAT <= s.LFDAT THEN 1 ELSE 0 END) AS on_time,
    ROUND(100.0 * SUM(CASE WHEN s.WADAT <= s.LFDAT THEN 1 ELSE 0 END) / COUNT(*), 1) AS on_time_pct
FROM LIKP s WHERE s.STATU = 'D';

-- 2b: On-time by carrier
SELECT c.NAME1 AS carrier, c.TDLNR,
    COUNT(*) AS shipments,
    ROUND(100.0 * SUM(CASE WHEN s.WADAT <= s.LFDAT THEN 1 ELSE 0 END) / COUNT(*), 1) AS on_time_pct
FROM LIKP s JOIN LFA2 c ON s.TDLNR = c.TDLNR
WHERE s.STATU = 'D'
GROUP BY c.NAME1, c.TDLNR;

-- 2c: Late shipments detail
SELECT s.TKNUM, s.MATNR, s.TDLNR, s.LFDAT AS promised, s.WADAT AS actual,
    DATEDIFF('day', s.LFDAT, s.WADAT) AS days_late
FROM LIKP s
WHERE s.STATU = 'D' AND s.WADAT > s.LFDAT
ORDER BY days_late DESC;

-- =====================================================================
-- PATTERN 3: COGS with credit memo separation (run 4x)
-- Teaches Sense: BSCHL=31 is invoice, BSCHL=34 is credit memo
-- =====================================================================

-- 3a: COGS = invoices minus credit memos
SELECT
    SUM(CASE WHEN BSCHL = '31' THEN DMBTR ELSE 0 END) AS gross_invoices,
    SUM(CASE WHEN BSCHL = '34' THEN DMBTR ELSE 0 END) AS credit_memos,
    SUM(CASE WHEN BSCHL = '31' THEN DMBTR ELSE 0 END) - SUM(CASE WHEN BSCHL = '34' THEN DMBTR ELSE 0 END) AS net_cogs
FROM BSEG WHERE BSCHL IN ('31','34');

-- 3b: COGS by vendor
SELECT l.NAME1 AS vendor, b.LIFNR,
    SUM(CASE WHEN b.BSCHL = '31' THEN b.DMBTR ELSE 0 END) AS invoices,
    SUM(CASE WHEN b.BSCHL = '34' THEN b.DMBTR ELSE 0 END) AS credits,
    SUM(CASE WHEN b.BSCHL = '31' THEN b.DMBTR ELSE 0 END) - SUM(CASE WHEN b.BSCHL = '34' THEN b.DMBTR ELSE 0 END) AS net_cost
FROM BSEG b JOIN LFA1 l ON b.LIFNR = l.LIFNR
WHERE b.BSCHL IN ('31','34')
GROUP BY l.NAME1, b.LIFNR
ORDER BY net_cost DESC;

-- 3c: Monthly COGS trend
SELECT b.MONAT AS fiscal_period,
    SUM(CASE WHEN b.BSCHL = '31' THEN b.DMBTR ELSE 0 END) - SUM(CASE WHEN b.BSCHL = '34' THEN b.DMBTR ELSE 0 END) AS monthly_cogs
FROM BSEG b WHERE b.BSCHL IN ('31','34')
GROUP BY b.MONAT ORDER BY b.MONAT;

-- 3d: Credit memo ratio by vendor (high ratio = red flag)
SELECT b.LIFNR, l.NAME1,
    SUM(CASE WHEN b.BSCHL = '34' THEN b.DMBTR ELSE 0 END) AS credits,
    SUM(CASE WHEN b.BSCHL = '31' THEN b.DMBTR ELSE 0 END) AS invoices,
    ROUND(100.0 * SUM(CASE WHEN b.BSCHL = '34' THEN b.DMBTR ELSE 0 END) / NULLIF(SUM(CASE WHEN b.BSCHL = '31' THEN b.DMBTR ELSE 0 END), 0), 1) AS credit_pct
FROM BSEG b JOIN LFA1 l ON b.LIFNR = l.LIFNR
WHERE b.BSCHL IN ('31','34')
GROUP BY b.LIFNR, l.NAME1
HAVING SUM(CASE WHEN b.BSCHL = '34' THEN b.DMBTR ELSE 0 END) > 0
ORDER BY credit_pct DESC;

-- =====================================================================
-- PATTERN 4: Material group analysis (run 3x)
-- Teaches Sense: EKPO → MARA join on MATNR, GROUP BY MATKL
-- =====================================================================

-- 4a: Spend by material group
SELECT m.MATKL, COUNT(DISTINCT e.EBELN) AS po_count, SUM(e.NETWR) AS total_spend
FROM EKPO e JOIN MARA m ON e.MATNR = m.MATNR
GROUP BY m.MATKL ORDER BY total_spend DESC;

-- 4b: Unit price by material
SELECT m.MATNR, m.MAKTX, m.MATKL, m.STPRS AS std_price,
    AVG(e.NETWR / NULLIF(e.MENGE, 0)) AS avg_po_unit_price
FROM MARA m JOIN EKPO e ON m.MATNR = e.MATNR
GROUP BY m.MATNR, m.MAKTX, m.MATKL, m.STPRS;

-- 4c: Materials with no recent POs (potential obsolete)
SELECT m.MATNR, m.MAKTX, MAX(e.BEDAT) AS last_po_date
FROM MARA m LEFT JOIN EKPO e ON m.MATNR = e.MATNR
GROUP BY m.MATNR, m.MAKTX
ORDER BY last_po_date ASC NULLS FIRST;

-- =====================================================================
-- PATTERN 5: Cross-schema DNB risk queries (run 2x)
-- Teaches Sense: analysts DO query the DNB risk table even though it's not in the SV
-- =====================================================================

-- 5a: Risk scores for all suppliers
SELECT * FROM DNB_RISK_ASSESSMENTS ORDER BY OVERALL_RISK_SCORE DESC;

-- 5b: High-risk suppliers (score >= 5) with their SAP spend
SELECT d.SUPPLIER_NAME, d.COUNTRY, d.OVERALL_RISK_SCORE, d.RISK_FACTORS,
    SUM(e.NETWR) AS sap_spend
FROM DNB_RISK_ASSESSMENTS d
LEFT JOIN LFA1 l ON UPPER(l.NAME1) LIKE '%' || UPPER(SPLIT_PART(d.SUPPLIER_NAME, ' ', 1)) || '%'
LEFT JOIN EKPO e ON l.LIFNR = e.LIFNR
WHERE d.OVERALL_RISK_SCORE >= 5
GROUP BY d.SUPPLIER_NAME, d.COUNTRY, d.OVERALL_RISK_SCORE, d.RISK_FACTORS;

-- =====================================================================
-- PATTERN 6: Mixed analytical patterns (run 8x)
-- Teaches Sense: various real-world queries analysts run day-to-day
-- =====================================================================

-- 6a: Warehouse utilization
SELECT w.LGORT, w.LGOBE, w.WERKS, w.LKAPA AS capacity,
    COUNT(s.TKNUM) AS shipments_in_transit
FROM T320 w LEFT JOIN LIKP s ON w.LGORT = s.LGORT_SRC AND s.STATU = 'T'
GROUP BY w.LGORT, w.LGOBE, w.WERKS, w.LKAPA;

-- 6b: Sales revenue by customer
SELECT v.KUNNR, SUM(v.NETWR) AS revenue, COUNT(*) AS order_lines
FROM VBAP v GROUP BY v.KUNNR ORDER BY revenue DESC;

-- 6c: Plant-level procurement summary
SELECT p.WERKS, p.NAME1 AS plant_name, p.REGIO,
    COUNT(DISTINCT e.EBELN) AS po_count, SUM(e.NETWR) AS spend
FROM T001W p JOIN EKPO e ON p.WERKS = e.WERKS
GROUP BY p.WERKS, p.NAME1, p.REGIO;

-- 6d: Quality inspection pass/fail rates
SELECT m.MAKTX AS material, q.VCODE AS decision,
    COUNT(*) AS inspections, AVG(q.QAESSION) AS avg_defect_rate
FROM QALS q JOIN MARA m ON q.MATNR = m.MATNR
GROUP BY m.MAKTX, q.VCODE;

-- 6e: Contract value by vendor
SELECT l.NAME1, c.VTART AS contract_type, c.JWERT AS annual_value, c.DTEND AS expires
FROM LFB1 c JOIN LFA1 l ON c.LIFNR = l.LIFNR
ORDER BY c.JWERT DESC;

-- 6f: Cost center spending
SELECT OBJNR AS cost_object, SUM(WRTBTR) AS total_cost
FROM COEP GROUP BY OBJNR ORDER BY total_cost DESC;

-- 6g: Discount analysis by customer
SELECT k.KUNNR, k.KSCHL AS condition_type, SUM(k.KWERT) AS total_value
FROM KONV k WHERE k.KSCHL IN ('K007','KF00')
GROUP BY k.KUNNR, k.KSCHL;

-- 6h: BOM cost rollup for assemblies
SELECT parent.MAKTX AS assembly, child.MAKTX AS component,
    b.MENGE AS qty_per, child.STPRS AS unit_cost,
    b.MENGE * child.STPRS AS component_cost
FROM STPO b
JOIN MARA parent ON b.STLNR = parent.MATNR
JOIN MARA child ON b.IDNRK = child.MATNR
ORDER BY parent.MAKTX, component_cost DESC;
