const fs = require('fs');

const CSS = `
:root{--p:#00bfff;--pl:#4dcfff;--pd:#0088cc;--a:#a855f7;--ok:#22c55e;--wn:#f59e0b;--er:#ef4444;--bg:#0a0e1a;--s1:#111827;--s2:#1e293b;--tx:#f1f5f9;--tm:#94a3b8;--bd:#1e3a5f;--gw:0 0 20px rgba(0,191,255,0.15);--radius:16px;--tr:0.3s cubic-bezier(0.4,0,0.2,1)}
*{margin:0;padding:0;box-sizing:border-box}
html,body{height:100%;overflow:hidden;font-family:'Inter',system-ui,sans-serif;background:var(--bg);color:var(--tx)}
.slide-container{display:flex;width:100vw;height:100vh;transition:transform 0.6s cubic-bezier(0.4,0,0.2,1)}
.slide{min-width:100vw;height:100vh;overflow-y:auto;overflow-x:hidden;scroll-behavior:smooth;padding:4.2rem 2.5rem 2rem;display:flex;flex-direction:column;opacity:0;transform:translateX(40px);transition:opacity 0.5s ease,transform 0.5s ease}
.slide.active{opacity:1;transform:translateX(0)}
.hero-slide{overflow-y:hidden!important}
@media(max-width:768px){.slide{padding:3.5rem 0.8rem 1.5rem}}
nav{position:fixed;top:0;left:0;right:0;z-index:1000;background:rgba(10,14,26,0.95);backdrop-filter:blur(20px);border-bottom:1px solid var(--bd);padding:0.4rem 1.5rem;display:flex;align-items:center;justify-content:space-between;gap:0.5rem}
nav .brand{font-family:'JetBrains Mono',monospace;font-weight:700;font-size:0.85rem;color:var(--p)}
nav .nav-center{display:flex;align-items:center;gap:0.5rem}
nav .nav-arrows{display:flex;gap:0.3rem}
nav .nav-arrows button{background:var(--s2);border:1px solid var(--bd);color:var(--tm);width:28px;height:28px;border-radius:6px;cursor:pointer;font-size:0.8rem;display:flex;align-items:center;justify-content:center;transition:all var(--tr)}
nav .nav-arrows button:hover{background:var(--p);color:var(--bg);border-color:var(--p)}
nav .nav-arrows button:disabled{opacity:0.3;cursor:not-allowed}
nav .slide-counter{font-family:'JetBrains Mono',monospace;font-size:0.7rem;color:var(--tm);min-width:50px;text-align:center}
.lang-switch{display:flex;gap:0.2rem}
.lang-switch button{background:transparent;border:1px solid var(--bd);color:var(--tm);padding:0.2em 0.5em;border-radius:4px;cursor:pointer;font-size:0.65rem;font-weight:600;transition:all var(--tr)}
.lang-switch button.active{background:var(--p);color:var(--bg);border-color:var(--p)}
.lang-switch button:hover:not(.active){border-color:var(--p);color:var(--p)}
.progress-bar{position:fixed;top:0;left:0;height:2px;background:linear-gradient(90deg,var(--p),var(--a));z-index:1001;transition:width 0.4s ease}
.sh{text-align:center;margin-bottom:1.2rem;flex-shrink:0}
.sh .ico{font-size:2rem;margin-bottom:0.3rem}
.sh h2{font-size:clamp(1.4rem,3vw,2rem);font-weight:800;margin-bottom:0.3rem}
.sh p{color:var(--tm);max-width:600px;margin:0 auto;font-size:0.8rem}
.g2{display:grid;grid-template-columns:repeat(auto-fit,minmax(280px,1fr));gap:0.9rem}
.g3{display:grid;grid-template-columns:repeat(auto-fit,minmax(220px,1fr));gap:0.7rem}
.g4{display:grid;grid-template-columns:repeat(auto-fit,minmax(180px,1fr));gap:0.6rem}
.g5{display:grid;grid-template-columns:repeat(auto-fit,minmax(155px,1fr));gap:0.5rem}
.c{background:var(--s1);border:1px solid var(--bd);border-radius:var(--radius);padding:0.9rem;transition:all var(--tr);position:relative}
.c:hover{border-color:var(--p);transform:translateY(-2px);box-shadow:var(--gw)}
.c .ci{font-size:1.3rem;margin-bottom:0.3rem}
.c h3{font-size:0.78rem;font-weight:700;margin-bottom:0.2rem}
.c p{font-size:0.66rem;color:var(--tm);line-height:1.4}
.tag{display:inline-block;padding:0.12em 0.45em;border-radius:6px;font-size:0.56rem;font-weight:600;margin-top:0.2rem}
.tag.ok{background:rgba(34,197,94,0.15);color:var(--ok)}
.tag.planned{background:rgba(0,191,255,0.12);color:var(--p)}
.tag.progress{background:rgba(245,158,11,0.15);color:var(--wn)}
.tag.backlog{background:rgba(148,163,184,0.12);color:var(--tm)}
.tag-note{display:block;font-size:0.52rem;color:var(--tm);margin-top:0.1rem;font-style:italic}
.sd{display:inline-block;width:6px;height:6px;border-radius:50%;margin-right:3px;vertical-align:middle}
.sd.ok{background:var(--ok)}.sd.planned{background:var(--p)}.sd.progress{background:var(--wn)}.sd.backlog{background:var(--tm)}
.info-trigger{display:inline-flex;align-items:center;justify-content:center;width:14px;height:14px;border-radius:50%;background:rgba(0,191,255,0.15);color:var(--p);font-size:0.5rem;font-weight:700;cursor:pointer;margin-left:3px;vertical-align:middle;transition:all var(--tr)}
.info-trigger:hover{background:var(--p);color:var(--bg)}
.info-popup-overlay{position:fixed;inset:0;background:rgba(0,0,0,0.6);z-index:2000;display:none;align-items:center;justify-content:center;backdrop-filter:blur(6px)}
.info-popup-overlay.active{display:flex}
.info-popup{background:var(--s1);border:1px solid var(--p);border-radius:var(--radius);padding:1.5rem;max-width:500px;width:92%;max-height:80vh;overflow-y:auto;box-shadow:0 0 60px rgba(0,191,255,0.25);animation:popIn 0.3s cubic-bezier(0.34,1.56,0.64,1);position:relative}
.info-popup .close-btn{position:absolute;top:0.6rem;right:0.6rem;width:24px;height:24px;border-radius:50%;border:1px solid var(--bd);background:var(--s2);color:var(--tm);cursor:pointer;display:flex;align-items:center;justify-content:center;font-size:0.8rem;transition:all var(--tr)}
.info-popup .close-btn:hover{background:var(--er);color:white;border-color:var(--er)}
.info-popup h4{font-size:0.9rem;font-weight:700;color:var(--p);margin-bottom:0.5rem;padding-right:1.5rem}
.info-popup p{font-size:0.75rem;color:var(--tm);line-height:1.55;margin-bottom:0.4rem}
.info-popup code{background:var(--s2);padding:0.1em 0.3em;border-radius:4px;font-family:'JetBrains Mono',monospace;font-size:0.7rem;color:var(--p)}
.info-popup ul{margin:0.3rem 0;padding-left:1rem}
.info-popup li{font-size:0.72rem;color:var(--tm);margin-bottom:0.2rem}
@keyframes popIn{from{opacity:0;transform:scale(0.9) translateY(20px)}to{opacity:1;transform:scale(1) translateY(0)}}
.cc{background:var(--s1);border:1px solid var(--bd);border-radius:var(--radius);padding:0.9rem;margin:0.7rem 0}
.ct{font-size:0.72rem;font-weight:600;margin-bottom:0.6rem;color:var(--tm)}
table{width:100%;border-collapse:collapse;font-size:0.66rem}
th{text-align:left;padding:0.35rem 0.5rem;border-bottom:2px solid var(--bd);color:var(--p);font-weight:600;font-size:0.62rem;text-transform:uppercase;letter-spacing:0.04em}
td{padding:0.3rem 0.5rem;border-bottom:1px solid rgba(30,58,95,0.4);color:var(--tm)}
tr:hover td{background:rgba(0,191,255,0.03)}
.mc{background:var(--s1);border:1px solid var(--bd);border-radius:var(--radius);padding:0.7rem;text-align:center;transition:all var(--tr)}
.mc:hover{border-color:var(--p);box-shadow:var(--gw)}
.mc .mn{font-size:1.5rem;font-weight:900;font-family:'JetBrains Mono',monospace;margin-bottom:0.15rem}
.mc .ml{font-size:0.64rem;color:var(--tm);font-weight:600;text-transform:uppercase;letter-spacing:0.04em;margin-bottom:0.2rem}
.mc .md{font-size:0.58rem;color:var(--tm);line-height:1.35}
.timeline{position:relative;padding:1rem 0 1rem 28px}
.timeline::before{content:'';position:absolute;left:12px;top:0;bottom:0;width:2px;background:linear-gradient(to bottom,var(--p),var(--a))}
.tl-item{position:relative;padding-left:28px;margin-bottom:0.9rem}
.tl-item::before{content:'';position:absolute;left:-20px;top:3px;width:11px;height:11px;border-radius:50%;background:var(--p);border:2px solid var(--bg);z-index:1}
.tl-item.done::before{background:var(--ok)}
.tl-item.current::before{background:var(--p);box-shadow:0 0 10px var(--p)}
.tl-item.future::before{background:var(--bd)}
.tl-item h4{font-size:0.82rem;font-weight:700;margin-bottom:0.15rem}
.tl-item p{font-size:0.7rem;color:var(--tm)}
.tl-tag{font-size:0.54rem;padding:0.1em 0.35em;border-radius:4px;font-weight:600;margin-left:0.3rem}
.arch-layer{background:var(--s1);border:1px solid var(--bd);border-radius:var(--radius);padding:0.5rem 0.9rem;margin-bottom:0.35rem;transition:all var(--tr)}
.arch-layer:hover{border-color:var(--p);box-shadow:var(--gw)}
.arch-layer .layer-name{font-size:0.62rem;font-weight:700;color:var(--p);text-transform:uppercase;letter-spacing:0.06em;margin-bottom:0.15rem}
.arch-layer .layer-items{display:flex;flex-wrap:wrap;gap:0.25rem}
.arch-layer .layer-items span{background:var(--s2);padding:0.12em 0.45em;border-radius:5px;font-size:0.6rem;color:var(--tm);border:1px solid transparent;transition:all var(--tr)}
.arch-layer:hover .layer-items span{border-color:rgba(0,191,255,0.2);color:var(--tx)}
.carousel-wrap{position:relative;overflow:hidden;border-radius:var(--radius)}
.carousel-track{display:flex;transition:transform 0.5s cubic-bezier(0.4,0,0.2,1)}
.carousel-item{min-width:100%;padding:0 0.3rem}
.carousel-nav{display:flex;justify-content:center;gap:0.5rem;margin-top:0.5rem}
.carousel-nav button{background:var(--s2);border:1px solid var(--bd);color:var(--tm);width:26px;height:26px;border-radius:50%;cursor:pointer;font-size:0.7rem;transition:all var(--tr)}
.carousel-nav button:hover{background:var(--p);color:var(--bg);border-color:var(--p)}
.carousel-dots{display:flex;gap:0.3rem;justify-content:center;margin-top:0.35rem}
.carousel-dots .cdot{width:6px;height:6px;border-radius:50%;background:var(--bd);cursor:pointer;transition:all var(--tr)}
.carousel-dots .cdot.active{background:var(--p);transform:scale(1.3)}
.hero-slide{display:flex;flex-direction:column;align-items:center;justify-content:center;text-align:center;position:relative}
.hero-slide::before{content:'';position:absolute;inset:-50%;width:200%;height:200%;background:radial-gradient(ellipse at 30% 50%,rgba(0,191,255,0.08) 0%,transparent 50%),radial-gradient(ellipse at 70% 20%,rgba(168,85,247,0.06) 0%,transparent 50%);animation:drift 20s ease-in-out infinite}
@keyframes drift{0%,100%{transform:translate(0)}50%{transform:translate(-2%,1%)}}
.badge{display:inline-flex;align-items:center;gap:0.5rem;background:rgba(0,191,255,0.1);border:1px solid rgba(0,191,255,0.2);padding:0.3rem 0.8rem;border-radius:100px;font-size:0.65rem;font-weight:600;color:var(--p);text-transform:uppercase;letter-spacing:0.08em;margin-bottom:0.8rem;position:relative;z-index:1}
h1{font-size:clamp(2.2rem,5.5vw,4rem);font-weight:900;letter-spacing:-0.02em;line-height:1.05;margin-bottom:0.6rem;position:relative;z-index:1}
h1 .g{background:linear-gradient(135deg,var(--p),var(--a));-webkit-background-clip:text;-webkit-text-fill-color:transparent;background-clip:text}
.hero-sub{font-size:clamp(0.8rem,1.6vw,1.05rem);color:var(--tm);max-width:600px;margin:0 auto 1.2rem;position:relative;z-index:1}
.hero-phrase{font-size:0.82rem;color:var(--a);font-weight:600;max-width:550px;margin:0 auto 1.5rem;position:relative;z-index:1;font-style:italic}
.stats{display:flex;gap:1.2rem;flex-wrap:wrap;justify-content:center;position:relative;z-index:1}
.stat{text-align:center}
.stat .n{font-size:1.9rem;font-weight:900;color:var(--p);font-family:'JetBrains Mono',monospace}
.stat .l{font-size:0.6rem;color:var(--tm);text-transform:uppercase;letter-spacing:0.06em}
.counter{display:inline-block}
#particles{position:fixed;top:0;left:0;width:100%;height:100%;z-index:0;pointer-events:none}
footer{text-align:center;padding:1.5rem;border-top:1px solid var(--bd);color:var(--tm);font-size:0.65rem;margin-top:auto}
footer a{color:var(--p);text-decoration:none}
@media(max-width:768px){nav{padding:0.4rem 0.8rem}nav .nav-center{gap:0.3rem}.g2,.g3,.g4,.g5{grid-template-columns:1fr}.carousel-item{min-width:100%}}
`;

// Build slides HTML
const slides = [];

// SLIDE 1: HERO
slides.push(`
<div class="slide hero-slide active" data-slide="0">
  <div class="badge" data-i18n="hero_badge">v5.0 — Enterprise Grade</div>
  <h1><span class="g" data-i18n="hero_title">Gentle-Vanguard</span></h1>
  <p class="hero-sub" data-i18n="hero_sub">AI-Powered Development Orchestrator — 20+ Components, 30 Agents, 390 Skills, 36 Normatives, 1475 Memories, 10+ Tool-Compatible.</p>
  <div class="stats">
    <div class="stat"><div class="n counter" data-target="20">0</div><div class="l" data-i18n="stat_components">Components</div></div>
    <div class="stat"><div class="n counter" data-target="30">0</div><div class="l" data-i18n="stat_agents">Agents</div></div>
    <div class="stat"><div class="n counter" data-target="390">0</div><div class="l" data-i18n="stat_skills">Skills</div></div>
    <div class="stat"><div class="n counter" data-target="36">0</div><div class="l" data-i18n="stat_normatives">Normatives</div></div>
    <div class="stat"><div class="n counter" data-target="1475">0</div><div class="l" data-i18n="stat_memories">Memories</div></div>
    <div class="stat"><div class="n">74/74</div><div class="l" data-i18n="stat_health">Health PASS</div></div>
  </div>
</div>`);

// SLIDE 2: WHAT IS IT
slides.push(`
<div class="slide" data-slide="1">
  <div class="sh"><div class="ico">&#127919;</div><h2 data-i18n="what_title">What is Gentle-Vanguard?</h2><p data-i18n="what_sub">The problem it solves and why it exists.</p></div>
  <div class="g2">
    <div class="cc"><div class="ct" data-i18n="what_problem_title">The Problem</div><p style="font-size:0.76rem;color:var(--tm);line-height:1.6" data-i18n="what_problem">AI-assisted development is powerful but chaotic. Multiple agents, dozens of skills, no memory between sessions, no governance, no cost control. Teams lose context, waste tokens, and repeat mistakes.</p></div>
    <div class="cc"><div class="ct" data-i18n="what_solution_title">The Solution</div><p style="font-size:0.76rem;color:var(--tm);line-height:1.6" data-i18n="what_solution">Gentle-Vanguard is a complete AI development orchestrator. Persistent memory, code intelligence, 30 specialized agents, 390 skills, 36 governance normatives, real-time dashboard, distributed tracing, and cloud connectors — one unified system.</p></div>
  </div>
  <div class="g3" style="margin-top:0.7rem">
    <div class="c"><div class="ci">&#129504;</div><h3 data-i18n="what_mem_title">Persistent Memory</h3><p data-i18n="what_mem">1475 observations survive across sessions. RAG vector search, auto-sync, integrity checks.</p></div>
    <div class="c"><div class="ci">&#129302;</div><h3 data-i18n="what_agents_title">30 Specialized Agents</h3><p data-i18n="what_agents">From BA exploration to QA verification, each agent is optimized for its domain.</p></div>
    <div class="c"><div class="ci">&#128202;</div><h3 data-i18n="what_dash_title">Real-time Dashboard</h3><p data-i18n="what_dash">React/TypeScript observability UI with 3 languages, 8 alert rules, WebSocket push.</p></div>
    <div class="c"><div class="ci">&#128274;</div><h3 data-i18n="what_sec_title">Enterprise Security</h3><p data-i18n="what_sec">RBAC, CSP, rate limiting, audit logging, OWASP compliance, HITL gates.</p></div>
    <div class="c"><div class="ci">&#9729;&#65039;</div><h3 data-i18n="what_cloud_title">Multi-Cloud</h3><p data-i18n="what_cloud">AWS Lambda, Azure Functions, circuit breaker routing, cost optimization.</p></div>
    <div class="c"><div class="ci">&#9889;</div><h3 data-i18n="what_event_title">Event Sourcing</h3><p data-i18n="what_event">Append-only event store with 10 projections, saga orchestration, crash recovery.</p></div>
  </div>
</div>`);

// SLIDE 3: COMPONENTS CAROUSEL
slides.push(`
<div class="slide" data-slide="2">
  <div class="sh"><div class="ico">&#129513;</div><h2 data-i18n="comp_title">Stack Components</h2><p data-i18n="comp_sub">20+ integrated subsystems powering the full development lifecycle.</p></div>
  <div class="carousel-wrap" id="compCarousel"><div class="carousel-track" id="compTrack">
    <div class="carousel-item"><div class="g5">
      <div class="c"><div class="ci">&#9881;&#65039;</div><h3>Session Pipeline<span class="info-trigger" data-info="session-pipeline">i</span></h3><p data-i18n="comp_session">46-step autostart pipeline with lazy execution, orphan cleanup, checkpoint auto-creation.</p><span class="tag ok"><span class="sd ok"></span>Active</span><span class="tag-note" data-i18n="status_active">Implemented &amp; running</span></div>
      <div class="c"><div class="ci">&#129504;</div><h3>Engram Memory<span class="info-trigger" data-info="engram">i</span></h3><p data-i18n="comp_engram">Persistent memory across sessions. 1475 observations, RAG vector index, integrity checks.</p><span class="tag ok"><span class="sd ok"></span>Active</span><span class="tag-note" data-i18n="status_active">Implemented &amp; running</span></div>
      <div class="c"><div class="ci">&#128279;</div><h3>CodeGraph<span class="info-trigger" data-info="codegraph">i</span></h3><p data-i18n="comp_cg">SQLite knowledge graph of every symbol, edge, and file. Sub-millisecond reads.</p><span class="tag ok"><span class="sd ok"></span>Active</span><span class="tag-note" data-i18n="status_active">Implemented &amp; running</span></div>
      <div class="c"><div class="ci">&#128202;</div><h3>Dashboard<span class="info-trigger" data-info="dashboard">i</span></h3><p data-i18n="comp_dash">React/TypeScript LLM observability dashboard. 17 components, i18n, 8 alert rules.</p><span class="tag ok"><span class="sd ok"></span>Active</span><span class="tag-note" data-i18n="status_active">Implemented &amp; running</span></div>
      <div class="c"><div class="ci">&#129302;</div><h3>ML Embeddings<span class="info-trigger" data-info="ml-embeddings">i</span></h3><p data-i18n="comp_ml">390 skills vectorized with TF-IDF n-grams. ML router for skill recommendation.</p><span class="tag ok"><span class="sd ok"></span>Active</span><span class="tag-note" data-i18n="status_active">Implemented &amp; running</span></div>
    </div></div>
    <div class="carousel-item"><div class="g5">
      <div class="c"><div class="ci">&#9729;&#65039;</div><h3>Cloud Connectors<span class="info-trigger" data-info="cloud-connectors">i</span></h3><p data-i18n="comp_cloud">Hybrid executor with cost/latency/load routing. AWS + Azure. Circuit breaker.</p><span class="tag ok"><span class="sd ok"></span>Active</span><span class="tag-note" data-i18n="status_active">Implemented &amp; running</span></div>
      <div class="c"><div class="ci">&#128230;</div><h3>State Persistence<span class="info-trigger" data-info="state-persistence">i</span></h3><p data-i18n="comp_state">Checkpoint, snapshot, rollback. Session state survives crashes and restarts.</p><span class="tag ok"><span class="sd ok"></span>Active</span><span class="tag-note" data-i18n="status_active">Implemented &amp; running</span></div>
      <div class="c"><div class="ci">&#128269;</div><h3>Distributed Tracing<span class="info-trigger" data-info="tracing">i</span></h3><p data-i18n="comp_trace">OpenTelemetry instrumentation with OTLP export. Prometheus metrics.</p><span class="tag ok"><span class="sd ok"></span>Active</span><span class="tag-note" data-i18n="status_active">Implemented &amp; running</span></div>
      <div class="c"><div class="ci">&#128203;</div><h3>Audit Pipeline<span class="info-trigger" data-info="audit">i</span></h3><p data-i18n="comp_audit">SOC2/GDPR audit logging with 9 event schemas, SHA256 signing.</p><span class="tag ok"><span class="sd ok"></span>Active</span><span class="tag-note" data-i18n="status_active">Implemented &amp; running</span></div>
      <div class="c"><div class="ci">&#9889;</div><h3>Event Sourcing<span class="info-trigger" data-info="event-sourcing">i</span></h3><p data-i18n="comp_event">Append-only event store with 10 projections. Saga orchestrator.</p><span class="tag ok"><span class="sd ok"></span>Active</span><span class="tag-note" data-i18n="status_active">Implemented &amp; running</span></div>
    </div></div>
    <div class="carousel-item"><div class="g5">
      <div class="c"><div class="ci">&#128176;</div><h3>Cost Tracker<span class="info-trigger" data-info="cost-tracker">i</span></h3><p data-i18n="comp_cost">Real-time cost tracking with daily budget ($5), per-task limits ($0.80).</p><span class="tag ok"><span class="sd ok"></span>Active</span><span class="tag-note" data-i18n="status_active">Implemented &amp; running</span></div>
      <div class="c"><div class="ci">&#127919;</div><h3>Planning Estimator<span class="info-trigger" data-info="planning-estimator">i</span></h3><p data-i18n="comp_plan">Task complexity scoring (5 levels), PR size classification, model selection.</p><span class="tag ok"><span class="sd ok"></span>Active</span><span class="tag-note" data-i18n="status_active">Implemented &amp; running</span></div>
      <div class="c"><div class="ci">&#128260;</div><h3>Correction Rules<span class="info-trigger" data-info="correction-rules">i</span></h3><p data-i18n="comp_correct">12 auto-correction rules with atomic transactions and rollback.</p><span class="tag ok"><span class="sd ok"></span>Active</span><span class="tag-note" data-i18n="status_active">Implemented &amp; running</span></div>
      <div class="c"><div class="ci">&#128737;&#65039;</div><h3>Watchtower<span class="info-trigger" data-info="watchtower">i</span></h3><p data-i18n="comp_watch">74 checks across 15 components. Auto-healing. 6 operational modes.</p><span class="tag ok"><span class="sd ok"></span>Active</span><span class="tag-note" data-i18n="status_active">Implemented &amp; running</span></div>
      <div class="c"><div class="ci">&#128274;</div><h3>Security Orch<span class="info-trigger" data-info="security-orch">i</span></h3><p data-i18n="comp_sec">RBAC (5 roles), CSP headers, rate limiting, secret vault, audit log.</p><span class="tag ok"><span class="sd ok"></span>Active</span><span class="tag-note" data-i18n="status_active">Implemented &amp; running</span></div>
    </div></div>
    <div class="carousel-item"><div class="g5">
      <div class="c"><div class="ci">&#128221;</div><h3>Knowledge Base<span class="info-trigger" data-info="knowledge-base">i</span></h3><p data-i18n="comp_kb">Obsidian vault architecture with 8 folders. Auto-init, sync, and management.</p><span class="tag ok"><span class="sd ok"></span>Active</span><span class="tag-note" data-i18n="status_active">Implemented &amp; running</span></div>
      <div class="c"><div class="ci">&#128268;</div><h3>MCP Bridge<span class="info-trigger" data-info="mcp">i</span></h3><p data-i18n="comp_mcp">Model Context Protocol bridge for Cursor, Windsurf, Cline. 390 skills.</p><span class="tag ok"><span class="sd ok"></span>Active</span><span class="tag-note" data-i18n="status_active">Implemented &amp; running</span></div>
      <div class="c"><div class="ci">&#127760;</div><h3>Graphify<span class="info-trigger" data-info="graphify">i</span></h3><p data-i18n="comp_graph">Knowledge graph from codebase. God nodes, community structure. 23 MB.</p><span class="tag ok"><span class="sd ok"></span>Active</span><span class="tag-note" data-i18n="status_active">Implemented &amp; running</span></div>
      <div class="c"><div class="ci">&#128640;</div><h3>Workspace Sync<span class="info-trigger" data-info="workspace-sync">i</span></h3><p data-i18n="comp_sync">Multi-workspace synchronization. List, status, init, sync across environments.</p><span class="tag ok"><span class="sd ok"></span>Active</span><span class="tag-note" data-i18n="status_active">Implemented &amp; running</span></div>
      <div class="c"><div class="ci">&#129302;</div><h3>Agent Protocol<span class="info-trigger" data-info="agent-protocol">i</span></h3><p data-i18n="comp_proto">Agent collaboration protocol. Register, discover, delegate, inbox messaging.</p><span class="tag ok"><span class="sd ok"></span>Active</span><span class="tag-note" data-i18n="status_active">Implemented &amp; running</span></div>
    </div></div>
    <div class="carousel-item"><div class="g5">
      <div class="c"><div class="ci">&#128736;&#65039;</div><h3>CI/CD Pipeline<span class="info-trigger" data-info="cicd">i</span></h3><p data-i18n="comp_cicd">GitHub Actions workflow. Validate, watchtower, test, release stages.</p><span class="tag ok"><span class="sd ok"></span>Active</span><span class="tag-note" data-i18n="status_active">Implemented &amp; running</span></div>
      <div class="c"><div class="ci">&#128200;</div><h3>Predictive Monitor<span class="info-trigger" data-info="predictive">i</span></h3><p data-i18n="comp_predict">Watchtower trends with record, trend, predict, and report actions.</p><span class="tag ok"><span class="sd ok"></span>Active</span><span class="tag-note" data-i18n="status_active">Implemented &amp; running</span></div>
      <div class="c"><div class="ci">&#129504;</div><h3>Incremental ML<span class="info-trigger" data-info="incremental-ml">i</span></h3><p data-i18n="comp_incr_ml">Change-detection skill embedder. Only re-embeds modified skills.</p><span class="tag ok"><span class="sd ok"></span>Active</span><span class="tag-note" data-i18n="status_active">Implemented &amp; running</span></div>
      <div class="c"><div class="ci">&#128451;&#65039;</div><h3>Auto-Compaction<span class="info-trigger" data-info="auto-compact">i</span></h3><p data-i18n="comp_compact">90-day TTL auto-compaction for Engram. 30% safety limit, DryRun mode.</p><span class="tag ok"><span class="sd ok"></span>Active</span><span class="tag-note" data-i18n="status_active">Implemented &amp; running</span></div>
      <div class="c"><div class="ci">&#9881;&#65039;</div><h3>Adaptive DAG<span class="info-trigger" data-info="adaptive-dag">i</span></h3><p data-i18n="comp_dag">Dynamic task graph with parallel execution and dependency resolution.</p><span class="tag progress"><span class="sd progress"></span>In Progress</span><span class="tag-note" data-i18n="status_progress">Implemented, not finalized</span></div>
    </div></div>
    <div class="carousel-item"><div class="g5">
      <div class="c"><div class="ci">&#127760;</div><h3>Multi-Tenant<span class="info-trigger" data-info="multi-tenant">i</span></h3><p data-i18n="comp_tenant">Workspace isolation per user/team. Separate memory, config, and state.</p><span class="tag planned"><span class="sd planned"></span>Planned</span><span class="tag-note" data-i18n="status_planned">Planned for v5.1</span></div>
      <div class="c"><div class="ci">&#128200;</div><h3>Eval Framework<span class="info-trigger" data-info="eval-framework">i</span></h3><p data-i18n="comp_eval">Agent performance benchmarking. A/B prompt testing, quality metrics.</p><span class="tag planned"><span class="sd planned"></span>Planned</span><span class="tag-note" data-i18n="status_planned">Planned for v5.1</span></div>
      <div class="c"><div class="ci">&#129504;</div><h3>Semantic Search<span class="info-trigger" data-info="semantic-search">i</span></h3><p data-i18n="comp_semantic">Real embeddings for Engram. Vector similarity beyond TF-IDF.</p><span class="tag backlog"><span class="sd backlog"></span>Backlog</span><span class="tag-note" data-i18n="status_backlog">Future roadmap</span></div>
      <div class="c"><div class="ci">&#129302;</div><h3>Self-Evolving<span class="info-trigger" data-info="self-evolving">i</span></h3><p data-i18n="comp_evolve">Agents that modify their own prompts and strategies over time.</p><span class="tag backlog"><span class="sd backlog"></span>Backlog</span><span class="tag-note" data-i18n="status_backlog">Future roadmap</span></div>
      <div class="c"><div class="ci">&#128640;</div><h3>Cross-Workspace<span class="info-trigger" data-info="cross-workspace">i</span></h3><p data-i18n="comp_cross">Agents from different workspaces collaborate on shared tasks.</p><span class="tag backlog"><span class="sd backlog"></span>Backlog</span><span class="tag-note" data-i18n="status_backlog">Future roadmap</span></div>
    </div></div>
  </div><div class="carousel-nav"><button onclick="moveCarousel('comp',-1)">&larr;</button><button onclick="moveCarousel('comp',1)">&rarr;</button></div><div class="carousel-dots" id="compDots"></div></div>
</div>`);

// SLIDE 4: ARCHITECTURE
slides.push(`
<div class="slide" data-slide="3">
  <div class="sh"><div class="ico">&#127959;&#65039;</div><h2 data-i18n="arch_title">Architecture</h2><p data-i18n="arch_sub">6-layer architecture from tools to infrastructure — every layer purpose-built.</p></div>
  <div class="arch-layer"><div class="layer-name" data-i18n="arch_l1">Layer 1 — Tools (IDE Integration)</div><div class="layer-items"><span>OpenCode</span><span>Claude Code</span><span>Cursor</span><span>Windsurf</span><span>Cline</span><span>Codex</span><span>Copilot</span><span>Continue.dev</span><span>Aider</span><span>Roo Code</span></div></div>
  <div class="arch-layer"><div class="layer-name" data-i18n="arch_l2">Layer 2 — Agents (30 Specialized)</div><div class="layer-items"><span>Orchestrator</span><span>BA Explore</span><span>SAD Design</span><span>DEV Implement</span><span>QA Verify</span><span>GOV Compliance</span><span>OPS Deploy</span><span>Audit</span><span>Manager</span><span>Adaptive Router</span><span>Judgment Day</span><span>ML Router</span></div></div>
  <div class="arch-layer"><div class="layer-name" data-i18n="arch_l3">Layer 3 — Orchestration (SDD Pipeline)</div><div class="layer-items"><span>pre-process-input</span><span>session-start</span><span>auto-delegation</span><span>subagent-mapping</span><span>team-mode</span><span style="border-color:rgba(245,158,11,0.4);color:var(--wn)">correction-rules</span><span style="border-color:rgba(245,158,11,0.4);color:var(--wn)">adaptive-dag</span></div></div>
  <div class="arch-layer"><div class="layer-name" data-i18n="arch_l4">Layer 4 — Memory &amp; Knowledge</div><div class="layer-items"><span>Engram (1475)</span><span>RAG Vector</span><span>CodeGraph (1410)</span><span>Graphify (23MB)</span><span>ML (390)</span><span style="border-color:rgba(0,191,255,0.3);color:var(--p)">Knowledge Vault</span></div></div>
  <div class="arch-layer"><div class="layer-name" data-i18n="arch_l5">Layer 5 — Governance &amp; Security</div><div class="layer-items"><span>36 Normatives</span><span>RBAC (5)</span><span>CSP</span><span>Audit</span><span>Token Budget</span><span>HITL</span><span style="border-color:rgba(148,163,184,0.3);color:var(--tm)">Cost Attribution</span><span style="border-color:rgba(148,163,184,0.3);color:var(--tm)">Observability SLOs</span></div></div>
  <div class="arch-layer"><div class="layer-name" data-i18n="arch_l6">Layer 6 — Infrastructure</div><div class="layer-items"><span>Pipeline (46)</span><span>Lefthook (12)</span><span>Cloud Connectors</span><span>State Persist</span><span>Tracing</span><span>Events</span><span>Audit</span></div></div>
  <div style="display:flex;gap:1rem;margin-top:0.4rem;flex-wrap:wrap">
    <div style="display:flex;align-items:center;gap:0.3rem;font-size:0.58rem;color:var(--tm)"><span class="sd ok"></span><span data-i18n="arch_active">Active</span></div>
    <div style="display:flex;align-items:center;gap:0.3rem;font-size:0.58rem;color:var(--wn)"><span class="sd progress"></span><span data-i18n="arch_progress">In Progress</span></div>
    <div style="display:flex;align-items:center;gap:0.3rem;font-size:0.58rem;color:var(--p)"><span class="sd planned"></span><span data-i18n="arch_planned">Planned</span></div>
    <div style="display:flex;align-items:center;gap:0.3rem;font-size:0.58rem;color:var(--tm)"><span class="sd backlog"></span><span data-i18n="arch_backlog">Backlog</span></div>
  </div>
</div>`);

// SLIDE 5: AGENTS
slides.push(`
<div class="slide" data-slide="4">
  <div class="sh"><div class="ico">&#129302;</div><h2 data-i18n="agents_title">30 Specialized Agents</h2><p data-i18n="agents_sub">Each agent is optimized for its domain with specific capabilities.</p></div>
  <div class="carousel-wrap" id="agentCarousel"><div class="carousel-track" id="agentTrack">
    <div class="carousel-item"><div class="g5">
      <div class="c"><div class="ci">&#129504;</div><h3>Orchestrator<span class="info-trigger" data-info="ag_orch">i</span></h3><p data-i18n="ag_orch_d">Central coordinator. Routes tasks to the right agent based on context and complexity.</p></div>
      <div class="c"><div class="ci">&#128269;</div><h3>BA Explore<span class="info-trigger" data-info="ag_ba">i</span></h3><p data-i18n="ag_ba_d">Business analysis. Requirements gathering, stakeholder mapping, user stories.</p></div>
      <div class="c"><div class="ci">&#128208;</div><h3>SAD Design<span class="info-trigger" data-info="ag_sad">i</span></h3><p data-i18n="ag_sad_d">System architecture. Component diagrams, API contracts, data models.</p></div>
      <div class="c"><div class="ci">&#128187;</div><h3>DEV Implement<span class="info-trigger" data-info="ag_dev">i</span></h3><p data-i18n="ag_dev_d">Code generation. Implements features, fixes bugs, writes tests.</p></div>
      <div class="c"><div class="ci">&#9989;</div><h3>QA Verify<span class="info-trigger" data-info="ag_qa">i</span></h3><p data-i18n="ag_qa_d">Quality assurance. Test planning, validation, regression analysis.</p></div>
    </div></div>
    <div class="carousel-item"><div class="g5">
      <div class="c"><div class="ci">&#9878;&#65039;</div><h3>GOV Compliance<span class="info-trigger" data-info="ag_gov">i</span></h3><p data-i18n="ag_gov_d">Governance. Normative enforcement, audit trail, compliance checking.</p></div>
      <div class="c"><div class="ci">&#128640;</div><h3>OPS Deploy<span class="info-trigger" data-info="ag_ops">i</span></h3><p data-i18n="ag_ops_d">Operations. Deployment, CI/CD, monitoring, infrastructure management.</p></div>
      <div class="c"><div class="ci">&#128203;</div><h3>Audit Agent<span class="info-trigger" data-info="ag_audit">i</span></h3><p data-i18n="ag_audit_d">Security audit. Vulnerability scanning, dependency checking, compliance.</p></div>
      <div class="c"><div class="ci">&#128202;</div><h3>Manager<span class="info-trigger" data-info="ag_mgr">i</span></h3><p data-i18n="ag_mgr_d">Project management. Task tracking, progress reporting, resource allocation.</p></div>
      <div class="c"><div class="ci">&#128260;</div><h3>Adaptive Router<span class="info-trigger" data-info="ag_adapt">i</span></h3><p data-i18n="ag_adapt_d">Dynamic routing. Adjusts agent selection based on performance and cost.</p></div>
    </div></div>
    <div class="carousel-item"><div class="g5">
      <div class="c"><div class="ci">&#9889;</div><h3>Judgment Day<span class="info-trigger" data-info="ag_jd">i</span></h3><p data-i18n="ag_jd_d">Auto-correction. 12 rules that detect and fix quality issues.</p></div>
      <div class="c"><div class="ci">&#129302;</div><h3>ML Router<span class="info-trigger" data-info="ag_ml">i</span></h3><p data-i18n="ag_ml_d">ML-powered routing. TF-IDF similarity for skill recommendation.</p></div>
      <div class="c"><div class="ci">&#128451;&#65039;</div><h3>Compaction<span class="info-trigger" data-info="ag_compact">i</span></h3><p data-i18n="ag_compact_d">Memory lifecycle. 90-day TTL, auto-merge, integrity verification.</p></div>
      <div class="c"><div class="ci">&#128200;</div><h3>Predictive<span class="info-trigger" data-info="ag_predict">i</span></h3><p data-i18n="ag_predict_d">Trend analysis. Record metrics, detect patterns, forecast issues.</p></div>
      <div class="c"><div class="ci">&#129302;</div><h3>Collaboration<span class="info-trigger" data-info="ag_collab">i</span></h3><p data-i18n="ag_collab_d">Cross-agent messaging. Register, discover, delegate, inbox protocol.</p></div>
    </div></div>
  </div><div class="carousel-nav"><button onclick="moveCarousel('agent',-1)">&larr;</button><button onclick="moveCarousel('agent',1)">&rarr;</button></div><div class="carousel-dots" id="agentDots"></div></div>
</div>`);

// SLIDE 6: SKILLS & MCP
slides.push(`
<div class="slide" data-slide="5">
  <div class="sh"><div class="ico">&#128218;</div><h2 data-i18n="skills_title">Skills &amp; MCP Bridge</h2><p data-i18n="skills_sub">390 skills vectorized for intelligent routing across 10+ IDE tools.</p></div>
  <div class="g2">
    <div class="cc"><div class="ct" data-i18n="skills_vector_title">Skill Vectorization</div>
      <div class="bc">
        <div class="br"><div class="bl" data-i18n="sv_vocab">Vocabulary</div><div class="bt"><div class="bf" style="width:100%;background:linear-gradient(90deg,var(--p),var(--a))"></div></div><span style="font-size:0.6rem;color:var(--tm)">1028 terms</span></div>
        <div class="br"><div class="bl" data-i18n="sv_indexed">Skills Indexed</div><div class="bt"><div class="bf" style="width:100%;background:linear-gradient(90deg,var(--ok),var(--p))"></div></div><span style="font-size:0.6rem;color:var(--tm)">390 skills</span></div>
        <div class="br"><div class="bl" data-i18n="sv_ngram">N-gram Size</div><div class="bt"><div class="bf" style="width:60%;background:linear-gradient(90deg,var(--wn),var(--ok))"></div></div><span style="font-size:0.6rem;color:var(--tm)">2-3 chars</span></div>
        <div class="br"><div class="bl" data-i18n="sv_agents">Agents Supported</div><div class="bt"><div class="bf" style="width:100%;background:linear-gradient(90deg,var(--a),var(--er))"></div></div><span style="font-size:0.6rem;color:var(--tm)">30 agents</span></div>
      </div>
    </div>
    <div class="cc"><div class="ct" data-i18n="skills_mcp_title">MCP Bridge Status</div>
      <table><tr><th data-i18n="th_tool">Tool</th><th data-i18n="th_method">Method</th><th data-i18n="th_status">Status</th></tr>
        <tr><td>Cursor</td><td>MCP Config</td><td><span class="tag ok">Active</span></td></tr>
        <tr><td>Windsurf</td><td>MCP Config</td><td><span class="tag ok">Active</span></td></tr>
        <tr><td>Cline</td><td>MCP Config</td><td><span class="tag ok">Active</span></td></tr>
        <tr><td>OpenCode</td><td data-i18n="mcp_native">Native Skills</td><td><span class="tag ok">Active</span></td></tr>
        <tr><td>Claude Code</td><td>MCP Config</td><td><span class="tag ok">Active</span></td></tr>
      </table>
    </div>
  </div>
  <div class="cc" style="margin-top:0.7rem"><div class="ct" data-i18n="skills_routing_title">Intelligent Routing Flow</div>
    <div style="font-family:'JetBrains Mono',monospace;font-size:0.66rem;color:var(--tm);line-height:1.7">
      <span data-i18n="routing_flow">User Query</span> &rarr; <span style="color:var(--p)">TF-IDF Vectorizer</span> &rarr; <span style="color:var(--a)">Cosine Similarity</span> &rarr; <span style="color:var(--ok)" data-i18n="routing_topk">Top-K Skills</span> &rarr; <span style="color:var(--wn)" data-i18n="routing_agent">Agent Selection</span> &rarr; <span style="color:var(--er)" data-i18n="routing_exec">Execution</span>
    </div>
  </div>
</div>`);

// SLIDE 7: DASHBOARD
slides.push(`
<div class="slide" data-slide="6">
  <div class="sh"><div class="ico">&#128202;</div><h2 data-i18n="dash_title">LLM Observability Dashboard</h2><p data-i18n="dash_sub">React/TypeScript real-time dashboard with WebSocket + HTTP fallback. 17 components, 3 languages.</p></div>
  <div class="g3">
    <div class="c"><div class="ci">&#128202;</div><h3>Dashboard.tsx<span class="info-trigger" data-info="dashboard-main">i</span></h3><p data-i18n="dash_main">Main layout with 7 sections, language selector (EN/ES/PT-BR), info icons for every metric.</p></div>
    <div class="c"><div class="ci">&#127754;</div><h3>TracingDashboard<span class="info-trigger" data-info="tracing-dash">i</span></h3><p data-i18n="dash_trace">Waterfall view with feedback buttons, search/filter by model, latency visualization.</p></div>
    <div class="c"><div class="ci">&#128200;</div><h3>LiveChart<span class="info-trigger" data-info="live-chart">i</span></h3><p data-i18n="dash_chart">Real-time charts for tokens/sessions/cost/latency. Auto-refresh every 5 seconds.</p></div>
    <div class="c"><div class="ci">&#128172;</div><h3>InfoPopup<span class="info-trigger" data-info="info-popup">i</span></h3><p data-i18n="dash_info">Animated popup with metric descriptions. Click outside or Escape to close.</p></div>
    <div class="c"><div class="ci">&#127760;</div><h3>useLocale Hook<span class="info-trigger" data-info="use-locale">i</span></h3><p data-i18n="dash_locale">14 metrics x 3 languages. Central i18n store with useLocale() hook.</p></div>
    <div class="c"><div class="ci">&#128680;</div><h3>Alert System<span class="info-trigger" data-info="alert-system">i</span></h3><p data-i18n="dash_alert">8 alert rules: token usage, budget, latency, error rate, feedback, SLA, sessions, cost spike.</p></div>
  </div>
  <div class="cc" style="margin-top:0.7rem"><div class="ct" data-i18n="dash_arch_title">Dashboard Architecture</div>
    <div style="font-family:'JetBrains Mono',monospace;font-size:0.64rem;color:var(--tm);line-height:1.7">
      <span data-i18n="dash_arch_1">.session/context-log/*/.state.json</span><br>&nbsp;&nbsp;&darr; <span data-i18n="dash_arch_2">real-data.ts reads on each poll</span><br>
      websocket-server.ts (<span data-i18n="dash_arch_port">port 8080</span>)<br>&nbsp;&nbsp;&darr; <span data-i18n="dash_arch_3">WebSocket push every 5s</span><br>
      &nbsp;&nbsp;&darr; <span data-i18n="dash_arch_4">HTTP GET /api/metrics (resilient fallback)</span><br>&nbsp;&nbsp;&darr; <span data-i18n="dash_arch_5">HTTP GET /api/traces</span><br>
      &nbsp;&nbsp;&darr; <span data-i18n="dash_arch_6">HTTP GET /api/alerts</span><br>React state (useMetrics.ts, useAlerts.ts)
    </div>
  </div>
</div>`);

// SLIDE 8: CLOUD & TRACING
slides.push(`
<div class="slide" data-slide="7">
  <div class="sh"><div class="ico">&#9729;&#65039;</div><h2 data-i18n="cloud_title">Cloud Connectors &amp; Tracing</h2><p data-i18n="cloud_sub">Multi-cloud routing with cost optimization. Full observability with OpenTelemetry.</p></div>
  <div class="g2">
    <div class="cc"><div class="ct" data-i18n="cloud_providers">Cloud Providers (7 Supported)</div>
      <table><tr><th data-i18n="th_provider">Provider</th><th data-i18n="th_service">Service</th><th data-i18n="th_status">Status</th></tr>
        <tr><td>AWS</td><td>Lambda (Bedrock, SageMaker)</td><td><span class="tag ok">Active</span></td></tr>
        <tr><td>Azure</td><td>Functions (OpenAI, Gemini)</td><td><span class="tag ok">Active</span></td></tr>
        <tr><td>Google</td><td>Cloud Functions (Gemini)</td><td><span class="tag planned">Planned</span></td></tr>
        <tr><td>Ollama</td><td data-i18n="cloud_ollama">Local inference</td><td><span class="tag ok">Active</span></td></tr>
        <tr><td>Dify</td><td data-i18n="cloud_dify">Workflow orchestration</td><td><span class="tag ok">Active</span></td></tr>
        <tr><td>Anthropic</td><td data-i18n="cloud_anthropic">Direct API</td><td><span class="tag ok">Active</span></td></tr>
        <tr><td>OpenAI</td><td data-i18n="cloud_openai">Direct API</td><td><span class="tag ok">Active</span></td></tr>
      </table>
    </div>
    <div class="cc"><div class="ct" data-i18n="cloud_circuit">Circuit Breaker Pattern</div>
      <table><tr><th data-i18n="cb_state">State</th><th data-i18n="cb_trigger">Trigger</th><th data-i18n="cb_behavior">Behavior</th></tr>
        <tr><td>CLOSED</td><td data-i18n="cb_normal">Normal</td><td data-i18n="cb_closed">All requests pass through</td></tr>
        <tr><td>OPEN</td><td data-i18n="cb_fail">5 consecutive failures</td><td data-i18n="cb_open">All rejected, fallback to cheapest</td></tr>
        <tr><td>HALF_OPEN</td><td data-i18n="cb_cooldown">After 30s cooldown</td><td data-i18n="cb_half">1 test request allowed</td></tr>
        <tr><td>CLOSED</td><td data-i18n="cb_2ok">2 successes in HALF_OPEN</td><td data-i18n="cb_resume">Resume normal operation</td></tr>
      </table>
    </div>
  </div>
  <div class="cc" style="margin-top:0.7rem"><div class="ct" data-i18n="trace_pipeline">Distributed Tracing Pipeline</div>
    <div class="g4">
      <div class="mc"><div class="mn" style="color:var(--p);font-size:1.1rem">OTLP</div><div class="ml" data-i18n="trace_otlp">OTLP Export</div><div class="md" data-i18n="trace_otlp_d">Standard protocol for traces, metrics, and logs. Compatible with Jaeger, Datadog, Grafana.</div></div>
      <div class="mc"><div class="mn" style="color:var(--ok);font-size:1.1rem">Jaeger</div><div class="ml" data-i18n="trace_jaeger">Jaeger Backend</div><div class="md" data-i18n="trace_jaeger_d">Distributed tracing system. Visualizes request flow across services and agents.</div></div>
      <div class="mc"><div class="mn" style="color:var(--wn);font-size:1.1rem">Prometheus</div><div class="ml" data-i18n="trace_prom">Prometheus Metrics</div><div class="md" data-i18n="trace_prom_d">Time-series database for system metrics. CPU, memory, latency, error rates.</div></div>
      <div class="mc"><div class="mn" style="color:var(--a);font-size:1.1rem">Spans</div><div class="ml" data-i18n="trace_spans">Span Collection</div><div class="md" data-i18n="trace_spans_d">Each operation creates a span with timing, status, and metadata. Stored in .telemetry/.</div></div>
    </div>
  </div>
</div>`);

// SLIDE 9: STATE & EVENTS
slides.push(`
<div class="slide" data-slide="8">
  <div class="sh"><div class="ico">&#128190;</div><h2 data-i18n="state_title">State Persistence &amp; Event Sourcing</h2><p data-i18n="state_sub">Crash-resistant session state. Append-only event store with saga orchestration.</p></div>
  <div class="g3">
    <div class="c"><div class="ci">&#128190;</div><h3>Checkpoint Manager<span class="info-trigger" data-info="checkpoint">i</span></h3><p data-i18n="state_cp">Create, list, diff, verify, and prune session checkpoints. Auto-created at session start.</p><span class="tag ok"><span class="sd ok"></span>Active</span><span class="tag-note" data-i18n="status_active">Implemented &amp; running</span></div>
    <div class="c"><div class="ci">&#128248;</div><h3>Snapshot Manager<span class="info-trigger" data-info="snapshot">i</span></h3><p data-i18n="state_snap">Periodic snapshots with configurable retention. Full state capture for disaster recovery.</p><span class="tag ok"><span class="sd ok"></span>Active</span><span class="tag-note" data-i18n="status_active">Implemented &amp; running</span></div>
    <div class="c"><div class="ci">&#9194;</div><h3>Rollback Orchestrator<span class="info-trigger" data-info="rollback">i</span></h3><p data-i18n="state_roll">Health gating before rollback, dry-run validation, auto-backup before restore.</p><span class="tag ok"><span class="sd ok"></span>Active</span><span class="tag-note" data-i18n="status_active">Implemented &amp; running</span></div>
    <div class="c"><div class="ci">&#10145;&#65039;</div><h3>Event Sourcing<span class="info-trigger" data-info="event-sourcing-detail">i</span></h3><p data-i18n="state_event">Append-only event store with 5 actions: append, project, snapshot, prune, list. 10 projections.</p><span class="tag ok"><span class="sd ok"></span>Active</span><span class="tag-note" data-i18n="status_active">Implemented &amp; running</span></div>
    <div class="c"><div class="ci">&#127754;</div><h3>Saga Orchestrator<span class="info-trigger" data-info="saga">i</span></h3><p data-i18n="state_saga">Compensating actions for distributed workflows. 4 step types: action, condition, parallel, compensate.</p><span class="tag ok"><span class="sd ok"></span>Active</span><span class="tag-note" data-i18n="status_active">Implemented &amp; running</span></div>
    <div class="c"><div class="ci">&#129657;</div><h3>Engram Autoheal<span class="info-trigger" data-info="engram-autoheal">i</span></h3><p data-i18n="state_heal">Auto-recovery for DB corruption. Schema repair, backup rotation, fallback JSON creation.</p><span class="tag ok"><span class="sd ok"></span>Active</span><span class="tag-note" data-i18n="status_active">Implemented &amp; running</span></div>
  </div>
</div>`);

// SLIDE 10: GOVERNANCE
slides.push(`
<div class="slide" data-slide="9">
  <div class="sh"><div class="ico">&#9878;&#65039;</div><h2 data-i18n="gov_title">Governance &amp; Normatives</h2><p data-i18n="gov_sub">36 normative files across 7 categories. Automated enforcement with audit trail.</p></div>
  <div class="g2">
    <div class="cc"><div class="ct" data-i18n="gov_cats">Normative Categories</div>
      <table><tr><th data-i18n="gov_cat">Category</th><th data-i18n="gov_count">Count</th><th data-i18n="gov_desc">Description</th></tr>
        <tr><td>&#128274; <span data-i18n="gov_sec">Security</span></td><td>8</td><td data-i18n="gov_sec_d">Authentication, encryption, access control, secrets management</td></tr>
        <tr><td>&#127959;&#65039; <span data-i18n="gov_arch">Architecture</span></td><td>7</td><td data-i18n="gov_arch_d">Design patterns, modularity, dependency rules, API contracts</td></tr>
        <tr><td>&#128196; <span data-i18n="gov_code">Code Quality</span></td><td>6</td><td data-i18n="gov_code_d">Linting, testing, formatting, documentation standards</td></tr>
        <tr><td>&#128640; <span data-i18n="gov_devops">DevOps</span></td><td>5</td><td data-i18n="gov_devops_d">CI/CD, deployment, monitoring, rollback procedures</td></tr>
        <tr><td>&#9889; <span data-i18n="gov_perf">Performance</span></td><td>4</td><td data-i18n="gov_perf_d">Latency budgets, memory limits, token optimization</td></tr>
        <tr><td>&#127919; <span data-i18n="gov_plan">Planning</span></td><td>3</td><td data-i18n="gov_plan_d">Task estimation, complexity scoring, resource allocation</td></tr>
        <tr><td>&#9989; <span data-i18n="gov_test">Testing</span></td><td>3</td><td data-i18n="gov_test_d">Unit, integration, regression test requirements</td></tr>
      </table>
    </div>
    <div class="cc"><div class="ct" data-i18n="gov_compliance">Compliance Checklist</div>
      <table><tr><th data-i18n="gov_standard">Standard</th><th data-i18n="gov_status">Status</th><th data-i18n="gov_coverage">Coverage</th></tr>
        <tr><td>OWASP LLM Top 10 2025</td><td><span class="tag ok">Covered</span></td><td data-i18n="cov_full">100% — all 10 threats mitigated</td></tr>
        <tr><td>OWASP Agentic Top 10 2026</td><td><span class="tag ok">Covered</span></td><td data-i18n="cov_full">100% — all 10 threats mitigated</td></tr>
        <tr><td>SOC2 Type II</td><td><span class="tag ok">Covered</span></td><td data-i18n="cov_soc2">Audit logging, access controls, encryption at rest</td></tr>
        <tr><td>GDPR</td><td><span class="tag ok">Covered</span></td><td data-i18n="cov_gdpr">PII masking, data retention, right to erasure</td></tr>
        <tr><td>ISO 27001</td><td><span class="tag ok">Covered</span></td><td data-i18n="cov_iso">Information security management controls</td></tr>
        <tr><td>NIST AI RMF</td><td><span class="tag ok">Covered</span></td><td data-i18n="cov_nist">AI risk management, fairness, transparency</td></tr>
        <tr><td>Zero Secrets Policy</td><td><span class="tag ok">Enforced</span></td><td data-i18n="cov_zero">No hardcoded secrets. SHA256 audit log on every write</td></tr>
        <tr><td>AES-256 Encryption</td><td><span class="tag ok">Enforced</span></td><td data-i18n="cov_aes">Data encrypted at rest and in transit</td></tr>
      </table>
    </div>
  </div>
</div>`);

// SLIDE 11: PLANNING
slides.push(`
<div class="slide" data-slide="10">
  <div class="sh"><div class="ico">&#128197;</div><h2 data-i18n="plan_title">Planning &amp; Estimation</h2><p data-i18n="plan_sub">Standardized estimation framework for tasks, PRs, and model selection.</p></div>
  <p style="font-size:0.7rem;color:var(--tm);text-align:center;margin-bottom:0.7rem;max-width:700px;margin-left:auto;margin-right:auto" data-i18n="plan_desc">This framework helps estimate task effort, cost, and the optimal model to use. Each task is scored by complexity, which determines the PR size, review time, and the best LLM model for the job.</p>
  <div class="g3">
    <div class="cc"><div class="ct" data-i18n="plan_complex">Task Complexity Scoring</div>
      <table><tr><th data-i18n="th_level">Level</th><th data-i18n="th_files">Files</th><th data-i18n="th_time">Time</th><th data-i18n="th_tokens">Tokens</th><th data-i18n="th_cost">Cost</th></tr>
        <tr><td data-i18n="lvl_trivial">Trivial</td><td>1-2</td><td>&lt;5min</td><td>&lt;10K</td><td>&lt;$0.10</td></tr>
        <tr><td data-i18n="lvl_simple">Simple</td><td>3-5</td><td>5-15min</td><td>10-50K</td><td>$0.10-0.50</td></tr>
        <tr><td data-i18n="lvl_moderate">Moderate</td><td>6-15</td><td>15-60min</td><td>50-200K</td><td>$0.50-2.00</td></tr>
        <tr><td data-i18n="lvl_complex">Complex</td><td>16-40</td><td>1-4h</td><td>200K-1M</td><td>$2-10</td></tr>
        <tr><td data-i18n="lvl_critical">Critical</td><td>40+</td><td>4h+</td><td>1M+</td><td>$10+</td></tr>
      </table>
    </div>
    <div class="cc"><div class="ct" data-i18n="plan_pr">PR Size Classification</div>
      <table><tr><th data-i18n="th_size">Size</th><th data-i18n="th_lines">Lines</th><th data-i18n="th_review">Review</th><th data-i18n="th_merge">Merge</th></tr>
        <tr><td>XS</td><td>&lt;50</td><td>5min</td><td data-i18n="pr_instant">Instant</td></tr>
        <tr><td>S</td><td>50-200</td><td>15min</td><td>1min</td></tr>
        <tr><td>M</td><td>200-500</td><td>30min</td><td>5min</td></tr>
        <tr><td>L</td><td>500-1000</td><td>1h</td><td>15min</td></tr>
        <tr><td>XL</td><td>1000+</td><td>2h+</td><td>30min+</td></tr>
      </table>
    </div>
    <div class="cc"><div class="ct" data-i18n="plan_model">Model Selection by Task</div>
      <table><tr><th data-i18n="th_task">Task</th><th data-i18n="th_model">Model</th><th data-i18n="th_cost1m">Cost/1M</th></tr>
        <tr><td data-i18n="model_ba">Explore/BA</td><td>Claude Haiku</td><td>$0.25</td></tr>
        <tr><td data-i18n="model_sad">Design/SAD</td><td>Claude Sonnet</td><td>$3.00</td></tr>
        <tr><td data-i18n="model_dev">Implement</td><td>Claude Haiku</td><td>$0.25</td></tr>
        <tr><td data-i18n="model_qa">Verify/QA</td><td>GPT-4o-mini</td><td>$0.15</td></tr>
        <tr><td data-i18n="model_gov">Audit/GOV</td><td>Claude Sonnet</td><td>$3.00</td></tr>
      </table>
    </div>
  </div>
</div>`);

// SLIDE 12: METRICS
slides.push(`
<div class="slide" data-slide="11">
  <div class="sh"><div class="ico">&#128200;</div><h2 data-i18n="met_title">Live Metrics</h2><p data-i18n="met_sub">Real-time system health — all components operational.</p></div>
  <div class="g4" style="margin-bottom:0.7rem">
    <div class="mc"><div class="mn" style="color:var(--p)">1475</div><div class="ml" data-i18n="met_engram">Engram Observations</div><div class="md" data-i18n="met_engram_d">Total observations stored in persistent memory. Each captures a decision, bug fix, or discovery.</div></div>
    <div class="mc"><div class="mn" style="color:var(--a)">1410</div><div class="ml" data-i18n="met_cg">CodeGraph Nodes</div><div class="md" data-i18n="met_cg_d">Symbols indexed from codebase. Functions, methods, classes, and their relationships.</div></div>
    <div class="mc"><div class="mn" style="color:var(--ok)">23 MB</div><div class="ml" data-i18n="met_graph">Knowledge Graph</div><div class="md" data-i18n="met_graph_d">Graphify output size. Contains god nodes, community structure, and cross-file edges.</div></div>
    <div class="mc"><div class="mn" style="color:var(--wn)">390</div><div class="ml" data-i18n="met_skills">Skills Vectorized</div><div class="md" data-i18n="met_skills_d">Skills with TF-IDF embeddings for intelligent routing. Vocabulary of 1028 terms.</div></div>
  </div>
  <div class="cc"><div class="ct" data-i18n="met_health">Component Health (15/15 PASS)</div>
    <div class="g3">
      <div class="mc" style="padding:0.5rem"><div style="display:flex;align-items:center;gap:0.4rem"><span class="sd ok"></span><span style="font-size:0.68rem;font-weight:600">Dashboard WS</span></div><div class="md" data-i18n="met_dash_d">WebSocket server, port 8080, pushes metrics every 5s</div></div>
      <div class="mc" style="padding:0.5rem"><div style="display:flex;align-items:center;gap:0.4rem"><span class="sd ok"></span><span style="font-size:0.68rem;font-weight:600">CodeGraph</span></div><div class="md" data-i18n="met_cg_d2">SQLite index, 1410 nodes, 1763 edges, sub-ms reads</div></div>
      <div class="mc" style="padding:0.5rem"><div style="display:flex;align-items:center;gap:0.4rem"><span class="sd ok"></span><span style="font-size:0.68rem;font-weight:600">ML Embeddings</span></div><div class="md" data-i18n="met_ml_d">390 skills vectorized, TF-IDF n-gram, 1028 vocabulary</div></div>
      <div class="mc" style="padding:0.5rem"><div style="display:flex;align-items:center;gap:0.4rem"><span class="sd ok"></span><span style="font-size:0.68rem;font-weight:600">Engram</span></div><div class="md" data-i18n="met_engram_d2">1475 observations, SHA256 integrity, auto-sync active</div></div>
      <div class="mc" style="padding:0.5rem"><div style="display:flex;align-items:center;gap:0.4rem"><span class="sd ok"></span><span style="font-size:0.68rem;font-weight:600">MCP Bridge</span></div><div class="md" data-i18n="met_mcp_d">5 IDE tools connected, 390 skills registered via MCP</div></div>
      <div class="mc" style="padding:0.5rem"><div style="display:flex;align-items:center;gap:0.4rem"><span class="sd ok"></span><span style="font-size:0.68rem;font-weight:600">Session Pipeline</span></div><div class="md" data-i18n="met_session_d">46 steps, lazy execution, orphan cleanup, checkpoint auto</div></div>
      <div class="mc" style="padding:0.5rem"><div style="display:flex;align-items:center;gap:0.4rem"><span class="sd ok"></span><span style="font-size:0.68rem;font-weight:600">Hooks</span></div><div class="md" data-i18n="met_hooks_d">12 git hooks via Lefthook, pre-commit + post-commit</div></div>
      <div class="mc" style="padding:0.5rem"><div style="display:flex;align-items:center;gap:0.4rem"><span class="sd ok"></span><span style="font-size:0.68rem;font-weight:600">Governance</span></div><div class="md" data-i18n="met_gov_d">36 normatives across 7 categories, auto-enforced</div></div>
      <div class="mc" style="padding:0.5rem"><div style="display:flex;align-items:center;gap:0.4rem"><span class="sd ok"></span><span style="font-size:0.68rem;font-weight:600">Security</span></div><div class="md" data-i18n="met_sec_d">RBAC, CSP, rate limiting, zero-secrets, audit logging</div></div>
    </div>
  </div>
</div>`);

// SLIDE 13: SECURITY
slides.push(`
<div class="slide" data-slide="12">
  <div class="sh"><div class="ico">&#128274;</div><h2 data-i18n="sec_title">Security Deep Dive</h2><p data-i18n="sec_sub">Multi-layered security architecture with automated enforcement.</p></div>
  <div class="g2">
    <div class="cc"><div class="ct" data-i18n="sec_owasp">OWASP LLM Top 10 Coverage</div>
      <table><tr><th data-i18n="th_threat">Threat</th><th data-i18n="th_mitigation">Mitigation</th></tr>
        <tr><td data-i18n="owasp_l1">LLM01 — Prompt Injection</td><td data-i18n="sec_l1">Input validation, sanitization, and output filtering</td></tr>
        <tr><td data-i18n="owasp_l2">LLM02 — Data Leakage</td><td data-i18n="sec_l2">PII masking, privacy gateway, output redaction</td></tr>
        <tr><td data-i18n="owasp_l6">LLM06 — Excessive Agency</td><td data-i18n="sec_l6">RBAC (5 roles), HITL gates, action scoping</td></tr>
        <tr><td data-i18n="owasp_l9">LLM09 — Overreliance</td><td data-i18n="sec_l9">Fact-checking, audit trail, human review gates</td></tr>
        <tr><td data-i18n="owasp_l10">LLM10 — Unbounded Consumption</td><td data-i18n="sec_l10">Token budgets, rate limiting, cost caps</td></tr>
      </table>
    </div>
    <div class="cc"><div class="ct" data-i18n="sec_hitl">Human-in-the-Loop Gates</div>
      <table><tr><th data-i18n="th_gate">Gate</th><th data-i18n="th_level">Level</th><th data-i18n="th_response">Response</th><th data-i18n="th_when">When</th></tr>
        <tr><td>G0</td><td data-i18n="gate_auto">Auto</td><td>&lt;1s</td><td data-i18n="gate_auto_d">Low-risk operations, no human needed</td></tr>
        <tr><td>G1</td><td data-i18n="gate_notify">Notify</td><td>&lt;5s</td><td data-i18n="gate_notify_d">Informational, user is informed</td></tr>
        <tr><td>G2</td><td data-i18n="gate_confirm">Confirm</td><td>&lt;30s</td><td data-i18n="gate_confirm_d">Medium risk, user confirms before execution</td></tr>
        <tr><td>G3</td><td data-i18n="gate_review">Review</td><td>&lt;5min</td><td data-i18n="gate_review_d">High risk, requires explicit review</td></tr>
        <tr><td>G4</td><td data-i18n="gate_block">Block</td><td data-i18n="gate_manual">Manual</td><td data-i18n="gate_block_d">Critical risk, blocked until manual approval</td></tr>
      </table>
    </div>
  </div>
  <div class="cc" style="margin-top:0.7rem"><div class="ct" data-i18n="sec_budget">Token Budget Limits</div>
    <div class="g3">
      <div class="mc" style="padding:0.6rem"><div class="mn" style="color:var(--ok);font-size:1.2rem">$5.00</div><div class="ml" data-i18n="budget_daily">Daily Cost Limit</div><div class="md" data-i18n="budget_daily_d">Maximum spending per day across all LLM calls. Prevents runaway costs.</div></div>
      <div class="mc" style="padding:0.6rem"><div class="mn" style="color:var(--p);font-size:1.2rem">500K</div><div class="ml" data-i18n="budget_tokens">Daily Token Limit</div><div class="md" data-i18n="budget_tokens_d">Total tokens consumed per day. Covers input + output across all models.</div></div>
      <div class="mc" style="padding:0.6rem"><div class="mn" style="color:var(--wn);font-size:1.2rem">$0.80</div><div class="ml" data-i18n="budget_task">Per-Task Cost Limit</div><div class="md" data-i18n="budget_task_d">Maximum cost per individual task. Prevents single tasks from consuming too much.</div></div>
    </div>
  </div>
</div>`);

// SLIDE 14: ROADMAP
slides.push(`
<div class="slide" data-slide="13">
  <div class="sh"><div class="ico">&#128506;</div><h2 data-i18n="road_title">Roadmap — Past &amp; Future</h2><p data-i18n="road_sub">From foundation to enterprise grade — and what comes next.</p></div>
  <div class="timeline">
    <div class="tl-item done"><h4>v1.0 — Foundation<span class="tl-tag tag ok">2026</span></h4><p data-i18n="road_v1">Core orchestrator, session management, basic hooks, 10 skills.</p></div>
    <div class="tl-item done"><h4>v2.0 — Intelligence<span class="tl-tag tag ok">2026</span></h4><p data-i18n="road_v2">Engram memory, CodeGraph, ML embeddings, adaptive routing, 50+ skills.</p></div>
    <div class="tl-item done"><h4>v3.0 — Orchestration<span class="tl-tag tag ok">2026</span></h4><p data-i18n="road_v3">SDD lifecycle, multi-agent team mode, judgment day, 100+ skills.</p></div>
    <div class="tl-item done"><h4>v3.3 — Production Ready<span class="tl-tag tag ok">2026</span></h4><p data-i18n="road_v33">Dashboard, governance, 12 normatives, MCP bridge, 390 skills.</p></div>
    <div class="tl-item current"><h4>v4.0 — Enterprise Grade<span class="tl-tag tag" style="background:var(--p);color:var(--bg)">Current</span></h4><p data-i18n="road_v4">Cloud connectors, state persistence, tracing, event sourcing, audit pipeline. 36 normatives, 74/74 health.</p></div>
    <div class="tl-item current"><h4>v4.1 — Intelligence<span class="tl-tag tag" style="background:var(--ok);color:var(--bg)">Done</span></h4><p data-i18n="road_v41">Real-time alerts, auto-compaction, predictive monitoring, incremental embeddings.</p></div>
    <div class="tl-item current"><h4>v5.0 — Enterprise<span class="tl-tag tag" style="background:var(--p);color:var(--bg)">Current</span></h4><p data-i18n="road_v5">Multi-workspace sync, CI/CD pipeline, Azure/Prometheus configs, agent collaboration.</p></div>
    <div class="tl-item future"><h4>v5.1 — Optimization<span class="tl-tag tag" style="background:var(--bd);color:var(--tm)">Next</span></h4><p data-i18n="road_v51">Multi-tenant isolation, eval/benchmark framework, A/B prompt testing, CI/CD self-healing.</p></div>
    <div class="tl-item future"><h4>v6.0 — Autonomy<span class="tl-tag tag" style="background:var(--bd);color:var(--tm)">Future</span></h4><p data-i18n="road_v6">Self-evolving agents, cross-workspace collaboration, autonomous code review, predictive incident response.</p></div>
  </div>
</div>`);

// SLIDE 15: CTA
slides.push(`
<div class="slide hero-slide" data-slide="14">
  <div class="badge" data-i18n="cta_badge">Open Source — MIT License</div>
  <h1><span class="g" data-i18n="cta_title">Start Building</span></h1>
  <p class="hero-sub" data-i18n="cta_sub">Join the community. Fork the repo. Build the future of AI-assisted development.</p>
  <p class="hero-phrase" data-i18n="cta_phrase">"The future of software is not written alone — it is orchestrated. Your AI-powered edge starts here."</p>
  <div class="stats" style="margin-bottom:1.5rem">
    <div class="stat"><div class="n" style="font-size:1.3rem">&#128230;</div><div class="l" data-i18n="cta_clone">git clone</div></div>
    <div class="stat"><div class="n" style="font-size:1.3rem">&#9889;</div><div class="l" data-i18n="cta_install">pnpm install</div></div>
    <div class="stat"><div class="n" style="font-size:1.3rem">&#128640;</div><div class="l" data-i18n="cta_start">opencode</div></div>
  </div>
  <div style="position:relative;z-index:1">
    <a href="https://github.com/EmmanuelOrtiz87/gentle-vanguard" style="display:inline-block;background:linear-gradient(135deg,var(--p),var(--a));color:white;padding:0.7rem 1.8rem;border-radius:100px;font-weight:700;text-decoration:none;font-size:0.85rem;transition:all 0.3s" data-i18n="cta_github">View on GitHub &rarr;</a>
  </div>
  <footer style="border:none;padding-top:1.5rem">
    <p>Gentle-Vanguard v5.0 — <span data-i18n="cta_footer">Built with precision. Powered by AI.</span></p>
    <p style="margin-top:0.2rem" data-i18n="cta_date">Generated July 2026</p>
  </footer>
</div>`);

// Assemble HTML
const html = `<!DOCTYPE html>
<html lang="en" data-lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Gentle-Vanguard v5.0 — Enterprise AI Orchestrator</title>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700;800;900&family=JetBrains+Mono:wght@400;500;600;700&display=swap" rel="stylesheet">
<style>${CSS}</style>
</head>
<body>
<canvas id="particles"></canvas>
<div class="progress-bar" id="progressBar"></div>
<nav>
  <div class="brand">Gentle-Vanguard v5.0</div>
  <div class="nav-center"><div class="nav-arrows">
    <button id="prevBtn" onclick="goSlide(current-1)">&larr;</button>
    <span class="slide-counter" id="slideCounter">1/15</span>
    <button id="nextBtn" onclick="goSlide(current+1)">&rarr;</button>
  </div></div>
  <div class="lang-switch">
    <button class="active" onclick="setLang('en')">EN</button>
    <button onclick="setLang('es')">ES</button>
    <button onclick="setLang('pt')">PT</button>
  </div>
</nav>
<div class="info-popup-overlay" id="infoOverlay"><div class="info-popup" id="infoPopup">
  <button class="close-btn" onclick="closeInfo()">&times;</button>
  <h4 id="infoTitle"></h4><div id="infoBody"></div>
</div></div>
<div class="slide-container" id="slideContainer">
${slides.join('\n')}
</div>
`;

fs.writeFileSync('gentle-vanguard-presentation-v5.html', html, 'utf8');
console.log('HTML part written:', html.length, 'bytes');
