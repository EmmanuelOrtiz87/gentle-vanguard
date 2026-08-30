import { describe, expect, it } from 'vitest';
import {
  addVersion,
  createExport,
  emptyContent,
  normalizeImport,
  rollback,
  type CmsState,
  type ContentItem,
} from './domain';

const state = (): CmsState => ({ schemaVersion: 2, items: [], versions: [], audit: [] });

function item(overrides: Partial<ContentItem> = {}): ContentItem {
  return {
    ...emptyContent(),
    id: 'article-1',
    title: 'Guía local-first',
    slug: 'guia-local-first',
    body: 'Contenido editorial',
    updatedAt: '2026-01-01T00:00:00.000Z',
    ...overrides,
  };
}

describe('CMS editorial workflow', () => {
  it('creates, edits and publishes an item with an auditable version trail', () => {
    const created = addVersion(state(), item(), 'save');
    const edited = addVersion(
      created,
      item({ title: 'Guía publicada', status: 'published', updatedAt: '2026-01-02T00:00:00.000Z' }),
      'publish',
    );

    expect(edited.items).toHaveLength(1);
    expect(edited.items[0].status).toBe('published');
    expect(edited.versions.map((version) => version.reason)).toEqual(['save', 'publish']);
    expect(edited.audit.map((event) => event.action)).toEqual(['created', 'published']);
  });

  it('exports and imports the complete editorial item without mutating the source', () => {
    const original = item({ tags: ['guía'], assets: [] });
    const exported = createExport([original]);
    const imported = normalizeImport(JSON.parse(JSON.stringify(exported)));

    expect(imported).toEqual([original]);
    expect(imported[0]).not.toBe(original);
    imported[0].title = 'Importación editada';
    expect(original.title).toBe('Guía local-first');
  });

  it('imports an item as a new version and rolls back to a prior snapshot', () => {
    const first = addVersion(state(), item(), 'save');
    const imported = addVersion(first, item({ title: 'Versión importada' }), 'import');
    const restored = rollback(imported, 'article-1', first.versions[0].id);

    expect(restored?.items[0].title).toBe('Guía local-first');
    expect(restored?.versions).toHaveLength(3);
    expect(restored?.versions.at(-1)?.reason).toBe('rollback');
    expect(restored?.audit.at(-1)?.action).toBe('rollback');
    expect(imported.versions[0].snapshot.title).toBe('Guía local-first');
  });
});
