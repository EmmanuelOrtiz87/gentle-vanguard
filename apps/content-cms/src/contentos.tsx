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
  image_path: string;
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

/** Media adjunto a una variante vía image_path = `media:<id>` (convención F2). */
function attachedMediaId(variant: Variant): string | null {
  return variant.image_path?.startsWith('media:') ? variant.image_path.slice(6) : null;
}

interface Slot {
  id: string;
  item_id: string;
  variant_id: string | null;
  platform: string;
  scheduled_at: string;
  status: string;
  rationale: string;
}

interface Media {
  id: string;
  name: string;
  path: string;
  mime: string;
  size: number;
  alt: string;
  source: string;
  created_at: string;
}

interface PublishEntry {
  id: number;
  variant_id: string;
  platform: string;
  mode: string;
  action: string;
  created_at: string;
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
  const [media, setMedia] = useState<Media[]>([]);
  const [publishLog, setPublishLog] = useState<PublishEntry[]>([]);
  const [busy, setBusy] = useState(false);
  const [status, setStatus] = useState('Servidor local: esperando verificación…');
  const [selectedItem, setSelectedItem] = useState<Item | null>(null);
  const [editingVariant, setEditingVariant] = useState<string | null>(null);
  const [editBody, setEditBody] = useState('');
  const [calView, setCalView] = useState<'month' | 'week'>('month');
  const [calAnchor, setCalAnchor] = useState(() => new Date());

  const refresh = useCallback(async () => {
    try {
      const [specRes, itemsRes, slotsRes, mediaRes, logRes] = await Promise.all([
        api<{ platforms: Record<string, PlatformSpec> }>('/api/platforms'),
        api<{ items: Item[] }>('/api/items'),
        api<{ slots: Slot[] }>('/api/slots'),
        api<{ media: Media[] }>('/api/media'),
        api<{ entries: PublishEntry[] }>('/api/publish-log'),
      ]);
      setSpecs(specRes.platforms);
      setItems(itemsRes.items);
      setSlots(slotsRes.slots);
      setMedia(mediaRes.media);
      setPublishLog(logRes.entries);
      setSelectedItem((prev) => (prev ? itemsRes.items.find((i) => i.id === prev.id) ?? null : null));
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

  function startEdit(variant: Variant): void {
    setEditingVariant(variant.id);
    setEditBody(variant.body);
  }

  async function saveEdit(variant: Variant): Promise<void> {
    try {
      await api(`/api/variants/${variant.id}`, {
        method: 'PATCH',
        body: JSON.stringify({ body: editBody }),
      });
      setEditingVariant(null);
      setStatus('Variante editada (pasa a "edited"); revisá antes de aprobar.');
      await refresh();
    } catch (err) {
      setStatus(`Error: ${(err as Error).message}`);
    }
  }

  async function approveVariant(variant: Variant): Promise<void> {
    try {
      await api(`/api/variants/${variant.id}`, {
        method: 'PATCH',
        body: JSON.stringify({ status: 'approved' }),
      });
      setStatus(
        `Variante ${PLATFORM_LABELS[variant.platform]} aprobada → export asistido registrado en publish_log (publicación sigue manual).`,
      );
      await refresh();
    } catch (err) {
      setStatus(`Error: ${(err as Error).message}`);
    }
  }

  async function proposeSlot(variant: Variant): Promise<void> {
    if (!selectedItem) return;
    try {
      const out = await api<{ scheduledAt: string }>('/api/slots/recommend', {
        method: 'POST',
        body: JSON.stringify({
          item_id: selectedItem.id,
          variant_id: variant.id,
          platform: variant.platform,
        }),
      });
      setStatus(`Slot propuesto para ${PLATFORM_LABELS[variant.platform]}: ${new Date(out.scheduledAt).toLocaleString('es')}`);
      await refresh();
    } catch (err) {
      setStatus(`Error: ${(err as Error).message}`);
    }
  }

  async function attachMedia(variant: Variant, mediaId: string): Promise<void> {
    try {
      await api(`/api/variants/${variant.id}`, {
        method: 'PATCH',
        body: JSON.stringify({ media_id: mediaId }),
      });
      await refresh();
    } catch (err) {
      setStatus(`Error: ${(err as Error).message}`);
    }
  }

  async function slotTransition(slot: Slot, next: 'confirmed' | 'rejected' | 'proposed'): Promise<void> {
    try {
      await api(`/api/slots/${slot.id}`, {
        method: 'PATCH',
        body: JSON.stringify({ status: next }),
      });
      await refresh();
    } catch (err) {
      setStatus(`Error: ${(err as Error).message}`);
    }
  }

  async function deleteSlot(slot: Slot): Promise<void> {
    try {
      await api(`/api/slots/${slot.id}`, { method: 'DELETE' });
      await refresh();
    } catch (err) {
      setStatus(`Error: ${(err as Error).message}`);
    }
  }

  async function uploadMedia(file: File): Promise<void> {
    setBusy(true);
    setStatus('Subiendo imagen…');
    try {
      const dataUrl = await new Promise<string>((resolve, reject) => {
        const reader = new FileReader();
        reader.onload = () => resolve(String(reader.result));
        reader.onerror = () => reject(new Error('no se pudo leer el archivo'));
        reader.readAsDataURL(file);
      });
      const name = file.name.replace(/\.[a-z0-9]+$/i, '');
      const out = await api<{ mediaId: string }>('/api/media', {
        method: 'POST',
        body: JSON.stringify({ dataUrl, mime: file.type, name, alt: '', source: 'upload' }),
      });
      setStatus(`Media "${name}" subido (${out.mediaId}). Completa el alt text (accesibilidad).`);
      await refresh();
    } catch (err) {
      setStatus(`Error: ${(err as Error).message}`);
    } finally {
      setBusy(false);
    }
  }

  async function saveAlt(m: Media, alt: string): Promise<void> {
    try {
      await api(`/api/media/${m.id}`, { method: 'PATCH', body: JSON.stringify({ alt }) });
      await refresh();
    } catch (err) {
      setStatus(`Error: ${(err as Error).message}`);
    }
  }

  async function deleteMedia(m: Media): Promise<void> {
    try {
      await api(`/api/media/${m.id}`, { method: 'DELETE' });
      await refresh();
    } catch (err) {
      setStatus(`Error: ${(err as Error).message}`);
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
            {selectedItem.variants.map((v) => {
              const mediaId = attachedMediaId(v);
              const attached = mediaId ? media.find((m) => m.id === mediaId) ?? null : null;
              return (
                <div key={v.id} style={{ display: 'grid', gap: 8 }}>
                  <VariantPreview variant={v} />
                  {attached && (
                    <img
                      src={`${API}/api/media/${attached.id}/file`}
                      alt={attached.alt || attached.name}
                      style={{ width: '100%', borderRadius: 8, border: `1px solid ${BORDER}` }}
                    />
                  )}
                  {editingVariant === v.id ? (
                    <div style={{ display: 'grid', gap: 6 }}>
                      <textarea
                        style={{ ...inputStyle, minHeight: 120, fontSize: 13 }}
                        value={editBody}
                        onChange={(e) => setEditBody(e.target.value)}
                      />
                      <div style={{ display: 'flex', gap: 6, alignItems: 'center' }}>
                        <span style={{ color: editBody.length > v.spec.charLimit ? '#F85149' : MUTED, fontSize: 12 }}>
                          {editBody.length}/{v.spec.charLimit}
                        </span>
                        <button style={{ ...btn(AZURE), marginLeft: 'auto' }} onClick={() => void saveEdit(v)}>
                          guardar edición
                        </button>
                        <button style={btn(BORDER)} onClick={() => setEditingVariant(null)}>
                          cancelar
                        </button>
                      </div>
                    </div>
                  ) : (
                    <div style={{ display: 'flex', gap: 6, flexWrap: 'wrap' }}>
                      <button
                        style={btn(v.status === 'approved' ? '#2EA043' : BORDER)}
                        disabled={v.status === 'approved'}
                        onClick={() => void approveVariant(v)}
                      >
                        {v.status === 'approved' ? '✓ aprobado' : 'aprobar'}
                      </button>
                      <button style={btn(BORDER)} onClick={() => void copy(v)}>
                        copiar
                      </button>
                      <button style={btn(BORDER)} onClick={() => startEdit(v)}>
                        editar
                      </button>
                      <button style={btn(BORDER)} onClick={() => void proposeSlot(v)}>
                        proponer slot
                      </button>
                      {v.status !== 'rejected' && (
                        <button style={btn(BORDER)} onClick={() => void act(v, 'reject')}>
                          descartar
                        </button>
                      )}
                    </div>
                  )}
                  <div style={{ display: 'flex', gap: 6, alignItems: 'center', fontSize: 12, color: MUTED }}>
                    <span>media:</span>
                    <select
                      value={mediaId ?? ''}
                      style={{ ...inputStyle, width: 'auto', fontSize: 12, padding: '4px 8px' }}
                      onChange={(e) => void attachMedia(v, e.target.value)}
                    >
                      <option value="">{mediaId ? 'quitar adjunto' : '— adjuntar —'}</option>
                      {media.map((m) => (
                        <option key={m.id} value={m.id}>
                          {m.name} {m.alt ? '(alt ✓)' : '(sin alt)'}
                        </option>
                      ))}
                    </select>
                  </div>
                </div>
              );
            })}
          </div>
        </section>
      )}

      <section style={{ display: 'grid', gap: 8 }}>
        <h2 style={{ margin: 0, fontSize: 15, color: TEXT, display: 'flex', alignItems: 'center', gap: 10 }}>
          Calendario
          <span style={{ color: MUTED, fontSize: 12 }}>({slots.length} slots)</span>
          <span style={{ marginLeft: 'auto', display: 'flex', gap: 6 }}>
            <button
              style={{ ...btn(calView === 'month' ? AZURE : BORDER), padding: '4px 10px' }}
              onClick={() => setCalView('month')}
            >
              mes
            </button>
            <button
              style={{ ...btn(calView === 'week' ? AZURE : BORDER), padding: '4px 10px' }}
              onClick={() => setCalView('week')}
            >
              semana
            </button>
            <button
              style={{ ...btn(BORDER), padding: '4px 10px' }}
              onClick={() => setCalAnchor(new Date(calAnchor.getFullYear(), calAnchor.getMonth() - 1, 1))}
            >
              ‹
            </button>
            <button style={{ ...btn(BORDER), padding: '4px 10px' }} onClick={() => setCalAnchor(new Date())}>
              hoy
            </button>
            <button
              style={{ ...btn(BORDER), padding: '4px 10px' }}
              onClick={() => setCalAnchor(new Date(calAnchor.getFullYear(), calAnchor.getMonth() + 1, 1))}
            >
              ›
            </button>
          </span>
        </h2>
        {(() => {
          const dayMs = 86_400_000;
          const startOfGrid =
            calView === 'month'
              ? (() => {
                  const first = new Date(calAnchor.getFullYear(), calAnchor.getMonth(), 1);
                  return new Date(first.getTime() - first.getDay() * dayMs);
                })()
              : (() => {
                  const w = new Date(calAnchor);
                  w.setHours(0, 0, 0, 0);
                  return new Date(w.getTime() - w.getDay() * dayMs);
                })();
          const days = calView === 'month' ? 42 : 7;
          const WEEKDAYS = ['dom', 'lun', 'mar', 'mié', 'jue', 'vie', 'sáb'];
          return (
            <div
              style={{
                display: 'grid',
                gridTemplateColumns: 'repeat(7, 1fr)',
                gap: 4,
                background: CARD,
                border: `1px solid ${BORDER}`,
                borderRadius: 12,
                padding: 10,
              }}
            >
              {WEEKDAYS.map((d) => (
                <div key={d} style={{ fontSize: 11, color: MUTED, textAlign: 'center' }}>
                  {d}
                </div>
              ))}
              {Array.from({ length: days }, (_, i) => {
                const day = new Date(startOfGrid.getTime() + i * dayMs);
                const dayKey = day.toISOString().slice(0, 10);
                const daySlots = slots.filter((s) => s.scheduled_at.slice(0, 10) === dayKey);
                const isCurrentMonth = day.getMonth() === calAnchor.getMonth();
                const isToday = dayKey === new Date().toISOString().slice(0, 10);
                return (
                  <div
                    key={dayKey + i}
                    style={{
                      minHeight: calView === 'month' ? 72 : 260,
                      border: `1px solid ${isToday ? AZURE + '66' : BORDER}`,
                      borderRadius: 8,
                      padding: 4,
                      display: 'grid',
                      gap: 3,
                      alignContent: 'start',
                      opacity: isCurrentMonth || calView === 'week' ? 1 : 0.4,
                      background: isToday ? AZURE + '0d' : 'transparent',
                    }}
                  >
                    <div style={{ fontSize: 11, color: MUTED }}>{day.getDate()}</div>
                    {daySlots.map((s) => {
                      const color = platformColor(s.platform);
                      return (
                        <div
                          key={s.id}
                          style={{
                            fontSize: 11,
                            borderRadius: 6,
                            padding: '3px 6px',
                            border: `1px solid ${color}55`,
                            background: color + (s.status === 'confirmed' ? '33' : '14'),
                            color: TEXT,
                            display: 'grid',
                            gap: 3,
                          }}
                          title={s.rationale}
                        >
                          <span style={{ color, fontWeight: 600 }}>
                            {new Date(s.scheduled_at).toLocaleTimeString('es', { hour: '2-digit', minute: '2-digit' })}{' '}
                            {PLATFORM_LABELS[s.platform] ?? s.platform}
                          </span>
                          <span style={{ fontSize: 10, color: s.status === 'confirmed' ? '#2EA043' : MUTED }}>
                            {s.status}
                          </span>
                          <span style={{ display: 'flex', gap: 4 }}>
                            {s.status === 'proposed' && (
                              <>
                                <button
                                  style={{ ...btn('#2EA043'), padding: '1px 6px', fontSize: 10 }}
                                  onClick={() => void slotTransition(s, 'confirmed')}
                                >
                                  ✓
                                </button>
                                <button
                                  style={{ ...btn(BORDER), padding: '1px 6px', fontSize: 10 }}
                                  onClick={() => void slotTransition(s, 'rejected')}
                                >
                                  ✕
                                </button>
                              </>
                            )}
                            {s.status !== 'rejected' && (
                              <button
                                style={{ ...btn(BORDER), padding: '1px 6px', fontSize: 10 }}
                                onClick={() => void deleteSlot(s)}
                              >
                                🗑
                              </button>
                            )}
                          </span>
                        </div>
                      );
                    })}
                  </div>
                );
              })}
            </div>
          );
        })()}
      </section>

      <section style={{ display: 'grid', gap: 8 }}>
        <h2 style={{ margin: 0, fontSize: 15, color: TEXT, display: 'flex', gap: 10, alignItems: 'center' }}>
          Biblioteca de medios
          <span style={{ color: MUTED, fontSize: 12 }}>({media.length})</span>
        </h2>
        <div>
          <input
            type="file"
            accept="image/png,image/jpeg,image/webp"
            disabled={busy}
            onChange={(e) => {
              const file = e.target.files?.[0];
              if (file) void uploadMedia(file);
              e.target.value = '';
            }}
          />
        </div>
        {media.length === 0 && <div style={{ color: MUTED, fontSize: 13 }}>Sin medios aún (png/jpeg/webp, máx 10MB).</div>}
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(220px, 1fr))', gap: 12 }}>
          {media.map((m) => {
            const uses = selectedItem?.variants.filter((v) => attachedMediaId(v) === m.id).length ?? 0;
            return (
              <div
                key={m.id}
                style={{
                  background: CARD,
                  border: `1px solid ${BORDER}`,
                  borderRadius: 12,
                  padding: 10,
                  display: 'grid',
                  gap: 8,
                }}
              >
                <img
                  src={`${API}/api/media/${m.id}/file`}
                  alt={m.alt || m.name}
                  style={{ width: '100%', borderRadius: 8, border: `1px solid ${BORDER}` }}
                />
                <div style={{ fontSize: 13, color: TEXT }}>
                  {m.name} <span style={{ color: MUTED, fontSize: 11 }}>· {(m.size / 1024).toFixed(0)} KB</span>
                </div>
                <input
                  style={{ ...inputStyle, fontSize: 12, padding: '4px 8px' }}
                  defaultValue={m.alt}
                  placeholder="alt text (accesibilidad)"
                  onBlur={(e) => {
                    if (e.target.value !== m.alt) void saveAlt(m, e.target.value);
                  }}
                />
                <div style={{ display: 'flex', gap: 6 }}>
                  <button
                    style={{ ...btn(uses ? '#2EA043' : BORDER), padding: '4px 10px', fontSize: 12 }}
                    disabled={!selectedItem?.variants.length}
                    title={uses ? `adjuntado a ${uses} variante(s)` : 'adjuntar a la primera variante del item seleccionado'}
                    onClick={() => {
                      const target = selectedItem?.variants.find((v) => attachedMediaId(v) !== m.id);
                      if (target) void attachMedia(target, m.id);
                    }}
                  >
                    {uses ? `✓ en ${uses} variante(s)` : 'adjuntar'}
                  </button>
                  <button style={{ ...btn(BORDER), padding: '4px 10px', fontSize: 12 }} onClick={() => void deleteMedia(m)}>
                    eliminar
                  </button>
                </div>
              </div>
            );
          })}
        </div>
      </section>

      {publishLog.length > 0 && (
        <section style={{ display: 'grid', gap: 6 }}>
          <h2 style={{ margin: 0, fontSize: 15, color: TEXT }}>Export asistido / publish_log ({publishLog.length})</h2>
          {publishLog.map((p) => (
            <div
              key={p.id}
              style={{
                display: 'flex',
                gap: 10,
                padding: '6px 12px',
                background: CARD,
                border: `1px solid ${BORDER}`,
                borderRadius: 8,
                fontSize: 12,
                color: TEXT,
              }}
            >
              <span style={{ color: platformColor(p.platform), fontWeight: 600 }}>
                {PLATFORM_LABELS[p.platform] ?? p.platform}
              </span>
              <span style={{ color: MUTED }}>{p.mode}</span>
              <span>{p.action}</span>
              <span style={{ marginLeft: 'auto', color: MUTED }}>
                {p.variant_id} · {p.created_at}
              </span>
            </div>
          ))}
        </section>
      )}

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
