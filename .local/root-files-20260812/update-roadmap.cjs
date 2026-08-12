const fs = require('fs');

const filePath = 'gentle-vanguard-presentation-v8.html';
let content = fs.readFileSync(filePath, 'utf-8');

// Find and replace the v5.0 Autonomy section with detailed roadmap items
const oldV5Section = `        <div class="tl-item future">
          <h4>
            v5.0 — Autonomy<span class="tl-tag tag" style="background: var(--bd); color: var(--tm)"
              >Future</span
            >
          </h4>
          <p>
            Self-evolving agents, cross-workspace collaboration, autonomous code review, predictive
            incident response.
          </p>
        </div>`;

const newRoadmapItems = `        <div class="tl-item future">
          <h4>
            v5.0 — Convergence<span class="tl-tag tag" style="background: var(--bd); color: var(--tm)"
              >Future</span
            >
          </h4>
          <p>
            Convergence Monitor, Knowledge Synthesizer, Self-Reflection Loop, Adaptive Router,
            Predictive Governor, Root-Cause Correlator, Skill Evolution Engine.
          </p>
        </div>
        <div class="tl-item future">
          <h4>
            v5.1 — Multi-Tenant<span class="tl-tag tag" style="background: var(--bd); color: var(--tm)"
              >Future</span
            >
          </h4>
          <p>
            Tenant Context isolation, Eval Quality Gate, CI Rollback Engine with auto-healing.
          </p>
        </div>
        <div class="tl-item future">
          <h4>
            v6.0 — Autonomous Review<span class="tl-tag tag" style="background: var(--bd); color: var(--tm)"
              >Future</span
            >
          </h4>
          <p>
            Auto Code Review with multi-lens analysis, Receipt Manager, Staged Review with incremental validation.
          </p>
        </div>
        <div class="tl-item future">
          <h4>
            v6.4 — MCP Native<span class="tl-tag tag" style="background: var(--bd); color: var(--tm)"
              >Future</span
            >
          </h4>
          <p>
            MCP Gateway for IDE integration, GateGuard MCP for protocol security.
          </p>
        </div>
        <div class="tl-item future">
          <h4>
            v8.0 — Trust Layer<span class="tl-tag tag" style="background: var(--bd); color: var(--tm)"
              >Future</span
            >
          </h4>
          <p>
            Findings Ledger, Compact State with CAS, Review Lenses, Result Gatekeeper, Publication Gates.
          </p>
        </div>`;

content = content.replace(oldV5Section, newRoadmapItems);

// Write back
fs.writeFileSync(filePath, content);
console.log('Roadmap updated successfully');
console.log('Added detailed roadmap items for:');
console.log('  - v5.0 — Convergence');
console.log('  - v5.1 — Multi-Tenant');
console.log('  - v6.0 — Autonomous Review');
console.log('  - v6.4 — MCP Native');
console.log('  - v8.0 — Trust Layer');
