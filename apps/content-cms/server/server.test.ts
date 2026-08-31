import { describe, expect, it } from 'vitest';
import { PLATFORM_SPECS, getSpec, recommendSlot, MVP_PLATFORM_IDS } from './platform-specs';
import { resolveGenerator, templateVariant, LlmGenerator, GenerateBrief } from './generator';
import { mediaRefFromPath, validateSlotTransition } from './server';

const brief: GenerateBrief = {
  title: 'Lanzamiento GV Content OS',
  brief:
    'Anunciamos el CMS social nativo local-first del stack: genera variantes por red con specs, calendario y gate humano.',
  objective: 'captar estudiantes y empresas',
  voice: '',
  platforms: ['linkedin', 'x', 'instagram'],
  format: 'text_image',
};

describe('platform-specs', () => {
  it('cubre las 10 redes del MVP con specs completas', () => {
    expect(MVP_PLATFORM_IDS.length).toBe(10);
    for (const id of MVP_PLATFORM_IDS) {
      const spec = getSpec(id);
      expect(spec).not.toBeNull();
      expect(spec!.charLimit).toBeGreaterThan(0);
      expect(spec!.imageSize.width).toBeGreaterThan(0);
      expect(spec!.bestTimes.length).toBeGreaterThan(0);
    }
  });

  it('respeta límites conocidos por red', () => {
    expect(PLATFORM_SPECS.x.charLimit).toBe(280);
    expect(PLATFORM_SPECS.instagram.imageSize).toEqual({ width: 1080, height: 1350 });
    expect(PLATFORM_SPECS.reddit.hashtagOptimal).toBe(0);
  });

  it('recommendSlot produce fechas futuras con rationale', () => {
    const rec = recommendSlot('linkedin');
    expect(rec).not.toBeNull();
    expect(new Date(rec!.scheduledAt).getTime()).toBeGreaterThan(Date.now() - 86_400_000);
    expect(rec!.rationale).toContain('LinkedIn');
  });

  it('rechaza plataformas desconocidas', () => {
    expect(recommendSlot('myspace')).toBeNull();
    expect(getSpec('myspace')).toBeNull();
  });
});

describe('generator', () => {
  it('template fallback genera una variante válida por cada plataforma', async () => {
    const gen = resolveGenerator('template');
    expect(gen.provider).toBe('template');
    const variants = await gen.generate(brief);
    expect(variants.map((v) => v.platform)).toEqual(['linkedin', 'x', 'instagram']);
    for (const v of variants) {
      expect(v.body.length).toBeGreaterThan(0);
      expect(v.body.length).toBeLessThanOrEqual(v.spec.charLimit);
      expect(v.imagePrompt).toContain('#0D1117');
    }
  });

  it('template omite imagePrompt cuando el formato es solo texto', async () => {
    const v = templateVariant({ ...brief, format: 'text' }, PLATFORM_SPECS.linkedin);
    expect(v.imagePrompt).toBe('');
  });

  it('LlmGenerator parsea la respuesta JSON y respeta charLimit', async () => {
    const llm = new LlmGenerator('openai', async () =>
      JSON.stringify({
        variants: [
          { platform: 'x', body: 'a'.repeat(400), imagePrompt: 'dark azure hero', score: 88 },
          { platform: 'unknown', body: 'ignorado' },
        ],
      }),
    );
    const variants = await llm.generate({ ...brief, platforms: ['x'] });
    expect(variants).toHaveLength(1);
    expect(variants[0].body.length).toBeLessThanOrEqual(280);
    expect(variants[0].score).toBe(88);
    expect(variants[0].provider).toBe('openai');
  });

  it('LlmGenerator falla con respuesta inválida (para que el caller caiga a template)', async () => {
    const llm = new LlmGenerator('gemini', async () => 'no soy json');
    await expect(llm.generate(brief)).rejects.toThrow(/variants JSON/);
  });

  it('resolveGenerator sin entorno ni preferencia cae a template', () => {
    const prevUrl = process.env.CONTENT_LLM_BASE_URL;
    const prevKey = process.env.GEMINI_API_KEY;
    delete process.env.CONTENT_LLM_BASE_URL;
    delete process.env.GEMINI_API_KEY;
    expect(resolveGenerator().provider).toBe('template');
    if (prevUrl) process.env.CONTENT_LLM_BASE_URL = prevUrl;
    if (prevKey) process.env.GEMINI_API_KEY = prevKey;
  });
});

describe('slot transitions (F2 calendario)', () => {
  it('permite proposed → confirmed y proposed → skipped', () => {
    expect(validateSlotTransition('proposed', 'confirmed')).toBeNull();
    expect(validateSlotTransition('proposed', 'skipped')).toBeNull();
  });

  it('permite volver atrás y publicar: confirmed → proposed|published|skipped, skipped → proposed', () => {
    expect(validateSlotTransition('confirmed', 'proposed')).toBeNull();
    expect(validateSlotTransition('confirmed', 'published')).toBeNull();
    expect(validateSlotTransition('confirmed', 'skipped')).toBeNull();
    expect(validateSlotTransition('skipped', 'proposed')).toBeNull();
  });

  it('rechaza saltos inválidos (estados fuera del CHECK de calendar_slots)', () => {
    expect(validateSlotTransition('proposed', 'rejected')).toMatch(/transición inválida/);
    expect(validateSlotTransition('skipped', 'confirmed')).toMatch(/transición inválida/);
    expect(validateSlotTransition('published', 'proposed')).toMatch(/transición inválida/);
  });

  it('idempotencia: mismo estado es no-op válido', () => {
    expect(validateSlotTransition('confirmed', 'confirmed')).toBeNull();
  });
});

describe('mediaRefFromPath (convención media:<id>)', () => {
  it('extrae el id de una referencia media:<id>', () => {
    expect(mediaRefFromPath('media:cm-123-abc')).toBe('cm-123-abc');
  });

  it('devuelve null para rutas normales o vacías', () => {
    expect(mediaRefFromPath('assets/hero.png')).toBeNull();
    expect(mediaRefFromPath('')).toBeNull();
  });
});
