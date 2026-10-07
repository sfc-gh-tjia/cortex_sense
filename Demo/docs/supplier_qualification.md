# Supplier Qualification Handbook
## Version 3.1 | Quality Assurance Department

### 1. Vendor Account Group Codes (KTOKK)

The SAP vendor account group code (field: KTOKK in table LFA1) determines a supplier's status and what business activities are permitted:

| Code | Classification | Meaning | PO Allowed? | Max PO Value |
|------|---------------|---------|-------------|--------------|
| ZSTR | Strategic     | Top-tier supplier with executive relationship, proven track record, and high annual spend | Yes | Unlimited |
| ZSTD | Standard      | Qualified supplier that has passed probation and meets baseline requirements | Yes | $500,000/order |
| ZPRB | Probationary  | New or demoted supplier under enhanced monitoring. Restricted purchasing. | Limited | $25,000/order |

**Important**: When counting "active" or "qualified" suppliers, ZPRB vendors must be EXCLUDED. The canonical supplier count uses `COUNT(DISTINCT LIFNR) WHERE KTOKK IN ('ZSTR','ZSTD')`. Including ZPRB vendors in active supplier counts is a common error that overstates our qualified supply base.

### 2. Qualification Matrix

A supplier must meet ALL of the following criteria to be qualified for a material:

| Criterion | ZSTR Threshold | ZSTD Threshold | ZPRB Threshold |
|-----------|---------------|---------------|----------------|
| Defect rate (QAESSION) | < 1.0% | < 2.0% | < 5.0% |
| On-time delivery | > 95% | > 85% | > 70% |
| Financial health (D&B) | Score >= 7 | Score >= 5 | Score >= 3 |
| Documentation compliance | 100% | 95% | 90% |

The QUAL_MATRIX table in SAP_PRODUCTION stores the current qualification status per supplier-material pair.

### 3. Probationary Period Rules

When a supplier is placed on ZPRB status:
1. **Duration**: Minimum 90 days, extendable to 180 days
2. **PO restrictions**: Maximum $25,000 per order, no blanket POs
3. **Inspection**: 100% incoming inspection on all deliveries
4. **Reviews**: Monthly quality review meetings with supplier
5. **Exit criteria**: Pass 3 consecutive quality audits with defect rate below 2%
6. **Escalation**: If 2 audits fail during probation, the supplier is de-qualified entirely

### 4. Re-Qualification Schedule

| Supplier Type | Re-qualification Frequency | Audit Scope |
|--------------|--------------------------|-------------|
| ZSTR (Strategic) | Every 18 months | Full supply chain audit + financial review |
| ZSTD (Standard)  | Every 12 months | Quality audit + delivery performance review |
| ZPRB (Probationary) | Every 90 days | Full quality audit + corrective action verification |

Re-qualification is tracked by the CERTIFICATION_EXPIRY field in the ARIBA_SUPPLIERS system. Suppliers with expired certifications should not receive new purchase orders until re-qualified.

### 5. Cross-System Entity Resolution

The same supplier may appear under different identifiers across systems:
- **SAP**: LIFNR (e.g., V10045)
- **Ariba**: SUPPLIER_PROFILE_ID (e.g., ARIBA-SP-2001)
- **D&B Risk**: SUPPLIER_NAME (e.g., "Shenzhen Electronics")
- **Internal Mapping**: SAP_VENDOR_MAPPING table links SUP-xxx to LIFNR

When looking up a supplier, always check the SAP_VENDOR_MAPPING table to resolve across systems. Name matching alone is unreliable due to abbreviations and regional variations (e.g., "Shenzhen Electronics Co. Ltd" in SAP vs "Shenzhen Electronics" in D&B).
