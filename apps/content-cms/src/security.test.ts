import { describe, expect, it } from 'vitest';
import { isSafeUrl, validateAssetMetadata, validateContent } from './domain';

const validContent = {
  id: 'content-1',
  title: 'Título seguro',
  slug: 'titulo-seguro',
  excerpt: '',
  body: 'Texto',
  coverUrl: '',
  tags: [],
  status: 'draft' as const,
  updatedAt: '2026-01-01T00:00:00.000Z',
};

const asset = {
  id: 'asset-1',
  name: 'cover.png',
  mime: 'image/png',
  size: 100,
  alt: 'Portada',
  localUrl: 'data:image/png;base64,abc',
  createdAt: '2026-01-01T00:00:00.000Z',
};

describe('CMS URL and asset security', () => {
  it.each([
    'javascript:alert(1)',
    'data:text/html,<script>alert(1)</script>',
    '//attacker.example/image.png',
    '/relative/path.png',
    'https://user:password@example.test/image.png',
    'https://example.test/" onerror="alert(1)',
  ])('rejects unsafe cover URL: %s', (url) => {
    expect(isSafeUrl(url)).toBe(false);
    expect(validateContent({ ...validContent, coverUrl: url }).valid).toBe(false);
  });

  it.each(['https://example.test/image.png', 'http://localhost:3000/cover.webp', ''])(
    'accepts safe cover URL: %s',
    (url) => expect(isSafeUrl(url)).toBe(true),
  );

  it('accepts raster data and blob assets but rejects SVG disguised as raster data', () => {
    expect(validateAssetMetadata(asset).valid).toBe(true);
    expect(
      validateAssetMetadata({ ...asset, localUrl: 'blob:http://localhost/asset-1' }).valid,
    ).toBe(true);
    expect(
      validateAssetMetadata({ ...asset, localUrl: 'data:image/svg+xml;base64,PHN2Zy8+' }).valid,
    ).toBe(false);
  });

  it.each([
    { name: '../secret.png', alt: 'Imagen' },
    { name: 'image.png', alt: '' },
    { name: 'image.png', alt: 'x'.repeat(301) },
    { name: 'image.svg', mime: 'image/svg+xml', localUrl: 'data:image/svg+xml;base64,abc' },
  ])('rejects unsafe or incomplete asset metadata: %j', (override) => {
    expect(validateAssetMetadata({ ...asset, ...override }).valid).toBe(false);
  });
});
