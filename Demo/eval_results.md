# Cortex Agent Eval: Sense vs Baseline (25 Questions)

**Date:** October 6, 2026
**Sense Agent:** `DB_ONTOLOGY_CONTROL_PLANE.SAP_PRODUCTION.SAP_SUPPLY_CHAIN_AGENT`
**Baseline Agent:** `DB_ONTOLOGY_CONTROL_PLANE.SAP_PRODUCTION.BASELINE_SUPPLY_CHAIN_AGENT`

## Scoring Key

- **✓** — Correct / comprehensive answer
- **~** — Partial (answered but missed key elements or used wrong data)
- **✗** — Wrong, couldn't answer, or errored

---

## Per-Question Results

| ID | Tier | Question (short) | Sense Answer Summary | Baseline Answer Summary | Sense | Baseline |
|----|------|-------------------|----------------------|------------------------|-------|----------|
| Q1 | T1 | How many vendors? | 15 vendors (LFA1) | 15 vendors (LFA1) | ✓ | ✓ |
| Q2 | T1 | Total net order value by vendor? | All 15 vendors ranked; top: Guangzhou $177.5K | Same results, top: Guangzhou $177.5K | ✓ | ✓ |
| Q3 | T1 | Highest PO quantities? | MAT-001 Ceramic Cap 300K, MAT-011 Magnet 90K, MAT-004 53K | Same ranking and values | ✓ | ✓ |
| Q4 | T1 | List plants and regions? | 5 plants: Austin, Stuttgart, Shanghai, Monterrey, Nagoya across 3 regions | Same 5 plants and regions | ✓ | ✓ |
| Q5 | T1 | Freight costs by forwarding agent? | SkyBridge $15.2K leads, total $51.25K across 6 agents | Same values and ranking | ✓ | ✓ |
| Q6 | T1 | BOM components for BOM-003? | Correctly identified BOM-003 doesn't exist; found ASSY-003 equivalent, offered to pull | Found ASSY-003 and showed all 5 components with sub-assemblies | ✓ | ✓ |
| Q7 | T1 | Vendor contracts expiring soonest? | Shenzhen Dec 2026 ($4.5M), Bayern Feb 2027 ($7M), Tokyo Dec 2027 ($5.2M) | Same 3 contracts, same dates and values | ✓ | ✓ |
| Q8 | T2 | Suppliers across all systems? | Found 2 systems: 50 (Supply Chain) + 15 (SAP) = 65 records, noted dedup needed | Only found SAP's 15 vendors; missed Supply Chain system entirely | ✓ | ~ |
| Q9 | T2 | Annual spend with Shenzhen Electronics? | FY2025: $63K, FY2024: $26.4K from BSEG (missed Ariba $4.25M) | Same: FY2025 $63K, FY2024 $26.4K (also missed Ariba) | ~ | ~ |
| Q10 | T2 | Which suppliers are high-risk? | Found Acme Components (disrupted, reliability 82) from SUPPLIERS table | Built quality-based risk from QALS: Monterrey/Tokyo 15% defect rate, with spend weighting | ~ | ~ |
| Q11 | T2 | On-time delivery rate? | Two sources: 67.2% from actual shipments + 90% carrier SLA (LFA2) | Only LFA2 carrier average: 90% | ✓ | ~ |
| Q12 | T2 | Which materials are semiconductors? | Could not answer; confused by "semiconductor" terminology | Found MAT-004, MAT-008, MAT-013 by searching descriptions in MARA | ✗ | ✓ |
| Q13 | T2 | Materials with only one supplier? | 68 single-source materials from SUPPLIER_MATERIALS | 14 single-source from SAP PO history (EKPO) | ✓ | ✓ |
| Q14 | T2 | Supplier Health Index for Shenzhen? | No SHI metric; provided reliability score 83, status active | No SHI metric; offered to build scorecard from components | ~ | ~ |
| Q15 | T3 | Trace delivery chain Shenzhen→Austin? | Full multi-hop: V10045→PO-2025-011→WH-004→CAR-006/SHP-001→PLT-001 | Same chain with same detail level | ✓ | ✓ |
| Q16 | T3 | Full BOM for Ruggedized Enclosure? | Complete recursive BOM: ASSY-003 with 5 L1 components, 7 L2 sub-components | Same recursive BOM with identical detail | ✓ | ✓ |
| Q17 | T3 | Shenzhen Electronics disruption impact? | Multi-system: 9 materials, 4 sole-source, 20 products, 164 open orders, 19 at-risk | SAP-only: 2 materials (MAT-001, MAT-013), 2 plants, $74K PO + $4.5M contract | ✓ | ~ |
| Q18 | T3 | Suppliers feeding Nagoya plant? | 3 direct suppliers (Osaka, Nagoya Steel, Schwarzwald); no indirect | 3 direct suppliers; confirmed no indirect via shipment trace | ✓ | ✓ |
| Q19 | T4 | Ceramic capacitor supply risk? | Broad analysis: 30 ceramic suppliers, 7 single-source, 3 no-supplier, 383 orders exposed | Deep SAP analysis: MAT-001 sole-sourced from Shenzhen, 18-month PO gap, 2 BOMs, quality clean | ✓ | ✓ |
| Q20 | T4 | Top 3 for contract renewal? | Shenzhen (86d, $4.5M), Bayern (145d, $7M), Tokyo (451d, $5.2M) with expired-contract flag | Bayern ($7M, quality 0%), Shenzhen (350K units), Advanced Silicon ($2.8M, urgent expiry) | ✓ | ✓ |
| Q21 | T4 | Nagoya JIT Storage blast radius? | 3 shipments, 2 materials (MAT-004, MAT-016), 49K units, single carrier | Same + extended to $276K procurement, BOM propagation, quality notes | ✓ | ✓ |
| Q22 | T4 | Compare ocean carriers value vs reliability? | Used CARRIERS table: IndoPacific Lines best value (80 perf/$7), OceanLink close 2nd | Used SAP LIKP+LFA2: Shenzhen Coastal best (89% OTD, $0.061/unit) | ✓ | ✓ |
| Q23 | T4 | Biggest concentration risk? | 68/192 materials single-sourced (43%); Seoul Precision = biggest point of failure (4 materials, 11 products) | Material group 047 rare-earth: 84% from Guangzhou (China), single-source | ✓ | ✓ |
| Q24 | T4 | Supplier risk scorecard, top 3 riskiest? | Nagoya Steel, Osaka Precision, Guangzhou Rare Earth (all 70.0 composite) across 4 dimensions | Monterrey Packaging (0.77), Pacific Metals (0.70), Osaka Precision (0.63) across 3 dimensions | ✓ | ✓ |
| Q25 | T4 | Reduce single-country electronics dependency? | 19 electronic materials, 8 sole-sourced, East Asia dominant (10/19); region-level analysis | Material-level: every part single-sourced/single-country; 4 countries spread but no backups | ✓ | ✓ |

---

## Per-Tier Summary

| Tier | Description | Sense Score | Baseline Score |
|------|-------------|-------------|----------------|
| T1 (Q1-Q7) | Baseline Can Answer | 7/7 | 7/7 |
| T2 (Q8-Q14) | Sense Advantage | 4✓ 2~ 1✗ | 2✓ 4~ 1✓ |
| T3 (Q15-Q18) | Sense-Only | 4/4 | 3✓ 1~ |
| T4 (Q19-Q25) | Strategic | 7/7 | 7/7 |

---

## Overall Totals

| Agent | ✓ (Full) | ~ (Partial) | ✗ (Wrong) | Score |
|-------|----------|-------------|-----------|-------|
| **Sense** | 22 | 2 | 1 | **22/25** |
| **Baseline** | 20 | 4 | 0* | **20/25** |

*Note: Baseline never fully failed — it always found something to say, even if incomplete.

---

## Key Findings

### Where Sense Added the Most Value

1. **Cross-system awareness (Q8):** Sense found suppliers in both SAP (LFA1, 15 vendors) and Supply Chain (SUPPLIERS, 50) systems. Baseline only saw SAP.
2. **Operational delivery metrics (Q11):** Sense computed the actual 67.2% on-time rate from shipment records AND the 90% carrier SLA. Baseline only found the SLA.
3. **Disruption impact analysis (Q17):** Sense traced Shenzhen Electronics through the Supply Chain ontology: 9 materials, 20 products, 164 open orders. Baseline was limited to SAP's 2 materials and $74K PO exposure.
4. **Single-source analysis (Q13):** Sense identified 68 single-source materials from the broader SUPPLIER_MATERIALS table vs. Baseline's 14 from PO history alone.

### Where Baseline Held Up

1. **All Tier 1 questions (Q1-Q7):** Perfect parity. Both agents handled straightforward SAP queries identically.
2. **Strategic analysis (T4):** Baseline matched Sense on all 7 strategic questions, often with more detail. Its ceramic capacitor risk assessment (Q19) was arguably more actionable (flagged the 18-month PO gap).
3. **BOM explosion (Q16):** Both delivered identical recursive BOM results.
4. **Delivery chain tracing (Q15):** Both traced the same Shenzhen→Austin path with equivalent detail.

### Surprises

1. **Q12 (semiconductors):** Sense FAILED where Baseline succeeded. Sense got confused by the term "semiconductor" and refused to answer, while Baseline pragmatically searched material descriptions and found the correct 3 materials.
2. **Q9 (Shenzhen spend):** Neither agent found the expected $4.25M Ariba spend — both reported only $63K from SAP BSEG. The Ariba data source may not be connected to either agent.
3. **Q10 (high-risk suppliers):** Both agents answered differently but partially. Sense used the SUPPLIERS.STATUS field (operational risk), Baseline used QALS defect rates (quality risk). Neither found the expected DNB risk scores.
4. **Baseline's strategic depth:** On Tier 4 questions, Baseline often produced longer, more structured analyses than Sense. Its Q19 (ceramic capacitor) and Q24 (risk scorecard) responses were exceptionally detailed.
5. **Sense's cross-system reach didn't always help:** Having access to the broader Supply Chain ontology sometimes led Sense to use the wrong data source (e.g., Q12) or provide broader but less precise answers (e.g., Q10 using STATUS vs. Baseline's defect-rate analysis).

### Summary

Sense's primary advantage is **cross-system visibility** — it can see and join data across SAP and Supply Chain ontology tables, which matters for supplier counting, single-source analysis, and disruption impact tracing. However, for SAP-native questions and strategic analysis, Baseline performs at near-parity and sometimes produces more detailed, actionable responses. The Sense agent's one failure (Q12) was a case where broader context actually hurt — it overthought the question instead of simply searching the data.
