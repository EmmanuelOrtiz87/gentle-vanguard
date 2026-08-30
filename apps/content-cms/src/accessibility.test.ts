import { readFileSync } from 'node:fs';
import { describe, expect, it } from 'vitest';

const appSource = readFileSync(new URL('./App.tsx', import.meta.url), 'utf8');

describe('CMS accessibility smoke checks', () => {
  it('keeps status feedback and grouped controls programmatically identifiable', () => {
    expect(appSource).toMatch(/role="status"/);
    expect(appSource).toMatch(/role="group" aria-label="Filtrar por estado"/);
    expect(appSource).toMatch(/role="group" aria-label="Modo de edición"/);
  });

  it('uses explicit labels for editable content controls and accessible asset alt fields', () => {
    for (const label of [
      'Título',
      'Slug',
      'Estado',
      'Resumen',
      'Cuerpo',
      'URL de portada',
      'Etiquetas',
    ]) {
      expect(appSource).toContain(`<label>`);
      expect(appSource).toContain(label);
    }
    expect(appSource).toMatch(/aria-label=\{`Alt \$\{asset\.name\}`\}/);
    expect(appSource).toMatch(/alt=\{asset\.alt\}/);
  });
});
