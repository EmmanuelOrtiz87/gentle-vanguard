import { CMS_SCHEMA_VERSION, validateContent, type CmsState, type ContentItem } from './domain';

const STORAGE_KEY = 'gentle-vanguard.content-cms.v2';
const fallback = new Map<string, string>();
function storage(): Storage | null {
  try {
    return typeof window !== 'undefined' ? window.localStorage : null;
  } catch {
    return null;
  }
}
export const emptyState = (): CmsState => ({
  schemaVersion: CMS_SCHEMA_VERSION,
  items: [],
  versions: [],
  audit: [],
});
export const contentStore = {
  load(): CmsState {
    try {
      const raw = storage()?.getItem(STORAGE_KEY) ?? fallback.get(STORAGE_KEY);
      if (!raw) return emptyState();
      const parsed = JSON.parse(raw) as Partial<CmsState>;
      if (parsed.schemaVersion !== CMS_SCHEMA_VERSION || !Array.isArray(parsed.items))
        return emptyState();
      const items = parsed.items.filter((item): item is ContentItem => validateContent(item).valid);
      return {
        schemaVersion: CMS_SCHEMA_VERSION,
        items,
        versions: Array.isArray(parsed.versions) ? parsed.versions : [],
        audit: Array.isArray(parsed.audit) ? parsed.audit : [],
      };
    } catch {
      return emptyState();
    }
  },
  save(state: CmsState): void {
    const serialized = JSON.stringify(state);
    try {
      const target = storage();
      if (target) target.setItem(STORAGE_KEY, serialized);
      else fallback.set(STORAGE_KEY, serialized);
    } catch {
      fallback.set(STORAGE_KEY, serialized);
    }
  },
};
