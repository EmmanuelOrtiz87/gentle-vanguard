/**
 * Homologador de Páginas Secundarias - Gentle-Vanguard
 * 
 * Convierte las páginas de studios/viewers para que tengan:
 * - Navbar estándar con navegación completa
 * - Footer estándar centralizado
 * - CSS/JS v3.0
 * - i18n básico
 * - Estructura consistente con las páginas principales
 */

import * as fs from 'fs';
import * as path from 'path';

interface PageConfig {
  name: string;
  title: string;
  icon: string;
  description: string;
}

const PAGES_TO_HOMOLOGATE: PageConfig[] = [
  { name: 'contract-viewer.html', title: 'Contract Viewer', icon: 'bi-file-text', description: 'Smart contract visualization and analysis' },
  { name: 'image-studio.html', title: 'Image Studio', icon: 'bi-image', description: 'Native image generation with multimodal AI' },
  { name: 'marketing.html', title: 'Marketing Studio', icon: 'bi-megaphone', description: 'Marketing templates and social content' },
  { name: 'md-viewer.html', title: 'Markdown Viewer', icon: 'bi-markdown', description: 'Markdown documentation viewer' },
  { name: 'product-doc-gentle.html', title: 'Product Documentation', icon: 'bi-book', description: 'Complete product documentation' },
  { name: 'resources-index.html', title: 'Resource Index', icon: 'bi-grid-3x3-gap', description: 'Central resource hub' },
  { name: 'social-post.html', title: 'Social Post Studio', icon: 'bi-share', description: 'Social media content generator' },
  { name: 'v4-features.html', title: 'v4.0 Features', icon: 'bi-stars', description: 'New features in v4.0' },
  { name: 'video-studio.html', title: 'Video Studio', icon: 'bi-camera-video', description: 'Native video generation capabilities' },
];

const NAV_LINKS = [
  { href: 'index.html', icon: 'bi-house', label: 'Home', i18n: 'nav_home' },
  { href: 'architecture.html', icon: 'bi-diagram-3', label: 'Arch', i18n: 'nav_arch' },
  { href: 'autonomy.html', icon: 'bi-robot', label: 'Autonomy', i18n: 'nav_autonomy' },
  { href: 'dashboard.html', icon: 'bi-speedometer2', label: 'Dashboard', i18n: 'nav_dashboard' },
  { href: 'quickstart.html', icon: 'bi-rocket-takeoff', label: 'Quickstart', i18n: 'nav_quickstart' },
  { href: 'memory-knowledge.html', icon: 'bi-brain', label: 'Memory', i18n: 'nav_memory' },
  { href: 'security-governance.html', icon: 'bi-shield-check', label: 'Security', i18n: 'nav_security' },
  { href: 'agents-pipeline.html', icon: 'bi-diagram-2', label: 'Agents', i18n: 'nav_agents' },
  { href: 'operations-cloud.html', icon: 'bi-cloud', label: 'Cloud', i18n: 'nav_cloud' },
  { href: 'patterns-conventions.html', icon: 'bi-file-code', label: 'Patterns', i18n: 'nav_patterns' },
  { href: 'health.html', icon: 'bi-heart-pulse', label: 'Health', i18n: 'nav_health' },
];

function generateHeader(title: string, _icon: string): string {
  return `<!doctype html>
<html lang="es" data-bs-theme="dark">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>${title} — Gentle-Vanguard</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet" />
    <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css" rel="stylesheet" />
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700;800;900&family=JetBrains+Mono:wght@400;500;600;700&display=swap" rel="stylesheet" />
    <link rel="stylesheet" href="assets/css/gv.css?v=3.0" />`;
}

function generateNavbar(currentPage: string): string {
  const links = NAV_LINKS.map(link => {
    const isActive = link.href === currentPage ? 'active' : '';
    return `<li class="nav-item">
              <a class="nav-link ${isActive}" href="${link.href}">
                <i class="bi ${link.icon} me-1"></i><span data-i18n="${link.i18n}">${link.label}</span>
              </a>
            </li>`;
  }).join('\n            ');

  return `    <script src="assets/js/i18n-content.js?v=3.0"></script>
    <script src="assets/js/i18n.js?v=3.0"></script>
  </head>
  <body class="grain">
    <div class="scroll-progress"></div>
    <div class="aurora" aria-hidden="true"><span></span><span></span><span></span></div>
    <div class="gv-particles" aria-hidden="true"></div>
    <nav class="navbar navbar-expand-xl nav-blur fixed-top">
      <div class="container-fluid px-3">
        <a class="navbar-brand text-light fw-bold mono" href="index.html" style="font-size: 0.85rem">
          <i class="bi bi-robot me-2" style="color: var(--p)"></i>GV
        </a>
        <button class="navbar-toggler" type="button" data-bs-toggle="collapse" data-bs-target="#navMain">
          <i class="bi bi-list" style="color: var(--p)"></i>
        </button>
        <div class="collapse navbar-collapse" id="navMain">
          <ul class="navbar-nav ms-auto" style="max-height: 85vh; overflow-y: auto">
            ${links}
            <li class="nav-item ms-2">
              <div class="lang-seg" role="group" aria-label="Language">
                <button type="button" data-lang="en" aria-pressed="false">
                  <span class="lang-flag">🇬🇧</span><span class="lang-code">EN</span>
                </button>
                <button type="button" data-lang="es" aria-pressed="false">
                  <span class="lang-flag">🇪🇸</span><span class="lang-code">ES</span>
                </button>
                <button type="button" data-lang="pt-BR" aria-pressed="false">
                  <span class="lang-flag">🇧🇷</span><span class="lang-code">PT</span>
                </button>
              </div>
            </li>
          </ul>
        </div>
      </div>
    </nav>`;
}

function generateFooter(): string {
  const footerLinks = [
    { href: 'architecture.html', icon: 'bi-diagram-3', label: 'Architecture' },
    { href: 'autonomy.html', icon: 'bi-robot', label: 'Autonomy' },
    { href: 'dashboard.html', icon: 'bi-speedometer2', label: 'Dashboard' },
    { href: 'quickstart.html', icon: 'bi-rocket-takeoff', label: 'Quick Start' },
    { href: 'memory-knowledge.html', icon: 'bi-brain', label: 'Memory' },
    { href: 'security-governance.html', icon: 'bi-shield', label: 'Security' },
    { href: 'agents-pipeline.html', icon: 'bi-people', label: 'Agents' },
    { href: 'operations-cloud.html', icon: 'bi-cloud', label: 'Operations' },
    { href: 'patterns-conventions.html', icon: 'bi-diagram-2', label: 'Patterns' },
    { href: 'health.html', icon: 'bi-heart-pulse', label: 'Health' },
    { href: 'index.html', icon: 'bi-book', label: 'The Book' },
  ].map(l => `<a href="${l.href}"><i class="bi ${l.icon} me-1"></i>${l.label}</a>`).join('\n        ');

  return `    <footer class="gv-footer">
      <p class="mb-2">
        Gentle-Vanguard <strong>v4.0</strong> — 100% Autonomous AI Stack ·
        <span class="text-secondary">✦ Plataforma Autónoma de Orquestración AI</span>
      </p>
      <p class="mb-2 d-flex flex-wrap justify-content-center gap-3">
        ${footerLinks}
        <a href="https://github.com/EmmanuelOrtiz17/gentle-vanguard" target="_blank"><i class="bi bi-github me-1"></i>GitHub</a>
      </p>
      <div class="d-flex flex-wrap justify-content-center gap-2 mt-2 mb-2">
        <span class="badge bg-primary bg-opacity-10 text-primary border border-primary border-opacity-25 px-2 py-1" style="font-size: 0.6rem">294 TS Files</span>
        <span class="badge bg-success bg-opacity-10 text-success border border-success border-opacity-25 px-2 py-1" style="font-size: 0.6rem">103 Test Files</span>
        <span class="badge bg-info bg-opacity-10 text-info border border-info border-opacity-25 px-2 py-1" style="font-size: 0.6rem">112/112 Health</span>
        <span class="badge bg-warning bg-opacity-10 text-warning border border-warning border-opacity-25 px-2 py-1" style="font-size: 0.6rem">11 Repos</span>
        <span class="badge bg-secondary bg-opacity-10 text-secondary border border-secondary border-opacity-25 px-2 py-1" style="font-size: 0.6rem">175 Skills</span>
        <span class="badge bg-light bg-opacity-10 text-light border border-light border-opacity-25 px-2 py-1" style="font-size: 0.6rem">65 Normatives</span>
      </div>
      <p class="mt-2 mb-0">
        <small><i class="bi bi-cpu me-1"></i>Don't let your mellow hustle be faded.</small>
      </p>
    </footer>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
    <script src="assets/js/gv.js?v=3.0"></script>
  </body>
</html>`;
}

/**
 * Extrae el contenido principal de una página existente
 * Busca el body y extrae todo entre el navbar y el footer (si existen)
 */
function extractMainContent(html: string): string {
  // Buscar contenido entre </nav> y <footer o </body>
  const navEnd = html.indexOf('</nav>');
  const footerStart = html.indexOf('<footer');
  const bodyEnd = html.indexOf('</body>');
  
  let start = navEnd > 0 ? navEnd + 6 : html.indexOf('<body');
  if (start < 0) start = html.indexOf('>') + 1;
  
  let end = footerStart > 0 ? footerStart : bodyEnd;
  if (end < 0) end = html.length;
  
  return html.slice(start, end).trim();
}

/**
 * Homologa una página individual
 */
function homologatePage(config: PageConfig): void {
  const filePath = path.join(process.cwd(), 'docs/presentations', config.name);
  
  if (!fs.existsSync(filePath)) {
    console.log(`⚠️  ${config.name} no existe, saltando...`);
    return;
  }
  
  console.log(`🔄 Procesando ${config.name}...`);
  
  const existingHtml = fs.readFileSync(filePath, 'utf8');
  const mainContent = extractMainContent(existingHtml);
  
  // Generar nueva estructura
  const newHtml = `${generateHeader(config.title, config.icon)}
${generateNavbar(config.name)}
${mainContent}
${generateFooter()}`;
  
  // Backup del original
  const backupPath = `${filePath}.backup`;
  if (!fs.existsSync(backupPath)) {
    fs.writeFileSync(backupPath, existingHtml);
    console.log(`   💾 Backup creado: ${config.name}.backup`);
  }
  
  // Escribir nueva versión
  fs.writeFileSync(filePath, newHtml);
  console.log(`   ✅ ${config.name} homologada`);
}

/**
 * Función principal
 */
function main(): void {
  console.log('🏗️  Homologando páginas secundarias...\n');
  
  let success = 0;
  let failed = 0;
  
  for (const page of PAGES_TO_HOMOLOGATE) {
    try {
      homologatePage(page);
      success++;
    } catch (error) {
      console.error(`   ❌ Error en ${page.name}:`, error);
      failed++;
    }
  }
  
  console.log(`\n📊 Resultado: ${success} homologadas, ${failed} fallidas`);
  
  if (failed === 0) {
    console.log('✨ Todas las páginas homologadas exitosamente');
    process.exit(0);
  } else {
    console.log('⚠️  Algunas páginas fallaron, revisar errores arriba');
    process.exit(1);
  }
}

main();
