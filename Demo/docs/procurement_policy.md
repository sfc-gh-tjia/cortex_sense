# Procurement Policy Manual
## Effective: January 2025 | Revision 4.2 | Owner: VP Procurement

### 1. Discount Approval Authority

| Discount Range | Approval Required | Turnaround SLA |
|----------------|-------------------|----------------|
| 0% - 5%        | Buyer (auto-approved) | Immediate |
| 5.01% - 10%    | Procurement Manager   | 24 hours  |
| 10.01% - 20%   | VP Procurement        | 48 hours  |
| Above 20%      | CFO + VP Procurement  | 72 hours  |

All discounts above 10% require written justification including competitive pricing evidence and volume commitment documentation.

### 2. Sole-Source Policy

**Critical materials** (as classified in the Material Categories hierarchy) **must not be single-sourced**. If a material has only one qualified supplier, the procurement team must:
1. Initiate a qualification process for at least one backup supplier within 90 days
2. Maintain 6 weeks of safety stock (vs standard 2-4 weeks)
3. Report the single-source risk to the Supply Chain Risk Committee quarterly

Exception: Materials with annual spend below $50,000 are exempt from the dual-source requirement.

### 3. Payment Terms

| Supplier Classification | Standard Terms | Extended Terms (requires approval) |
|------------------------|----------------|-----------------------------------|
| ZSTR (Strategic)       | Net-30         | Net-60 (VP Procurement approval)  |
| ZSTD (Standard)        | Net-30         | Not available                     |
| ZPRB (Probationary)    | Net-15 prepay  | Not available                     |

Strategic suppliers with 3+ years of history and zero critical incidents may qualify for Net-60 terms with VP Procurement approval.

### 4. Supplier Qualification & Disqualification

#### 4.1 New Supplier Qualification
New suppliers enter as ZPRB (Probationary) status for a minimum of 90 days. During probation:
- No purchase orders exceeding $25,000 per order
- 100% incoming inspection on all deliveries
- Monthly quality review meetings required
- Must pass 3 consecutive quality audits to advance to ZSTD

#### 4.2 Advancement to Strategic (ZSTR)
Requirements: 12+ months as ZSTD, zero critical incidents, on-time delivery rate above 95%, annual spend above $500,000, executive sponsor relationship established.

#### 4.3 Three-Strike Rule
Any supplier accumulating 3 critical quality incidents within a rolling 12-month period is automatically placed on ZPRB (Probationary) status. All new POs are suspended pending a full audit. The supplier must pass a comprehensive re-qualification audit to be reinstated.

### 5. Emergency Procurement

For production-critical shortages requiring immediate procurement:
1. Emergency PO authorization: SVP Operations sign-off within 4 hours
2. Maximum emergency PO value: $100,000 without full competitive bidding
3. Expedite premium: up to 25% above standard pricing authorized for genuine emergencies
4. Post-emergency review: full procurement review within 5 business days
5. Emergency POs must be tagged with reason code "EMRG" in SAP for audit trail

### 6. Contract Renewal

All supplier contracts must be reviewed 90 days before expiration. The review checklist includes:
- Year-over-year price comparison
- Quality performance trend (from SUPPLIER_SCORECARDS)
- On-time delivery rate (operational definition: WADAT <= LFDAT)
- Open incident count from INCIDENT_LOG
- Market price benchmarking from at least 2 alternative suppliers
