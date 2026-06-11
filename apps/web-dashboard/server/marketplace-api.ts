import { readFileSync, writeFileSync, existsSync, mkdirSync, readdirSync, statSync } from 'fs';
import { join } from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = join(__filename, '..');
const SKILLS_DIR = join(__dirname, '..', '..', '..', 'skills');
const DATA_PATH = join(__dirname, '..', 'data', 'marketplace.json');

export interface SkillListing {
  id: string;
  name: string;
  description: string;
  author: string;
  version: string;
  downloads: number;
  rating: number;
  reviews: Review[];
  tags: string[];
  createdAt: string;
  updatedAt: string;
  triggers?: string[];
  agentType?: string;
  skillPath?: string;
}

export interface Review {
  id: string;
  user: string;
  rating: number;
  comment: string;
  createdAt: string;
}

export interface CreateSkillPayload {
  name: string;
  description: string;
  author: string;
  version?: string;
  tags?: string[];
  triggers?: string[];
  agentType?: string;
  skillContent: string;
}

function loadMarketplace(): SkillListing[] {
  if (!existsSync(DATA_PATH)) {
    return [];
  }
  try {
    const data = readFileSync(DATA_PATH, 'utf-8');
    return JSON.parse(data);
  } catch {
    return [];
  }
}

function saveMarketplace(listings: SkillListing[]) {
  const dir = join(DATA_PATH, '..');
  if (!existsSync(dir)) {
    mkdirSync(dir, { recursive: true });
  }
  writeFileSync(DATA_PATH, JSON.stringify(listings, null, 2));
}

function parseFrontmatter(content: string): Record<string, unknown> {
  const match = content.match(/^---\s*\n([\s\S]*?)\n---/);
  if (!match) return {};
  const frontmatter: Record<string, unknown> = {};
  const lines = match[1].split('\n');
  for (const line of lines) {
    const kvMatch = line.match(/^\s*(\w+):\s*(.*)/);
    if (kvMatch) {
      let value: unknown = kvMatch[2].trim();
      if (value === 'true') value = true;
      else if (value === 'false') value = false;
      else if (/^\d+$/.test(value as string)) value = parseInt(value as string, 10);
      else if (/^\d+\.\d+$/.test(value as string)) value = parseFloat(value as string);
      frontmatter[kvMatch[1]] = value;
    }
  }
  return frontmatter;
}

export function validateSkillStructure(skillContent: string): { valid: boolean; errors: string[] } {
  const errors: string[] = [];

  if (!skillContent || skillContent.trim().length === 0) {
    return { valid: false, errors: ['SKILL.md content is empty'] };
  }

  if (!/^---/.test(skillContent)) {
    errors.push('Missing YAML frontmatter (must start with ---)');
  }

  const frontmatter = parseFrontmatter(skillContent);
  if (!frontmatter.name) {
    errors.push("Frontmatter must include 'name' field");
  }
  if (!frontmatter.description) {
    errors.push("Frontmatter must include 'description' field");
  }

  if (!/##\s+Usage|##\s+When to Use/.test(skillContent)) {
    errors.push("Missing '## Usage' or '## When to Use' section");
  }

  if (!/##\s+Examples/.test(skillContent)) {
    errors.push("Missing '## Examples' section");
  }

  return { valid: errors.length === 0, errors };
}

function scanSkillsDirectory(): SkillListing[] {
  if (!existsSync(SKILLS_DIR)) {
    return [];
  }

  const listings: SkillListing[] = [];
  const entries = readdirSync(SKILLS_DIR);

  for (const entry of entries) {
    const skillPath = join(SKILLS_DIR, entry);
    if (!statSync(skillPath).isDirectory()) continue;

    const skillMdPath = join(skillPath, 'SKILL.md');
    if (!existsSync(skillMdPath)) continue;

    try {
      const content = readFileSync(skillMdPath, 'utf-8');
      const frontmatter = parseFrontmatter(content);

      listings.push({
        id: `skill-${entry}`,
        name: (frontmatter.name as string) || entry,
        description: (frontmatter.description as string) || '',
        author:
          ((frontmatter.metadata as Record<string, unknown>)?.author as string) || 'community',
        version: ((frontmatter.metadata as Record<string, unknown>)?.version as string) || '1.0.0',
        downloads: 0,
        rating: 0,
        reviews: [],
        tags: [],
        createdAt: (frontmatter.created as string) || new Date().toISOString(),
        updatedAt: (frontmatter.updated as string) || new Date().toISOString(),
        triggers: [],
        agentType: (frontmatter.agent as string) || 'any',
        skillPath: skillPath,
      });
    } catch {
      continue;
    }
  }

  return listings;
}

export function getListings(): SkillListing[] {
  const dbListings = loadMarketplace();
  const fsListings = scanSkillsDirectory();

  const merged = new Map<string, SkillListing>();

  for (const l of fsListings) {
    merged.set(l.id, l);
  }

  for (const l of dbListings) {
    if (merged.has(l.id)) {
      const existing = merged.get(l.id);
      if (!existing) continue;
      existing.downloads = l.downloads;
      existing.rating = l.rating;
      existing.reviews = l.reviews;
      existing.tags = l.tags;
      existing.triggers = l.triggers;
      existing.agentType = l.agentType || existing.agentType;
    } else {
      merged.set(l.id, l);
    }
  }

  return Array.from(merged.values());
}

export function getListing(id: string): SkillListing | undefined {
  return getListings().find((l) => l.id === id);
}

export function createListing(payload: CreateSkillPayload): SkillListing {
  const valid = validateSkillStructure(payload.skillContent);
  if (!valid.valid) {
    throw new Error(`Validation failed: ${valid.errors.join('; ')}`);
  }

  const existing = getListings().find((l) => l.name === payload.name);
  if (existing) {
    throw new Error(`Skill named '${payload.name}' already exists`);
  }

  const skillDir = join(SKILLS_DIR, payload.name);
  if (existsSync(skillDir)) {
    throw new Error(`Directory 'skills/${payload.name}' already exists`);
  }

  mkdirSync(skillDir, { recursive: true });

  const skillMdPath = join(skillDir, 'SKILL.md');
  writeFileSync(skillMdPath, payload.skillContent, 'utf-8');

  const now = new Date().toISOString();
  const newListing: SkillListing = {
    id: `skill-${payload.name}`,
    name: payload.name,
    description: payload.description,
    author: payload.author,
    version: payload.version || '1.0.0',
    downloads: 0,
    rating: 0,
    reviews: [],
    tags: payload.tags || [],
    createdAt: now,
    updatedAt: now,
    triggers: payload.triggers || [],
    agentType: payload.agentType || 'any',
    skillPath: skillDir,
  };

  const allListings = loadMarketplace();
  allListings.push(newListing);
  saveMarketplace(allListings);

  return newListing;
}

export function addReview(listingId: string, review: Omit<Review, 'id' | 'createdAt'>): Review {
  const listings = loadMarketplace();
  let listing = listings.find((l) => l.id === listingId);
  if (!listing) {
    const fsListings = scanSkillsDirectory();
    const fsListing = fsListings.find((l) => l.id === listingId);
    if (!fsListing) {
      throw new Error('Listing not found');
    }
    listing = { ...fsListing };
    listings.push(listing);
  }

  const newReview: Review = {
    ...review,
    id: `review-${Date.now()}`,
    createdAt: new Date().toISOString(),
  };

  listing.reviews.push(newReview);
  listing.rating = listing.reviews.reduce((acc, r) => acc + r.rating, 0) / listing.reviews.length;
  listing.updatedAt = new Date().toISOString();

  saveMarketplace(listings);
  return newReview;
}

export function incrementDownloads(listingId: string): number {
  const listings = loadMarketplace();
  let listing = listings.find((l) => l.id === listingId);
  if (!listing) {
    const fsListings = scanSkillsDirectory();
    const fsListing = fsListings.find((l) => l.id === listingId);
    if (!fsListing) {
      return 0;
    }
    listing = { ...fsListing, downloads: 0 };
    listings.push(listing);
  }

  listing.downloads++;
  listing.updatedAt = new Date().toISOString();
  saveMarketplace(listings);
  return listing.downloads;
}

export function getSkillContent(skillPath: string): string | null {
  const skillMdPath = join(skillPath, 'SKILL.md');
  if (!existsSync(skillMdPath)) return null;
  try {
    return readFileSync(skillMdPath, 'utf-8');
  } catch {
    return null;
  }
}
