# Warehouse Operations Standard Operating Procedure
## Document ID: WH-SOP-2025-001 | Facilities & Logistics

### 1. Capacity Utilization Targets

| Utilization Range | Status | Action Required |
|------------------|--------|-----------------|
| Below 60%        | Under-utilized | Review allocation — consider consolidation |
| 60% - 85%        | Optimal | No action required |
| 85% - 90%        | Elevated | Monitor daily. Prepare overflow plan. |
| 90% - 95%        | Warning | Trigger rebalancing alert. Shift inventory to under-utilized locations. |
| Above 95%        | Critical | Immediate action required. No new inbound receipts until below 90%. Escalate to VP Operations. |

The LKAPA field in T320 (Storage Location Data) stores the current capacity percentage for each location.

### 2. Allocation Priority

When warehouse space is constrained (>85% utilization), allocate in this priority order:
1. **Safety stock** — minimum 2 weeks for standard materials, 6 weeks for critical/single-source
2. **In-transit receipts** — goods already on the way cannot be redirected
3. **Planned production** — materials needed for next 2-week production schedule
4. **Speculative orders** — advance purchases for price protection may be deferred

### 3. Hazardous Material Rules

- Maximum 30% of any single storage location's capacity may be hazmat
- Chemical solvents (material group MATKL = 044, including IPA) must be in locations with ventilation and spill containment
- Hazmat inventory must be segregated from food-grade and electronics components
- MSDS/SDS must be current (see INCIDENT_LOG for documentation incidents)

### 4. Temperature-Sensitive Storage

Only locations WH-003 and WH-007 have climate-controlled zones:
- Temperature range: 15-25 degrees C, humidity below 45%
- Required for: MEMS sensors (MAT-004, MAT-013), ceramic capacitors (MAT-001), epoxy resins (MAT-002)
- All other locations are ambient temperature only

### 5. Receiving Inspection Process

| Supplier Type | Inspection Level | Sample Size |
|--------------|-----------------|-------------|
| ZSTR (Strategic) | Skip lot (if last 3 lots passed) | N/A |
| ZSTD (Standard) | Normal (AQL 1.0) | Per ANSI Z1.4 |
| ZPRB (Probationary) | Tightened (100% inspection) | All units |

Inspection results are recorded in QALS (Inspection Lot Data). The VCODE field indicates the usage decision:
- A = Accepted
- R = Rejected
- C = Conditional acceptance (with deviation note)

### 6. Shipment Status Codes

The STATU field in LIKP (Shipment Data) uses these codes:
- DLVD = Delivered (goods received and confirmed)
- INTR = In Transit (shipped but not yet received)
- PEND = Pending (PO confirmed, not yet shipped)
- CNCL = Cancelled
- PART = Partially delivered
