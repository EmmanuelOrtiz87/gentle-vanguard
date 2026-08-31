import { useEffect, useMemo, useRef, useState, type ChangeEvent } from 'react';
import {
  createId,
  addVersion,
  createExport,
  emptyContent,
  isSafeUrl,
  rollback,
  validateAssetMetadata,
  validateImport,
  validateContent,
  type ContentDraft,
  type ContentItem,
} from './domain';
import { contentStore } from './storage';
import ContentOS from './contentos';
import { Calendar, Download, Eye, FileText, Image, Pencil, Plus, Save, Upload } from 'lucide-react';
import { useT } from './i18n';

type Tab = 'content-os' | 'studio';

function downloadJson(items: ContentItem[]): void {
  const blob = new Blob([JSON.stringify(createExport(items), null, 2)], {
    type: 'application/json',
  });
  const url = URL.createObjectURL(blob);
  const anchor = document.createElement('a');
  anchor.href = url;
  anchor.download = 'gentle-vanguard-content.json';
  anchor.click();
  URL.revokeObjectURL(url);
}

export default function App() {
  const { locale, setLocale, t } = useT();
  const [theme, setTheme] = useState<'dark' | 'light'>(() =>
    localStorage.getItem('gv-cms-theme') === 'light' ? 'light' : 'dark',
  );
  const [tab, setTab] = useState<Tab>('content-os');
  const [state, setState] = useState(() => contentStore.load());
  const [selectedId, setSelectedId] = useState<string | null>(null);
  const [form, setForm] = useState<ContentDraft>(emptyContent());
  const [preview, setPreview] = useState(false);
  const [filter, setFilter] = useState<'all' | 'draft' | 'published'>('all');
  const [message, setMessage] = useState(() => t('ready'));
  const importRef = useRef<HTMLInputElement>(null);
  const visibleItems = useMemo(
    () => (filter === 'all' ? state.items : state.items.filter((item) => item.status === filter)),
    [filter, state.items],
  );

  useEffect(() => {
    document.documentElement.dataset.theme = theme;
    localStorage.setItem('gv-cms-theme', theme);
  }, [theme]);

  function select(item: ContentItem): void {
    setSelectedId(item.id);
    setForm({
      title: item.title,
      slug: item.slug,
      excerpt: item.excerpt,
      body: item.body,
      coverUrl: item.coverUrl,
      tags: item.tags,
      status: item.status,
    });
    setPreview(false);
  }

  function startNew(): void {
    setSelectedId(null);
    setForm(emptyContent());
    setPreview(false);
    setMessage('Nuevo borrador.');
  }

  function save(): void {
    const candidate: ContentItem = {
      ...form,
      id: selectedId ?? createId(),
      updatedAt: new Date().toISOString(),
    };
    const result = validateContent(candidate);
    if (!result.valid) {
      setMessage(result.errors.join(' '));
      return;
    }
    const next = addVersion(
      state,
      candidate,
      candidate.status === 'published' ? 'publish' : 'save',
    );
    setState(next);
    contentStore.save(next);
    setSelectedId(candidate.id);
    setMessage(
      candidate.status === 'published'
        ? 'Contenido publicado localmente.'
        : 'Borrador guardado localmente.',
    );
  }

  function update<K extends keyof ContentDraft>(key: K, value: ContentDraft[K]): void {
    setForm((current) => ({ ...current, [key]: value }));
  }

  async function importJson(event: ChangeEvent<HTMLInputElement>): Promise<void> {
    const file = event.target.files?.[0];
    if (!file) return;
    try {
      const result = validateImport(JSON.parse(await file.text()));
      if (!result.valid || !result.items.length) {
        setMessage(
          result.errors.join(' ') || 'No se encontraron contenidos válidos en el archivo.',
        );
        return;
      }
      let next = state;
      result.items.forEach((item) => {
        next = addVersion(next, item, 'import');
      });
      setState(next);
      contentStore.save(next);
      setMessage(`${result.items.length} contenido(s) importado(s).`);
    } catch {
      setMessage('No se pudo leer el JSON.');
    }
    event.target.value = '';
  }

  async function addAsset(event: ChangeEvent<HTMLInputElement>): Promise<void> {
    const file = event.target.files?.[0];
    if (!file || !selectedId) return;
    const localUrl = await new Promise<string>((resolve, reject) => {
      const reader = new FileReader();
      reader.onload = () => resolve(String(reader.result));
      reader.onerror = () => reject(new Error('read'));
      reader.readAsDataURL(file);
    });
    const asset = {
      id: createId('asset'),
      name: file.name,
      mime: file.type,
      size: file.size,
      alt: file.name.replace(/\.[^.]+$/, ''),
      localUrl,
      createdAt: new Date().toISOString(),
    };
    const result = validateAssetMetadata(asset);
    if (!result.valid || !result.data) {
      setMessage(result.errors.join(' '));
      return;
    }
    update('assets', [...(form.assets ?? []), result.data]);
    setMessage('Asset local añadido. Añade un texto alternativo descriptivo y guarda.');
    event.target.value = '';
  }

  function restoreVersion(versionId: string): void {
    if (!selectedId) return;
    const next = rollback(state, selectedId, versionId);
    if (!next) {
      setMessage('No se encontró esa versión.');
      return;
    }
    setState(next);
    contentStore.save(next);
    select(next.items.find((item) => item.id === selectedId) ?? (form as ContentItem));
    setMessage('Versión restaurada como nueva versión inmutable.');
  }

  return (
    <div className="app-shell">
      <div className="gv-grid-bg" />
      <div className="gv-glow-a" />
      <div className="gv-glow-b" />
      <header className="gv-topbar">
        <div className="gv-topbar-inner">
          <div className="gv-brand">
            <span className="mark" aria-hidden="true">
              GV
            </span>
            <span className="name">
              Gentle<span>Vanguard</span> <small>{t('contentStudio')}</small>
            </span>
          </div>
          <nav className="gv-main-nav gv-view-tabs" aria-label="Secciones del CMS">
            <button
              className={tab === 'content-os' ? 'active' : ''}
              onClick={() => setTab('content-os')}
            >
              <FileText size={16} aria-hidden="true" /> {t('contentOs')}
            </button>
            <button className={tab === 'studio' ? 'active' : ''} onClick={() => setTab('studio')}>
              <Pencil size={16} aria-hidden="true" /> {t('legacy')}
            </button>
          </nav>
          <div className="gv-system-state ready">
            {state.items.length} {t('items')}
          </div>
          <div className="locale-controls">
            <select
              aria-label={t('language')}
              value={locale}
              onChange={(event) => setLocale(event.target.value as 'es' | 'en')}
            >
              <option value="es">{t('es')}</option>
              <option value="en">{t('en')}</option>
            </select>
            <button
              className="gv-btn gv-btn-ghost"
              aria-label={t('theme')}
              onClick={() => setTheme((current) => (current === 'dark' ? 'light' : 'dark'))}
            >
              {theme === 'dark' ? '☀' : '🌙'}
            </button>
          </div>
          <div className="top-actions">
            {tab === 'studio' && (
              <>
                <button className="gv-btn gv-btn-ghost" onClick={() => importRef.current?.click()}>
                  <Upload size={16} aria-hidden="true" /> {t('importJson')}
                </button>
                <input
                  ref={importRef}
                  className="visually-hidden"
                  type="file"
                  accept="application/json"
                  onChange={importJson}
                />
                <button className="gv-btn gv-btn-ghost" onClick={() => downloadJson(state.items)}>
                  <Download size={16} aria-hidden="true" /> {t('exportJson')}
                </button>
                <button className="gv-btn gv-btn-primary" onClick={startNew}>
                  <Plus size={16} aria-hidden="true" /> {t('newContent')}
                </button>
              </>
            )}
          </div>
        </div>
      </header>
      {tab === 'content-os' ? (
        <div className="gv-view-fade">
          <ContentOS />
        </div>
      ) : (
        <main className="layout gv-view-fade">
          <aside className="sidebar">
            <div className="side-heading">
              <div>
                <span className="eyebrow">{t('library')}</span>
                <h1 className="gv-section-title">{t('content')}</h1>
              </div>
              <span className="count">{state.items.length}</span>
            </div>
            <div className="filters" role="group" aria-label="Filtrar por estado">
              {(['all', 'draft', 'published'] as const).map((value) => (
                <button
                  key={value}
                  className={filter === value ? 'filter active' : 'filter'}
                  onClick={() => setFilter(value)}
                >
                  {value === 'all' ? t('all') : value === 'draft' ? t('drafts') : t('published')}{' '}
                  <span>
                    {value === 'all'
                      ? state.items.length
                      : state.items.filter((item) => item.status === value).length}
                  </span>
                </button>
              ))}
            </div>
            <div className="item-list">
              {visibleItems.map((item) => (
                <button
                  className={item.id === selectedId ? 'item selected' : 'item'}
                  key={item.id}
                  onClick={() => select(item)}
                >
                  <span className={`status-dot ${item.status}`} />
                  <span className="item-copy">
                    <strong>{item.title || 'Sin título'}</strong>
                    <small>/{item.slug || 'sin-slug'}</small>
                  </span>
                  <span className="item-date">
                    {new Date(item.updatedAt).toLocaleDateString('es-ES', {
                      day: '2-digit',
                      month: 'short',
                    })}
                  </span>
                </button>
              ))}
              {!visibleItems.length && <p className="empty">{t('noContent')}</p>}
            </div>
          </aside>
          <section className="workspace">
            <div className="workspace-header">
              <div>
                <span className="eyebrow">{selectedId ? t('editEntry') : t('newEntry')}</span>
                <h2 className="gv-section-title">
                  {preview ? t('preview') : form.title || t('content')}
                </h2>
                <p className="gv-section-sub">{t('contentStudio')}</p>
              </div>
              <div className="view-toggle" role="group" aria-label="Modo de edición">
                <button
                  className={!preview ? 'toggle active' : 'toggle'}
                  onClick={() => setPreview(false)}
                >
                  <Pencil size={16} aria-hidden="true" /> {t('editor')}
                </button>
                <button
                  className={preview ? 'toggle active' : 'toggle'}
                  onClick={() => setPreview(true)}
                >
                  <Eye size={16} aria-hidden="true" /> {t('preview')}
                </button>
              </div>
            </div>
            {preview ? (
              <article className="preview gv-panel">
                <div className="preview-meta">
                  <span className={`badge ${form.status}`}>
                    {form.status === 'published' ? t('publishedStatus') : t('draft')}
                  </span>
                  {form.tags.map((tag) => (
                    <span className="tag" key={tag}>
                      {tag}
                    </span>
                  ))}
                </div>
                <h3>{form.title || 'Sin título'}</h3>
                {form.coverUrl && isSafeUrl(form.coverUrl) && <img src={form.coverUrl} alt="" />}
                {form.excerpt && <p className="lead">{form.excerpt}</p>}
                <div className="body-copy">
                  {form.body.split('\n').map((line, index) => (
                    <p key={`${line}-${index}`}>{line || ' '}</p>
                  ))}
                </div>
              </article>
            ) : (
              <div className="editor card gv-panel">
                <label>
                  Título
                  <input
                    value={form.title}
                    onChange={(event) => update('title', event.target.value)}
                    placeholder="Ej. Cómo trabajamos mejor"
                  />
                </label>
                <div className="two-col">
                  <label>
                    Slug
                    <input
                      value={form.slug}
                      onChange={(event) =>
                        update('slug', event.target.value.toLowerCase().replace(/\s+/g, '-'))
                      }
                      placeholder="como-trabajamos-mejor"
                    />
                  </label>
                  <label>
                    Estado
                    <select
                      value={form.status}
                      onChange={(event) =>
                        update('status', event.target.value as ContentDraft['status'])
                      }
                    >
                      <option value="draft">Borrador</option>
                      <option value="published">Publicado</option>
                    </select>
                  </label>
                </div>
                <div className="asset-panel">
                  <div className="asset-heading">
                    <span>
                      <Image size={16} aria-hidden="true" /> Assets locales
                    </span>
                    <span className="hint">
                      máx. 10 MB · PNG/JPEG/WebP/GIF/AVIF · SVG bloqueado
                    </span>
                  </div>
                  <input
                    className="asset-input"
                    type="file"
                    accept="image/png,image/jpeg,image/webp,image/gif,image/avif"
                    onChange={addAsset}
                    disabled={!selectedId}
                  />
                  {(form.assets ?? []).map((asset, index) => (
                    <div className="asset-row" key={asset.id}>
                      <img src={asset.localUrl} alt={asset.alt} />
                      <input
                        aria-label={`Alt ${asset.name}`}
                        value={asset.alt}
                        onChange={(event) =>
                          update(
                            'assets',
                            (form.assets ?? []).map((entry, i) =>
                              i === index ? { ...entry, alt: event.target.value } : entry,
                            ),
                          )
                        }
                      />
                      <span>
                        {asset.name} · {(asset.size / 1024).toFixed(0)} KB
                      </span>
                    </div>
                  ))}
                </div>
                <label>
                  Resumen
                  <textarea
                    rows={3}
                    value={form.excerpt}
                    onChange={(event) => update('excerpt', event.target.value)}
                    placeholder="Una frase que invite a seguir leyendo"
                  />
                </label>
                <label>
                  Cuerpo
                  <textarea
                    className="body-input"
                    rows={12}
                    value={form.body}
                    onChange={(event) => update('body', event.target.value)}
                    placeholder="Escribe el contenido estructurado…"
                  />
                </label>
                <div className="two-col">
                  <label>
                    URL de portada <span className="hint">(http/https)</span>
                    <input
                      type="url"
                      value={form.coverUrl}
                      onChange={(event) => update('coverUrl', event.target.value)}
                      placeholder="https://…"
                    />
                  </label>
                  <label>
                    Etiquetas <span className="hint">(separadas por coma)</span>
                    <input
                      value={form.tags.join(', ')}
                      onChange={(event) =>
                        update(
                          'tags',
                          event.target.value
                            .split(',')
                            .map((tag) => tag.trim())
                            .filter(Boolean),
                        )
                      }
                      placeholder="guía, producto"
                    />
                  </label>
                </div>
                <div className="editor-footer">
                  <span className="message" role="status">
                    {message}
                  </span>
                  <button className="gv-btn gv-btn-primary" onClick={save}>
                    <Save size={16} aria-hidden="true" /> Guardar{' '}
                    {form.status === 'published' ? 'y publicar' : 'borrador'}
                  </button>
                </div>
              </div>
            )}
            {selectedId && (
              <section className="history card gv-panel">
                <div className="asset-heading">
                  <span>
                    <Calendar size={16} aria-hidden="true" /> Historial inmutable
                  </span>
                  <span className="hint">
                    {state.versions.filter((version) => version.contentId === selectedId).length}{' '}
                    versiones · publicación auditable
                  </span>
                </div>
                {state.versions
                  .filter((version) => version.contentId === selectedId)
                  .slice()
                  .reverse()
                  .map((version) => (
                    <div className="history-row" key={version.id}>
                      <span>
                        v{version.number} · {version.reason}
                      </span>
                      <small>{new Date(version.createdAt).toLocaleString('es-ES')}</small>
                      <button
                        className="gv-btn gv-btn-ghost"
                        onClick={() => restoreVersion(version.id)}
                      >
                        Restaurar
                      </button>
                    </div>
                  ))}
              </section>
            )}
          </section>
        </main>
      )}
      <footer className="gv-footer">
        <strong>Gentle-Vanguard</strong> · {t('footerTagline')} — {t('footerVersion')}
      </footer>
    </div>
  );
}
