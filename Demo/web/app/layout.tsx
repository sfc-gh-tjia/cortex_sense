import "./globals.css";
import type { Metadata } from "next";

export const metadata: Metadata = {
  title: "Cortex Sense Evaluation — SAP Supply Chain",
  description: "Side-by-side comparison: SV-only baseline vs Cortex Sense agent — 10 questions, 3 mechanisms",
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <body className="min-h-screen bg-[var(--bg)] text-[var(--text)] antialiased">
        <header className="border-b border-[var(--border)] bg-[var(--bg-card)]">
          <div className="max-w-7xl mx-auto px-6 py-5">
            <h1 className="text-2xl font-bold tracking-tight">
              Cortex Sense Evaluation
            </h1>
            <p className="text-sm text-[var(--text-muted)] mt-1">
              SAP Supply Chain — 10 questions comparing a Semantic View-only baseline vs a Cortex Sense-powered agent. Sense 10/10 vs Baseline 2/10.
            </p>
          </div>
        </header>
        <main className="max-w-7xl mx-auto px-6 py-6">{children}</main>
      </body>
    </html>
  );
}
