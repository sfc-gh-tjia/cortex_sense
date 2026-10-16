"use client";
import { useState, useEffect } from "react";
import ReactMarkdown from "react-markdown";
import remarkGfm from "remark-gfm";

const STREAMLIT_URL = "https://app.snowflake.com/sfsenorthamerica/tjia_aws_usw2/#/streamlit-apps/DB_ONTOLOGY_CONTROL_PLANE.SAP_PRODUCTION.SUPPLY_CHAIN_DASHBOARD";

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
    <div className="space-y-6">
      {viewingFile && <FileViewer fileKey={viewingFile} onClose={() => setViewingFile(null)} />}

      {/* Architecture diagram */}
      <section>
        <iframe
          src="/architecture.html"
          className="w-full border border-[var(--border)] rounded-xl"
          style={{ height: "900px" }}
          sandbox="allow-scripts"
        />
      </section>

      {/* Indexed sources with viewable files */}
      <section>
        <h2 className="text-lg font-bold mb-3">Indexed Sources (click to view)</h2>
        <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
          <button
            onClick={() => setViewingFile("knowledge_doc")}
            className="rounded-lg border border-[var(--border)] bg-[var(--bg-card)] p-4 text-left hover:border-[var(--sense)] transition-colors"
          >
            <div className="flex items-center gap-2 mb-1">
              <span>📄</span>
              <span className="font-semibold text-sm">Stage File: Knowledge Doc</span>
            </div>
            <div className="text-xs text-[var(--text-muted)]">sap_supply_chain_knowledge.md — metric formulas, SAP codes, procurement policies</div>
          </button>
          <button
            onClick={() => setViewingFile("dashboard_source")}
            className="rounded-lg border border-[var(--border)] bg-[var(--bg-card)] p-4 text-left hover:border-[var(--sense)] transition-colors"
          >
            <div className="flex items-center gap-2 mb-1">
              <span>📈</span>
              <span className="font-semibold text-sm">Streamlit App: Dashboard Source</span>
            </div>
            <div className="text-xs text-[var(--text-muted)]">supply_chain_dashboard.py — Supplier Health Index, Concentration Risk, warehouse zones</div>
          </button>
        </div>
        <div className="mt-3">
          <a
            href={STREAMLIT_URL}
            target="_blank"
            rel="noopener noreferrer"
            className="text-xs font-medium hover:underline inline-flex items-center gap-1"
            style={{ color: "var(--sense)" }}
          >
            Open live Streamlit Dashboard in Snowsight ↗
          </a>
        </div>
      </section>
    </div>
  );
}
