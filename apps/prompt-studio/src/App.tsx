import { useCallback, useEffect, useMemo, useState } from 'react';
import { Sparkles, Copy, Check, Wand2, Save, Library, BookOpen, Trash2, Star, Pencil, Search } from 'lucide-react';

const API = 'http://127.0.0.1:5177';

const TASK_TYPES = [
  { id: 'review', label: 'Code review' },
  { id: 'feature', label: 'Feature build' },
  { id: 'architecture', label: 'Analysis / architecture' },
  { id: 'docs', label: 'Documentation' },
  { id: 'tests', label: 'Tests' },
  { id: 'refactor', label: 'Refactor / optimization' },
  { id: 'research', label: 'Research' },
] as const;

// Taxonomía de categorías (benchmark alpackaai.xyz — docs/reference/PROMPT-LIBRARY-BENCHMARK.md)
const CATEGORIES = [
  'Desarrollo',
  'Negocios',
  'Marketing / Redes',
  'Educación',
  'E-commerce',
  'Finanzas',
  'Empleo',
  'Imagen',
] as const;

const OUTPUT_FORMATS = [
  'Findings report with severity levels and evidence per finding',
  'Complete ready-to-apply code, comments only where needed',
  'Numbered step-by-step plan with dependencies and risks',
  'Markdown document with sections and decision table',
  'Strict JSON matching the schema described in context',
];

const EXAMPLE = {
  type: 'review',
  role: 'Senior software engineer specialized in quality and architecture',
  goal: 'Review the checkout module before releasing to production',
  context: 'TypeScript + React 18 monorepo. vitest tests. Stripe payments. Public API contracts must not break.',
  criteria: 'No high/medium vulnerabilities\nCovers error and timeout paths\nFlags technical debt',
  format: OUTPUT_FORMATS[0],
  tone: 'Direct, technical, no filler',
};

interface PromptRow {
  id: string;
  title: string;
  type: string;
  category?: string;
  role: string;
  goal: string;
  context: string;
  criteria: string;
  format: string;
  tone: string;
  body: string;
  tags: string;
  favorite: number;
  updated_at: string;
}

type Tab = 'create' | 'library' | 'guides';

async function api<T>(path: string, init?: RequestInit): Promise<T> {
  const r = await fetch(`${API}${path}`, {
    headers: { 'content-type': 'application/json' },
    ...init,
  });
  return (await r.json()) as T;
}

export default function App() {
  const [tab, setTab] = useState<Tab>('create');

  // creator state
  const [type, setType] = useState<string>('review');
  const [role, setRole] = useState('');
  const [goal, setGoal] = useState('');
  const [context, setContext] = useState('');
  const [criteria, setCriteria] = useState('');
  const [format, setFormat] = useState(OUTPUT_FORMATS[0]);
  const [tone, setTone] = useState('');
  const [copied, setCopied] = useState(false);
  const [editingId, setEditingId] = useState<string | null>(null);
  const [saveTitle, setSaveTitle] = useState('');
  const [saveTags, setSaveTags] = useState('');
  const [saveCategory, setSaveCategory] = useState<string>('');
  const [status, setStatus] = useState('');

  // library state
  const [prompts, setPrompts] = useState<PromptRow[]>([]);
  const [categories, setCategories] = useState<{ category: string; count: number }[]>([]);
  const [categoryFilter, setCategoryFilter] = useState<string>('');
  const [query, setQuery] = useState('');
  const [libStatus, setLibStatus] = useState('');

  const taskLabel = useMemo(() => TASK_TYPES.find((x) => x.id === type)?.label ?? '', [type]);

  const prompt = useMemo(() => {
    const crit = criteria.split('\n').map((s) => s.trim()).filter(Boolean);
    const L: string[] = [];
    L.push('# Role');
    L.push(`Act as ${role.trim() || '[FILL: who the assistant should be]'}. Your goal: ${goal.trim() || '[FILL: the concrete task in one sentence]'}.`);
    L.push('', '# Task');
    L.push(`${taskLabel}. Work from the provided information; if something essential is missing, ask ONE short list of questions before executing.`);
    if (context.trim()) L.push('', '# Context', context.trim());
    if (crit.length) {
      L.push('', '# Acceptance criteria', 'The answer is correct only if:');
      crit.forEach((c) => L.push(`- ${c}`));
    }
    L.push('', '# Output format', `${format}.`);
    if (tone.trim()) L.push('', '# Style', `${tone.trim()}.`);
    L.push('', '# Verification');
    L.push('Before answering, review your draft against the acceptance criteria and fix it. Show only the final version.');
    return L.join('\n');
  }, [taskLabel, role, goal, context, criteria, format, tone]);

  const refresh = useCallback(
    async (q = query, cat = categoryFilter) => {
      try {
        const params = new URLSearchParams();
        if (q) params.set('q', q);
        if (cat) params.set('category', cat);
        const d = await api<{ prompts: PromptRow[]; categories?: { category: string; count: number }[] }>(
          `/api/prompts${params.toString() ? `?${params}` : ''}`,
        );
        setPrompts(d.prompts ?? []);
        setCategories(d.categories ?? []);
        setLibStatus('');
      } catch {
        setLibStatus('Sin conexión al servidor local (:5177).');
      }
    },
    [query, categoryFilter],
  );

  useEffect(() => {
    if (tab === 'library') void refresh();
  }, [tab, refresh]);

  const loadExample = () => {
    setType(EXAMPLE.type); setRole(EXAMPLE.role); setGoal(EXAMPLE.goal);
    setContext(EXAMPLE.context); setCriteria(EXAMPLE.criteria);
    setFormat(EXAMPLE.format); setTone(EXAMPLE.tone);
  };

  const copy = async () => {
    try { await navigator.clipboard.writeText(prompt); } catch { /* noop */ }
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  };

  const save = async () => {
    const title = saveTitle.trim() || goal.trim().slice(0, 60) || 'Prompt sin título';
    const payload = { title, type, category: saveCategory, role, goal, context, criteria, format, tone, body: prompt, tags: saveTags.trim() };
    try {
      if (editingId) {
        await api(`/api/prompts/${editingId}`, { method: 'PUT', body: JSON.stringify(payload) });
        setStatus(`Actualizado: ${title}`);
      } else {
        await api('/api/prompts', { method: 'POST', body: JSON.stringify(payload) });
        setStatus(`Guardado en la biblioteca: ${title}`);
      }
      setSaveTitle(''); setSaveTags('');
      void refresh(query, categoryFilter);
    } catch {
      setStatus('Error al guardar — ¿está el servidor en :5177?');
    }
  };

  const openInEditor = (p: PromptRow) => {
    setEditingId(p.id);
    setType(p.type || 'review'); setRole(p.role ?? ''); setGoal(p.goal ?? '');
    setContext(p.context ?? ''); setCriteria(p.criteria ?? '');
    setFormat(p.format || OUTPUT_FORMATS[0]); setTone(p.tone ?? '');
    setSaveTitle(p.title); setSaveTags(p.tags ?? ''); setSaveCategory(p.category ?? '');
    setTab('create');
    setStatus(`Editando: ${p.title}`);
  };

  const newPrompt = () => {
    setEditingId(null);
    setRole(''); setGoal(''); setContext(''); setCriteria(''); setTone('');
    setSaveTitle(''); setSaveTags(''); setSaveCategory(''); setType('review'); setFormat(OUTPUT_FORMATS[0]);
    setStatus('Nuevo prompt.');
  };

  const toggleFav = async (p: PromptRow) => {
    await api(`/api/prompts/${p.id}`, { method: 'PUT', body: JSON.stringify({ favorite: !p.favorite }) });
    void refresh();
  };

  const remove = async (p: PromptRow) => {
    await api(`/api/prompts/${p.id}`, { method: 'DELETE' });
    if (editingId === p.id) setEditingId(null);
    void refresh();
  };

  const inputCls =
    'w-full rounded-lg bg-slate-900/70 border border-slate-600/50 px-3 py-2 text-sm text-slate-100 focus:outline-none focus:border-cyan-400/60 transition-colors';
  const tabBtn = (t: Tab, label: string, Icon: typeof Sparkles) => (
    <button
      key={t}
      type="button"
      onClick={() => setTab(t)}
      className={`inline-flex items-center gap-2 rounded-full px-4 py-2 text-sm font-semibold transition-colors ${
        tab === t ? 'bg-cyan-400/15 text-cyan-200 border border-cyan-400/50' : 'text-slate-400 border border-transparent hover:text-slate-200'
      }`}
    >
      <Icon className="w-4 h-4" /> {label}
    </button>
  );

  return (
    <div className="app-shell">
      <header className="topbar">
        <div className="brand">
          <span className="mark">GV</span>
          <span>
            <strong>Gentle-Vanguard</strong>
            <small className="block text-slate-400 text-xs">Prompt Studio · local-first</small>
          </span>
        </div>
        <div className="flex gap-1">
          {tabBtn('create', 'Crear', Sparkles)}
          {tabBtn('library', 'Biblioteca', Library)}
          {tabBtn('guides', 'Guías', BookOpen)}
        </div>
      </header>

      <main className="flex-1 w-full max-w-6xl mx-auto p-6">
        {tab === 'create' && (
          <div className="gv-panel p-5">
            <div className="flex items-center justify-between mb-4">
              <h2 className="text-xl font-bold text-slate-100">
                {editingId ? 'Editar prompt' : 'Crear prompt'}
              </h2>
              <div className="flex gap-2">
                <button type="button" onClick={loadExample}
                  className="inline-flex items-center gap-2 rounded-full border border-cyan-400/50 px-4 py-2 text-sm font-semibold text-cyan-200 hover:bg-cyan-400/10">
                  <Wand2 className="w-4 h-4" /> Ejemplo
                </button>
                <button type="button" onClick={newPrompt}
                  className="inline-flex items-center gap-2 rounded-full border border-slate-500/50 px-4 py-2 text-sm font-semibold text-slate-300 hover:bg-slate-500/10">
                  <Pencil className="w-4 h-4" /> Nuevo
                </button>
              </div>
            </div>

            <div className="grid gap-5 lg:grid-cols-2">
              <section className="space-y-3">
                <div>
                  <label className="block text-xs font-semibold text-slate-300 mb-1" htmlFor="ps-type">Tipo de tarea</label>
                  <select id="ps-type" className={inputCls} value={type} onChange={(e) => setType(e.target.value)}>
                    {TASK_TYPES.map((x) => <option key={x.id} value={x.id}>{x.label}</option>)}
                  </select>
                </div>
                {([
                  ['ps-role', 'Rol del asistente', role, setRole, 'Quién debe ser el asistente'],
                  ['ps-goal', 'Objetivo / tarea', goal, setGoal, 'Una frase concreta'],
                  ['ps-tone', 'Tono (opcional)', tone, setTone, 'ej. directo, técnico, sin relleno'],
                ] as const).map(([id, label, val, set, ph]) => (
                  <div key={id}>
                    <label className="block text-xs font-semibold text-slate-300 mb-1" htmlFor={id}>{label}</label>
                    <input id={id} className={inputCls} value={val} onChange={(e) => set(e.target.value)} placeholder={ph} />
                  </div>
                ))}
                <div>
                  <label className="block text-xs font-semibold text-slate-300 mb-1" htmlFor="ps-context">Contexto</label>
                  <textarea id="ps-context" className={`${inputCls} font-mono text-xs min-h-[72px]`} value={context}
                    onChange={(e) => setContext(e.target.value)} placeholder="Repo, stack, restricciones…" />
                </div>
                <div>
                  <label className="block text-xs font-semibold text-slate-300 mb-1" htmlFor="ps-criteria">Criterios de aceptación (uno por línea)</label>
                  <textarea id="ps-criteria" className={`${inputCls} font-mono text-xs min-h-[72px]`} value={criteria}
                    onChange={(e) => setCriteria(e.target.value)} />
                </div>
                <div>
                  <label className="block text-xs font-semibold text-slate-300 mb-1" htmlFor="ps-format">Formato de salida</label>
                  <select id="ps-format" className={inputCls} value={format} onChange={(e) => setFormat(e.target.value)}>
                    {OUTPUT_FORMATS.map((f) => <option key={f} value={f}>{f}</option>)}
                  </select>
                </div>
              </section>

              <section className="flex flex-col">
                <label className="block text-xs font-semibold text-slate-300 mb-1" htmlFor="ps-out">Tu prompt</label>
                <textarea id="ps-out" readOnly value={prompt}
                  className="flex-1 w-full rounded-xl bg-slate-950/80 border border-violet-400/25 px-4 py-3 font-mono text-xs leading-relaxed text-slate-100 min-h-[280px] whitespace-pre-wrap" />
                <div className="mt-3 flex flex-wrap gap-2 items-center">
                  <button type="button" onClick={copy}
                    className="inline-flex items-center gap-2 rounded-full bg-gradient-to-r from-violet-400 to-cyan-400 px-5 py-2 text-sm font-bold text-slate-950 hover:opacity-90">
                    {copied ? <Check className="w-4 h-4" /> : <Copy className="w-4 h-4" />} {copied ? 'Copiado' : 'Copiar'}
                  </button>
                  <input className={`${inputCls} flex-1 min-w-[180px]`} value={saveTitle} onChange={(e) => setSaveTitle(e.target.value)}
                    placeholder="Título para la biblioteca (opcional)" />
                  <input className={`${inputCls} w-44`} value={saveTags} onChange={(e) => setSaveTags(e.target.value)}
                    placeholder="etiquetas, separadas, por coma" />
                  <select className={`${inputCls} w-40`} value={saveCategory} onChange={(e) => setSaveCategory(e.target.value)} aria-label="Categoría">
                    <option value="">Sin categoría</option>
                    {CATEGORIES.map((c) => <option key={c} value={c}>{c}</option>)}
                  </select>
                  <button type="button" onClick={save}
                    className="inline-flex items-center gap-2 rounded-full border border-emerald-400/50 px-4 py-2 text-sm font-semibold text-emerald-200 hover:bg-emerald-400/10">
                    <Save className="w-4 h-4" /> {editingId ? 'Actualizar' : 'Guardar'}
                  </button>
                </div>
                {status && <p className="mt-2 text-xs text-cyan-300" role="status">{status}</p>}
              </section>
            </div>
          </div>
        )}

        {tab === 'library' && (
          <div className="gv-panel p-5">
            <h2 className="text-xl font-bold text-slate-100 mb-1">Biblioteca</h2>
            <p className="text-sm text-slate-400 mb-4">Buscá por lenguaje natural — «cómo revisar código», «documentar arquitectura» — o por etiquetas. Los favoritos aparecen primero.</p>
            <form
              className="flex gap-2 mb-4"
              onSubmit={(e) => {
                e.preventDefault();
                void refresh();
              }}
            >
              <div className="relative flex-1">
                <Search className="w-4 h-4 absolute left-3 top-3 text-slate-500" />
                <input className={`${inputCls} pl-9`} value={query} onChange={(e) => setQuery(e.target.value)}
                  placeholder="Buscar en lenguaje natural…" />
              </div>
              <button type="submit" className="rounded-full border border-cyan-400/50 px-4 py-2 text-sm font-semibold text-cyan-200 hover:bg-cyan-400/10">
                Buscar
              </button>
            </form>
            {categories.length > 0 && (
              <div className="flex flex-wrap gap-2 mb-4">
                <button type="button" onClick={() => { setCategoryFilter(''); void refresh(query, ''); }}
                  className={`text-[11px] px-3 py-1 rounded-full border ${!categoryFilter ? 'bg-cyan-400/15 text-cyan-200 border-cyan-400/40' : 'text-slate-400 border-slate-700 hover:border-slate-500'}`}>
                  Todas
                </button>
                {categories.map((c) => (
                  <button key={c.category} type="button"
                    onClick={() => { setCategoryFilter(c.category); void refresh(query, c.category); }}
                    className={`text-[11px] px-3 py-1 rounded-full border ${categoryFilter === c.category ? 'bg-cyan-400/15 text-cyan-200 border-cyan-400/40' : 'text-slate-400 border-slate-700 hover:border-slate-500'}`}>
                    {c.category} <span className="opacity-60">{c.count}</span>
                  </button>
                ))}
              </div>
            )}
            {libStatus && <p className="text-xs text-amber-300 mb-2">{libStatus}</p>}
            <div className="grid gap-3 md:grid-cols-2">
              {prompts.map((p) => (
                <article key={p.id} className="rounded-xl border border-slate-700/60 bg-slate-900/40 p-4">
                  <div className="flex items-start justify-between gap-2">
                    <h3 className="font-semibold text-slate-100 text-sm">{p.title}</h3>
                    <div className="flex gap-1 shrink-0">
                      <button type="button" aria-label="Favorito" onClick={() => void toggleFav(p)}
                        className={p.favorite ? 'text-amber-300' : 'text-slate-500 hover:text-amber-200'}>
                        <Star className={`w-4 h-4 ${p.favorite ? 'fill-current' : ''}`} />
                      </button>
                      <button type="button" aria-label="Editar" onClick={() => openInEditor(p)} className="text-slate-400 hover:text-cyan-300">
                        <Pencil className="w-4 h-4" />
                      </button>
                      <button type="button" aria-label="Eliminar" onClick={() => void remove(p)} className="text-slate-400 hover:text-red-400">
                        <Trash2 className="w-4 h-4" />
                      </button>
                    </div>
                  </div>
                  <p className="text-xs text-slate-400 mt-1 line-clamp-2 font-mono">{p.body.slice(0, 140)}…</p>
                  <div className="flex flex-wrap gap-1 mt-2">
                    {p.category && (
                      <span className="text-[10px] px-2 py-0.5 rounded-full bg-violet-400/10 text-violet-300 border border-violet-400/20">{p.category}</span>
                    )}
                    {p.tags.split(',').filter(Boolean).map((t) => (
                      <span key={t} className="text-[10px] px-2 py-0.5 rounded-full bg-cyan-400/10 text-cyan-300 border border-cyan-400/20">{t.trim()}</span>
                    ))}
                  </div>
                  <p className="text-[10px] text-slate-500 mt-2">Actualizado: {p.updated_at?.slice(0, 16).replace('T', ' ')}</p>
                </article>
              ))}
              {!prompts.length && !libStatus && (
                <p className="text-sm text-slate-500">Sin resultados. Creá tu primer prompt desde la pestaña «Crear».</p>
              )}
            </div>
          </div>
        )}

        {tab === 'guides' && (
          <div className="gv-panel p-6 space-y-8">
            <div>
              <h2 className="text-xl font-bold text-slate-100 mb-2">Guía: usar tus prompts con agentes de IA</h2>
              <ol className="list-decimal list-inside space-y-2 text-sm text-slate-300">
                <li><strong>Copiar y pegar</strong>: todo prompt generado funciona en cualquier chat de IA (ChatGPT, Claude, Gemini, Copilot, ZCode).</li>
                <li><strong>Delegar a un subagente</strong>: en el stack, usá <code className="text-cyan-300">npm run delegate:run -- --task "&lt;objetivo del prompt&gt;"</code> y el router elige el agente por dominio.</li>
                <li><strong>Guardar como instrucción persistente</strong>: convertí el prompt en la instrucción de sistema de tu herramienta (AGENTS.md, GEMINI.md, custom instructions).</li>
              </ol>
            </div>
            <div>
              <h2 className="text-xl font-bold text-slate-100 mb-2">Guía: crear Gemas en Gemini (asistentes potenciados)</h2>
              <p className="text-sm text-slate-400 mb-3">
                Una Gema es un asistente reutilizable de Gemini con instrucciones y conocimiento propios. Tu prompt del Studio es exactamente lo que una Gema necesita.
              </p>
              <ol className="list-decimal list-inside space-y-2 text-sm text-slate-300">
                <li>Entrá a Gemini → <strong>Gemas</strong> → <strong>Nueva Gema</strong> (o Gem manager).</li>
                <li><strong>Nombre</strong>: el objetivo en 3-5 palabras (ej. «Revisor de código senior»).</li>
                <li><strong>Instrucciones</strong>: pegá el prompt completo generado acá — la estructura Rol / Tarea / Contexto / Criterios / Formato / Verificación es ideal porque deja claro qué hacer y cómo autoevaluarse.</li>
                <li><strong>Conocimiento</strong> (opcional pero potente): subí archivos de contexto — specs, convenciones del repo, ejemplos de buen resultado. La Gema los usa como referencia permanente.</li>
                <li><strong>Probar y refinar</strong>: dale una tarea real; si falla un criterio, ajustá esa sección del prompt (editándolo acá en el Studio) y actualizá las instrucciones de la Gema.</li>
                <li><strong>Reutilizar</strong>: cada Gema queda disponible como chat propio — es tu «agente» para esa tarea, sin re-escribir el prompt nunca más.</li>
              </ol>
            </div>
            <div>
              <h2 className="text-xl font-bold text-slate-100 mb-2">Patrones que multiplican resultados</h2>
              <ul className="list-disc list-inside space-y-2 text-sm text-slate-300">
                <li><strong>Criterios medibles</strong>: «sin vulnerabilidades alta/media» mejor que «que sea seguro».</li>
                <li><strong>Formato estricto</strong> cuando la salida alimenta otra herramienta (JSON con schema).</li>
                <li><strong>Verificación obligatoria</strong>: pedir auto-revisión contra criterios reduce drásticamente respuestas mediocres.</li>
                <li><strong>Contexto mínimo suficiente</strong>: más contexto no es mejor; el contexto <em>correcto</em> sí.</li>
              </ul>
            </div>
          </div>
        )}
      </main>

      <footer>
        <span>100% local — biblioteca en .runtime/prompt-studio</span>
        <span>Gentle-Vanguard / Prompt Studio</span>
      </footer>
    </div>
  );
}
