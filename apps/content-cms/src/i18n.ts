import { useCallback, useState } from 'react';

export type Locale = 'es' | 'en';
export type TranslationKey = keyof typeof STRINGS.es;

const STRINGS = {
  es: {
    contentStudio: 'Content Studio',
    contentOs: 'Content OS',
    legacy: 'Studio (legacy)',
    items: 'items',
    importJson: 'Importar JSON',
    exportJson: 'Exportar JSON',
    newContent: 'Nuevo contenido',
    library: 'Biblioteca',
    content: 'Contenido',
    all: 'Todo',
    drafts: 'Borradores',
    published: 'Publicados',
    noContent: 'Aún no hay contenido aquí.',
    editEntry: 'Editar entrada',
    newEntry: 'Nueva entrada',
    preview: 'Vista previa',
    editor: 'Editor',
    draft: 'Borrador',
    publishedStatus: 'Publicado',
    title: 'Título',
    slug: 'Slug',
    status: 'Estado',
    summary: 'Resumen',
    body: 'Cuerpo',
    save: 'Guardar',
    publish: 'y publicar',
    saveDraft: 'borrador',
    restore: 'Restaurar',
    language: 'Idioma',
    theme: 'Cambiar tema',
    ready: 'Listo para crear contenido.',
    localPersistence: 'Persistencia local · sin backend ni publicación remota',
    contentOsFooter: 'Content OS · Nexus + generación asistida · gate humano',
    noTitle: 'Sin título',
    es: 'ES',
    en: 'EN',
    light: 'Activar tema claro',
    dark: 'Activar tema oscuro',
  },
  en: {
    contentStudio: 'Content Studio',
    contentOs: 'Content OS',
    legacy: 'Studio (legacy)',
    items: 'items',
    importJson: 'Import JSON',
    exportJson: 'Export JSON',
    newContent: 'New content',
    library: 'Library',
    content: 'Content',
    all: 'All',
    drafts: 'Drafts',
    published: 'Published',
    noContent: 'There is no content here yet.',
    editEntry: 'Edit entry',
    newEntry: 'New entry',
    preview: 'Preview',
    editor: 'Editor',
    draft: 'Draft',
    publishedStatus: 'Published',
    title: 'Title',
    slug: 'Slug',
    status: 'Status',
    summary: 'Summary',
    body: 'Body',
    save: 'Save',
    publish: 'and publish',
    saveDraft: 'draft',
    restore: 'Restore',
    language: 'Language',
    theme: 'Change theme',
    ready: 'Ready to create content.',
    localPersistence: 'Local persistence · no backend or remote publishing',
    contentOsFooter: 'Content OS · Nexus + assisted generation · human gate',
    noTitle: 'Untitled',
    es: 'ES',
    en: 'EN',
    light: 'Enable light theme',
    dark: 'Enable dark theme',
  },
} as const;

export function useT(): {
  locale: Locale;
  setLocale: (locale: Locale) => void;
  t: (key: TranslationKey) => string;
} {
  const [locale, setLocale] = useState<Locale>(() =>
    localStorage.getItem('gv-cms-lang') === 'en' ? 'en' : 'es',
  );
  const changeLocale = useCallback((next: Locale) => {
    setLocale(next);
    localStorage.setItem('gv-cms-lang', next);
  }, []);
  return { locale, setLocale: changeLocale, t: (key) => STRINGS[locale][key] ?? STRINGS.es[key] };
}
