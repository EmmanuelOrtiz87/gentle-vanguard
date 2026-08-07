/**
 * TokenTracker — opencode plugin (opencode-ai >= 1.17, plugin API).
 *
 * Captures REAL token usage from opencode's `message.updated` events and
 * persists it into the Gentle-Vanguard stack so `token:status`, the dashboard
 * and the metrics collectors show real numbers instead of stale/zero data.
 *
 * Data source (verified against @opencode-ai/sdk types.gen.d.ts):
 *   AssistantMessage = {
 *     id, sessionID, role: "assistant",
 *     modelID, providerID,
 *     cost: number,
 *     tokens: { input, output, reasoning, cache: { read, write } }
 *   }
 *
 * Writes:
 *   - .session/token-usage.json          (canonical session token file)
 *   - .session/session-current.json      (updates totalInput/Output/TotalTokens)
 *   - .runtime/token-tracker.log         (append-only jsonl-ish history)
 *   - .runtime/token-tracker-state.json  (per-message dedup state)
 *
 * Loaded automatically from .opencode/plugins/ (project level).
 */
import { mkdirSync, readFileSync, writeFileSync, appendFileSync, existsSync } from "fs";
import { join } from "path";

interface TrackedMsg {
  input: number;
  output: number;
  cost: number;
  modelID: string;
  updated: string;
}

type State = Record<string, Record<string, TrackedMsg>>;

function statePath(root: string): string {
  return join(root, ".runtime", "token-tracker-state.json");
}

function loadState(root: string): State {
  try {
    const p = statePath(root);
    if (existsSync(p)) return JSON.parse(readFileSync(p, "utf-8")) as State;
  } catch {
    /* fresh start */
  }
  return {};
}

function saveState(root: string, state: State): void {
  try {
    const p = statePath(root);
    mkdirSync(join(root, ".runtime"), { recursive: true });
    writeFileSync(p, JSON.stringify(state, null, 2));
  } catch {
    /* non-fatal */
  }
}

function persistSession(root: string, state: State, sessionID: string): void {
  try {
    const msgs = state[sessionID] || {};
    let input = 0;
    let output = 0;
    let cost = 0;
    const models = new Set<string>();
    for (const m of Object.values(msgs)) {
      input += m.input || 0;
      output += m.output || 0;
      cost += m.cost || 0;
      if (m.modelID) models.add(m.modelID);
    }
    const sessionDir = join(root, ".session");
    mkdirSync(sessionDir, { recursive: true });

    const data = {
      sessionId: sessionID,
      totalInputTokens: input,
      totalOutputTokens: output,
      totalTokens: input + output,
      cost_usd: cost,
      model: [...models].join(",") || "unknown",
      source: "opencode-plugin",
      messageCount: Object.keys(msgs).length,
      updatedAt: new Date().toISOString(),
    };

    // Canonical session token file (what token-status / close orchestrator read).
    writeFileSync(join(sessionDir, "token-usage.json"), JSON.stringify(data, null, 2));

    // Update live session file token fields if present.
    const cur = join(sessionDir, "session-current.json");
    if (existsSync(cur)) {
      try {
        const s = JSON.parse(readFileSync(cur, "utf-8")) as Record<string, unknown>;
        s.totalInputTokens = input;
        s.totalOutputTokens = output;
        s.totalTokens = input + output;
        s.cost = cost;
        s.toolCalls = s.toolCalls ?? 0;
        writeFileSync(cur, JSON.stringify(s, null, 2));
      } catch {
        /* non-fatal */
      }
    }

    // Append-only history.
    try {
      appendFileSync(
        join(root, ".runtime", "token-tracker.log"),
        `${new Date().toISOString()} session=${sessionID} in=${input} out=${output} total=${
          input + output
        } cost=${cost.toFixed(6)} msgs=${Object.keys(msgs).length}\n`,
        "utf-8",
      );
    } catch {
      /* non-fatal */
    }
  } catch {
    /* never break the tool loop */
  }
}

/**
 * The plugin function. `directory` is the current working directory (repo root).
 */
export const TokenTracker = async ({ directory }: { directory?: string }) => {
  // Root resolution: prefer the opencode-provided cwd, fall back to the repo
  // root derived from this plugin's own location (.opencode/plugins/ -> repo root).
  const root =
    directory ||
    join(import.meta.dirname || __dirname || process.cwd(), "..", "..");

  // Persist the in-memory state across message events (loaded once at startup).
  const state = loadState(root);

  const handleMessage = (event: unknown): void => {
    try {
      const e = event as {
        properties?: { info?: { [k: string]: unknown } };
        info?: { [k: string]: unknown };
      };
      // Named hooks may receive the full event {type, properties} or just the payload.
      const info = e?.properties?.info ?? e?.info ?? (event as { [k: string]: unknown });
      if (!info || info.role !== "assistant") return;
      const tokens = info.tokens as
        | { input?: number; output?: number; reasoning?: number; cache?: { read?: number; write?: number } }
        | undefined;
      const sessionID = info.sessionID as string | undefined;
      const msgID = info.id as string | undefined;
      if (!tokens || !sessionID || !msgID) return;

      const input = tokens.input ?? 0;
      const output = tokens.output ?? 0;

      state[sessionID] = state[sessionID] || {};
      const prev = state[sessionID][msgID];
      // Dedup: only persist when the tracked values actually changed (the
      // message.updated event can fire many times while a response streams).
      if (prev && prev.input === input && prev.output === output) return;

      state[sessionID][msgID] = {
        input,
        output,
        cost: (info.cost as number) ?? 0,
        modelID: (info.modelID as string) ?? "",
        updated: new Date().toISOString(),
      };
      saveState(root, state);
      persistSession(root, state, sessionID);
    } catch {
      /* never break the tool loop */
    }
  };

  return {
    "message.updated": async (event: unknown) => handleMessage(event),
    "session.idle": async (event: unknown) => {
      // Finalize the session total with the accumulated per-message state.
      try {
        const e = event as { properties?: { sessionID?: string }; sessionID?: string };
        const sessionID = e?.properties?.sessionID ?? e?.sessionID;
        if (sessionID && state[sessionID]) persistSession(root, state, sessionID);
      } catch {
        /* non-fatal */
      }
    },
  };
};

export default TokenTracker;
