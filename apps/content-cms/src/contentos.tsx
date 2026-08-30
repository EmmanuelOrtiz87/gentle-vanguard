/**
 * GV Content OS — superficie de creación (ADR-0021).
 * Brief en lenguaje natural → variantes multi-red con preview fiel,
 * aprobación con gate humano y calendario con horarios recomendados.
 */
import { useCallback, useEffect, useState } from 'react';

const API = 'http://127.0.0.1:3787';

export interface PlatformSpec {
  id: string;
  name: string;
  charLimit: number;
  hashtagOptimal: number;
  aspect: string;
  imageSize: { width: number; height: number };
  tone: string;
  hookStyle: string;
  bestTimes: string[];
  notes: string;
}

interface Variant {
  id: string;
  platform: string;
  format: string;
  body: string;
  image_prompt: string;
  status: string;
  score: number | null;
  provider: string;
  spec: PlatformSpec;
}

interface Item {
  id: string;
  title: string;
  brief: string;
  objective: string;
  status: string;
  variants: Variant[];
}

interface Slot {
  id: string;
  item_id: string;
  platform: string;
  scheduled_at: string;
  status: string;
  rationale: string;
}

const DARK = '#0D1117';
const AZURE = '#00BFFF';
const CARD = '#161B27';
const BORDER = '#2A3040';
const TEXT = '#E6EDF3';
const MUTED = '#8B949E';

const PLATFORM_LABELS: Record<string, string> = {
  linkedin: 'LinkedIn',
  x: 'X',
  instagram: 'Instagram',
  facebook: 'Facebook',
  telegram: 'Telegram',
  discord: 'Discord',
  reddit: 'Reddit',
  threads: 'Threads',
  whatsapp: 'WhatsApp',
  tiktok: 'TikTok',
};

const PALETTE = ['#00BFFF', '#A855F7', '#2EA043', '#F0883E', '#BF4B8A', '#58A6FF'];

function platformColor(id: string): string {
  let h = 0;
  for (const c of id) h = (h * 31 + c.charCodeAt(0)) % 997;
  return PALETTE[h % PALETTE.length];
}

async function api<T>(path: string, init?: RequestInit): Promise<T> {
  const res = await fetch(`${API}${path}`, {
    ...init,
    headers: { 'content-type': 'application/json' },
  });
  if (!res.ok) throw new Error((await res.json().catch(() => ({}))).error ?? `HTTP ${res.status}`);
  return res.json() as Promise<T>;
}

/** Preview fiel por red: reproduce proporciones y gramática visual de cada plataforma. */
function VariantPreview({ variant }: { variant: Variant }) {
  const color = platformColor(variant.platform);
  const isVertical = variant.spec.aspect === '9:16';
  const isSquare = variant.spec.aspect === '1:1';
  const imgRatio = isVertical ? 0.52 : isSquare ? 1 : variant.spec.aspect === '4:5' ? 0.8 : 1.9;
  const overLimit = variant.body.length > variant.spec.charLimit;
  return (
    <div
      style={{
        border: `1px solid ${BORDER}`,
        borderRadius: 12,
        background: CARD,
        overflow: 'hidden',
        display: 'flex',
        flexDirection: 'column',
        minWidth: 280,
      }}
    >
      <div
        style={{
          display: 'flex',
          justifyContent: 'space-between',
          alignItems: 'center',
          padding: '8px 12px',
          borderBottom: `1px solid ${BORDER}`,
          fontSize: 12,
          color: MUTED,
        }}
      >
        <strong style={{ color: platformColor(variant.platform) }}>
          {PLATFORM_LABELS[variant.platform] ?? variant.platform}
        </strong>
        <span>
          {variant.body.length}/{variant.spec.charLimit} · {variant.spec.aspect}
          {variant.score != null && ` · score ${variant.score}`}
          {variant.provider === 'template' && ' · plantilla'}
        </span>
      </div>
      {variant.format !== 'text' && (
        <div
          style={{
            margin: 10,
            borderRadius: 8,
            aspectRatio: String(imgRatio),
            maxHeight: 220,
            background: `linear-gradient(135deg, ${DARK} 0%, ${color}22 100%)`,
            border: `1px dashed ${color}55`,
            display: 'flex',
            flexDirection: 'column',
            alignItems: 'center',
            justifyContent: 'center',
            color: MUTED,
            fontSize: 11,
            textAlign: 'center',
            padding: 8,
          }}
        >
          <div style={{ color, fontWeight: 600, marginBottom: 4 }}>
            {variant.spec.imageSize.width}×{variant.spec.imageSize.height}
          </div>
          {variant.image_prompt ? variant.image_prompt.slice(0, 120) : 'sin prompt de imagen'}
        </div>
      )}
      <div style={{ padding: '4px 12px 12px', whiteSpace: 'pre-wrap', fontSize: 13, color: TEXT }}>
        {variant.body}
      </div>
      {overLimit && (
        <div style={{ padding: '0 12px 10px', color: '#F85149', fontSize: 11 }}>
          ⚠ excede el límite de {variant.spec.charLimit} caracteres
        </div>
      )}
    </div>
  );
}

export default function ContentOS() {
  const [brief, setBrief] = useState('');
  const [objective, setObjective] = useState('');
  const [title, setTitle] = useState('');
  const [format, setFormat] = useState<'text' | 'image' | 'text_image'>('text_image');
  const [platforms, setPlatforms] = useState<string[]>(['linkedin', 'x', 'instagram']);
  const [schedule, setSchedule] = useState(true);
  const [specs, setSpecs] = useState<Record<string, PlatformSpec>>({});
  const [items, setItems] = useState<Item[]>([]);
  const [slots, setSlots] = useState<Slot[]>([]);
  const [busy, setBusy] = useState(false);
  const [status, setStatus] = useState('Servidor local: esperando verificación…');
  const [selectedItem, setSelectedItem] = useState<Item | null>(null);

  const refresh = useCallback(async () => {
    try {
      const [{ platforms: specMap }, { items: list }, { slots: slotList }] = await Promise.all([
        api<{ platforms: Record<string, PlatformSpec> }>('/api/platforms'),
        api<{ items: Item[] }>('/api/items'),
        api<{ slots: Slot[] }>('/api/slots'),
      ]);
      setSpecs(specMap);
      setItems(list);
      setSlots(slotList);
      setSelectedItem((prev) => (prev ? list.find((i) => i.id === prev.id) ?? null : null));
      setStatus('Conectado al Content OS (Nexus).');
    } catch (err) {
      setStatus(`Sin conexión al servidor (${(err as Error).message}). Arrancá: node --import tsx apps/content-cms/server/server.ts`);
    }
  }, []);

  useEffect(() => {
    void refresh();
  }, [refresh]);

  function togglePlatform(id: string): void {
    setPlatforms((prev) => (prev.includes(id) ? prev.filter((p) => p !== id) : [...prev, id]));
  }

  async function generate(): Promise<void> {
    if (!brief.trim() || !platforms.length) {
      setStatus('Escribí un brief y elegí al menos una red.');
      return;
    }
    setBusy(true);
    setStatus('Generando variantes…');
    try {
      const out = await api<{ itemId: string; provider: string }>('/api/generate', {
        method: 'POST',
        body: JSON.stringify({ brief, objective, title, platforms, format, schedule }),
      });
      setStatus(`Generado con provider "${out.provider}". Revisá y aprobá cada variante (gate humano).`);
      await refresh();
      const fresh = await api<{ item: Item }>(`/api/items/${out.itemId}`);
      setSelectedItem(fresh.item);
    } catch (err) {
      setStatus(`Error: ${(err as Error).message}`);
    } finally {
      setBusy(false);
    }
  }

  async function act(variant: Variant, action: 'approve' | 'reject'): Promise<void> {
    try {
      await api(`/api/variants/${variant.id}`, {
        method: 'PATCH',
        body: JSON.stringify({ status: action === 'approve' ? 'approved' : 'rejected' }),
      });
      await refresh();
    } catch (err) {
      setStatus(`Error: ${(err as Error).message}`);
    }
  }

  async function copy(variant: Variant): Promise<void> {
    try {
      await navigator.clipboard.writeText(variant.body);
      setStatus(`Copiado al portapapeles (${PLATFORM_LABELS[variant.platform]}). Listo para pegar en la red.`);
    } catch {
      setStatus('No se pudo copiar al portapapeles.');
    }
  }

  const inputStyle: React.CSSProperties = {
    width: '100%',
    boxSizing: 'border-box',
    background: DARK,
    border: `1px solid ${BORDER}`,
    borderRadius: 8,
    color: TEXT,
    padding: '8px 10px',
    fontSize: 14,
    fontFamily: 'inherit',
  };
  const btn = (bg: string): React.CSSProperties => ({
    background: bg,
    color: bg === AZURE ? DARK : TEXT,
    border: 'none',
    borderRadius: 8,
    padding: '8px 14px',
    fontSize: 13,
    fontWeight: 600,
    cursor: 'pointer',
  });

  return (
    <div style={{ display: 'grid', gap: 16 }}>
      <div style={{ fontSize: 13, color: MUTED }}>{status}</div>

      <section style={{ background: CARD, border: `1px solid ${BORDER}`, borderRadius: 12, padding: 16, display: 'grid', gap: 12 }}>
        <h2 style={{ margin: 0, fontSize: 16, color: TEXT }}>Brief → contenido multi-red</h2>
        <input
          style={inputStyle}
          placeholder="Título (opcional)"
          value={title}
          onChange={(e) => setTitle(e.target.value)}
        />
        <textarea
          style={{ ...inputStyle, minHeight: 90 }}
          placeholder="Contale la necesidad en lenguaje natural: qué publicar, para quién, con qué objetivo…"
          value={brief}
          onChange={(e) => setBrief(e.target.value)}
        />
        <input
          style={inputStyle}
          placeholder="Objetivo de negocio (ej: captar estudiantes, vender servicios)"
          value={objective}
          onChange={(e) => setObjective(e.target.value)}
        />
        <div style={{ display: 'flex', flexWrap: 'wrap', gap: 6 }}>
          {Object.keys(specs).map((p) => (
            <button
              key={p}
              onClick={() => togglePlatform(p)}
              style={{
                ...btn('transparent'),
                border: `1px solid ${platforms.includes(p) ? platformColor(p) : BORDER}`,
                color: platforms.includes(p) ? platformColor(p) : MUTED,
                padding: '4px 10px',
              }}
            >
              {PLATFORM_LABELS[p] ?? p}
            </button>
          ))}
        </div>
        <div style={{ display: 'flex', gap: 10, alignItems: 'center', flexWrap: 'wrap' }}>
          <select
            value={format}
            onChange={(e) => setFormat(e.target.value as typeof format)}
            style={{ ...inputStyle, width: 'auto' }}
          >
            <option value="text">Solo texto</option>
            <option value="image">Solo imagen</option>
            <option value="text_image">Texto + imagen</option>
          </select>
          <label style={{ color: MUTED, fontSize: 13 }}>
            <input type="checkbox" checked={schedule} onChange={(e) => setSchedule(e.target.checked)} />{' '}
            proponer horarios en calendario
          </label>
          <button style={btn(AZURE)} disabled={busy} onClick={() => void generate()}>
            {busy ? 'Generando…' : 'Generar'}
          </button>
        </div>
      </section>

      {selectedItem && (
        <section style={{ display: 'grid', gap: 10 }}>
          <h2 style={{ margin: 0, fontSize: 15, color: TEXT }}>
            {selectedItem.title}{' '}
            <span style={{ color: MUTED, fontSize: 12 }}>· {selectedItem.status}</span>
          </h2>
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(280px, 1fr))', gap: 12 }}>
            {selectedItem.variants.map((v) => (
              <div key={v.id} style={{ display: 'grid', gap: 8 }}>
                <VariantPreview variant={v} />
                <div style={{ display: 'flex', gap: 6 }}>
                  <button
                    style={btn(v.status === 'approved' ? '#2EA043' : BORDER)}
                    disabled={v.status === 'approved'}
                    onClick={() => void act(v, 'approve')}
                  >
                    {v.status === 'approved' ? '✓ aprobado' : 'aprobar'}
                  </button>
                  <button style={btn(BORDER)} onClick={() => void copy(v)}>
                    copiar
                  </button>
                  {v.status !== 'rejected' && (
                    <button style={btn(BORDER)} onClick={() => void act(v, 'reject')}>
                      descartar
                    </button>
                  )}
                </div>
              </div>
            ))}
          </div>
        </section>
      )}

      <section style={{ display: 'grid', gap: 8 }}>
        <h2 style={{ margin: 0, fontSize: 15, color: TEXT }}>
          Calendario propuesto{' '}
          <span style={{ color: MUTED, fontSize: 12 }}>({slots.length} slots)</span>
        </h2>
        {slots.length === 0 && <div style={{ color: MUTED, fontSize: 13 }}>Sin slots aún.</div>}
        {slots.map((s) => (
          <div
            key={s.id}
            style={{
              display: 'flex',
              gap: 10,
              alignItems: 'baseline',
              padding: '8px 12px',
              background: CARD,
              border: `1px solid ${BORDER}`,
              borderRadius: 8,
              fontSize: 13,
              color: TEXT,
            }}
          >
            <span style={{ color: platformColor(s.platform), fontWeight: 600 }}>
              {PLATFORM_LABELS[s.platform] ?? s.platform}
            </span>
            <span>{new Date(s.scheduled_at).toLocaleString('es')}</span>
            <span style={{ color: MUTED, fontSize: 12 }}>{s.rationale.split('.')[0]}</span>
            <span style={{ marginLeft: 'auto', color: s.status === 'confirmed' ? '#2EA043' : MUTED }}>
              {s.status}
            </span>
          </div>
        ))}
      </section>

      {items.length > 0 && (
        <section style={{ display: 'grid', gap: 6 }}>
          <h2 style={{ margin: 0, fontSize: 15, color: TEXT }}>Historial ({items.length})</h2>
          {items.map((i) => (
            <button
              key={i.id}
              onClick={() => setSelectedItem(i)}
              style={{
                textAlign: 'left',
                background: selectedItem?.id === i.id ? AZURE + '22' : CARD,
                border: `1px solid ${BORDER}`,
                borderRadius: 8,
                padding: '8px 12px',
                color: TEXT,
                cursor: 'pointer',
                fontSize: 13,
              }}
            >
              <strong>{i.title}</strong>{' '}
              <span style={{ color: MUTED }}>
                · {i.status} · {i.variants.length} variantes
              </span>
            </button>
          ))}
        </section>
      )}
    </div>
  );
}
