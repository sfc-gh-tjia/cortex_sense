import { EvalQuestion } from "./types";

export const EVAL_QUESTIONS: EvalQuestion[] = [
  // External Table Routing (V1, V2, V3)
  {
    id: "V1", tier: "T2",
    q: "What is the total annual procurement spend across all suppliers in Ariba?",
    expected: "$30,100,000 across 10 suppliers. Source: ARIBA_SUPPLIERS.ANNUAL_SPEND_USD",
    source: "Cortex Sense → ARIBA_SUPPLIERS",
    baselineCanAnswer: false,
    baselineError: "Cannot access ARIBA_SUPPLIERS. Attempts EKPO.NETWR or BSEG.DMBTR — wrong source, wrong $.",
  },
  {
    id: "V2", tier: "T2",
    q: "Which suppliers have a geopolitical risk score above 5 according to D&B?",
    expected: "3 suppliers: Guangzhou Rare Earth (7), Jiangsu Copper Alloys (6), Shenzhen Electronics (6). All China.",
    source: "Cortex Sense → DNB_RISK_ASSESSMENTS",
    baselineCanAnswer: false,
    baselineError: "No risk data in the semantic view. Baseline fails or says it cannot answer.",
  },
  {
    id: "V3", tier: "T2",
    q: 'Which supplier received a "Poor" overall rating in Q4 2025?',
    expected: "Puebla Corrugated Products SA (V10245) — Delivery 2.0, Quality 1.5, Responsiveness 2.5.",
    source: "Cortex Sense → SUPPLIER_SCORECARDS",
    baselineCanAnswer: false,
    baselineError: "SUPPLIER_SCORECARDS exists in SAP_PRODUCTION but not in the SV. Baseline can't see it.",
  },

  // Business Knowledge Injection (V5, V6, V10)
  {
    id: "V5", tier: "T3",
    q: "What is our Cost of Goods Sold?",
    expected: "$1,542,520. Formula: SUM(DMBTR WHERE BSCHL='31') - SUM(DMBTR WHERE BSCHL='34').",
    source: "Cortex Sense → BSCHL posting key logic",
    baselineCanAnswer: false,
    baselineError: "Returns naive SUM(DMBTR) = ~$1.67M or COEP.WRTBTR = ~$1.33M. No posting key logic.",
  },
  {
    id: "V6", tier: "T3",
    q: "What happens to a supplier that scores below C for three consecutive quarters?",
    expected: "Three-Strike Rule: auto probation (ZPRB), restricted to existing POs, prepay/Net15 only. Recovery needs 2× B+.",
    source: "Cortex Sense → business policy (knowledge doc)",
    baselineCanAnswer: false,
    baselineError: "No policy docs in the SV. Baseline hallucinates or says 'cannot answer'.",
  },
  {
    id: "V10", tier: "T3",
    q: "What do the vendor account group codes ZSTR, ZSTD, and ZPRB mean, and what payment terms apply?",
    expected: "ZSTR=Strategic/Net60, ZSTD=Standard/Net30, ZPRB=Probationary/Prepay. Plus Three-Strike Rule context.",
    source: "Cortex Sense → SAP field reference (knowledge doc)",
    baselineCanAnswer: false,
    baselineError: "Can query LFA1 and see raw code values but cannot decode their business meaning or explain the policy.",
  },

  // Cross-Domain Synthesis (V7, V8)
  {
    id: "V7", tier: "T3",
    q: "What is the combined annual Ariba spend on suppliers flagged as high-risk by D&B?",
    expected: "$4,250,000. Only Shenzhen Electronics appears in both Ariba + DNB (risk 6, spend $4.25M).",
    source: "Cortex Sense → ARIBA_SUPPLIERS + DNB_RISK_ASSESSMENTS",
    baselineCanAnswer: false,
    baselineError: "Cannot access either external table, let alone join them across identifier schemes.",
  },
  {
    id: "V8", tier: "T3",
    q: "Give me a risk profile for Guangzhou Rare Earth — D&B risk, scorecard, and Ariba spend.",
    expected: "D&B: overall 7, geopolitical 7. Scorecard Q4: Delivery 3.0, Quality 2.5, 'Acceptable'. Ariba: no record.",
    source: "Cortex Sense → DNB + Scorecards + Ariba + LFA1",
    baselineCanAnswer: false,
    baselineError: "Returns only LFA1 master data (name, city, country). No risk scores, no scorecard.",
  },

  // Ties (V4, V9)
  {
    id: "V4", tier: "T1",
    q: "How many active suppliers do we have in SAP, excluding probationary vendors?",
    expected: "14. Both filter LFA1 KTOKK excluding ZPRB. Breakdown: ZSTD=10, ZSTR=4.",
    source: "Semantic View (LFA1)",
    baselineCanAnswer: true,
  },
  {
    id: "V9", tier: "T1",
    q: "What is the actual on-time delivery rate for our shipments?",
    expected: "~67%. Both use operational data (not LFA2.OTRAT carrier-reported 90%).",
    source: "Semantic View (LIKP/SHIPMENTS)",
    baselineCanAnswer: true,
  },
];

export const TIER_LABELS: Record<string, string> = {
  T1: "Tie (both answer correctly)",
  T2: "External Table Routing (Sense discovers tables outside the SV)",
  T3: "Knowledge Injection + Cross-Domain Synthesis (Sense only)",
};

export const TIER_COLORS: Record<string, string> = {
  T1: "#3b82f6",   // blue
  T2: "#10b981",   // green
  T3: "#ef4444",   // red
};

export const SOURCE_ICONS: Record<string, string> = {
  T1: "Semantic View",
  T2: "Cortex Sense → External Tables",
  T3: "Cortex Sense → Knowledge + Multi-Source Joins",
};
