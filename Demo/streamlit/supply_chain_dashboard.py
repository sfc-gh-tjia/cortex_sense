"""
Supply Chain Analytics Dashboard
Deploy to Snowflake as Streamlit-in-Snowflake.

CORTEX SENSE SOURCE: This dashboard contains business logic, KPI thresholds,
and composite metrics that exist ONLY here — not in the Semantic View, not in
any policy document, and not in the Business Ontology. Cortex Sense indexes
this source code so agents can answer questions like "What is the Supplier
Health Index?" or "Which warehouses are in the red zone?"
"""
import streamlit as st
from snowflake.snowpark.context import get_active_session

st.set_page_config(page_title="Supply Chain Analytics", layout="wide")
session = get_active_session()

DB = "DB_ONTOLOGY_CONTROL_PLANE"
SCHEMA = "SAP_PRODUCTION"

def run(sql):
    return session.sql(sql).to_pandas()

# ==========================================================================
# BUSINESS LOGIC: KPI Thresholds (unique to this dashboard)
# These thresholds are operational standards set by VP Operations.
# ==========================================================================

# On-Time Delivery thresholds:
#   GREEN: >= 80%   (meeting target)
#   YELLOW: 60-79%  (needs attention)
#   RED: < 60%      (escalation required, triggers carrier review)
OTD_GREEN = 80
OTD_YELLOW = 60

# Warehouse Utilization zones:
#   GREEN: < 85%           (optimal operating range)
#   YELLOW: 85% to 89.9%   (monitor, schedule rebalancing)
#   ORANGE: 90% to 94.9%   (rebalancing triggered, overflow planning)
#   RED: >= 95%             (critical — emergency overflow protocol activated)
WH_GREEN = 85
WH_ORANGE = 90
WH_RED = 95

# Supplier Rating interpretation:
#   A or Excellent = Healthy (preferred for new POs)
#   B or Good = Healthy
#   C or Acceptable = Watch list (quarterly review required)
#   D or Poor = Escalation required (restrict new POs, consider de-qualification)
HEALTHY_RATINGS = ['A', 'B', 'Excellent', 'Good']
WATCH_RATINGS = ['C', 'Acceptable']
ESCALATION_RATINGS = ['D', 'Poor']

# ==========================================================================
# BUSINESS LOGIC: Supplier Health Index (unique to this dashboard)
# Composite score combining delivery, quality, responsiveness, and risk.
# Formula: 0.35 * delivery_score + 0.30 * quality_score
#        + 0.20 * responsiveness + 0.15 * (10 - overall_risk_score)
# Risk is inverted: lower risk = higher health contribution.
# If no DNB risk score exists for a supplier, use default risk of 3.
# Thresholds:
#   >= 7.0  = Healthy
#   5.0-6.9 = Watch
#   < 5.0   = Critical
# ==========================================================================
SHI_HEALTHY = 7.0
SHI_WATCH = 5.0

def compute_supplier_health_index(delivery, quality, responsiveness, risk_score):
    """Supplier Health Index = weighted composite of performance and risk."""
    if risk_score is None:
        risk_score = 3  # default when no DNB assessment exists
    return round(0.35 * delivery + 0.30 * quality + 0.20 * responsiveness + 0.15 * (10 - risk_score), 2)

# ==========================================================================
# BUSINESS LOGIC: Procurement Concentration Risk (unique to this dashboard)
# Measures spend dependency on top suppliers.
# Formula: SUM(top N supplier spend) / SUM(total spend)
# Thresholds:
#   Top 3 suppliers > 60% of total spend = HIGH concentration risk
#   Top 3 suppliers 40-60% = MEDIUM
#   Top 3 suppliers < 40% = LOW
# ==========================================================================
CONCENTRATION_HIGH = 0.60
CONCENTRATION_MEDIUM = 0.40

# -- Sidebar --
st.sidebar.title("Supply Chain Analytics")
page = st.sidebar.radio("Navigate", [
    "Supplier Health",
    "Procurement Risk",
    "Operations"
])

# =====================================================================
# PAGE 1: Supplier Health (features Supplier Health Index)
# =====================================================================
if page == "Supplier Health":
    st.title("Supplier Health Dashboard")

    # Compute Supplier Health Index for all vendors
    # Joins: LFA1 (vendor master) + SUPPLIER_SCORECARDS (latest quarter)
    #       + DNB_RISK_ASSESSMENTS (external risk, matched by name)
    shi_data = run(f"""
        WITH latest_scores AS (
            SELECT LIFNR,
                AVG(DELIVERY_SCORE) AS delivery,
                AVG(QUALITY_SCORE) AS quality,
                AVG(RESPONSIVENESS) AS responsiveness,
                MAX(OVERALL_RATING) AS rating
            FROM {DB}.{SCHEMA}.SUPPLIER_SCORECARDS
            GROUP BY LIFNR
        ),
        risk AS (
            SELECT SUPPLIER_NAME, OVERALL_RISK_SCORE
            FROM {DB}.{SCHEMA}.DNB_RISK_ASSESSMENTS
        )
        SELECT
            l.LIFNR, l.NAME1 AS vendor, l.KTOKK, l.LAND1 AS country,
            s.delivery, s.quality, s.responsiveness, s.rating,
            r.OVERALL_RISK_SCORE AS risk_score
        FROM {DB}.{SCHEMA}.LFA1 l
        LEFT JOIN latest_scores s ON l.LIFNR = s.LIFNR
        LEFT JOIN risk r ON UPPER(l.NAME1) LIKE '%' || UPPER(SPLIT_PART(r.SUPPLIER_NAME, ' ', 1)) || '%'
        WHERE l.KTOKK != 'ZPRB'
        ORDER BY l.NAME1
    """)

    # Compute SHI for each row
    shi_data['HEALTH_INDEX'] = shi_data.apply(
        lambda row: compute_supplier_health_index(
            row['DELIVERY'] or 5, row['QUALITY'] or 5,
            row['RESPONSIVENESS'] or 5, row['RISK_SCORE']
        ), axis=1
    )
    shi_data['STATUS'] = shi_data['HEALTH_INDEX'].apply(
        lambda x: 'Healthy' if x >= SHI_HEALTHY else ('Watch' if x >= SHI_WATCH else 'Critical')
    )

    # KPI row
    col1, col2, col3, col4 = st.columns(4)
    healthy_count = len(shi_data[shi_data['STATUS'] == 'Healthy'])
    watch_count = len(shi_data[shi_data['STATUS'] == 'Watch'])
    critical_count = len(shi_data[shi_data['STATUS'] == 'Critical'])
    col1.metric("Qualified Suppliers", len(shi_data))
    col2.metric("Healthy", healthy_count)
    col3.metric("Watch", watch_count)
    col4.metric("Critical", critical_count)

    st.divider()

    # Full table with health index
    st.subheader("Supplier Health Index")
    st.caption("Formula: 0.35*delivery + 0.30*quality + 0.20*responsiveness + 0.15*(10-risk)")
    display_cols = ['VENDOR', 'COUNTRY', 'DELIVERY', 'QUALITY', 'RESPONSIVENESS',
                    'RISK_SCORE', 'HEALTH_INDEX', 'STATUS', 'RATING']
    st.dataframe(
        shi_data[display_cols].sort_values('HEALTH_INDEX', ascending=True),
        use_container_width=True
    )

    st.divider()

    # On-Time Delivery with threshold coloring
    st.subheader("On-Time Delivery by Carrier")
    st.caption(f"Thresholds: GREEN >= {OTD_GREEN}%, YELLOW {OTD_YELLOW}-{OTD_GREEN}%, RED < {OTD_YELLOW}%")
    otd = run(f"""
        SELECT c.NAME1 AS carrier,
            COUNT(*) AS shipments,
            ROUND(100.0 * SUM(CASE WHEN s.WADAT <= s.LFDAT THEN 1 ELSE 0 END) / COUNT(*), 1) AS otd_pct
        FROM {DB}.{SCHEMA}.LIKP s JOIN {DB}.{SCHEMA}.LFA2 c ON s.TDLNR = c.TDLNR
        WHERE s.STATU = 'D'
        GROUP BY c.NAME1
    """)
    otd['ZONE'] = otd['OTD_PCT'].apply(
        lambda x: 'GREEN' if x >= OTD_GREEN else ('YELLOW' if x >= OTD_YELLOW else 'RED')
    )
    st.dataframe(otd, use_container_width=True)

# =====================================================================
# PAGE 2: Procurement Risk (features Concentration Risk)
# =====================================================================
elif page == "Procurement Risk":
    st.title("Procurement Risk Dashboard")

    # Procurement Concentration Risk
    # Top 3 suppliers as % of total spend
    spend_data = run(f"""
        SELECT l.NAME1 AS vendor, SUM(e.NETWR) AS spend
        FROM {DB}.{SCHEMA}.EKPO e JOIN {DB}.{SCHEMA}.LFA1 l ON e.LIFNR = l.LIFNR
        WHERE l.KTOKK != 'ZPRB'
        GROUP BY l.NAME1
        ORDER BY spend DESC
    """)
    total_spend = spend_data['SPEND'].sum()
    top3_spend = spend_data.head(3)['SPEND'].sum()
    concentration_pct = round(100 * top3_spend / total_spend, 1) if total_spend > 0 else 0
    concentration_level = (
        'HIGH' if concentration_pct / 100 >= CONCENTRATION_HIGH
        else ('MEDIUM' if concentration_pct / 100 >= CONCENTRATION_MEDIUM else 'LOW')
    )

    col1, col2, col3 = st.columns(3)
    col1.metric("Total Spend (Qualified)", f"${total_spend:,.0f}")
    col2.metric("Top 3 Concentration", f"{concentration_pct}%")
    col3.metric("Risk Level", concentration_level,
                help=f"HIGH > {CONCENTRATION_HIGH*100}%, MEDIUM {CONCENTRATION_MEDIUM*100}-{CONCENTRATION_HIGH*100}%, LOW < {CONCENTRATION_MEDIUM*100}%")

    st.divider()

    # Spend by vendor chart
    st.subheader("Spend by Vendor (Qualified Only)")
    st.caption("Excludes ZPRB probationary vendors per business policy")
    st.bar_chart(spend_data.set_index('VENDOR')['SPEND'])
    st.dataframe(spend_data, use_container_width=True)

    st.divider()

    # COGS breakdown
    st.subheader("Cost of Goods Sold")
    st.caption("COGS = SUM(DMBTR WHERE BSCHL='31') - SUM(DMBTR WHERE BSCHL='34')")
    cogs = run(f"""
        SELECT
            SUM(CASE WHEN BSCHL='31' THEN DMBTR ELSE 0 END) AS invoices,
            SUM(CASE WHEN BSCHL='34' THEN DMBTR ELSE 0 END) AS credits,
            SUM(CASE WHEN BSCHL='31' THEN DMBTR ELSE 0 END)
          - SUM(CASE WHEN BSCHL='34' THEN DMBTR ELSE 0 END) AS net_cogs
        FROM {DB}.{SCHEMA}.BSEG WHERE BSCHL IN ('31','34')
    """)
    c1, c2, c3 = st.columns(3)
    c1.metric("Gross Invoices", f"${cogs['INVOICES'].iloc[0]:,.0f}")
    c2.metric("Credit Memos", f"${cogs['CREDITS'].iloc[0]:,.0f}")
    c3.metric("Net COGS", f"${cogs['NET_COGS'].iloc[0]:,.0f}")

# =====================================================================
# PAGE 3: Operations (features warehouse zones + forecast bias)
# =====================================================================
elif page == "Operations":
    st.title("Operations Dashboard")

    # Warehouse utilization with zone coloring
    st.subheader("Warehouse Utilization Zones")
    st.caption(f"GREEN < {WH_GREEN}% | YELLOW {WH_GREEN}-{WH_ORANGE}% | ORANGE {WH_ORANGE}-{WH_RED}% | RED >= {WH_RED}%")
    wh = run(f"""
        SELECT w.LGORT, w.LGOBE AS location_name, w.WERKS AS plant,
            w.LKAPA AS utilization_pct
        FROM {DB}.{SCHEMA}.T320 w ORDER BY w.LKAPA DESC
    """)
    for _, row in wh.iterrows():
        pct = float(row['UTILIZATION_PCT'])
        if pct >= WH_RED:
            zone = 'RED'
        elif pct >= WH_ORANGE:
            zone = 'ORANGE'
        elif pct >= WH_GREEN:
            zone = 'YELLOW'
        else:
            zone = 'GREEN'
        color = 'red' if zone == 'RED' else ('orange' if zone == 'ORANGE' else ('blue' if zone == 'YELLOW' else 'green'))
        label = f"{row['LOCATION_NAME']} ({row['LGORT']}) — {row['PLANT']}"
        st.progress(min(pct / 100, 1.0), text=f":{color}[{label}: {pct}% ({zone})]")

    st.divider()

    # Forecast Bias: systematic over/under-forecasting by material group
    # Bias = AVG(VARIANCE_PCT) — positive means under-forecast, negative means over-forecast
    # Thresholds:
    #   |bias| > 15% = systematic bias, needs model recalibration
    #   |bias| 5-15% = minor bias, monitor
    #   |bias| < 5%  = acceptable
    st.subheader("Demand Forecast Bias by Material Group")
    st.caption("Bias = AVG(VARIANCE_PCT). Positive = systematic under-forecast. |bias| > 15% = needs recalibration.")
    bias = run(f"""
        SELECT m.MATKL AS material_group,
            COUNT(*) AS forecast_periods,
            ROUND(AVG(f.VARIANCE_PCT), 1) AS avg_bias_pct,
            ROUND(AVG(ABS(f.VARIANCE_PCT)), 1) AS avg_abs_error_pct
        FROM {DB}.{SCHEMA}.DEMAND_FORECAST f
        JOIN {DB}.{SCHEMA}.MARA m ON f.MATNR = m.MATNR
        GROUP BY m.MATKL
        ORDER BY ABS(AVG(f.VARIANCE_PCT)) DESC
    """)
    bias['BIAS_STATUS'] = bias['AVG_BIAS_PCT'].abs().apply(
        lambda x: 'RECALIBRATE' if x > 15 else ('MONITOR' if x > 5 else 'OK')
    )
    st.dataframe(bias, use_container_width=True)

    st.divider()

    # Recent incidents
    st.subheader("Recent Quality Incidents")
    st.caption("Source: INCIDENT_LOG — not in the Semantic View")
    incidents = run(f"""
        SELECT i.INCIDENT_ID, i.INCIDENT_DATE, i.SEVERITY,
            l.NAME1 AS vendor, m.MAKTX AS material,
            i.CATEGORY, i.STATUS, i.ROOT_CAUSE
        FROM {DB}.{SCHEMA}.INCIDENT_LOG i
        LEFT JOIN {DB}.{SCHEMA}.LFA1 l ON i.LIFNR = l.LIFNR
        LEFT JOIN {DB}.{SCHEMA}.MARA m ON i.MATNR = m.MATNR
        ORDER BY i.INCIDENT_DATE DESC
        LIMIT 10
    """)
    st.dataframe(incidents, use_container_width=True)
