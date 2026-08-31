import { useMemo, useRef, useState, type ChangeEvent } from 'react';
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
  const [tab, setTab] = useState<Tab>('content-os');
  const [state, setState] = useState(() => contentStore.load());
  const [selectedId, setSelectedId] = useState<string | null>(null);
  const [form, setForm] = useState<ContentDraft>(emptyContent());
  const [preview, setPreview] = useState(false);
  const [filter, setFilter] = useState<'all' | 'draft' | 'published'>('all');
  const [message, setMessage] = useState('Listo para crear contenido.');
  const importRef = useRef<HTMLInputElement>(null);
  const visibleItems = useMemo(
    () => (filter === 'all' ? state.items : state.items.filter((item) => item.status === filter)),
    [filter, state.items],
  );

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
      <div className="grid-bg" />
      <div className="glow-a" />
      <div className="glow-b" />
      <header className="topbar">
        <div className="topbar-inner">
          <div className="brand">
            <span className="mark" aria-hidden="true">
              GV
            </span>
            <span className="name">
              Gentle<span>Vanguard</span> <small>Content Studio</small>
            </span>
          </div>
          <nav className="main-nav view-tabs" aria-label="Secciones del CMS">
            <button
              className={tab === 'content-os' ? 'active' : ''}
              onClick={() => setTab('content-os')}
            >
              <FileText size={16} aria-hidden="true" /> Content OS
            </button>
            <button className={tab === 'studio' ? 'active' : ''} onClick={() => setTab('studio')}>
              <Pencil size={16} aria-hidden="true" /> Studio (legacy)
            </button>
          </nav>
          <div className="system-state ready">
            <span />
            {state.items.length} items
          </div>
          <div className="top-actions">
            {tab === 'studio' && (
              <>
                <button className="button ghost" onClick={() => importRef.current?.click()}>
                  <Upload size={16} aria-hidden="true" /> Importar JSON
                </button>
                <input
                  ref={importRef}
                  className="visually-hidden"
                  type="file"
                  accept="application/json"
                  onChange={importJson}
                />
                <button className="button ghost" onClick={() => downloadJson(state.items)}>
                  <Download size={16} aria-hidden="true" /> Exportar JSON
                </button>
                <button className="button primary" onClick={startNew}>
                  <Plus size={16} aria-hidden="true" /> Nuevo contenido
                </button>
              </>
            )}
          </div>
        </div>
      </header>
      {tab === 'content-os' ? (
        <ContentOS />
      ) : (
        <main className="layout">
          <aside className="sidebar">
            <div className="side-heading">
              <div>
                <span className="eyebrow">Biblioteca</span>
                <h1>Contenido</h1>
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
                  {value === 'all' ? 'Todo' : value === 'draft' ? 'Borradores' : 'Publicados'}{' '}
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
              {!visibleItems.length && <p className="empty">Aún no hay contenido aquí.</p>}
            </div>
          </aside>
          <section className="workspace">
            <div className="workspace-header">
              <div>
                <span className="eyebrow">{selectedId ? 'Editar entrada' : 'Nueva entrada'}</span>
                <h2>{preview ? 'Vista previa' : form.title || 'Da forma a una idea'}</h2>
              </div>
              <div className="view-toggle" role="group" aria-label="Modo de edición">
                <button
                  className={!preview ? 'toggle active' : 'toggle'}
                  onClick={() => setPreview(false)}
                >
                  <Pencil size={16} aria-hidden="true" /> Editor
                </button>
                <button
                  className={preview ? 'toggle active' : 'toggle'}
                  onClick={() => setPreview(true)}
                >
                  <Eye size={16} aria-hidden="true" /> Preview
                </button>
              </div>
            </div>
            {preview ? (
              <article className="preview panel">
                <div className="preview-meta">
                  <span className={`badge ${form.status}`}>
                    {form.status === 'published' ? 'Publicado' : 'Borrador'}
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
              <div className="editor card panel">
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
                  <button className="button primary" onClick={save}>
                    <Save size={16} aria-hidden="true" /> Guardar{' '}
                    {form.status === 'published' ? 'y publicar' : 'borrador'}
                  </button>
                </div>
              </div>
            )}
            {selectedId && (
              <section className="history card panel">
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
                      <button className="button ghost" onClick={() => restoreVersion(version.id)}>
                        Restaurar
                      </button>
                    </div>
                  ))}
              </section>
            )}
          </section>
        </main>
      )}
      <footer>
        <span>
          {tab === 'content-os'
            ? 'Content OS · Nexus + generación asistida · gate humano'
            : 'Persistencia local · sin backend ni publicación remota'}
        </span>
        <span>Gentle-Vanguard / MVP CMS</span>
      </footer>
    </div>
  );
}
