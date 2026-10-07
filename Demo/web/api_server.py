"""
Backend API server for the Cortex Sense comparison app.
Flask + snowflake.connector (supports connections.toml).

Run:  python api_server.py
Then: npm run dev (in the web/ directory)
"""

from flask import Flask, request, jsonify, send_from_directory
from flask_cors import CORS
import snowflake.connector
import json
import re
import time
import os
from concurrent.futures import ThreadPoolExecutor

app = Flask(__name__)
CORS(app)

DEMO_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))

# Allowed files for the file viewer (relative to demo/)
ALLOWED_FILES = {
    "knowledge_doc": "stage_files/sap_supply_chain_knowledge.md",
    "eval_report": "eval_v2_final_report.md",
    "setup_reference": "setup_reference.md",
    "dashboard_source": "streamlit/supply_chain_dashboard.py",
    "sap_field_guide": "docs/sap_field_guide.md",
    "metric_definitions": "docs/metric_definitions.md",
    "procurement_policy": "docs/procurement_policy.md",
}

BASELINE_AGENT = "DB_ONTOLOGY_CONTROL_PLANE.SAP_PRODUCTION.BASELINE_SUPPLY_CHAIN_AGENT"
SENSE_AGENT = "DB_ONTOLOGY_CONTROL_PLANE.SAP_PRODUCTION.SAP_SUPPLY_CHAIN_AGENT"


def get_connection():
    return snowflake.connector.connect(
        connection_name="tjia_demo_aws2",
        database="DB_ONTOLOGY_CONTROL_PLANE",
        schema="SAP_PRODUCTION",
    )


def parse_agent_response(raw):
    html_artifacts = []
    text_parts = []
    raw_str = str(raw) if raw else ""

    try:
        resp = json.loads(raw) if isinstance(raw, str) else raw
        if isinstance(resp, dict):
            for item in resp.get("content", []):
                if not isinstance(item, dict):
                    continue
                if item.get("type") == "text" and item.get("text", "").strip():
                    text_parts.append(item["text"].strip())
                elif item.get("type") == "tool_result":
                    for tc in item.get("tool_result", {}).get("content", []):
                        if isinstance(tc, dict) and tc.get("type") == "json":
                            result_str = tc.get("json", {}).get("result", "")
                            if isinstance(result_str, str) and "<!DOCTYPE html>" in result_str:
                                html_artifacts.append(result_str)
    except (json.JSONDecodeError, TypeError):
        pass

    if not html_artifacts and "<!DOCTYPE html>" in raw_str:
        match = re.search(r'"result"\s*:\s*"(<!DOCTYPE html>.*?</html>)"', raw_str, re.DOTALL)
        if match:
            html = match.group(1).replace('\\"', '"').replace('\\n', '\n').replace('\\t', '\t')
            html_artifacts.append(html)

    if not text_parts:
        for m in re.finditer(r'"type"\s*:\s*"text"\s*,\s*"text"\s*:\s*"([^"]+(?:\\.[^"]*)*)"', raw_str):
            t = m.group(1).replace('\\n', '\n').replace('\\"', '"')
            if t.strip() and len(t.strip()) > 5:
                text_parts.append(t.strip())

    return {"text": "\n".join(text_parts), "htmlArtifacts": html_artifacts}


def call_single_agent(question, agent_fqn):
    req = json.dumps({"messages": [{"role": "user", "content": [{"type": "text", "text": question}]}]})
    sql = f"SELECT SNOWFLAKE.CORTEX.DATA_AGENT_RUN('{agent_fqn}', $${req}$$) AS response"
    start = time.time()
    try:
        conn = get_connection()
        cur = conn.cursor()
        cur.execute(sql)
        row = cur.fetchone()
        elapsed = round(time.time() - start, 1)
        cur.close()
        conn.close()
        if row:
            parsed = parse_agent_response(row[0])
            parsed["elapsed"] = elapsed
            return parsed
    except Exception as e:
        elapsed = round(time.time() - start, 1)
        return {"text": f"Error: {str(e)}", "htmlArtifacts": [], "elapsed": elapsed}
    return {"text": "No response.", "htmlArtifacts": [], "elapsed": 0}


@app.route("/api/agent", methods=["POST"])
def agent_endpoint():
    data = request.json
    question = data.get("question", "")
    if not question:
        return jsonify({"error": "Missing question"}), 400

    with ThreadPoolExecutor(max_workers=2) as executor:
        f_baseline = executor.submit(call_single_agent, question, BASELINE_AGENT)
        f_sense = executor.submit(call_single_agent, question, SENSE_AGENT)
        baseline = f_baseline.result()
        sense = f_sense.result()

    return jsonify({"baseline": baseline, "sense": sense})


@app.route("/api/config", methods=["GET"])
def config_endpoint():
    try:
        conn = get_connection()
        cur = conn.cursor()

        # Get agent DDLs
        cur.execute(f"SELECT GET_DDL('CORTEX_AGENT', '{BASELINE_AGENT}')")
        baseline_ddl = cur.fetchone()[0]

        cur.execute(f"SELECT GET_DDL('CORTEX_AGENT', '{SENSE_AGENT}')")
        sense_ddl = cur.fetchone()[0]

        # Get SV tables with comments
        cur.execute("DESCRIBE SEMANTIC VIEW DB_ONTOLOGY_CONTROL_PLANE.SAP_PRODUCTION.SAP_BASELINE_SV")
        sv_rows = cur.fetchall()
        sv_tables = []
        sv_columns = []
        for row in sv_rows:
            kind, name, parent, prop, val = row[0], row[1], row[2], row[3], row[4]
            if kind == "TABLE" and prop == "COMMENT":
                sv_tables.append({"name": name, "comment": val})
            elif kind in ("DIMENSION", "FACT") and prop == "COMMENT":
                sv_columns.append({"table": parent, "column": name, "kind": kind.lower(), "comment": val})

        # Get all tables in scope
        cur.execute("""
            SELECT TABLE_SCHEMA, TABLE_NAME, ROW_COUNT, TABLE_TYPE
            FROM INFORMATION_SCHEMA.TABLES
            WHERE TABLE_SCHEMA IN ('SAP_PRODUCTION', 'RAW_SOURCES')
            AND TABLE_TYPE IN ('BASE TABLE', 'VIEW')
            ORDER BY TABLE_SCHEMA, TABLE_NAME
        """)
        all_tables = [{"schema": r[0], "name": r[1], "rows": r[2], "type": r[3]} for r in cur.fetchall()]

        cur.close()
        conn.close()

        # Identify tables NOT in SV
        sv_table_names = {t["name"] for t in sv_tables}
        long_tail = [t for t in all_tables if t["name"] not in sv_table_names]

        # Ambiguous columns the baseline can't decode
        ambiguous = [c for c in sv_columns if c["column"] in ("BSCHL", "KTOKK", "OTRAT", "STATU", "MATKL")]

        return jsonify({
            "baselineDDL": baseline_ddl,
            "senseDDL": sense_ddl,
            "svTables": sv_tables,
            "svColumns": sv_columns,
            "allTables": all_tables,
            "longTailTables": long_tail,
            "ambiguousColumns": ambiguous,
            "sources": [
                {"name": "Semantic View", "id": "semantic_views", "detail": "SAP_BASELINE_SV — 14 tables, joins, column types", "tables": len(sv_tables)},
                {"name": "Catalog Objects", "id": "catalog_objects", "detail": f"{len(all_tables)} tables across SAP_PRODUCTION + RAW_SOURCES", "tables": len(all_tables)},
                {"name": "Query History", "id": "query_history", "detail": "Account-wide, 30-day lookback — ZPRB filter, BSCHL separation patterns"},
                {"name": "Stage File", "id": "stage_files", "detail": "sap_supply_chain_knowledge.md — metric formulas, SAP codes, policies"},
                {"name": "Streamlit Dashboard", "id": "streamlit_apps", "detail": "SUPPLY_CHAIN_DASHBOARD — Supplier Health Index, Concentration Risk, warehouse zones"},
            ],
        })
    except Exception as e:
        return jsonify({"error": str(e)}), 500


@app.route("/api/files", methods=["GET"])
def list_files():
    """List available files for the viewer."""
    result = {}
    for key, rel_path in ALLOWED_FILES.items():
        full = os.path.join(DEMO_DIR, rel_path)
        result[key] = {
            "name": os.path.basename(rel_path),
            "path": rel_path,
            "exists": os.path.isfile(full),
            "size": os.path.getsize(full) if os.path.isfile(full) else 0,
        }
    return jsonify(result)


@app.route("/api/file/<key>", methods=["GET"])
def get_file(key):
    """Return the content of an allowed file."""
    if key not in ALLOWED_FILES:
        return jsonify({"error": f"Unknown file key: {key}"}), 404
    full = os.path.join(DEMO_DIR, ALLOWED_FILES[key])
    if not os.path.isfile(full):
        return jsonify({"error": f"File not found: {ALLOWED_FILES[key]}"}), 404
    with open(full, "r") as f:
        content = f.read()
    return jsonify({
        "key": key,
        "name": os.path.basename(ALLOWED_FILES[key]),
        "content": content,
    })


if __name__ == "__main__":
    print("Starting Cortex Sense eval API on http://localhost:5001")
    app.run(port=5001, debug=False)
