/**
 * ContentGenerator — generación de variantes multi-red a partir de un brief.
 *
 * Proveedores plugables (ADR-0021):
 *  - `openai`: cualquier endpoint OpenAI-compatible (CONTENT_LLM_BASE_URL / CONTENT_LLM_API_KEY / CONTENT_LLM_MODEL)
 *  - `gemini`: Google AI free tier (GEMINI_API_KEY)
 *  - `template`: fallback determinista local (sin red, sin claves) — garantiza que el
 *    pipeline siempre produce un borrador estructurado aunque falte el proveedor.
 */

import { getSpec, PlatformSpec, ContentFormat } from './platform-specs';

export interface GenerateBrief {
  title: string;
  brief: string;
  objective: string;
  voice: string;
  platforms: string[];
  format: ContentFormat;
}

export interface GeneratedVariant {
  platform: string;
  format: ContentFormat;
  body: string;
  imagePrompt: string;
  spec: PlatformSpec;
  provider: string;
  score: number | null;
}

export interface ContentGenerator {
  readonly provider: string;
  generate(brief: GenerateBrief): Promise<GeneratedVariant[]>;
}

const GV_VOICE_DEFAULT = `Gentle-Vanguard: marca técnica local-first. Tono: consultivo, claro, en español neutro.
Evitar hype vacío, clickbait y emojis excesivos. Valor concreto antes que adjetivos.`;

function buildSystemPrompt(voice: string): string {
  return `Sos un redactor de contenido social experto para la marca Gentle-Vanguard.
Voz de marca:
${voice || GV_VOICE_DEFAULT}

Reglas:
- Respondé SOLO con un objeto JSON válido: {"variants":[{"platform":"...","body":"...","imagePrompt":"...","score":0-100}]}
- "body" en texto plano (sin markdown de encabezados), respetando el límite de caracteres de cada red.
- "imagePrompt" = prompt en inglés para un generador de imágenes (composición, estilo, paleta azure #00BFFF sobre dark #0D1117).
- "score" = tu autoevaluación de impacto 0-100.
- Cada variante debe sentirse nativa de su red, no un copy-paste recortado.`;
}

function buildUserPrompt(brief: GenerateBrief): string {
  const specs = brief.platforms
    .map((p) => getSpec(p))
    .filter((s): s is PlatformSpec => Boolean(s))
    .map(
      (s) =>
        `- ${s.id} (${s.name}): máx ${s.charLimit} chars, ${s.hashtagOptimal} hashtags, tono ${s.tone}. Hook: ${s.hookStyle}. Imagen ${s.imageSize.width}x${s.imageSize.height} (${s.aspect}).`,
    )
    .join('\n');
  const formatHint =
    brief.format === 'image'
      ? 'La entrega principal es la imagen: "body" corto (caption mínimo) e "imagePrompt" detallado.'
      : brief.format === 'text_image'
        ? 'Texto e imagen equilibrados: body completo + imagePrompt coherente con el texto.'
        : 'Solo texto: imagePrompt puede quedar vacío.';
  return `Objetivo de negocio: ${brief.objective || 'no especificado'}
Título/trabajo: ${brief.title}
Brief:
${brief.brief}

Plataformas:
${specs}

Formato: ${brief.format}. ${formatHint}`;
}

interface LlmJson {
  variants?: Array<{ platform?: string; body?: string; imagePrompt?: string; score?: number }>;
}

function parseLlmJson(raw: string): LlmJson | null {
  const match = raw.match(/\{[\s\S]*\}/);
  if (!match) return null;
  try {
    return JSON.parse(match[0]) as LlmJson;
  } catch {
    return null;
  }
}

async function callOpenAiCompatible(system: string, user: string): Promise<string> {
  const baseUrl = process.env.CONTENT_LLM_BASE_URL;
  const apiKey = process.env.CONTENT_LLM_API_KEY ?? '';
  const model = process.env.CONTENT_LLM_MODEL ?? 'gpt-4o-mini';
  if (!baseUrl) throw new Error('CONTENT_LLM_BASE_URL no configurado');
  const res = await fetch(`${baseUrl.replace(/\/$/, '')}/chat/completions`, {
    method: 'POST',
    headers: { 'content-type': 'application/json', authorization: `Bearer ${apiKey}` },
    body: JSON.stringify({
      model,
      temperature: 0.7,
      messages: [
        { role: 'system', content: system },
        { role: 'user', content: user },
      ],
    }),
  });
  if (!res.ok) throw new Error(`LLM HTTP ${res.status}`);
  const data = (await res.json()) as { choices?: Array<{ message?: { content?: string } }> };
  return data.choices?.[0]?.message?.content ?? '';
}

async function callGemini(system: string, user: string): Promise<string> {
  const apiKey = process.env.GEMINI_API_KEY;
  if (!apiKey) throw new Error('GEMINI_API_KEY no configurado');
  const model = process.env.GEMINI_MODEL ?? 'gemini-2.0-flash';
  const res = await fetch(
    `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${apiKey}`,
    {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify({
        systemInstruction: { parts: [{ text: system }] },
        contents: [{ role: 'user', parts: [{ text: user }] }],
        generationConfig: { temperature: 0.7 },
      }),
    },
  );
  if (!res.ok) throw new Error(`Gemini HTTP ${res.status}`);
  const data = (await res.json()) as {
    candidates?: Array<{ content?: { parts?: Array<{ text?: string }> } }>;
  };
  return data.candidates?.[0]?.content?.parts?.map((p) => p.text ?? '').join('') ?? '';
}

/** Fallback determinista: genera un borrador estructurado por red sin LLM. */
export function templateVariant(brief: GenerateBrief, spec: PlatformSpec): GeneratedVariant {
  const core = brief.brief.trim().slice(0, Math.min(brief.brief.length, spec.charLimit - 200));
  const hook = `${brief.title}`;
  const body = [
    hook,
    '',
    core,
    '',
    `— ${brief.objective ? `Objetivo: ${brief.objective}. ` : ''}Borrador generado por GV Content OS (plantilla); editar antes de aprobar.`,
    spec.hashtagOptimal
      ? Array.from({ length: spec.hashtagOptimal }, (_, i) => `#tag${i + 1}`).join(' ')
      : '',
  ]
    .filter(Boolean)
    .join('\n')
    .slice(0, spec.charLimit);
  return {
    platform: spec.id,
    format: brief.format,
    body,
    imagePrompt:
      brief.format === 'text'
        ? ''
        : `Clean editorial graphic for ${spec.name}, ${spec.aspect} aspect, dark background #0D1117 with azure #00BFFF accents, subject: ${brief.title}. No text longer than 5 words.`,
    spec,
    provider: 'template',
    score: null,
  };
}

export class TemplateGenerator implements ContentGenerator {
  readonly provider = 'template';
  async generate(brief: GenerateBrief): Promise<GeneratedVariant[]> {
    return brief.platforms
      .map((p) => getSpec(p))
      .filter((s): s is PlatformSpec => Boolean(s))
      .map((spec) => templateVariant(brief, spec));
  }
}

export class LlmGenerator implements ContentGenerator {
  constructor(
    readonly provider: 'openai' | 'gemini',
    private call: (system: string, user: string) => Promise<string>,
  ) {}

  async generate(brief: GenerateBrief): Promise<GeneratedVariant[]> {
    const system = buildSystemPrompt(brief.voice);
    const user = buildUserPrompt(brief);
    const raw = await this.call(system, user);
    const parsed = parseLlmJson(raw);
    if (!parsed?.variants?.length) throw new Error('Respuesta LLM sin variants JSON válido');
    const out: GeneratedVariant[] = [];
    for (const v of parsed.variants) {
      const spec = v.platform ? getSpec(v.platform) : null;
      if (!spec || !brief.platforms.includes(spec.id)) continue;
      out.push({
        platform: spec.id,
        format: brief.format,
        body: (v.body ?? '').slice(0, spec.charLimit),
        imagePrompt: v.imagePrompt ?? '',
        spec,
        provider: this.provider,
        score: typeof v.score === 'number' ? v.score : null,
      });
    }
    if (!out.length) throw new Error('El LLM no produjo variantes para las plataformas pedidas');
    return out;
  }
}

/** Resuelve el generador disponible con mejor calidad; nunca falla: cae a template. */
export function resolveGenerator(preferred?: string): ContentGenerator {
  const explicit = preferred ?? process.env.CONTENT_LLM_PROVIDER ?? '';
  if (explicit === 'openai' || (!explicit && process.env.CONTENT_LLM_BASE_URL)) {
    return new LlmGenerator('openai', callOpenAiCompatible);
  }
  if (explicit === 'gemini' || (!explicit && process.env.GEMINI_API_KEY)) {
    return new LlmGenerator('gemini', callGemini);
  }
  return new TemplateGenerator();
}
