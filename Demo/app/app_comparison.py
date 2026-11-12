"""
Cortex Sense Demo — Side-by-Side Agent Comparison App
Run locally: streamlit run demo/app/app_comparison.py

Compares a Semantic View-only baseline agent against a Cortex Sense agent
to show the value of grounding agents with indexed business context.
"""
import streamlit as st
import json
import time
from pathlib import Path

st.set_page_config(page_title="Cortex Sense: SV vs Sense", layout="wide")

DB = "DB_ONTOLOGY_CONTROL_PLANE"
SCHEMA = "SAP_PRODUCTION"
BASELINE_AGENT = f"{DB}.{SCHEMA}.BASELINE_SUPPLY_CHAIN_AGENT"
SENSE_AGENT = f"{DB}.{SCHEMA}.SAP_SUPPLY_CHAIN_AGENT"

# Load eval questions
QUESTIONS_PATH = Path(__file__).parent.parent / "eval" / "questions.json"
if QUESTIONS_PATH.exists():
    with open(QUESTIONS_PATH) as f:
        EVAL_DATA = json.load(f)
        EVAL_QUESTIONS = EVAL_DATA["eval_questions"]
else:
    EVAL_QUESTIONS = []

TIER_COLORS = {
    "A": "#3b82f6",   # blue
    "B": "#10b981",   # green
    "C": "#8b5cf6",   # purple
    "D": "#f59e0b",   # amber
    "E": "#ef4444",   # red
    "F": "#06b6d4",   # cyan
    "X": "#ec4899",   # pink
}

TIER_LABELS = {
    "A": "SV Parity",
    "B": "Business Knowledge",
    "C": "Policy & Docs",
    "D": "Query History",
    "E": "Long-Tail Tables",
    "F": "Dashboard Logic",
    "X": "Cross-Source",
}

SOURCE_ICONS = {
    "A": "Semantic View",
    "B": "Stage File (Business Knowledge)",
    "C": "Stage File (Policies)",
    "D": "Query History",
    "E": "Catalog Objects",
    "F": "Streamlit Dashboard",
    "X": "Multiple Sources",
}


def get_session():
    if "snowpark_session" not in st.session_state or st.session_state.snowpark_session is None:
        from snowflake.snowpark import Session
        try:
            from snowflake.snowpark.context import get_active_session
            st.session_state.snowpark_session = get_active_session()
        except Exception:
            st.session_state.snowpark_session = Session.builder.configs({
                "connection_name": __import__("os").environ.get("SNOWFLAKE_CONNECTION_NAME", "default"),
                "database": "DB_ONTOLOGY_CONTROL_PLANE",
                "schema": "SAP_PRODUCTION",
            }).create()
    return st.session_state.snowpark_session


def invoke_agent(agent_fqn: str, question: str) -> dict:
    session = get_session()
    req = json.dumps({"messages": [{"role": "user", "content": [{"type": "text", "text": question}]}]})
    sql = f"SELECT SNOWFLAKE.CORTEX.DATA_AGENT_RUN('{agent_fqn}', $${req}$$) AS response"
    try:
        start = time.time()
        result = session.sql(sql).collect()[0][0]
        elapsed = round(time.time() - start, 1)
        parsed = json.loads(result) if isinstance(result, str) else result
        text = ""
        if isinstance(parsed, dict):
            messages = parsed.get("messages", [])
            for msg in messages:
                if msg.get("role") == "assistant":
                    content = msg.get("content", "")
                    if isinstance(content, list):
                        text = "\n".join(c.get("text", "") for c in content if c.get("type") == "text")
                    else:
                        text = str(content)
        return {"text": text or str(parsed), "elapsed": elapsed, "raw": parsed}
    except Exception as e:
        return {"text": f"Error: {str(e)}", "elapsed": 0, "raw": None}


# --- Header ---
st.title("Semantic View Agent vs Cortex Sense Agent")

st.markdown("""
<div style="display: grid; grid-template-columns: 1fr 1fr; gap: 16px; margin-bottom: 24px;">
  <div style="padding: 16px; border-radius: 8px; border-left: 4px solid #11567F; background: #f0f4f8;">
    <strong style="color: #11567F;">BASELINE</strong><br/>
    <span style="font-size: 14px;">Semantic View only (14 SAP tables)<br/>
    Tool: <code>cortex_analyst_text_to_sql</code></span>
  </div>
  <div style="padding: 16px; border-radius: 8px; border-left: 4px solid #29B5E8; background: #e6f6fc;">
    <strong style="color: #11567F;">CORTEX SENSE</strong><br/>
    <span style="font-size: 14px;">SV + 30 tables + dashboard + docs + query history<br/>
    Tools: <code>cortex_sense</code> + <code>system_execute_sql</code></span>
  </div>
</div>
""", unsafe_allow_html=True)

# --- Sidebar ---
st.sidebar.header("Questions")
mode = st.sidebar.radio("Mode", ["Eval Set", "Custom Question"])

if mode == "Eval Set" and EVAL_QUESTIONS:
    tier_filter = st.sidebar.multiselect(
        "Filter by tier",
        options=list(TIER_LABELS.keys()),
        default=list(TIER_LABELS.keys()),
        format_func=lambda t: f"{t}: {TIER_LABELS[t]}"
    )
    filtered = [q for q in EVAL_QUESTIONS if q["tier"] in tier_filter]
    selected_q = st.sidebar.selectbox(
        "Select question",
        options=filtered,
        format_func=lambda q: f"[{q['id']}] {q['question'][:55]}"
    )
    if selected_q:
        question = selected_q["question"]
        tier = selected_q["tier"]
        color = TIER_COLORS.get(tier, "#666")
        st.sidebar.markdown(f"""
**Tier:** <span style="color:{color}; font-weight:700">{tier} — {TIER_LABELS.get(tier, '')}</span>  
**Cortex Sense source:** {SOURCE_ICONS.get(tier, 'Unknown')}  
**Baseline can answer?** {'Yes' if selected_q.get('baseline_can_answer') else 'No'}
""", unsafe_allow_html=True)
        with st.sidebar.expander("Expected answer"):
            st.write(selected_q["expected"])
            if selected_q.get("baseline_likely_error"):
                st.warning(f"Baseline likely error: {selected_q['baseline_likely_error']}")
    else:
        question = ""
else:
    question = st.sidebar.text_area("Enter your question:", height=100)
    selected_q = None

# --- Run Comparison ---
if st.sidebar.button("Compare", type="primary", use_container_width=True) and question:
    st.markdown(f"### {question}")

    col1, col2 = st.columns(2)

    with col1:
        st.markdown('<div style="border-left: 4px solid #11567F; padding-left: 12px;">', unsafe_allow_html=True)
        st.markdown("#### Baseline (SV Only)")
        with st.spinner("Querying baseline..."):
            baseline = invoke_agent(BASELINE_AGENT, question)
        st.markdown("</div>", unsafe_allow_html=True)
        st.markdown(baseline["text"])
        st.caption(f"Response time: {baseline['elapsed']}s")

    with col2:
        st.markdown('<div style="border-left: 4px solid #29B5E8; padding-left: 12px;">', unsafe_allow_html=True)
        st.markdown("#### Cortex Sense (5 Sources)")
        with st.spinner("Querying sense agent..."):
            sense = invoke_agent(SENSE_AGENT, question)
        st.markdown("</div>", unsafe_allow_html=True)
        st.markdown(sense["text"])
        st.caption(f"Response time: {sense['elapsed']}s")

    # --- Verdict Panel ---
    if selected_q:
        st.divider()
        verdict_col1, verdict_col2, verdict_col3 = st.columns([2, 2, 3])

        with verdict_col1:
            can_answer = selected_q.get("baseline_can_answer", False)
            if can_answer:
                st.success("Baseline: CAN answer")
            else:
                st.error("Baseline: CANNOT answer correctly")
            if selected_q.get("baseline_likely_error"):
                st.caption(selected_q["baseline_likely_error"])

        with verdict_col2:
            st.success("Sense: CAN answer")
            tier = selected_q["tier"]
            st.caption(f"Context from: {SOURCE_ICONS.get(tier, 'Cortex Sense')}")

        with verdict_col3:
            st.info(f"**Expected:** {selected_q['expected'][:300]}")

    # Raw responses
    with st.expander("Raw responses"):
        raw1, raw2 = st.columns(2)
        with raw1:
            st.markdown("**Baseline**")
            st.json(baseline["raw"])
        with raw2:
            st.markdown("**Sense**")
            st.json(sense["raw"])

# --- Scorecard in sidebar ---
if EVAL_QUESTIONS:
    st.sidebar.divider()
    st.sidebar.markdown("### Scorecard")
    for tier in TIER_LABELS:
        qs = [q for q in EVAL_QUESTIONS if q["tier"] == tier]
        if not qs:
            continue
        count = len(qs)
        baseline_yes = sum(1 for q in qs if q.get("baseline_can_answer"))
        color = TIER_COLORS.get(tier, "#666")
        bar_pct = int(100 * baseline_yes / count) if count else 0
        st.sidebar.markdown(f"""
<div style="margin-bottom: 8px;">
  <span style="color:{color}; font-weight:700; font-size:13px;">{tier}: {TIER_LABELS[tier]}</span>
  <span style="float:right; font-size:12px; color:#888;">{count} questions</span>
  <div style="display:flex; gap:4px; margin-top:4px;">
    <div style="flex:1; height:20px; border-radius:4px; overflow:hidden; background:#fee2e2;">
      <div style="width:{bar_pct}%; height:100%; background:#86efac;"></div>
    </div>
    <span style="font-size:12px; min-width:60px; text-align:right;">B:{baseline_yes}/{count} S:{count}/{count}</span>
  </div>
</div>
""", unsafe_allow_html=True)
    st.sidebar.caption("B = Baseline can answer, S = Sense can answer")

# --- Footer ---
st.sidebar.divider()
st.sidebar.markdown("""
**5 Cortex Sense Sources:**
1. Semantic View (SAP_BASELINE_SV)
2. Catalog Objects (30 tables)
3. Query History (account-wide)
4. Stage File (business knowledge)
5. Streamlit Dashboard (unique KPIs)
""")
