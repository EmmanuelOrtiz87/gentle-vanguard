/**
 * GV Content OS — superficie de creación (ADR-0021).
 * Brief en lenguaje natural → variantes multi-red con preview fiel,
 * aprobación con gate humano y calendario con horarios recomendados.
 */
import { useCallback, useEffect, useState } from 'react';
import { AlertTriangle, ChevronLeft, ChevronRight } from 'lucide-react';
import { useT } from './i18n';

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

const PALETTE = ['#00BFFF', '#A855F7', '#06B6D4', '#F59E0B', '#EF4444', '#4DCFFF'];

function platformColor(id: string): string {
  let h = 0;
  for (const c of id) h = (h * 31 + c.charCodeAt(0)) % 997;
  return PALETTE[h % PALETTE.length];
}

/** Color semántico por estado de slot (F2): proposed → azure, confirmed → verde, skipped → rojo, published → púrpura. */
function slotStatusClass(status: string): string {
  return `content-os-slot-${status}`;
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
  const { t } = useT();
  const color = platformColor(variant.platform);
  const isVertical = variant.spec.aspect === '9:16';
  const isSquare = variant.spec.aspect === '1:1';
  const imgRatio = isVertical ? 0.52 : isSquare ? 1 : variant.spec.aspect === '4:5' ? 0.8 : 1.9;
  const overLimit = variant.body.length > variant.spec.charLimit;
  return (
    <div
      style={{
        border: '1px solid var(--gv-border)',
        borderRadius: 12,
        background: 'var(--gv-glass)',
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
          borderBottom: '1px solid var(--gv-border)',
          fontSize: 12,
          color: 'var(--gv-muted)',
        }}
      >
        <strong style={{ color: platformColor(variant.platform) }}>
          {PLATFORM_LABELS[variant.platform] ?? variant.platform}
        </strong>
        <span>
          {variant.body.length}/{variant.spec.charLimit} · {variant.spec.aspect}
          {variant.score != null && ` · ${t('score')} ${variant.score}`}
          {variant.provider === 'template' && ` · ${t('template')}`}
        </span>
      </div>
      {variant.format !== 'text' && (
        <div
          style={{
            margin: 10,
            borderRadius: 8,
            aspectRatio: String(imgRatio),
            maxHeight: 220,
            background: `linear-gradient(135deg, var(--gv-bg) 0%, ${color}22 100%)`,
            border: `1px dashed ${color}55`,
            display: 'flex',
            flexDirection: 'column',
            alignItems: 'center',
            justifyContent: 'center',
            color: 'var(--gv-muted)',
            fontSize: 11,
            textAlign: 'center',
            padding: 8,
          }}
        >
          <div style={{ color, fontWeight: 600, marginBottom: 4 }}>
            {variant.spec.imageSize.width}×{variant.spec.imageSize.height}
          </div>
          {variant.image_prompt ? variant.image_prompt.slice(0, 120) : t('noMedia')}
        </div>
      )}
      <div
        style={{
          padding: '4px 12px 12px',
          whiteSpace: 'pre-wrap',
          fontSize: 13,
          color: 'var(--gv-text)',
        }}
      >
        {variant.body}
      </div>
      {overLimit && (
        <div style={{ padding: '0 12px 10px', color: 'var(--gv-error)', fontSize: 11 }}>
          <AlertTriangle size={14} aria-hidden="true" /> {t('exceedsLimit')}{' '}
          {variant.spec.charLimit} {t('characters')}
        </div>
      )}
    </div>
  );
}

export default function ContentOS() {
  const { t } = useT();
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
  const [status, setStatus] = useState(`${t('localServer')}: ${t('ready')}`);
  const [selectedItem, setSelectedItem] = useState<Item | null>(null);
  const [editingVariant, setEditingVariant] = useState<string | null>(null);
  const [editBody, setEditBody] = useState('');
  const [calView, setCalView] = useState<'month' | 'week'>('month');
  const [calAnchor, setCalAnchor] = useState(() => new Date());
  const [view, setView] = useState<'crear' | 'calendario' | 'medios'>('crear');
  const [selectedSlotId, setSelectedSlotId] = useState<string | null>(null);

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
      setSelectedItem((prev) =>
        prev ? (itemsRes.items.find((i) => i.id === prev.id) ?? null) : null,
      );
      setStatus(t('connected'));
    } catch (err) {
      setStatus(`${t('offline')} (${(err as Error).message}). ${t('startServer')}`);
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
      setStatus(t('briefRequired'));
      return;
    }
    setBusy(true);
    setStatus(t('generating'));
    try {
      const out = await api<{ itemId: string; provider: string }>('/api/generate', {
        method: 'POST',
        body: JSON.stringify({ brief, objective, title, platforms, format, schedule }),
      });
      setStatus(`${t('generatedWith')} "${out.provider}". ${t('reviewGate')}`);
      await refresh();
      const fresh = await api<{ item: Item }>(`/api/items/${out.itemId}`);
      setSelectedItem(fresh.item);
    } catch (err) {
      setStatus(`${t('errorPrefix')}: ${(err as Error).message}`);
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
      setStatus(`${t('errorPrefix')}: ${(err as Error).message}`);
    }
  }

  async function copy(variant: Variant): Promise<void> {
    try {
      await navigator.clipboard.writeText(variant.body);
      setStatus(`${t('copied')} (${PLATFORM_LABELS[variant.platform]}). ${t('readyToPaste')}`);
    } catch {
      setStatus(t('copyFailed'));
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
      setStatus(t('editedReview'));
      await refresh();
    } catch (err) {
      setStatus(`${t('errorPrefix')}: ${(err as Error).message}`);
    }
  }

  async function approveVariant(variant: Variant): Promise<void> {
    try {
      await api(`/api/variants/${variant.id}`, {
        method: 'PATCH',
        body: JSON.stringify({ status: 'approved' }),
      });
      setStatus(
        `${t('variantApproved')} ${PLATFORM_LABELS[variant.platform]} → ${t('assistedExport')}`,
      );
      await refresh();
    } catch (err) {
      setStatus(`${t('errorPrefix')}: ${(err as Error).message}`);
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
      setStatus(
        `${t('slotProposed')} ${PLATFORM_LABELS[variant.platform]}: ${new Date(out.scheduledAt).toLocaleString('es')}`,
      );
      await refresh();
    } catch (err) {
      setStatus(`${t('errorPrefix')}: ${(err as Error).message}`);
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
      setStatus(`${t('errorPrefix')}: ${(err as Error).message}`);
    }
  }

  async function slotTransition(
    slot: Slot,
    next: 'confirmed' | 'skipped' | 'published' | 'proposed',
  ): Promise<void> {
    try {
      await api(`/api/slots/${slot.id}`, {
        method: 'PATCH',
        body: JSON.stringify({ status: next }),
      });
      await refresh();
    } catch (err) {
      setStatus(`${t('errorPrefix')}: ${(err as Error).message}`);
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
    setStatus(t('uploading'));
    try {
      const dataUrl = await new Promise<string>((resolve, reject) => {
        const reader = new FileReader();
        reader.onload = () => resolve(String(reader.result));
        reader.onerror = () => reject(new Error(t('readFileFailed')));
        reader.readAsDataURL(file);
      });
      const name = file.name.replace(/\.[a-z0-9]+$/i, '');
      const out = await api<{ mediaId: string }>('/api/media', {
        method: 'POST',
        body: JSON.stringify({ dataUrl, mime: file.type, name, alt: '', source: 'upload' }),
      });
      setStatus(`${t('mediaUploaded')} "${name}" (${out.mediaId}). ${t('completeAlt')}`);
      await refresh();
    } catch (err) {
      setStatus(`${t('errorPrefix')}: ${(err as Error).message}`);
    } finally {
      setBusy(false);
    }
  }

  async function saveAlt(m: Media, alt: string): Promise<void> {
    try {
      await api(`/api/media/${m.id}`, { method: 'PATCH', body: JSON.stringify({ alt }) });
      await refresh();
    } catch (err) {
      setStatus(`${t('errorPrefix')}: ${(err as Error).message}`);
    }
  }

  async function deleteMedia(m: Media): Promise<void> {
    try {
      await api(`/api/media/${m.id}`, { method: 'DELETE' });
      await refresh();
    } catch (err) {
      setStatus(`${t('errorPrefix')}: ${(err as Error).message}`);
    }
  }

  return (
    <div className="content-os-shell" style={{ display: 'grid', gap: 16 }}>
      <div style={{ fontSize: 13, color: 'var(--gv-muted)' }}>{status}</div>

      <div
        style={{ display: 'flex', gap: 8, flexWrap: 'wrap' }}
        role="tablist"
        aria-label={t('contentSections')}
      >
        {(['crear', 'calendario', 'medios'] as const).map((v) => (
          <button
            key={v}
            role="tab"
            aria-selected={view === v}
            className={`gv-btn ${view === v ? 'gv-btn-primary' : 'gv-btn-ghost'}`}
            style={{ textTransform: 'capitalize' }}
            onClick={() => setView(v)}
          >
            {v === 'crear'
              ? t('newContent')
              : v === 'calendario'
                ? `${t('calendar')} (${slots.length})`
                : `${t('media')} (${media.length})`}
          </button>
        ))}
      </div>

      {view === 'crear' && (
        <>
          <section className="gv-panel" style={{ display: 'grid', gap: 12 }}>
            <h2 className="gv-section-title">
              {t('contentOs')} → {t('content')}
            </h2>
            <input
              className="content-os-input"
              placeholder={`${t('title')} (${t('optional')})`}
              value={title}
              onChange={(e) => setTitle(e.target.value)}
            />
            <textarea
              className="content-os-input"
              style={{ minHeight: 90 }}
              placeholder={t('briefPlaceholder')}
              value={brief}
              onChange={(e) => setBrief(e.target.value)}
            />
            <input
              className="content-os-input"
              placeholder={t('objectivePlaceholder')}
              value={objective}
              onChange={(e) => setObjective(e.target.value)}
            />
            <div style={{ display: 'flex', flexWrap: 'wrap', gap: 6 }}>
              {Object.keys(specs).map((p) => (
                <button
                  key={p}
                  onClick={() => togglePlatform(p)}
                  className="gv-btn gv-btn-ghost"
                  style={{
                    borderColor: platforms.includes(p) ? platformColor(p) : undefined,
                    color: platforms.includes(p) ? platformColor(p) : undefined,
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
                className="content-os-input"
                style={{ width: 'auto' }}
              >
                <option value="text">{t('textOnly')}</option>
                <option value="image">{t('imageOnly')}</option>
                <option value="text_image">{t('textImage')}</option>
              </select>
              <label style={{ fontSize: 13 }}>
                <input
                  type="checkbox"
                  checked={schedule}
                  onChange={(e) => setSchedule(e.target.checked)}
                />{' '}
                {t('suggestSchedule')}
              </label>
              <button
                className="gv-btn gv-btn-primary"
                disabled={busy}
                onClick={() => void generate()}
              >
                {busy ? t('generating') : t('newContent')}
              </button>
            </div>
          </section>

          {selectedItem && (
            <section style={{ display: 'grid', gap: 10 }}>
              <h2 className="gv-section-title">
                {selectedItem.title}{' '}
                <span style={{ color: 'var(--gv-muted)', fontSize: 12 }}>
                  · {selectedItem.status}
                </span>
              </h2>
              <div
                style={{
                  display: 'grid',
                  gridTemplateColumns: 'repeat(auto-fill, minmax(280px, 1fr))',
                  gap: 12,
                }}
              >
                {selectedItem.variants.map((v) => {
                  const mediaId = attachedMediaId(v);
                  const attached = mediaId ? (media.find((m) => m.id === mediaId) ?? null) : null;
                  return (
                    <div key={v.id} style={{ display: 'grid', gap: 8 }}>
                      <VariantPreview variant={v} />
                      {attached && (
                        <img
                          src={`${API}/api/media/${attached.id}/file`}
                          alt={attached.alt || attached.name}
                          style={{
                            width: '100%',
                            borderRadius: 8,
                            border: '1px solid var(--gv-border)',
                          }}
                        />
                      )}
                      {editingVariant === v.id ? (
                        <div style={{ display: 'grid', gap: 6 }}>
                          <textarea
                            className="content-os-input"
                            style={{ minHeight: 120, fontSize: 13 }}
                            value={editBody}
                            onChange={(e) => setEditBody(e.target.value)}
                          />
                          <div style={{ display: 'flex', gap: 6, alignItems: 'center' }}>
                            <span
                              style={{
                                color:
                                  editBody.length > v.spec.charLimit
                                    ? 'var(--gv-error)'
                                    : 'var(--gv-muted)',
                                fontSize: 12,
                              }}
                            >
                              {editBody.length}/{v.spec.charLimit}
                            </span>
                            <button
                              className="gv-btn gv-btn-primary"
                              style={{ marginLeft: 'auto' }}
                              onClick={() => void saveEdit(v)}
                            >
                              {t('saveEdit')}
                            </button>
                            <button
                              className="gv-btn gv-btn-ghost"
                              onClick={() => setEditingVariant(null)}
                            >
                              {t('cancel')}
                            </button>
                          </div>
                        </div>
                      ) : (
                        <div style={{ display: 'flex', gap: 6, flexWrap: 'wrap' }}>
                          <button
                            className={`gv-btn ${v.status === 'approved' ? 'gv-btn-success' : 'gv-btn-ghost'}`}
                            disabled={v.status === 'approved'}
                            onClick={() => void approveVariant(v)}
                          >
                            {v.status === 'approved' ? `✓ ${t('approved')}` : t('approve')}
                          </button>
                          <button className="gv-btn gv-btn-ghost" onClick={() => void copy(v)}>
                            {t('copy')}
                          </button>
                          <button className="gv-btn gv-btn-ghost" onClick={() => startEdit(v)}>
                            {t('edit')}
                          </button>
                          <button
                            className="gv-btn gv-btn-ghost"
                            onClick={() => void proposeSlot(v)}
                          >
                            {t('suggestSlot')}
                          </button>
                          {v.status !== 'rejected' && (
                            <button
                              className="gv-btn gv-btn-danger"
                              onClick={() => void act(v, 'reject')}
                            >
                              {t('discard')}
                            </button>
                          )}
                        </div>
                      )}
                      <div
                        style={{
                          display: 'flex',
                          gap: 6,
                          alignItems: 'center',
                          fontSize: 12,
                          color: 'var(--gv-muted)',
                        }}
                      >
                        <span>{t('media')}:</span>
                        <select
                          value={mediaId ?? ''}
                          className="content-os-input"
                          style={{ width: 'auto', fontSize: 12, padding: '4px 8px' }}
                          onChange={(e) => void attachMedia(v, e.target.value)}
                        >
                          <option value="">
                            {mediaId ? t('removeAttachment') : `— ${t('attach')} —`}
                          </option>
                          {media.map((m) => (
                            <option key={m.id} value={m.id}>
                              {m.name} {m.alt ? `(${t('altPresent')})` : `(${t('altMissing')})`}
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
        </>
      )}

      {view === 'calendario' && (
        <section className="gv-panel" style={{ display: 'grid', gap: 8 }}>
          <h2
            className="gv-section-title"
            style={{ display: 'flex', alignItems: 'center', gap: 10 }}
          >
            {t('calendar')}
            <span style={{ color: 'var(--gv-muted)', fontSize: 12 }}>
              ({slots.length} {t('slotsCount')})
            </span>
            <span style={{ marginLeft: 'auto', display: 'flex', gap: 6 }}>
              <button
                className={`gv-btn ${calView === 'month' ? 'gv-btn-primary' : 'gv-btn-ghost'}`}
                style={{ padding: '4px 10px' }}
                onClick={() => setCalView('month')}
              >
                {t('calendarMonth')}
              </button>
              <button
                className={`gv-btn ${calView === 'week' ? 'gv-btn-primary' : 'gv-btn-ghost'}`}
                style={{ padding: '4px 10px' }}
                onClick={() => setCalView('week')}
              >
                {t('calendarWeek')}
              </button>
              <button
                className="gv-btn gv-btn-ghost"
                style={{ padding: '4px 10px' }}
                onClick={() =>
                  setCalAnchor(new Date(calAnchor.getFullYear(), calAnchor.getMonth() - 1, 1))
                }
              >
                <ChevronLeft size={16} aria-hidden="true" />
              </button>
              <button
                className="gv-btn gv-btn-ghost"
                style={{ padding: '4px 10px' }}
                onClick={() => setCalAnchor(new Date())}
              >
                {t('today')}
              </button>
              <button
                className="gv-btn gv-btn-ghost"
                style={{ padding: '4px 10px' }}
                onClick={() =>
                  setCalAnchor(new Date(calAnchor.getFullYear(), calAnchor.getMonth() + 1, 1))
                }
              >
                <ChevronRight size={16} aria-hidden="true" />
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
            const WEEKDAYS = t('weekdays').split('|');
            return (
              <div
                style={{
                  display: 'grid',
                  gridTemplateColumns: 'repeat(7, 1fr)',
                  gap: 4,
                  background: 'var(--gv-glass)',
                  border: '1px solid var(--gv-border)',
                  borderRadius: 12,
                  padding: 10,
                }}
              >
                {WEEKDAYS.map((d) => (
                  <div
                    key={d}
                    style={{ fontSize: 11, color: 'var(--gv-muted)', textAlign: 'center' }}
                  >
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
                        border: `1px solid ${isToday ? 'var(--gv-primary)' : 'var(--gv-border)'}`,
                        borderRadius: 8,
                        padding: 4,
                        display: 'grid',
                        gap: 3,
                        alignContent: 'start',
                        opacity: isCurrentMonth || calView === 'week' ? 1 : 0.4,
                        background: isToday ? 'rgba(0, 191, 255, 0.05)' : 'transparent',
                      }}
                    >
                      <div style={{ fontSize: 11, color: 'var(--gv-muted)' }}>{day.getDate()}</div>
                      {daySlots.map((s) => {
                        const selected = selectedSlotId === s.id;
                        return (
                          <div
                            key={s.id}
                            role="button"
                            tabIndex={0}
                            onClick={() => setSelectedSlotId(selected ? null : s.id)}
                            onKeyDown={(e) => {
                              if (e.key === 'Enter' || e.key === ' ')
                                setSelectedSlotId(selected ? null : s.id);
                            }}
                            className={`content-os-slot ${slotStatusClass(s.status)}${selected ? ' selected' : ''}`}
                            style={{
                              fontSize: 11,
                              borderRadius: 6,
                              padding: '3px 6px',
                              display: 'grid',
                              gap: 3,
                              cursor: 'pointer',
                            }}
                            title={s.rationale}
                          >
                            <span style={{ fontWeight: 600 }}>
                              {new Date(s.scheduled_at).toLocaleTimeString('es', {
                                hour: '2-digit',
                                minute: '2-digit',
                              })}{' '}
                              {PLATFORM_LABELS[s.platform] ?? s.platform}
                            </span>
                            <span style={{ fontSize: 10 }}>{s.status}</span>
                          </div>
                        );
                      })}
                    </div>
                  );
                })}
              </div>
            );
          })()}
          {(() => {
            const slot = slots.find((s) => s.id === selectedSlotId) ?? null;
            if (!slot) return null;
            const item = items.find((i) => i.id === slot.item_id) ?? null;
            const variant = item?.variants.find((v) => v.id === slot.variant_id) ?? null;
            return (
              <div
                style={{
                  background: 'var(--gv-glass)',
                  border: '1px solid var(--gv-border)',
                  borderRadius: 12,
                  padding: 14,
                  display: 'grid',
                  gap: 8,
                }}
              >
                <div style={{ display: 'flex', gap: 10, alignItems: 'center', flexWrap: 'wrap' }}>
                  <strong style={{ color: platformColor(slot.platform), fontSize: 14 }}>
                    {PLATFORM_LABELS[slot.platform] ?? slot.platform}
                  </strong>
                  <span style={{ color: 'var(--gv-text)', fontSize: 13 }}>
                    {new Date(slot.scheduled_at).toLocaleString('es')}
                  </span>
                  <span className={`gv-status-badge gv-status-${slot.status}`}>{slot.status}</span>
                  <button
                    className="gv-btn gv-btn-ghost"
                    style={{ marginLeft: 'auto', padding: '4px 10px' }}
                    onClick={() => setSelectedSlotId(null)}
                  >
                    {t('close')}
                  </button>
                </div>
                {item && (
                  <div style={{ fontSize: 12, color: 'var(--gv-muted)' }}>
                    {t('itemLabel')}: <span style={{ color: 'var(--gv-text)' }}>{item.title}</span>
                    {variant && (
                      <>
                        {' · '}
                        {t('variantLabel')} {variant.platform} ({variant.status})
                        <div
                          style={{
                            marginTop: 6,
                            padding: 8,
                            border: '1px solid var(--gv-border)',
                            borderRadius: 8,
                            whiteSpace: 'pre-wrap',
                            color: 'var(--gv-text)',
                            maxHeight: 120,
                            overflow: 'auto',
                          }}
                        >
                          {variant.body}
                        </div>
                      </>
                    )}
                  </div>
                )}
                {slot.rationale && (
                  <div style={{ fontSize: 12, color: 'var(--gv-muted)' }}>
                    {t('rationale')}: {slot.rationale}
                  </div>
                )}
                <div style={{ display: 'flex', gap: 6, flexWrap: 'wrap' }}>
                  {slot.status === 'proposed' && (
                    <button
                      className="gv-btn gv-btn-success"
                      onClick={() => void slotTransition(slot, 'confirmed')}
                    >
                      {t('approve')} ({t('approved')})
                    </button>
                  )}
                  {slot.status === 'confirmed' && (
                    <button
                      className="gv-btn gv-btn-accent"
                      onClick={() => void slotTransition(slot, 'published')}
                    >
                      {t('publish')}
                    </button>
                  )}
                  {(slot.status === 'proposed' || slot.status === 'confirmed') && (
                    <button
                      className="gv-btn gv-btn-danger"
                      onClick={() => void slotTransition(slot, 'skipped')}
                    >
                      {t('discard')}
                    </button>
                  )}
                  {slot.status === 'skipped' && (
                    <button
                      className="gv-btn gv-btn-ghost"
                      onClick={() => void slotTransition(slot, 'proposed')}
                    >
                      {t('suggestSlot')}
                    </button>
                  )}
                  {variant && (
                    <button
                      className="gv-btn gv-btn-ghost"
                      onClick={() => void proposeSlot(variant)}
                    >
                      {t('suggestSlot')}
                    </button>
                  )}
                  <button
                    className="gv-btn gv-btn-danger"
                    onClick={() => {
                      void deleteSlot(slot);
                      setSelectedSlotId(null);
                    }}
                  >
                    {t('deleteSlot')}
                  </button>
                </div>
              </div>
            );
          })()}
        </section>
      )}

      {view === 'medios' && (
        <>
          <section className="gv-panel" style={{ display: 'grid', gap: 8 }}>
            <h2
              className="gv-section-title"
              style={{ display: 'flex', gap: 10, alignItems: 'center' }}
            >
              {t('mediaLibrary')}
              <span style={{ color: 'var(--gv-muted)', fontSize: 12 }}>({media.length})</span>
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
            {media.length === 0 && (
              <div style={{ color: 'var(--gv-muted)', fontSize: 13 }}>{t('noMedia')}</div>
            )}
            <div
              style={{
                display: 'grid',
                gridTemplateColumns: 'repeat(auto-fill, minmax(220px, 1fr))',
                gap: 12,
              }}
            >
              {media.map((m) => {
                const uses =
                  selectedItem?.variants.filter((v) => attachedMediaId(v) === m.id).length ?? 0;
                return (
                  <div
                    key={m.id}
                    style={{
                      background: 'var(--gv-glass)',
                      border: '1px solid var(--gv-border)',
                      borderRadius: 12,
                      padding: 10,
                      display: 'grid',
                      gap: 8,
                    }}
                  >
                    <img
                      src={`${API}/api/media/${m.id}/file`}
                      alt={m.alt || m.name}
                      style={{
                        width: '100%',
                        borderRadius: 8,
                        border: '1px solid var(--gv-border)',
                      }}
                    />
                    <div style={{ fontSize: 13, color: 'var(--gv-text)' }}>
                      {m.name}{' '}
                      <span style={{ color: 'var(--gv-muted)', fontSize: 11 }}>
                        · {(m.size / 1024).toFixed(0)} KB
                      </span>
                    </div>
                    <input
                      className="content-os-input"
                      style={{ fontSize: 12, padding: '4px 8px' }}
                      defaultValue={m.alt}
                      placeholder={t('accessibilityAlt')}
                      onBlur={(e) => {
                        if (e.target.value !== m.alt) void saveAlt(m, e.target.value);
                      }}
                    />
                    <div style={{ display: 'flex', gap: 6 }}>
                      <button
                        className={`gv-btn ${uses ? 'gv-btn-success' : 'gv-btn-ghost'}`}
                        style={{ padding: '4px 10px', fontSize: 12 }}
                        disabled={!selectedItem?.variants.length}
                        title={
                          uses
                            ? `${t('attach')} · ${uses} ${t('variants')}`
                            : `${t('attach')} ${t('attachToFirst')} ${t('variants')} ${t('itemLabel')} seleccionado`
                        }
                        onClick={() => {
                          const target = selectedItem?.variants.find(
                            (v) => attachedMediaId(v) !== m.id,
                          );
                          if (target) void attachMedia(target, m.id);
                        }}
                      >
                        {uses ? `✓ ${uses} ${t('variants')}` : t('attach')}
                      </button>
                      <button
                        className="gv-btn gv-btn-ghost"
                        style={{ padding: '4px 10px', fontSize: 12 }}
                        onClick={() => void deleteMedia(m)}
                      >
                        {t('delete')}
                      </button>
                    </div>
                  </div>
                );
              })}
            </div>
          </section>

          {publishLog.length > 0 && (
            <section className="gv-panel" style={{ display: 'grid', gap: 6 }}>
              <h2 className="gv-section-title">
                {t('assistedExport')} ({publishLog.length})
              </h2>
              {publishLog.map((p) => (
                <div
                  key={p.id}
                  style={{
                    display: 'flex',
                    gap: 10,
                    padding: '6px 12px',
                    background: 'var(--gv-glass)',
                    border: '1px solid var(--gv-border)',
                    borderRadius: 8,
                    fontSize: 12,
                    color: 'var(--gv-text)',
                  }}
                >
                  <span style={{ color: platformColor(p.platform), fontWeight: 600 }}>
                    {PLATFORM_LABELS[p.platform] ?? p.platform}
                  </span>
                  <span style={{ color: 'var(--gv-muted)' }}>{p.mode}</span>
                  <span>{p.action}</span>
                  <span style={{ marginLeft: 'auto', color: 'var(--gv-muted)' }}>
                    {p.variant_id} · {p.created_at}
                  </span>
                </div>
              ))}
            </section>
          )}
        </>
      )}

      {view === 'crear' && items.length > 0 && (
        <section className="gv-panel" style={{ display: 'grid', gap: 6 }}>
          <h2 className="gv-section-title">
            {t('history')} ({items.length})
          </h2>
          {items.map((i) => (
            <button
              key={i.id}
              onClick={() => setSelectedItem(i)}
              style={{
                textAlign: 'left',
                background:
                  selectedItem?.id === i.id ? 'rgba(0, 191, 255, 0.13)' : 'var(--gv-glass)',
                border: '1px solid var(--gv-border)',
                borderRadius: 8,
                padding: '8px 12px',
                color: 'var(--gv-text)',
                cursor: 'pointer',
                fontSize: 13,
              }}
            >
              <strong>{i.title}</strong>{' '}
              <span style={{ color: 'var(--gv-muted)' }}>
                · {i.status} · {i.variants.length} {t('variants')}
              </span>
            </button>
          ))}
        </section>
      )}
    </div>
  );
}
