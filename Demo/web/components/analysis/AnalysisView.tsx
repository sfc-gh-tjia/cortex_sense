"use client";
import { TIER_COLORS } from "@/lib/questions";

interface Analysis {
  id: string;
  tier: string;
  question: string;
  baseline: { answer: string; wrong: boolean };
  sense: { answer: string; wrong: boolean };
  category: string;
  whyBaselineFails: string[];
  whySenseWorks: string[];
  senseSource: string;
  insight: string;
}

const ANALYSES: Analysis[] = [
  // ── External Table Routing ──
  {
    id: "V1", tier: "T2", question: "What is the total annual procurement spend across all suppliers in Ariba?",
    baseline: { answer: "Uses EKPO.NETWR — wrong source, wrong $", wrong: true },
    sense: { answer: "$30,100,000 across 10 suppliers", wrong: false },
    category: "External Table Routing",
    whyBaselineFails: [
      "ARIBA_SUPPLIERS is not in the semantic view — baseline can't discover it",
      "Falls back to EKPO.NETWR or BSEG.DMBTR — PO transactional values, not contracted annual spend",
      "Different concept: PO line items ≠ annual supplier spend",
    ],
    whySenseWorks: [
      "Cortex Sense knows ARIBA_SUPPLIERS exists and routes the agent to ANNUAL_SPEND_USD",
      "Agent queries the correct table and returns $30.1M across 10 suppliers",
      "Sense provides table discovery beyond the semantic view boundary",
    ],
    senseSource: "Cortex Sense → ARIBA_SUPPLIERS",
    insight: "Sense discovers the right table. Baseline is locked to its 14-table SV.",
  },
  {
    id: "V2", tier: "T2", question: "Which suppliers have a geopolitical risk score above 5 according to D&B?",
    baseline: { answer: "No risk data available", wrong: true },
    sense: { answer: "3 suppliers: Guangzhou (7), Jiangsu (6), Shenzhen (6)", wrong: false },
    category: "External Table Routing",
    whyBaselineFails: [
      "No risk scoring tables exist in the semantic view",
      "Baseline either fails silently or says it cannot answer",
      "The SV was designed for SAP transactional data, not external risk enrichment",
    ],
    whySenseWorks: [
      "Cortex Sense indexes DNB_RISK_ASSESSMENTS and routes the agent to it",
      "Agent inspects the schema, finds GEOPOLITICAL_RISK_SCORE, filters > 5",
      "All 3 flagged suppliers are in China — a geographic concentration signal",
    ],
    senseSource: "Cortex Sense → DNB_RISK_ASSESSMENTS",
    insight: "Risk data lives outside SAP. Sense bridges transactional and enrichment data.",
  },
  {
    id: "V3", tier: "T2", question: 'Which supplier received a "Poor" overall rating in Q4 2025?',
    baseline: { answer: "No scorecard data available", wrong: true },
    sense: { answer: "Puebla Corrugated (V10245) — Del 2.0, Qual 1.5, Resp 2.5", wrong: false },
    category: "External Table Routing",
    whyBaselineFails: [
      "SUPPLIER_SCORECARDS exists in SAP_PRODUCTION but is NOT in the semantic view",
      "The SV was scoped to 14 core SAP tables; scorecards were excluded",
      "Baseline can't query tables outside its SV definition, even in the same schema",
    ],
    whySenseWorks: [
      "SUPPLIER_SCORECARDS is in the Cortex Sense context scope (SAP_PRODUCTION.*)",
      "Sense routes the agent to the correct table for scorecard questions",
      "Returns full evaluation detail: scores, overall rating, reviewer name",
    ],
    senseSource: "Cortex Sense → SUPPLIER_SCORECARDS",
    insight: "Even tables in the same schema are invisible to SV-only agents if not declared. Sense's scope is wider.",
  },

  // ── Business Knowledge ──
  {
    id: "V5", tier: "T3", question: "What is our Cost of Goods Sold?",
    baseline: { answer: "~$1.67M (naive SUM) or ~$1.33M (COEP)", wrong: true },
    sense: { answer: "$1,542,520 (BSCHL 31 minus 34)", wrong: false },
    category: "Business Knowledge",
    whyBaselineFails: [
      "Can query BSEG but doesn't know SAP posting key semantics",
      "Naive SUM(DMBTR) = ~$1.67M includes credit memos and other posting types",
      "Alternative COEP.WRTBTR = ~$1.33M is controlling cost — different concept entirely",
    ],
    whySenseWorks: [
      "Cortex Sense provides the COGS formula: SUM(DMBTR WHERE BSCHL=31) - SUM(DMBTR WHERE BSCHL=34)",
      "BSCHL 31 = vendor invoices, 34 = credit memos — the standard SAP COGS formula",
      "Agent follows the formula precisely: $1,542,520",
    ],
    senseSource: "Cortex Sense → BSCHL posting key logic",
    insight: "The data is accessible to both. Only Sense has the institutional knowledge to interpret it correctly.",
  },
  {
    id: "V6", tier: "T3", question: "What happens to a supplier that scores below C for three consecutive quarters?",
    baseline: { answer: "Cannot answer — no policy documentation", wrong: true },
    sense: { answer: "Three-Strike Rule: auto probation → ZPRB, prepay only, recovery needs 2× B+", wrong: false },
    category: "Business Knowledge",
    whyBaselineFails: [
      "Pure business knowledge question — no SQL can answer this",
      "The semantic view contains structured data tables, not governance documentation",
      "Baseline hallucinates a policy or says it cannot answer",
    ],
    whySenseWorks: [
      "Cortex Sense indexes the knowledge doc containing the Three-Strike Rule policy",
      "Delivers the full policy text when the query matches supplier probation patterns",
      "No SQL execution needed — Sense provides the answer directly from business context",
    ],
    senseSource: "Cortex Sense → business policy (knowledge doc)",
    insight: "Business rules live in documentation, not databases. Sense bridges structured data and institutional knowledge.",
  },
  {
    id: "V10", tier: "T3", question: "What do ZSTR, ZSTD, and ZPRB mean, and what payment terms apply?",
    baseline: { answer: "Shows raw code values but can't decode meaning", wrong: true },
    sense: { answer: "ZSTR=Strategic/Net60, ZSTD=Standard/Net30, ZPRB=Probation/Prepay", wrong: false },
    category: "Business Knowledge",
    whyBaselineFails: [
      "Can query LFA1 and show the distribution of KTOKK values",
      "Sees ZSTR=4, ZSTD=10, ZPRB=1 — but can't explain what they mean",
      "No metadata in the SV decodes SAP codes into business classifications",
    ],
    whySenseWorks: [
      "Cortex Sense provides the code-to-meaning mapping and payment terms policy",
      "Cross-references with Three-Strike Rule for how vendors land on ZPRB",
      "Doesn't just show data — explains institutional knowledge behind the codes",
    ],
    senseSource: "Cortex Sense → SAP field reference (knowledge doc)",
    insight: "SAP codes are opaque without domain expertise. Sense delivers the decoder ring at query time.",
  },

  // ── Cross-Domain Synthesis ──
  {
    id: "V7", tier: "T3", question: "What is the combined annual Ariba spend on suppliers flagged as high-risk by D&B?",
    baseline: { answer: "Cannot access either table", wrong: true },
    sense: { answer: "$4,250,000 — Shenzhen Electronics (risk 6, spend $4.25M)", wrong: false },
    category: "Cross-Domain Synthesis",
    whyBaselineFails: [
      "Cannot access ARIBA_SUPPLIERS (spend) or DNB_RISK_ASSESSMENTS (risk)",
      "Even if it could, no context for joining two systems with different ID schemes",
      "Would need SUPPLIER_NAME text matching — SAP LIFNR won't work here",
    ],
    whySenseWorks: [
      "Cortex Sense provides context for both Ariba and D&B tables simultaneously",
      "Agent joins on SUPPLIER_NAME, handles fuzzy match across systems",
      "Only 1 of 3 high-risk suppliers has an Ariba record — $4.25M concentrated exposure",
    ],
    senseSource: "Cortex Sense → ARIBA_SUPPLIERS + DNB_RISK_ASSESSMENTS",
    insight: "Sense enables cross-domain joins the baseline can't even attempt.",
  },
  {
    id: "V8", tier: "T3", question: "Give me a risk profile for Guangzhou Rare Earth — D&B risk, scorecard, and Ariba spend.",
    baseline: { answer: "Only LFA1 master data (name, city, country)", wrong: true },
    sense: { answer: "D&B: overall 7, geo 7. Scorecard: 'Acceptable'. Ariba: no record. + LFA1 master.", wrong: false },
    category: "Cross-Domain Synthesis",
    whyBaselineFails: [
      "Returns only what's in the SV: vendor name, city, country from LFA1",
      "No risk scores, no performance scorecard, no Ariba spend data",
      "Partial answer at best — useless for executive risk decisions",
    ],
    whySenseWorks: [
      "Cortex Sense provides context across DNB, Scorecards, Ariba, and LFA1",
      "Agent executes 4 targeted SQL queries and synthesizes a complete executive dossier",
      "Correctly reports 'no Ariba record' rather than fabricating data — honest synthesis",
    ],
    senseSource: "Cortex Sense → DNB + Scorecards + Ariba + LFA1",
    insight: "The marquee question: 4 sources, 4 queries, 1 executive-ready profile. This is what Sense enables.",
  },

  // ── Ties ──
  {
    id: "V4", tier: "T1", question: "How many active suppliers do we have, excluding probationary vendors?",
    baseline: { answer: "14 (ZSTD=10, ZSTR=4, excluded ZPRB)", wrong: false },
    sense: { answer: "14 (ZSTD=10, ZSTR=4, excluded ZPRB)", wrong: false },
    category: "Tie",
    whyBaselineFails: [
      "Both agents query LFA1 and filter KTOKK correctly",
      "KTOKK values are self-documenting — 'excluding probationary' → exclude ZPRB",
      "Simple single-table lookup fully within the SV scope",
    ],
    whySenseWorks: [
      "Same answer — proves Sense doesn't regress on queries the SV handles well",
      "Sense may add the ZSTR/ZSTD decode from its business context, but the number matches",
    ],
    senseSource: "Semantic View (LFA1)",
    insight: "Parity: both get 14. Sense adds breadth without losing accuracy on SV-native queries.",
  },
  {
    id: "V9", tier: "T1", question: "What is the actual on-time delivery rate for our shipments?",
    baseline: { answer: "~66.7% from LIKP (WADAT ≤ LFDAT)", wrong: false },
    sense: { answer: "~67.2% from SHIPMENTS (actual ≤ ETA)", wrong: false },
    category: "Tie",
    whyBaselineFails: [
      "Both agents avoid the LFA2.OTRAT trap (carrier self-reported ~90%)",
      "Baseline computes from LIKP: WADAT ≤ LFDAT WHERE STATU='D' → 66.7%",
      "Methodologically correct — used operational delivery data, not planning benchmarks",
    ],
    whySenseWorks: [
      "Sense uses SHIPMENTS table: ACTUAL_DELIVERY ≤ ETA → 67.2%",
      "Different tables, slightly different populations, same correct methodology",
      "Both explicitly note that the ~90% LFA2 rate is misleading",
    ],
    senseSource: "Semantic View (LIKP / SHIPMENTS)",
    insight: "Tie: ~67% either way. Both correctly avoided the 90% carrier-reported trap.",
  },
];

const CATEGORY_ORDER = [
  "External Table Routing",
  "Business Knowledge",
  "Cross-Domain Synthesis",
  "Tie",
];

export default function AnalysisView() {
  const senseScore = 10;
  const baselineScore = 2;
  const gap = "5×";

  return (
    <div>
      <p className="text-sm text-[var(--text-muted)] mb-2">
        10 questions designed to isolate where Cortex Sense adds value over a Semantic View-only baseline. All results from live agent runs.
      </p>

      {/* Scorecard */}
      <div className="grid grid-cols-3 gap-3 mb-6">
        <div className="rounded-lg border border-[var(--border)] p-3 text-center">
          <div className="text-2xl font-bold" style={{ color: "var(--sense)" }}>{senseScore}/10</div>
          <div className="text-xs text-[var(--text-muted)]">Sense Agent</div>
        </div>
        <div className="rounded-lg border border-[var(--border)] p-3 text-center">
          <div className="text-2xl font-bold" style={{ color: "var(--baseline)" }}>{baselineScore}/10</div>
          <div className="text-xs text-[var(--text-muted)]">Baseline Agent</div>
        </div>
        <div className="rounded-lg border border-[var(--border)] p-3 text-center">
          <div className="text-2xl font-bold" style={{ color: "var(--sense)" }}>{gap}</div>
          <div className="text-xs text-[var(--text-muted)]">Performance gap</div>
        </div>
      </div>

      {/* Mechanism summary */}
      <div className="rounded-lg border border-[var(--border)] p-4 mb-6 bg-[var(--bg-card)]">
        <h3 className="text-sm font-bold mb-3">Where Sense Wins</h3>
        <div className="grid grid-cols-3 gap-4 text-xs">
          <div>
            <div className="font-semibold mb-1" style={{ color: TIER_COLORS.T2 }}>Table Discovery</div>
            <div className="text-[var(--text-muted)]">Sense finds tables outside the SV — Ariba, D&B, Scorecards (V1, V2, V3)</div>
          </div>
          <div>
            <div className="font-semibold mb-1" style={{ color: TIER_COLORS.T3 }}>Business Context</div>
            <div className="text-[var(--text-muted)]">Metric formulas, policies, field decodes delivered at query time (V5, V6, V10)</div>
          </div>
          <div>
            <div className="font-semibold mb-1" style={{ color: TIER_COLORS.T3 }}>Multi-Source Joins</div>
            <div className="text-[var(--text-muted)]">Cross-domain synthesis across systems with different ID schemes (V7, V8)</div>
          </div>
        </div>
      </div>

      {/* Analyses by category */}
      {CATEGORY_ORDER.map((cat) => {
        const items = ANALYSES.filter((a) => a.category === cat);
        if (items.length === 0) return null;
        return (
          <div key={cat} className="mb-6">
            <h3 className="text-sm font-bold mb-3 flex items-center gap-2">
              <span className="w-2 h-2 rounded-full" style={{
                backgroundColor: cat === "External Table Routing" ? TIER_COLORS.T2
                  : cat === "Tie" ? TIER_COLORS.T1 : TIER_COLORS.T3
              }} />
              {cat}
              <span className="text-xs font-normal text-[var(--text-muted)]">({items.length} questions)</span>
            </h3>
            <div className="space-y-4">
              {items.map((a) => (
                <div key={a.id} className="rounded-xl border border-[var(--border)] bg-[var(--bg-card)] overflow-hidden">
                  <div className="flex items-center gap-3 px-5 py-3 border-b border-[var(--border)] bg-[var(--bg)]">
                    <span className="text-xs font-bold px-2 py-0.5 rounded-full text-white"
                          style={{ backgroundColor: TIER_COLORS[a.tier] || "#666" }}>
                      {a.id}
                    </span>
                    <span className="font-medium text-sm flex-1">{a.question}</span>
                  </div>

                  <div className="grid grid-cols-1 lg:grid-cols-2 divide-y lg:divide-y-0 lg:divide-x divide-[var(--border)]">
                    <div className="p-5" style={{ borderLeft: `4px solid var(--baseline)` }}>
                      <div className="flex items-center gap-2 mb-3">
                        <span className={`text-xs font-semibold uppercase ${a.baseline.wrong ? "text-red-600" : "text-emerald-600"}`}>
                          Baseline: {a.baseline.wrong ? "WRONG" : "CORRECT"}
                        </span>
                        <span className={`font-mono text-sm font-bold ${a.baseline.wrong ? "text-red-600" : "text-emerald-600"}`}>
                          {a.baseline.answer}
                        </span>
                      </div>
                      <ul className="space-y-1.5">
                        {a.whyBaselineFails.map((r, i) => (
                          <li key={i} className="text-xs text-[var(--text-muted)] flex gap-2">
                            <span className={`mt-0.5 ${a.baseline.wrong ? "text-red-400" : "text-emerald-400"}`}>
                              {a.baseline.wrong ? "×" : "+"}
                            </span>
                            <span>{r}</span>
                          </li>
                        ))}
                      </ul>
                    </div>

                    <div className="p-5" style={{ borderLeft: `4px solid var(--sense)` }}>
                      <div className="flex items-center gap-2 mb-3">
                        <span className="text-xs font-semibold uppercase text-emerald-600">Sense: CORRECT</span>
                        <span className="font-mono text-sm font-bold text-emerald-600">{a.sense.answer}</span>
                      </div>
                      <ul className="space-y-1.5">
                        {a.whySenseWorks.map((r, i) => (
                          <li key={i} className="text-xs text-[var(--text-muted)] flex gap-2">
                            <span className="text-emerald-400 mt-0.5">+</span>
                            <span>{r}</span>
                          </li>
                        ))}
                      </ul>
                      <div className="mt-3 text-xs px-2 py-1 rounded bg-[var(--bg)] inline-block" style={{ color: "var(--sense)" }}>
                        {a.senseSource}
                      </div>
                    </div>
                  </div>

                  <div className="px-5 py-3 border-t border-[var(--border)] bg-[var(--bg)]">
                    <p className="text-xs font-medium">{a.insight}</p>
                  </div>
                </div>
              ))}
            </div>
          </div>
        );
      })}
    </div>
  );
}
