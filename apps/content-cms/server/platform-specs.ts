/**
 * Platform specs — formato, tono y mejores horarios por red social.
 * Fuente de verdad del Content OS (ADR-0021); complementa
 * config/content-operations/platforms.json (que define modos de operación).
 */

export type ContentFormat = 'text' | 'image' | 'text_image';

export interface PlatformSpec {
  id: string;
  name: string;
  charLimit: number;
  hashtagOptimal: number;
  aspect: string;
  imageSize: { width: number; height: number };
  tone: string;
  hookStyle: string;
  supportsImage: boolean;
  bestTimes: string[]; // horas locales recomendadas
  notes: string;
}

export const PLATFORM_SPECS: Record<string, PlatformSpec> = {
  linkedin: {
    id: 'linkedin',
    name: 'LinkedIn',
    charLimit: 3000,
    hashtagOptimal: 3,
    aspect: '1.91:1',
    imageSize: { width: 1200, height: 627 },
    tone: 'profesional, experto, orientado a valor de negocio',
    hookStyle:
      'primera línea = insight o dato que genera curiosidad (es lo único visible antes del "ver más")',
    supportsImage: true,
    bestTimes: ['07:30', '12:00', '17:30'],
    notes: 'Lunes-jueves mayor alcance. Evitar hashtags excesivos. Carruseles (PDF) rinden bien.',
  },
  x: {
    id: 'x',
    name: 'X (Twitter)',
    charLimit: 280,
    hashtagOptimal: 1,
    aspect: '16:9',
    imageSize: { width: 1600, height: 900 },
    tone: 'directo, nítido, con opinión',
    hookStyle: 'una idea fuerte por post; hilos si hay profundidad',
    supportsImage: true,
    bestTimes: ['08:00', '12:00', '19:00'],
    notes: 'Threads para desarrollo. El primer tweet decide el hilo.',
  },
  instagram: {
    id: 'instagram',
    name: 'Instagram',
    charLimit: 2200,
    hashtagOptimal: 5,
    aspect: '4:5',
    imageSize: { width: 1080, height: 1350 },
    tone: 'visual-first, cercano, aspiracional',
    hookStyle: 'el hook va en la imagen y en la primera línea; CTA a "link en bio" o guardar post',
    supportsImage: true,
    bestTimes: ['11:00', '14:00', '20:00'],
    notes: 'Carrusel 4:5 (10 slides) es el formato de mayor retención. Reels es post-MVP.',
  },
  facebook: {
    id: 'facebook',
    name: 'Facebook',
    charLimit: 5000,
    hashtagOptimal: 2,
    aspect: '1.91:1',
    imageSize: { width: 1200, height: 630 },
    tone: 'conversacional, comunidad',
    hookStyle: 'pregunta directa o historia corta que invite a comentar',
    supportsImage: true,
    bestTimes: ['09:00', '13:00', '19:00'],
    notes: 'Grupos y compartidos impulsan alcance. Menos hashtags.',
  },
  telegram: {
    id: 'telegram',
    name: 'Telegram',
    charLimit: 4096,
    hashtagOptimal: 2,
    aspect: '16:9',
    imageSize: { width: 1280, height: 720 },
    tone: 'informativo, directo, canal propio',
    hookStyle: 'primera línea en negrita con el anuncio; el detalle después',
    supportsImage: true,
    bestTimes: ['09:00', '18:00'],
    notes: 'Audiencia suscripta: frecuencia alta tolerada. Formato con Markdown.',
  },
  discord: {
    id: 'discord',
    name: 'Discord',
    charLimit: 2000,
    hashtagOptimal: 0,
    aspect: '16:9',
    imageSize: { width: 1200, height: 675 },
    tone: 'comunidad, informal-profesional',
    hookStyle: 'mención de rol si aplica + anuncio claro; evita formato marketing',
    supportsImage: true,
    bestTimes: ['15:00', '21:00'],
    notes: 'Sin hashtags. Formato embebido. El tono spam degrada la comunidad.',
  },
  reddit: {
    id: 'reddit',
    name: 'Reddit',
    charLimit: 40000,
    hashtagOptimal: 0,
    aspect: '16:9',
    imageSize: { width: 1200, height: 675 },
    tone: 'honesto, técnico, anti-promocional',
    hookStyle: 'título tipo pregunta o hallazgo concreto; el valor va en el cuerpo',
    supportsImage: true,
    bestTimes: ['07:00', '11:00', '20:00'],
    notes: 'Reglas de cada subreddit son ley. Autopromoción >10% quema la cuenta.',
  },
  threads: {
    id: 'threads',
    name: 'Threads',
    charLimit: 500,
    hashtagOptimal: 1,
    aspect: '1:1',
    imageSize: { width: 1080, height: 1080 },
    tone: 'casual, conversacional, opinion-driven',
    hookStyle: 'opinion fuerte o pregunta abierta; el engagement es por respuestas',
    supportsImage: true,
    bestTimes: ['10:00', '20:00'],
    notes: 'Conversación > difusión. Responder comentarios amplifica.',
  },
  whatsapp: {
    id: 'whatsapp',
    name: 'WhatsApp (Canal/Estado)',
    charLimit: 4096,
    hashtagOptimal: 0,
    aspect: '9:16',
    imageSize: { width: 1080, height: 1920 },
    tone: 'personal, breve, 1:1',
    hookStyle: 'primera línea decide si abren; emoji moderado',
    supportsImage: true,
    bestTimes: ['08:00', '13:00', '20:00'],
    notes: 'Canal: difusión a suscriptos. Estado: 24h, formato vertical.',
  },
  tiktok: {
    id: 'tiktok',
    name: 'TikTok',
    charLimit: 2200,
    hashtagOptimal: 4,
    aspect: '9:16',
    imageSize: { width: 1080, height: 1920 },
    tone: 'nativo, dinámico, trend-aware',
    hookStyle: 'hook en los primeros 2 segundos (post-MVP: video; hoy solo caption/thumbnail)',
    supportsImage: true,
    bestTimes: ['12:00', '19:00', '22:00'],
    notes: 'Video es post-MVP (ADR-0021); soportado solo como texto/thumbnail.',
  },
};

export const MVP_PLATFORM_IDS = Object.keys(PLATFORM_SPECS);

export function getSpec(platform: string): PlatformSpec | null {
  return PLATFORM_SPECS[platform] ?? null;
}

/** Heurística v1 de horario recomendado: distribuye N publicaciones entre los bestTimes de cada red. */
export function recommendSlot(
  platform: string,
  weekOffset = 0,
  dayOfWeek = 2, // 0=domingo … 2=martes por defecto
): { scheduledAt: string; rationale: string } | null {
  const spec = getSpec(platform);
  if (!spec) return null;
  const time = spec.bestTimes[weekOffset % spec.bestTimes.length];
  const base = new Date();
  base.setDate(base.getDate() + ((dayOfWeek - base.getDay() + 7) % 7) + weekOffset * 7);
  const iso = `${base.toISOString().slice(0, 10)}T${time}:00`;
  return {
    scheduledAt: iso,
    rationale: `${spec.name} rinde mejor alrededor de las ${time} (heurística v1; se refina con métricas reales). ${spec.notes}`,
  };
}
