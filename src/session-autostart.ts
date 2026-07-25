#!/usr/bin/env node
/**
 * session-autostart.ts — Entry point for AGENTS.md compatibility
 *
 * The actual implementation lives at src/core/session-autostart.ts.
 * This file exists so the AGENTS.md command `npx tsx src/session-autostart.ts`
 * resolves correctly.
 */

// Delegate to the core implementation
import './core/session-autostart';
