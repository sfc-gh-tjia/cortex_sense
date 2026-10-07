"use client";
import { useState, useEffect } from "react";
import ReactMarkdown from "react-markdown";
import remarkGfm from "remark-gfm";

const STREAMLIT_URL = "https://app.snowflake.com/sfsenorthamerica/tjia_aws_usw2/#/streamlit-apps/DB_ONTOLOGY_CONTROL_PLANE.SAP_PRODUCTION.SUPPLY_CHAIN_DASHBOARD";

interface FileInfo {
  key: string;
  label: string;
  description: string;
}

const DEMO_FILES: FileInfo[] = [
  { key: "knowledge_doc", label: "Knowledge Doc (indexed by Sense)", description: "sap_supply_chain_knowledge.md — metric formulas, SAP codes, policies" },
  { key: "dashboard_source", label: "Dashboard Source (indexed by Sense)", description: "supply_chain_dashboard.py — Streamlit app with Supplier Health Index" },
  { key: "eval_report", label: "Eval Report", description: "eval_v2_final_report.md — full 10-question analysis (10 vs 2)" },
];

function FileViewer({ fileKey, onClose }: { fileKey: string; onClose: () => void }) {
  const [content, setContent] = useState<string | null>(null);
  const [name, setName] = useState("");
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetch(`http://localhost:5001/api/file/${fileKey}`)
      .then((r) => r.json())
      .then((data) => {
        setContent(data.content || data.error || "Empty");
        setName(data.name || fileKey);
        setLoading(false);
      })
      .catch((e) => {
        setContent(`Error loading file: ${e.message}`);
        setLoading(false);
      });
  }, [fileKey]);

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50" onClick={onClose}>
      <div className="bg-[var(--bg-card)] border border-[var(--border)] rounded-xl w-[90vw] max-w-4xl max-h-[85vh] flex flex-col" onClick={(e) => e.stopPropagation()}>
        <div className="flex items-center justify-between px-5 py-3 border-b border-[var(--border)]">
          <span className="font-semibold text-sm font-mono">{name}</span>
          <button onClick={onClose} className="text-[var(--text-muted)] hover:text-[var(--text)] text-lg px-2">✕</button>
        </div>
        <div className="flex-1 overflow-auto p-5">
          {loading ? (
            <div className="text-[var(--text-muted)]">Loading...</div>
          ) : name.endsWith(".py") ? (
            <pre className="text-xs leading-relaxed whitespace-pre-wrap">{content}</pre>
          ) : (
            <div className="prose prose-sm dark:prose-invert max-w-none">
              <ReactMarkdown remarkPlugins={[remarkGfm]}>{content || ""}</ReactMarkdown>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}

export default function ContextView() {
  const [viewingFile, setViewingFile] = useState<string | null>(null);

  return (
    <div className="space-y-8">
      {viewingFile && <FileViewer fileKey={viewingFile} onClose={() => setViewingFile(null)} />}

      {/* Architecture diagram */}
      <section>
        <h2 className="text-lg font-bold mb-4">Architecture</h2>
        <pre className="text-xs bg-[var(--bg)] border border-[var(--border)] rounded-xl p-5 overflow-x-auto leading-relaxed">{`┌─────────────────────────────────────────────────────────────────────┐
│                    SAP Supply Chain Data Estate                      │
│                                                                     │
│  SAP_PRODUCTION (18 tables)                                         │
│    LFA1, MARA, EKPO, LIKP, T001W, T320, STPO, LFB1, QALS, LFA2,  │
│    BSEG, COEP, VBAP, KONV,                                         │
│    SUPPLIER_SCORECARDS, DEMAND_FORECAST, INCIDENT_LOG, QUAL_MATRIX  │
│                                                                     │
│  RAW_SOURCES (multi-source)                                         │
│    ARIBA_SUPPLIERS, DNB_RISK_ASSESSMENTS, SAP_VENDORS,              │
│    SAP_MATERIALS, SAP_PURCHASE_ORDERS, SHIPMENTS, CARRIERS, ...     │
│                                                                     │
│  Business Ontology  │  Knowledge Doc  │  Streamlit Dashboard        │
└─────────────────────────────────────────────────────────────────────┘
          │                                    │
          ▼                                    ▼
┌─────────────────────┐          ┌────────────────────────────────────┐
│  BASELINE AGENT      │          │  SENSE AGENT                       │
│  (SV-only)           │          │  (Cortex Sense)                    │
│                      │          │                                    │
│  Tool: query_sap     │          │  Tool: cortex_sense                │
│    └→ SAP_BASELINE_SV│          │    └→ SAP_SUPPLY_CHAIN context     │
│       (14 tables)    │          │       (all indexed sources)        │
│                      │          │  Tool: system_execute_sql          │
│  Score: 2/10         │          │  Score: 10/10                      │
└─────────────────────┘          └────────────────────────────────────┘`}</pre>
      </section>

      {/* Side-by-side agent comparison */}
      <section>
        <h2 className="text-lg font-bold mb-4">Agent Comparison</h2>
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-5">
          <div className="rounded-xl border border-[var(--border)] overflow-hidden" style={{ borderLeftWidth: "4px", borderLeftColor: "var(--baseline)" }}>
            <div className="px-5 py-3 border-b border-[var(--border)] bg-[var(--bg)]">
              <span className="font-semibold text-sm">BASELINE_SUPPLY_CHAIN_AGENT</span>
              <span className="text-xs text-[var(--text-muted)] ml-2">2/10</span>
            </div>
            <div className="p-5 space-y-3 text-sm">
              <div>
                <div className="text-xs font-semibold text-[var(--text-muted)] uppercase tracking-wider mb-1">Tools</div>
                <div><code className="text-xs bg-[var(--bg)] px-1.5 py-0.5 rounded">cortex_analyst_text_to_sql</code> <span className="text-[var(--text-muted)]">→ locked to SAP_BASELINE_SV</span></div>
                <div><code className="text-xs bg-[var(--bg)] px-1.5 py-0.5 rounded">data_to_chart</code></div>
              </div>
              <div>
                <div className="text-xs font-semibold text-[var(--text-muted)] uppercase tracking-wider mb-1">Can access</div>
                <div>14 SAP tables declared in the Semantic View</div>
              </div>
              <div>
                <div className="text-xs font-semibold text-[var(--text-muted)] uppercase tracking-wider mb-1">Cannot access</div>
                <div className="text-[var(--text-muted)]">ARIBA_SUPPLIERS, DNB_RISK_ASSESSMENTS, SUPPLIER_SCORECARDS, business ontology, knowledge docs</div>
              </div>
            </div>
          </div>

          <div className="rounded-xl border border-[var(--border)] overflow-hidden" style={{ borderLeftWidth: "4px", borderLeftColor: "var(--sense)" }}>
            <div className="px-5 py-3 border-b border-[var(--border)] bg-[var(--bg)]">
              <span className="font-semibold text-sm">SAP_SUPPLY_CHAIN_AGENT</span>
              <span className="text-xs ml-2" style={{ color: "var(--sense)" }}>10/10</span>
            </div>
            <div className="p-5 space-y-3 text-sm">
              <div>
                <div className="text-xs font-semibold text-[var(--text-muted)] uppercase tracking-wider mb-1">Tools</div>
                <div><code className="text-xs bg-[var(--bg)] px-1.5 py-0.5 rounded">cortex_sense</code> <span className="text-[var(--text-muted)]">→ SAP_SUPPLY_CHAIN context</span></div>
                <div><code className="text-xs bg-[var(--bg)] px-1.5 py-0.5 rounded">system_execute_sql</code> <span className="text-[var(--text-muted)]">→ can query ANY accessible table</span></div>
                <div><code className="text-xs bg-[var(--bg)] px-1.5 py-0.5 rounded">data_to_chart</code></div>
              </div>
              <div>
                <div className="text-xs font-semibold text-[var(--text-muted)] uppercase tracking-wider mb-1">Key flag</div>
                <div><code className="text-xs bg-[var(--bg)] px-1.5 py-0.5 rounded">EnableCortexSense: true</code> — auto-provisions cortex_sense + system_execute_sql</div>
              </div>
              <div>
                <div className="text-xs font-semibold text-[var(--text-muted)] uppercase tracking-wider mb-1">How it answers</div>
                <div className="text-[var(--text-muted)]">1. Calls cortex_sense → 2. Receives table schemas + business context → 3. Writes SQL → 4. Executes</div>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* Semantic View */}
      <section>
        <h2 className="text-lg font-bold mb-4">Shared Foundation: SAP_BASELINE_SV</h2>
        <div className="rounded-xl border border-[var(--border)] bg-[var(--bg-card)] p-5">
          <div className="grid grid-cols-2 md:grid-cols-4 gap-4 text-center">
            <div>
              <div className="text-2xl font-bold">14</div>
              <div className="text-xs text-[var(--text-muted)]">SAP tables</div>
            </div>
            <div>
              <div className="text-2xl font-bold">12</div>
              <div className="text-xs text-[var(--text-muted)]">relationships</div>
            </div>
            <div>
              <div className="text-2xl font-bold">18</div>
              <div className="text-xs text-[var(--text-muted)]">facts</div>
            </div>
            <div>
              <div className="text-2xl font-bold">66</div>
              <div className="text-xs text-[var(--text-muted)]">dimensions</div>
            </div>
          </div>
          <p className="text-xs text-[var(--text-muted)] mt-4 text-center">
            Both agents read from this SV. The baseline is <em>locked</em> to it. The Sense agent uses it as one context source among many.
          </p>
        </div>
      </section>

      {/* Cortex Sense Context */}
      <section>
        <h2 className="text-lg font-bold mb-4">What Cortex Sense Indexes</h2>
        <p className="text-sm text-[var(--text-muted)] mb-4">
          Cortex Sense builds a unified context from 6 source types. The agent receives relevant context at query time.
        </p>
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
          {[
            { name: "Catalog Objects", detail: "All tables in RAW_SOURCES + SAP_PRODUCTION — columns, types, comments, row profiles", icon: "📊", link: null },
            { name: "Semantic Views", detail: "SAP_BASELINE_SV structure — tables, relationships, facts, dimensions, join patterns", icon: "🔗", link: null },
            { name: "Business Ontology", detail: "Supply Chain (23 nodes) + SAP Purchasing (15 nodes) — entity definitions, relationships", icon: "🧠", link: null },
            { name: "Stage Files", detail: "sap_supply_chain_knowledge.md — metric formulas, entity definitions, SAP field codes", icon: "📄", link: "knowledge_doc" },
            { name: "Query History", detail: "Recent analyst queries against these schemas — learned patterns and idioms", icon: "🔍", link: null },
            { name: "Streamlit Apps", detail: "SUPPLY_CHAIN_DASHBOARD — supplier health, concentration risk, warehouse zones", icon: "📈", link: "dashboard" },
          ].map((src) => (
            <div key={src.name} className="rounded-xl border border-[var(--border)] bg-[var(--bg-card)] p-4" style={{ borderTopWidth: "3px", borderTopColor: "var(--sense)" }}>
              <div className="flex items-center gap-2 mb-2">
                <span>{src.icon}</span>
                <h3 className="font-semibold text-sm">{src.name}</h3>
              </div>
              <p className="text-xs text-[var(--text-muted)] mb-2">{src.detail}</p>
              {src.link === "dashboard" ? (
                <a href={STREAMLIT_URL} target="_blank" rel="noopener noreferrer"
                   className="text-xs font-medium hover:underline" style={{ color: "var(--sense)" }}>
                  Open Dashboard ↗
                </a>
              ) : src.link ? (
                <button onClick={() => setViewingFile(src.link)}
                        className="text-xs font-medium hover:underline" style={{ color: "var(--sense)" }}>
                  View File →
                </button>
              ) : null}
            </div>
          ))}
        </div>
      </section>

      {/* Demo Files */}
      <section>
        <h2 className="text-lg font-bold mb-4">Demo Files</h2>
        <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
          {DEMO_FILES.map((f) => (
            <button
              key={f.key}
              onClick={() => setViewingFile(f.key)}
              className="rounded-lg border border-[var(--border)] bg-[var(--bg-card)] p-4 text-left hover:border-[var(--sense)] transition-colors"
            >
              <div className="font-semibold text-sm mb-1">{f.label}</div>
              <div className="text-xs text-[var(--text-muted)]">{f.description}</div>
            </button>
          ))}
          <a
            href={STREAMLIT_URL}
            target="_blank"
            rel="noopener noreferrer"
            className="rounded-lg border border-[var(--border)] bg-[var(--bg-card)] p-4 text-left hover:border-[var(--sense)] transition-colors"
          >
            <div className="font-semibold text-sm mb-1">Streamlit Dashboard ↗</div>
            <div className="text-xs text-[var(--text-muted)]">Open SUPPLY_CHAIN_DASHBOARD in Snowsight</div>
          </a>
        </div>
      </section>

      {/* The key difference */}
      <section>
        <h2 className="text-lg font-bold mb-4">The Key Difference</h2>
        <div className="rounded-xl border border-[var(--border)] bg-[var(--bg-card)] p-5">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6 text-sm">
            <div>
              <div className="font-semibold mb-2" style={{ color: "var(--baseline)" }}>Baseline Agent</div>
              <ul className="space-y-1 text-xs text-[var(--text-muted)]">
                <li>• Locked to 14 tables in the Semantic View</li>
                <li>• No access to external data (Ariba, D&B)</li>
                <li>• No business knowledge (formulas, policies)</li>
                <li>• Can only generate SQL within the SV scope</li>
              </ul>
            </div>
            <div>
              <div className="font-semibold mb-2" style={{ color: "var(--sense)" }}>Cortex Sense Agent</div>
              <ul className="space-y-1 text-xs text-[var(--text-muted)]">
                <li>• Discovers tables across all schemas</li>
                <li>• Receives business context at query time</li>
                <li>• Knows metric formulas and policies</li>
                <li>• Can write and execute SQL against any table</li>
              </ul>
            </div>
          </div>
        </div>
      </section>
    </div>
  );
}
