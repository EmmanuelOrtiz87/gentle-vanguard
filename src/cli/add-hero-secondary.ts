/**
 * Agregar hero sections a páginas secundarias
 * Script ejecutado por el orquestador directamente
 */

import * as fs from 'fs';
import * as path from 'path';

const PAGES_CONFIG = [
  { name: 'contract-viewer.html', badge: 'Studio', title: 'Contract Viewer', key: 'c_contractviewer_desc' },
  { name: 'image-studio.html', badge: 'Studio', title: 'Image Studio', key: 'c_imagestudio_desc' },
  { name: 'marketing.html', badge: 'Studio', title: 'Marketing Studio', key: 'c_marketing_desc' },
  { name: 'md-viewer.html', badge: 'Tool', title: 'Markdown Viewer', key: 'c_mdviewer_desc' },
  { name: 'product-doc-gentle.html', badge: 'Doc', title: 'Product Documentation', key: 'c_productdoc_desc' },
  { name: 'resources-index.html', badge: 'Index', title: 'Resource Index', key: 'c_resources_desc' },
  { name: 'social-post.html', badge: 'Studio', title: 'Social Post Studio', key: 'c_socialpost_desc' },
  { name: 'v4-features.html', badge: 'Features', title: 'v4.0 Features', key: 'c_v4features_desc' },
  { name: 'video-studio.html', badge: 'Studio', title: 'Video Studio', key: 'c_videostudio_desc' },
];

const DESCRIPTIONS: Record<string, string> = {
  c_contractviewer_desc: 'Smart contract visualization and analysis with markdown rendering',
  c_imagestudio_desc: 'Native image generation using multimodal AI capabilities',
  c_marketing_desc: 'Marketing templates and social content generation tools',
  c_mdviewer_desc: 'Markdown documentation viewer with syntax highlighting',
  c_productdoc_desc: 'Complete product documentation and feature reference',
  c_resources_desc: 'Central resource hub with indexed materials',
  c_socialpost_desc: 'Social media content generator for multiple platforms',
  c_v4features_desc: 'New features and capabilities in Gentle-Vanguard v4.0',
  c_videostudio_desc: 'Native video generation with multimodal AI',
};

const generateHero = (badge: string, title: string, contentKey: string, desc: string): string => {
  return `    <header class="hero" id="overview" style="padding-top: 90px; min-height: 40vh; background: var(--bg);">
      <div>
        <span class="hero-badge mb-3">✦ ${badge}</span>
        <h1><span class="glow">${title}</span></h1>
        <p class="lead" data-i18n="${contentKey}">${desc}</p>
      </div>
    </header>

    <main style="padding-top: 50px; min-height: 60vh;">`;
};

function processPage(config: typeof PAGES_CONFIG[0]): void {
  const filePath = path.join('docs/presentations', config.name);
  
  if (!fs.existsSync(filePath)) {
    console.log(`⚠️  ${config.name} no existe`);
    return;
  }
  
  let content = fs.readFileSync(filePath, 'utf8');
  
  // Verificar si ya tiene hero
  if (content.includes('class="hero"')) {
    console.log(`✓ ${config.name} ya tiene hero section`);
    return;
  }
  
  // Generar hero
  const hero = generateHero(config.badge, config.title, config.key, DESCRIPTIONS[config.key]);
  
  // Insertar después de </nav>
  const navEndPattern = /<\/nav>\s*\n/;
  if (!navEndPattern.test(content)) {
    console.log(`⚠️  ${config.name} - no se encontró </nav>`);
    return;
  }
  
  content = content.replace(navEndPattern, '</nav>\n\n' + hero + '\n');
  
  // También reemplazar <main> si existe, o agregar </main> antes del footer
  if (!content.includes('</main>')) {
    content = content.replace(/<footer class="gv-footer">/, '</main>\n\n    <footer class="gv-footer">');
  }
  
  fs.writeFileSync(filePath, content);
  console.log(`✅ ${config.name} - hero agregado`);
}

console.log('🏗️  Agregando hero sections a páginas secundarias...\n');

for (const config of PAGES_CONFIG) {
  try {
    processPage(config);
  } catch (error) {
    console.error(`❌ Error en ${config.name}:`, error);
  }
}

console.log('\n✨ Proceso completado');
