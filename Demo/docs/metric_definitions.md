# Official Metric Definitions
## Finance & Operations | Approved by CFO and VP Operations
## Last reviewed: Q4 2025

These are the canonical metric definitions for reporting and agent use. When multiple calculation methods exist, the definition below is authoritative.

---

### Cost of Goods Sold (COGS)

**Definition**: Total cost of materials and services invoiced by suppliers, net of credit memos and returns.

**Formula**: `SUM(DMBTR WHERE BSCHL = '31') - SUM(DMBTR WHERE BSCHL = '34')` from BSEG table.

- BSCHL 31 = Vendor invoices (add)
- BSCHL 34 = Credit memos / returns (subtract)

**Correct answer**: $1,542,520

**Common error**: Using `SUM(DMBTR)` without separating posting keys, or only including BSCHL=31 without subtracting BSCHL=34 credits. This overstates COGS to approximately $1,606,190.

---

### On-Time Delivery Rate

**Definition**: Percentage of completed shipments where goods were issued on or before the promised delivery date.

**Formula**: `COUNT(WADAT <= LFDAT) / COUNT(*) WHERE STATU = 'DLVD'` from LIKP table.

**Correct answer**: 66.7% (operational)

**Common error**: Using the OTRAT field from the LFA2 (carrier) table. OTRAT is the carrier's self-reported on-time rate and is typically inflated (shows ~90%). Always use the operational definition based on actual dates.

**Why the difference matters**: OTRAT reflects the carrier's internal measurement (may include "delivered within 1 day" as on-time). Our operational definition is strict: goods issue date must be on or before the promised date, no exceptions.

---

### Canonical Supplier Count

**Definition**: Number of distinct qualified (non-probationary) suppliers.

**Formula**: `COUNT(DISTINCT LIFNR) FROM LFA1 WHERE KTOKK IN ('ZSTR', 'ZSTD')`

**Correct answer**: 14

**Common error**: Including ZPRB (probationary) vendors gives 15. Probationary vendors are under enhanced monitoring and restricted purchasing — they should NOT be counted as part of the active supply base.

---

### Weighted Supply Risk Score

**Definition**: Composite risk score per material combining single-source dependency, quality defect history, and delivery reliability.

**Formula**: `0.4 * single_source_flag + 0.3 * defect_rate + 0.3 * (1 - on_time_rate)`

- **single_source_flag**: 1.0 if material has only one qualified supplier (KTOKK in ZSTR, ZSTD), else 0.0
- **defect_rate**: Average QAESSION from QALS for that material
- **on_time_rate**: Fraction of shipments for that material where WADAT <= LFDAT

**Highest risk material**: MAT-006 at 0.70

**Common error**: Using weights 40/35/25 (incorrect) instead of 40/30/30 (correct).

---

### Gross Margin

**Definition**: Revenue from sales minus the true material cost calculated by BOM rollup.

**Formula**: `SUM(VBAP.NETWR) - SUM(BOM_component_qty * component_STPRS)` for each assembly

- Revenue comes from VBAP (sales orders)
- Cost must use recursive BOM rollup from STPO, multiplying component quantities by their STPRS from MARA
- This gives the TRUE manufacturing cost per assembly

**Common error**: Using the assembly's own STPRS (standard price) as the cost instead of rolling up the BOM. The assembly STPRS is an inventory valuation price, not the actual material cost. For example, ASSY-004 has STPRS of $520 but true BOM cost of $286.60.

---

### Revenue Lost to Discounts

**Definition**: Total discount value granted to customers.

**Formula**: `SUM(KWERT) FROM KONV WHERE KSCHL = 'K007'`

**Correct answer**: $34,085

**Common error**: Including KSCHL = 'KF00' (freight surcharges) in the discount total. KF00 is a cost surcharge, not a revenue discount.

---

### Cost Center Allocation

**Definition**: Total cost allocated to a specific manufacturing cost center.

**Formula**: `SUM(WRTBTR) FROM COEP WHERE OBJNR = '<cost_object_id>'`

For US Manufacturing: OBJNR = 'KS-MFG-US', result = $419,750.
