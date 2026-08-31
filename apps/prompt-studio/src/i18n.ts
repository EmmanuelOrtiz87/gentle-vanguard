import { useCallback, useState } from 'react';

export type Locale = 'es' | 'en';
export type TranslationKey = keyof typeof STRINGS.es;

const STRINGS = {
  es: {
    appName: 'Prompt Studio',
    brandSub: 'local-first',
    create: 'Crear',
    library: 'Biblioteca',
    guides: 'Guías',
    editPrompt: 'Editar prompt',
    createPrompt: 'Crear prompt',
    example: 'Ejemplo',
    newPrompt: 'Nuevo',
    taskType: 'Tipo de tarea',
    assistantRole: 'Rol del asistente',
    goal: 'Objetivo / tarea',
    tone: 'Tono (opcional)',
    context: 'Contexto',
    criteria: 'Criterios de aceptación (uno por línea)',
    outputFormat: 'Formato de salida',
    yourPrompt: 'Tu prompt',
    copy: 'Copiar',
    copied: 'Copiado',
    titlePlaceholder: 'Título para la biblioteca (opcional)',
    tagsPlaceholder: 'etiquetas, separadas, por coma',
    noCategory: 'Sin categoría',
    category: 'Categoría',
    update: 'Actualizar',
    save: 'Guardar',
    libraryHelp:
      'Buscá por lenguaje natural — «cómo revisar código», «documentar arquitectura» — o por etiquetas. Los favoritos aparecen primero.',
    searchPlaceholder: 'Buscar en lenguaje natural…',
    search: 'Buscar',
    all: 'Todas',
    updated: 'Actualizado',
    noResults: 'Sin resultados. Creá tu primer prompt desde la pestaña «Crear».',
    guideAgents: 'Guía: usar tus prompts con agentes de IA',
    guideGems: 'Guía: crear Gemas en Gemini (asistentes potenciados)',
    patterns: 'Patrones que multiplican resultados',
    localLibrary: '100% local — biblioteca en .runtime/prompt-studio',
    footer: 'Gentle-Vanguard — Prompt Studio',
    systemState: 'Local-first',
    footerTagline: 'Prompt Studio',
    language: 'Idioma',
    theme: 'Cambiar tema',
    light: 'Activar tema claro',
    dark: 'Activar tema oscuro',
    ready: 'Listo para crear contenido.',
    allEnglish: 'All',
  },
  en: {
    appName: 'Prompt Studio',
    brandSub: 'local-first',
    create: 'Create',
    library: 'Library',
    guides: 'Guides',
    editPrompt: 'Edit prompt',
    createPrompt: 'Create prompt',
    example: 'Example',
    newPrompt: 'New',
    taskType: 'Task type',
    assistantRole: 'Assistant role',
    goal: 'Goal / task',
    tone: 'Tone (optional)',
    context: 'Context',
    criteria: 'Acceptance criteria (one per line)',
    outputFormat: 'Output format',
    yourPrompt: 'Your prompt',
    copy: 'Copy',
    copied: 'Copied',
    titlePlaceholder: 'Library title (optional)',
    tagsPlaceholder: 'tags, separated, by comma',
    noCategory: 'No category',
    category: 'Category',
    update: 'Update',
    save: 'Save',
    libraryHelp:
      'Search in natural language — “how to review code”, “document architecture” — or by tags. Favorites appear first.',
    searchPlaceholder: 'Search in natural language…',
    search: 'Search',
    all: 'All',
    updated: 'Updated',
    noResults: 'No results. Create your first prompt from the “Create” tab.',
    guideAgents: 'Guide: use your prompts with AI agents',
    guideGems: 'Guide: create Gems in Gemini (powerful assistants)',
    patterns: 'Patterns that multiply results',
    localLibrary: '100% local — library in .runtime/prompt-studio',
    footer: 'Gentle-Vanguard — Prompt Studio',
    systemState: 'Local-first',
    footerTagline: 'Prompt Studio',
    language: 'Language',
    theme: 'Change theme',
    light: 'Enable light theme',
    dark: 'Enable dark theme',
    ready: 'Ready to create content.',
    allEnglish: 'All',
  },
} as const;

export function useT(): {
  locale: Locale;
  setLocale: (locale: Locale) => void;
  t: (key: TranslationKey) => string;
} {
  const [locale, setLocale] = useState<Locale>(() =>
    localStorage.getItem('gv-cc-lang') === 'en' ? 'en' : 'es',
  );
  const changeLocale = useCallback((next: Locale) => {
    setLocale(next);
    localStorage.setItem('gv-cc-lang', next);
  }, []);
  return { locale, setLocale: changeLocale, t: (key) => STRINGS[locale][key] ?? STRINGS.es[key] };
}
