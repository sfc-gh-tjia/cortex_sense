# Cortex Sense Demo Script
## Baseline Agent vs Cortex Sense Agent — SAP Supply Chain

**Duration**: ~15 minutes  
**Pre-req**: Both servers running (`python api_server.py` on 5001, `npm run dev` on 3000)

---

## Opening (1 min)

"We're going to compare two Snowflake agents answering the same supply chain questions. Both agents have the same underlying SAP data. The difference is how much *context* each agent has about that data."

---

## Tab 1: Setup (3 min)

Walk through the architecture diagram:

- **Baseline agent**: locked to a Semantic View with 14 SAP tables. It can only generate SQL within that scope. This is a typical Cortex Analyst setup.
- **Sense agent**: powered by Cortex Sense, which indexes the full data estate — catalog metadata, business ontology, knowledge docs, query history, and a Streamlit dashboard. It can discover and query any table.

Point out the **key difference** at the bottom:
- Baseline: can only see what's declared in the SV
- Sense: discovers tables, receives business context at query time, writes SQL against any table

Optionally click a demo file (e.g., "Knowledge Doc") to show what kind of business context Sense has access to — metric formulas, SAP field codes, procurement policies.

---

## Tab 2: Comparison (8 min)

Run 3–4 questions live, one from each category. Let the agents respond in real time.

### Pick 1: Tie (Q1 or Q2)
**Q1: "How many active suppliers do we have, excluding probationary vendors?"**

Both return 14. Point out: "Sense doesn't break what already works. Simple SV queries still work perfectly."

### Pick 2: External Table Routing (Q3, Q4, or Q5)
**Q4: "Which suppliers have a geopolitical risk score above 5 according to D&B?"**

- Baseline: "I don't have risk data" — the DNB_RISK_ASSESSMENTS table isn't in the SV
- Sense: Returns 3 suppliers with scores, all in China

"The risk data exists in the account but the baseline can't see it. Sense discovers the table and routes the agent to it."

### Pick 3: Business Knowledge (Q6, Q7, or Q8)
**Q6: "What is our Cost of Goods Sold?"**

- Baseline: Returns ~$1.67M (wrong — naive SUM without posting key logic)
- Sense: Returns $1,542,520 (correct — uses BSCHL 31 minus 34 formula)

"Both agents can query the same BSEG table. The difference is that Sense knows the SAP posting key formula. The data is the same — the *interpretation* is different."

### Pick 4: Cross-Domain Synthesis (Q9 or Q10)
**Q10: "Give me a risk profile for Guangzhou Rare Earth — D&B risk, scorecard, and Ariba spend."**

- Baseline: Returns only vendor name and city from LFA1
- Sense: Returns a full executive dossier — D&B risk scores, scorecard ratings, Ariba spend status, plus LFA1 master data

"This is the marquee question. Sense pulls from 4 different sources and synthesizes a complete supplier profile. The baseline can only see one table."

---

## Tab 3: Analysis (3 min)

"We ran all 10 questions. Here are the results."

Point out the scorecard: **10/10 Sense vs 2/10 Baseline, 5x gap.**

Walk through the three categories briefly:
1. **External Table Routing** (3 questions) — Sense finds tables the SV doesn't include
2. **Business Knowledge** (3 questions) — Sense provides formulas, policies, field code meanings
3. **Cross-Domain Synthesis** (2 questions) — Sense joins across systems with different ID schemes

The 2 ties show Sense doesn't regress on queries the SV handles well.

---

## Closing (1 min)

"The takeaway: a Semantic View gives you a curated, governed data model — great for known questions. Cortex Sense adds the surrounding business context — table discovery, metric formulas, policies, cross-system joins. It's not a replacement, it's an amplifier. The agent goes from answering 2 out of 10 questions to answering all 10."

---

## Quick-start commands

```bash
# Terminal 1: Flask API
cd demo/web && python api_server.py

# Terminal 2: Next.js
cd demo/web && npm run dev -- -p 3000

# Open: http://localhost:3000
```

## Backup: if agents are slow or timing out

The Analysis tab has all 10 results pre-baked. You can walk through the entire demo from the Analysis tab alone without running any live agent calls.
