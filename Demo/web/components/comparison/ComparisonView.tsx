"use client";
import { useState } from "react";
import ReactMarkdown from "react-markdown";
import remarkGfm from "remark-gfm";
import { EVAL_QUESTIONS, TIER_LABELS, TIER_COLORS, SOURCE_ICONS } from "@/lib/questions";
import { AgentResponse } from "@/lib/types";

function AgentPanel({ label, response, color }: { label: string; response: AgentResponse | null; color: string }) {
  if (!response) {
    return (
      <div className="rounded-xl border-l-4 border-[var(--border)] bg-[var(--bg-card)] p-5 animate-pulse"
           style={{ borderLeftColor: color }}>
        <div className="h-4 bg-[var(--border)] rounded w-1/3 mb-3" />
        <div className="h-3 bg-[var(--border)] rounded w-full mb-2" />
        <div className="h-3 bg-[var(--border)] rounded w-2/3" />
      </div>
    );
  }
  return (
    <div className="rounded-xl border border-[var(--border)] bg-[var(--bg-card)] overflow-hidden"
         style={{ borderLeftWidth: "4px", borderLeftColor: color }}>
      <div className="flex items-center justify-between px-5 py-3 border-b border-[var(--border)] bg-[var(--bg)]">
        <span className="font-semibold text-sm">{label}</span>
        <span className="text-xs px-2 py-0.5 rounded-full bg-[var(--border)] text-[var(--text-muted)]">
          {response.elapsed}s
        </span>
      </div>
      <div className="p-5">
        {response.text ? (
          <div className="text-sm leading-relaxed prose prose-sm dark:prose-invert max-w-none">
            <ReactMarkdown remarkPlugins={[remarkGfm]}>{response.text}</ReactMarkdown>
          </div>
        ) : (
          <p className="text-sm text-[var(--text-muted)] italic">No text response</p>
        )}
        {response.htmlArtifacts.map((html, i) => (
          <div key={i} className="mt-4 border border-[var(--border)] rounded-lg overflow-hidden">
            <div className="text-xs px-3 py-1.5 bg-[var(--bg)] text-[var(--text-muted)] border-b border-[var(--border)]">
              Chart
            </div>
            <iframe srcDoc={html} className="w-full border-0" style={{ height: "400px" }} sandbox="allow-scripts" />
          </div>
        ))}
      </div>
    </div>
  );
}

export default function ComparisonView() {
  const [selectedIdx, setSelectedIdx] = useState<number>(0);
  const [customQ, setCustomQ] = useState("");
  const [loading, setLoading] = useState(false);
  const [baseline, setBaseline] = useState<AgentResponse | null>(null);
  const [sense, setSense] = useState<AgentResponse | null>(null);
  const [currentQ, setCurrentQ] = useState<{ q: string; id: string; expected: string; source: string; baselineCanAnswer: boolean; baselineError?: string } | null>(null);

  const runQuestion = async (question: string, qId: string, expected: string, source: string, baselineCanAnswer: boolean, baselineError?: string) => {
    setLoading(true);
    setBaseline(null);
    setSense(null);
    setCurrentQ({ q: question, id: qId, expected, source, baselineCanAnswer, baselineError });
    try {
      const res = await fetch("http://localhost:5001/api/agent", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ question }),
      });
      const data = await res.json();
      setBaseline(data.baseline);
      setSense(data.sense);
    } catch (err: any) {
      setBaseline({ text: `Error: ${err.message}`, htmlArtifacts: [], elapsed: 0 });
      setSense({ text: `Error: ${err.message}`, htmlArtifacts: [], elapsed: 0 });
    }
    setLoading(false);
  };

  const grouped = Object.entries(TIER_LABELS).map(([tier, label]) => ({
    tier,
    label,
    questions: EVAL_QUESTIONS.filter((q) => q.tier === tier),
  }));

  return (
    <div>
      {/* Question selector */}
      <div className="rounded-xl border border-[var(--border)] bg-[var(--bg-card)] p-5 mb-6">
        <div className="flex flex-col lg:flex-row gap-4">
          <div className="flex-1">
            <label className="text-xs font-semibold uppercase tracking-wider text-[var(--text-muted)] mb-2 block">
              Select a question
            </label>
            <select
              value={selectedIdx}
              onChange={(e) => setSelectedIdx(parseInt(e.target.value))}
              className="w-full px-3 py-2 rounded-lg border border-[var(--border)] bg-[var(--bg)] text-sm"
            >
              {(() => {
                let counter = 0;
                return grouped.map((g) => (
                  <optgroup key={g.tier} label={`${g.tier}: ${g.label}`}>
                    {g.questions.map((q) => {
                      counter++;
                      const idx = EVAL_QUESTIONS.indexOf(q);
                      return (
                        <option key={q.id} value={idx}>
                          Q{counter}: {q.q.slice(0, 75)}
                        </option>
                      );
                    })}
                  </optgroup>
                ));
              })()}
            </select>
          </div>
          <div className="flex items-end">
            <button
              onClick={() => {
                const q = EVAL_QUESTIONS[selectedIdx];
                runQuestion(q.q, q.id, q.expected, q.source, q.baselineCanAnswer, q.baselineError);
              }}
              disabled={loading}
              className="px-6 py-2 rounded-lg bg-[var(--sense)] text-white font-medium text-sm hover:opacity-90 disabled:opacity-50 transition-opacity"
            >
              {loading ? "Running..." : "Ask Both Agents"}
            </button>
          </div>
        </div>

        <div className="mt-4 pt-4 border-t border-[var(--border)]">
          <label className="text-xs font-semibold uppercase tracking-wider text-[var(--text-muted)] mb-2 block">
            Or type a custom question
          </label>
          <div className="flex gap-3">
            <input
              type="text"
              value={customQ}
              onChange={(e) => setCustomQ(e.target.value)}
              onKeyDown={(e) => {
                if (e.key === "Enter" && customQ.trim()) {
                  runQuestion(customQ, "Custom", "", "Unknown", false);
                  setCustomQ("");
                }
              }}
              placeholder="Type any supply chain question..."
              className="flex-1 px-3 py-2 rounded-lg border border-[var(--border)] bg-[var(--bg)] text-sm"
            />
            <button
              onClick={() => {
                if (customQ.trim()) {
                  runQuestion(customQ, "Custom", "", "Unknown", false);
                  setCustomQ("");
                }
              }}
              disabled={loading || !customQ.trim()}
              className="px-5 py-2 rounded-lg border border-[var(--border)] text-sm font-medium hover:bg-[var(--bg)] disabled:opacity-50"
            >
              Ask
            </button>
          </div>
        </div>
      </div>

      {/* Current question */}
      {currentQ && (
        <div className="mb-6">
          <div className="flex items-center gap-2 mb-1">
            <span className="text-xs font-bold px-2 py-0.5 rounded-full text-white"
                  style={{ backgroundColor: TIER_COLORS[EVAL_QUESTIONS.find(eq => eq.id === currentQ.id)?.tier || ""] || "#666" }}>
              {currentQ.id}
            </span>
            <span className="text-xs text-[var(--text-muted)]">{currentQ.source}</span>
          </div>
          <p className="text-lg font-medium">{currentQ.q}</p>
        </div>
      )}

      {loading && (
        <div className="text-center py-12 text-[var(--text-muted)]">
          <div className="inline-block w-8 h-8 border-2 border-[var(--sense)] border-t-transparent rounded-full animate-spin mb-3" />
          <p className="text-sm">Running both agents in parallel...</p>
        </div>
      )}

      {/* Side-by-side results */}
      {(baseline || sense || loading) && (
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-5">
          <AgentPanel label="Baseline Agent (SV Only)" response={baseline} color="var(--baseline)" />
          <AgentPanel label="Cortex Sense Agent" response={sense} color="var(--sense)" />
        </div>
      )}

      {/* Verdict */}
      {currentQ?.expected && !loading && (baseline || sense) && (
        <div className="mt-5 grid grid-cols-1 lg:grid-cols-3 gap-4">
          <div className={`rounded-xl px-5 py-4 ${currentQ.baselineCanAnswer ? "bg-emerald-50 dark:bg-emerald-950 border border-emerald-200 dark:border-emerald-800" : "bg-red-50 dark:bg-red-950 border border-red-200 dark:border-red-800"}`}>
            <div className={`text-xs font-semibold uppercase tracking-wider mb-1 ${currentQ.baselineCanAnswer ? "text-emerald-600" : "text-red-600"}`}>
              Baseline: {currentQ.baselineCanAnswer ? "CAN answer" : "WRONG or CAN'T answer"}
            </div>
            {currentQ.baselineError && <p className="text-xs text-[var(--text-muted)]">{currentQ.baselineError}</p>}
          </div>
          <div className="rounded-xl px-5 py-4 bg-emerald-50 dark:bg-emerald-950 border border-emerald-200 dark:border-emerald-800">
            <div className="text-xs font-semibold uppercase tracking-wider text-emerald-600 mb-1">
              Sense: CAN answer
            </div>
            <p className="text-xs text-[var(--text-muted)]">Context from: {currentQ.source}</p>
          </div>
          <div className="rounded-xl px-5 py-4 bg-blue-50 dark:bg-blue-950 border border-blue-200 dark:border-blue-800">
            <div className="text-xs font-semibold uppercase tracking-wider text-blue-600 mb-1">Expected Answer</div>
            <p className="text-xs">{currentQ.expected}</p>
          </div>
        </div>
      )}

      {/* Scorecard */}
      <div className="mt-8 rounded-xl border border-[var(--border)] bg-[var(--bg-card)] p-5">
        <h3 className="font-semibold text-sm mb-4">Scorecard</h3>
        <div className="grid grid-cols-3 gap-3">
          {Object.entries(TIER_LABELS).map(([tier, label]) => {
            const qs = EVAL_QUESTIONS.filter((q) => q.tier === tier);
            const bYes = qs.filter((q) => q.baselineCanAnswer).length;
            return (
              <div key={tier} className="text-center p-3 rounded-lg border border-[var(--border)]">
                <div className="text-xs font-bold mb-1" style={{ color: TIER_COLORS[tier] }}>{tier}</div>
                <div className="text-[10px] text-[var(--text-muted)] mb-2 leading-tight">{label.split("(")[0].trim()}</div>
                <div className="text-xs">B: {bYes}/{qs.length}</div>
                <div className="text-xs font-bold" style={{ color: "var(--sense)" }}>S: {qs.length}/{qs.length}</div>
              </div>
            );
          })}
        </div>
      </div>
    </div>
  );
}
