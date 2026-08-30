import { describe, expect, it } from 'vitest';
import {
  addVersion,
  createExport,
  normalizeImport,
  rollback,
  validateAssetMetadata,
  validateContent,
  validateImport,
  type CmsState,
} from './domain';

const valid = {
  id: 'one',
  title: 'Título válido',
  slug: 'titulo-valido',
  excerpt: '',
  body: 'Contenido',
  coverUrl: '',
  tags: ['guía'],
  status: 'draft' as const,
  updatedAt: new Date().toISOString(),
};

describe('content domain', () => {
  it('rejects unsafe URLs and malformed slugs', () => {
    expect(validateContent({ ...valid, coverUrl: 'javascript:alert(1)' }).valid).toBe(false);
    expect(validateContent({ ...valid, slug: 'Título inválido' }).valid).toBe(false);
  });
  it('accepts valid structured content', () => {
    expect(validateContent(valid).valid).toBe(true);
  });
  it('imports only valid entries', () => {
    expect(normalizeImport([valid, { ...valid, id: 'bad', body: '' }])).toHaveLength(1);
  });
  it('requires the versioned import envelope', () => {
    expect(validateImport({ version: 1, items: [valid] }).valid).toBe(false);
    expect(validateImport({ schemaVersion: 2, items: [valid] }).valid).toBe(true);
    expect(validateImport(createExport([valid])).items).toEqual([valid]);
  });
  it('keeps immutable versions and rolls back as a new version', () => {
    const initial: CmsState = { schemaVersion: 2, items: [], versions: [], audit: [] };
    const first = addVersion(initial, valid, 'save');
    const changed = { ...valid, title: 'Otro título' };
    const second = addVersion(first, changed, 'save');
    const restored = rollback(second, valid.id, first.versions[0].id);
    expect(second.versions).toHaveLength(2);
    expect(restored?.versions).toHaveLength(3);
    expect(restored?.items[0].title).toBe(valid.title);
    expect(second.versions[0].snapshot.title).toBe(valid.title);
  });
  it('blocks executable and oversized asset inputs', () => {
    const base = {
      id: 'asset',
      name: 'x.svg',
      mime: 'image/svg+xml',
      size: 20,
      alt: 'x',
      localUrl: 'data:image/svg+xml;base64,abc',
      createdAt: new Date().toISOString(),
    };
    expect(validateAssetMetadata(base).valid).toBe(false);
    expect(
      validateAssetMetadata({
        ...base,
        mime: 'image/png',
        name: 'x.png',
        localUrl: 'data:image/png;base64,abc',
        size: 11 * 1024 * 1024,
      }).valid,
    ).toBe(false);
  });
});
