// .cursor/hooks/grind.ts
// Stop hook for long-running agent loops (e.g. "keep running until tests pass")
// Requires Cursor Nightly + Bun runtime
// Cursor calls this after each agent stop to decide whether to continue

import { readFileSync, existsSync } from "fs";

interface StopHookInput {
  conversation_id: string;
  status: "completed" | "aborted" | "error";
  loop_count: number;
}

const input: StopHookInput = await Bun.stdin.json();

const MAX_ITERATIONS = 5;

if (input.status !== "completed" || input.loop_count >= MAX_ITERATIONS) {
  console.log(JSON.stringify({}));
  process.exit(0);
}

const scratchpad = existsSync(".cursor/scratchpad.md")
  ? readFileSync(".cursor/scratchpad.md", "utf-8")
  : "";

if (scratchpad.includes("DONE")) {
  console.log(JSON.stringify({}));
} else {
  console.log(JSON.stringify({
    followup_message: `[Iteracion ${input.loop_count + 1}/${MAX_ITERATIONS}] Continua trabajando. Actualiza .cursor/scratchpad.md con DONE cuando hayas terminado.`
  }));
}
