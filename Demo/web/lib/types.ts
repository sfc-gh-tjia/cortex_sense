export interface AgentResponse {
  text: string;
  htmlArtifacts: string[];
  elapsed: number;
}

export interface EvalQuestion {
  id: string;
  tier: string;
  q: string;
  expected: string;
  source: string;
  baselineCanAnswer: boolean;
  baselineError?: string;
}

export interface SourceInfo {
  name: string;
  id: string;
  detail: string;
  tables?: number;
}

export interface SvTable {
  name: string;
  comment: string;
}

export interface SvColumn {
  table: string;
  column: string;
  kind: string;
  comment: string;
}

export interface ConfigData {
  baselineDDL: string;
  senseDDL: string;
  svTables: SvTable[];
  svColumns: SvColumn[];
  allTables: { schema: string; name: string; rows: number | null; type: string }[];
  longTailTables: { schema: string; name: string; rows: number | null; type: string }[];
  ambiguousColumns: SvColumn[];
  sources: SourceInfo[];
}
