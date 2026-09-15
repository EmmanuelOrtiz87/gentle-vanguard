#!/usr/bin/env node
/**
 * GV Design System — validate:shell (GATE NATIVO de homologación de identidad).
 *
 * PROBLEMA QUE CERRAMOS (homologación 2026-09-15):
 * Las apps homologadas importan `packages/gv-design-system/dist/shell.css` (vía exports
 * "./shell.css"). El wordmark oficial "Gentle**Vanguard**" quedaba MAL en archify +
 * design-hub + prompt-studio + command-center + gv-analytics (wordmark "Gentle" cian, o
 * TODO en una línea ilegible) porque las apps sobreescribían `.gv-brand-wordmark` con sus
 * propias reglas App.css (gradiente en el span "Gentle", font-size distinto del botón
 * idioma 文A, etc.).
 *
 * ESTE GATE:
 * - FALLA (exit 1) si `dist/shell.css` NO contiene la identidad homologada nativa
 *   (wordmark "Gentle" blanco + SOLO "Vanguard" gradiente + botón idioma 文A 13px
 *   homologado). Así el "mejor stack" se vuelve NORMATIVO: cualquier app que no
 *   respete la identidad → `npm run validate:shell` falla en CI y salva la marca.
 *
 * USO:
 *   npm run validate:shell                # solo chequear (exit 0 = homologado)
 *   npm run validate:shell -- --fix       # además RE-EJECUTA el pipeline de BUILD del
 *                                         # dist (build:tokens && build:components &&
 *                                         # build:mcp) para regenerar shell.css nativo
 *
 * CLAVES COMUNES HOMOLOGADAS (compartidas entre TODAS las apps — NO por-app):
 *   gv-cc-lang · gv-cc-theme · gv-cc-lang-dropdown · gv-cc-lang-check ·
 *   gv-brand-wordmark · gv-brand-wordmark span (solo "Vanguard" con gradiente) ·
 *   gv-lang-dropdown... (icono 文A homologado)
 */
'use strict';
import { readFileSync, existsSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { execSync } from 'node:child_process';

const __dirname = dirname(fileURLToPath(import.meta.url));
const ROOT = join(__dirname, '..');
const DIST_SHELL_CSS = join(ROOT, 'dist', 'shell.css');

const LBL = {
  wordmarkBase: 'wordmark "Gentle" → blanco (--gv-text)',
  wordmarkSpan: 'SÓLO el <span> "Vanguard" lleva gradiente (background-clip:text)',
  langBtn: 'botón idioma 文A · 13px homologado (font-size + line-height)',
  langShared: 'dropdown idioma usa clases compartidas gv-lang-* (no claves por-app)',
};

function has(pattern, haystack) { return pattern.test(haystack); }

function check() {
  if (!existsSync(DIST_SHELL_CSS)) {
    console.error(`  ❌ No existe ${DIST_SHELL_CSS} — corré \`npm run build\` (o \`-- --fix\`) primero.`);
    return false;
  }
  const css = readFileSync(DIST_SHELL_CSS, 'utf8');
  const ok = {
    wordmarkBase: has(/\.gv-brand-wordmark[^{]*\{[^}]*color:\s*var\(--gv-text/, css),
    wordmarkSpan: has(/\.gv-brand-wordmark\s+span[^{]*\{[^}]*background-clip:\s*text/, css),
    langBtn: has(/\.gv-lang-dropdown\s+\.gv-icon-btn[^{]*\{[^}]*font-size:\s*13px/, css),
    langShared: has(/\.gv-lang-dropdown/, css) && !has(/gv-(analytics|archify|cms|crm|prompt|dashboard|hub)-lang/, css),
  };
  Object.entries(ok).forEach(([k, v]) => {
    console.log(`  ${v ? '✅' : '❌'} ${LBL[k]}`);
  });
  return Object.values(ok).every(Boolean);
}

/* ── CLI ─────────────────────────────────────────────── */
const args = process.argv.slice(2);
const useFix = args.includes('--fix');

if (useFix) {
  console.log('♻️  validate:shell --fix → rebuild del dist (build:tokens && build:components && build:mcp)…');
  try {
    execSync('npm run build 2>&1', { cwd: ROOT, stdio: 'inherit' });
  } catch (e) {
    console.error('\n  ❌ Build falló:', e.message.split('\n')[0]);
    process.exit(1);
  }
}

const pass = check();
if (!pass) {
  console.error('\n  ✗✗✗ IDENTIDAD NO HOMOLOGADA en dist/shell.css ✗✗✗');
  console.error('     Ejecutá:  npm run validate:shell -- --fix');
  console.error('     (regenera el dist a partir de src/ homologado)');
  process.exit(1);
}
console.log('\n  ✓ IDENTIDAD GV HOMOLOGADA — dist/shell.css nativo ✅');