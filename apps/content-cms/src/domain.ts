export const CMS_SCHEMA_VERSION = 2;
export const MAX_ASSET_BYTES = 10 * 1024 * 1024;
const SAFE_IMAGE_MIMES = new Set([
  'image/png',
  'image/jpeg',
  'image/webp',
  'image/gif',
  'image/avif',
]);

export type ContentStatus = 'draft' | 'published';
export type AssetMetadata = {
  id: string;
  name: string;
  mime: string;
  size: number;
  alt: string;
  localUrl: string;
  createdAt: string;
};
export type ContentItem = {
  id: string;
  title: string;
  slug: string;
  excerpt: string;
  body: string;
  coverUrl: string;
  tags: string[];
  status: ContentStatus;
  updatedAt: string;
  assets?: AssetMetadata[];
};
export type ContentDraft = Omit<ContentItem, 'id' | 'updatedAt'>;
export type ContentVersion = {
  id: string;
  contentId: string;
  number: number;
  snapshot: ContentItem;
  createdAt: string;
  reason: 'save' | 'publish' | 'rollback' | 'import';
};
export type AuditEvent = {
  id: string;
  contentId: string;
  action: 'created' | 'updated' | 'published' | 'rollback' | 'imported';
  at: string;
  version: number;
};
export type CmsState = {
  schemaVersion: typeof CMS_SCHEMA_VERSION;
  items: ContentItem[];
  versions: ContentVersion[];
  audit: AuditEvent[];
};
export type ContentExport = { schemaVersion: typeof CMS_SCHEMA_VERSION; items: ContentItem[] };

export function createId(prefix = 'content'): string {
  return `${prefix}-${Date.now()}-${Math.random().toString(36).slice(2, 8)}`;
}
export function emptyContent(): ContentDraft {
  return {
    title: '',
    slug: '',
    excerpt: '',
    body: '',
    coverUrl: '',
    tags: [],
    status: 'draft',
    assets: [],
  };
}
export function isSafeUrl(value: string): boolean {
  if (!value.trim()) return true;
  try {
    const url = new URL(value);
    return (
      ['http:', 'https:'].includes(url.protocol) &&
      !url.username &&
      !url.password &&
      !/["'<>`\u0000-\u001f\u007f]/.test(value)
    );
  } catch {
    return false;
  }
}
export function validateAssetMetadata(value: unknown): {
  valid: boolean;
  errors: string[];
  data?: AssetMetadata;
} {
  if (!value || typeof value !== 'object')
    return { valid: false, errors: ['El asset debe ser un objeto.'] };
  const asset = value as Partial<AssetMetadata>;
  const errors: string[] = [];
  if (typeof asset.name !== 'string' || !asset.name.trim() || /[\\/\0]/.test(asset.name))
    errors.push('El nombre del asset no es válido.');
  if (typeof asset.mime !== 'string' || !SAFE_IMAGE_MIMES.has(asset.mime.toLowerCase()))
    errors.push('Solo se admiten imágenes raster seguras; SVG está bloqueado.');
  if (
    typeof asset.size !== 'number' ||
    !Number.isInteger(asset.size) ||
    asset.size < 1 ||
    asset.size > MAX_ASSET_BYTES
  )
    errors.push('El asset supera el tamaño permitido o es inválido.');
  if (typeof asset.alt !== 'string' || asset.alt.trim().length < 1 || asset.alt.length > 300)
    errors.push('El texto alternativo es obligatorio (máximo 300 caracteres).');
  if (
    typeof asset.localUrl !== 'string' ||
    (!asset.localUrl.startsWith('blob:') &&
      !/^data:image\/(?:png|jpeg|webp|gif|avif);/i.test(asset.localUrl))
  )
    errors.push('La referencia local del asset no es válida.');
  if (typeof asset.id !== 'string' || typeof asset.createdAt !== 'string')
    errors.push('Faltan metadatos del asset.');
  return errors.length
    ? { valid: false, errors }
    : { valid: true, errors: [], data: asset as AssetMetadata };
}
export function validateContent(value: unknown): {
  valid: boolean;
  errors: string[];
  data?: ContentItem;
} {
  if (!value || typeof value !== 'object')
    return { valid: false, errors: ['El contenido debe ser un objeto.'] };
  const item = value as Partial<ContentItem>;
  const errors: string[] = [];
  if (typeof item.title !== 'string' || item.title.trim().length < 3)
    errors.push('El título debe tener al menos 3 caracteres.');
  if (typeof item.slug !== 'string' || !/^[a-z0-9]+(?:-[a-z0-9]+)*$/.test(item.slug))
    errors.push('El slug solo acepta minúsculas, números y guiones.');
  if (typeof item.body !== 'string' || item.body.trim().length < 1)
    errors.push('El cuerpo no puede estar vacío.');
  if (typeof item.excerpt !== 'string') errors.push('El resumen debe ser texto.');
  if (typeof item.coverUrl !== 'string' || !isSafeUrl(item.coverUrl))
    errors.push('La URL de portada debe usar http o https.');
  if (!Array.isArray(item.tags) || item.tags.some((tag) => typeof tag !== 'string'))
    errors.push('Las etiquetas deben ser texto.');
  if (item.status !== 'draft' && item.status !== 'published')
    errors.push('El estado no es válido.');
  if (typeof item.id !== 'string' || typeof item.updatedAt !== 'string')
    errors.push('Faltan metadatos del contenido.');
  if (
    item.assets &&
    (!Array.isArray(item.assets) ||
      item.assets.some((asset) => !validateAssetMetadata(asset).valid))
  )
    errors.push('Hay assets locales inválidos.');
  return errors.length
    ? { valid: false, errors }
    : { valid: true, errors: [], data: item as ContentItem };
}
export function validateImport(value: unknown): {
  valid: boolean;
  errors: string[];
  items: ContentItem[];
} {
  if (!value || typeof value !== 'object')
    return { valid: false, errors: ['El archivo debe ser un objeto JSON.'], items: [] };
  const envelope = value as { schemaVersion?: unknown; items?: unknown };
  if (envelope.schemaVersion !== CMS_SCHEMA_VERSION)
    return {
      valid: false,
      errors: [`Schema no compatible. Se esperaba ${CMS_SCHEMA_VERSION}.`],
      items: [],
    };
  if (!Array.isArray(envelope.items))
    return { valid: false, errors: ['El campo items debe ser una lista.'], items: [] };
  const results = envelope.items.map(validateContent);
  const items = results.flatMap((result) => (result.valid && result.data ? [result.data] : []));
  return {
    valid: items.length === results.length,
    errors: results.flatMap((result) => result.errors),
    items,
  };
}
export function createExport(items: ContentItem[]): ContentExport {
  return { schemaVersion: CMS_SCHEMA_VERSION, items: structuredClone(items) };
}
export function normalizeImport(value: unknown): ContentItem[] {
  if (Array.isArray(value))
    return value.flatMap((candidate) => {
      const result = validateContent(candidate);
      return result.valid && result.data ? [result.data] : [];
    });
  return validateImport(value).items;
}
export function addVersion(
  state: CmsState,
  item: ContentItem,
  reason: ContentVersion['reason'],
): CmsState {
  const number = state.versions.filter((version) => version.contentId === item.id).length + 1;
  const version: ContentVersion = {
    id: createId('version'),
    contentId: item.id,
    number,
    snapshot: structuredClone(item),
    createdAt: new Date().toISOString(),
    reason,
  };
  const action: AuditEvent['action'] =
    reason === 'publish'
      ? 'published'
      : reason === 'rollback'
        ? 'rollback'
        : reason === 'import'
          ? 'imported'
          : number === 1
            ? 'created'
            : 'updated';
  return {
    ...state,
    items: state.items.some((entry) => entry.id === item.id)
      ? state.items.map((entry) => (entry.id === item.id ? item : entry))
      : [item, ...state.items],
    versions: [...state.versions, version],
    audit: [
      ...state.audit,
      { id: createId('audit'), contentId: item.id, action, at: version.createdAt, version: number },
    ],
  };
}
export function rollback(state: CmsState, contentId: string, versionId: string): CmsState | null {
  const version = state.versions.find(
    (entry) => entry.id === versionId && entry.contentId === contentId,
  );
  if (!version) return null;
  return addVersion(
    state,
    { ...structuredClone(version.snapshot), updatedAt: new Date().toISOString() },
    'rollback',
  );
}
