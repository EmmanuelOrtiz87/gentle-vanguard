import { IncomingMessage, ServerResponse } from 'http';
import {
  getListings,
  getListing,
  createListing,
  addReview,
  incrementDownloads,
  validateSkillStructure,
  getSkillContent,
  CreateSkillPayload,
} from './marketplace-api.js';

function json(res: ServerResponse, status: number, data: unknown): void {
  res.writeHead(status, { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' });
  res.end(JSON.stringify(data));
}

function readBody(req: IncomingMessage): Promise<string> {
  return new Promise((resolve, reject) => {
    let body = '';
    req.on('data', (chunk: Buffer) => {
      body += chunk.toString();
    });
    req.on('end', () => resolve(body));
    req.on('error', reject);
  });
}

export async function handleMarketplaceRoutes(
  req: IncomingMessage,
  res: ServerResponse,
): Promise<boolean> {
  const url = new URL(req.url || '/', `http://${req.headers.host}`);
  const method = req.method || 'GET';

  if (req.method === 'OPTIONS') {
    res.writeHead(204, {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type',
    });
    res.end();
    return true;
  }

  // GET /api/marketplace — list all
  if (url.pathname === '/api/marketplace' && method === 'GET') {
    const listings = getListings();
    json(res, 200, { success: true, data: listings, total: listings.length });
    return true;
  }

  // POST /api/marketplace — submit new
  if (url.pathname === '/api/marketplace' && method === 'POST') {
    try {
      const body = JSON.parse(await readBody(req));
      const missing: string[] = [];
      if (!body.name) missing.push('name');
      if (!body.description) missing.push('description');
      if (!body.author) missing.push('author');
      if (!body.skillContent) missing.push('skillContent');
      if (missing.length > 0) {
        json(res, 400, { success: false, error: `Missing required fields: ${missing.join(', ')}` });
        return true;
      }

      const payload: CreateSkillPayload = {
        name: body.name,
        description: body.description,
        author: body.author,
        version: body.version || '1.0.0',
        tags: body.tags || [],
        triggers: body.triggers || [],
        agentType: body.agentType || 'any',
        skillContent: body.skillContent,
      };

      const validation = validateSkillStructure(payload.skillContent);
      if (!validation.valid) {
        json(res, 400, {
          success: false,
          error: 'Skill structure validation failed',
          details: validation.errors,
        });
        return true;
      }

      const listing = createListing(payload);
      json(res, 201, { success: true, data: listing, message: `Skill '${payload.name}' created` });
    } catch (err) {
      const msg = err instanceof Error ? err.message : 'Failed to create listing';
      json(res, msg.includes('already exists') ? 409 : 500, { success: false, error: msg });
    }
    return true;
  }

  // POST /api/marketplace/validate/structure
  if (url.pathname === '/api/marketplace/validate/structure' && method === 'POST') {
    try {
      const body = JSON.parse(await readBody(req));
      if (!body.skillContent) {
        json(res, 400, { success: false, error: 'Missing required field: skillContent' });
        return true;
      }
      const result = validateSkillStructure(body.skillContent);
      json(res, 200, { success: true, data: result });
    } catch {
      json(res, 500, { success: false, error: 'Validation failed' });
    }
    return true;
  }

  // GET /api/marketplace/:id
  const detailMatch = url.pathname.match(/^\/api\/marketplace\/([^/]+)$/);
  if (detailMatch && method === 'GET') {
    const listing = getListing(detailMatch[1]);
    if (!listing) {
      json(res, 404, { success: false, error: 'Listing not found' });
      return true;
    }
    const content = listing.skillPath ? getSkillContent(listing.skillPath) : null;
    json(res, 200, { success: true, data: { ...listing, content } });
    return true;
  }

  // POST /api/marketplace/:id/review
  const reviewMatch = url.pathname.match(/^\/api\/marketplace\/([^/]+)\/review$/);
  if (reviewMatch && method === 'POST') {
    try {
      const body = JSON.parse(await readBody(req));
      if (!body.user || body.rating === null || body.rating === undefined || !body.comment) {
        json(res, 400, { success: false, error: 'Missing required fields: user, rating, comment' });
        return true;
      }
      if (typeof body.rating !== 'number' || body.rating < 1 || body.rating > 5) {
        json(res, 400, { success: false, error: 'Rating must be a number between 1 and 5' });
        return true;
      }
      const review = addReview(reviewMatch[1], {
        user: body.user,
        rating: body.rating,
        comment: body.comment,
      });
      json(res, 201, { success: true, data: review });
    } catch {
      json(res, 500, { success: false, error: 'Failed to add review' });
    }
    return true;
  }

  // POST /api/marketplace/:id/download
  const downloadMatch = url.pathname.match(/^\/api\/marketplace\/([^/]+)\/download$/);
  if (downloadMatch && method === 'POST') {
    const downloads = incrementDownloads(downloadMatch[1]);
    json(res, 200, { success: true, data: { id: downloadMatch[1], downloads } });
    return true;
  }

  return false;
}
