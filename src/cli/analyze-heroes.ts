import * as fs from 'fs';
import * as path from 'path';

const pages = [
  'index.html', 'memory-knowledge.html', 'security-governance.html', 'agents-pipeline.html',
  'architecture.html', 'autonomy.html', 'dashboard.html', 'health.html', 'operations-cloud.html',
  'patterns-conventions.html', 'quickstart.html', 'contract-viewer.html', 'image-studio.html',
  'marketing.html', 'md-viewer.html', 'product-doc-gentle.html', 'resources-index.html',
  'social-post.html', 'v4-features.html', 'video-studio.html'
];

console.log('ANÁLISIS DE HEROES\n' + '='.repeat(80) + '\n');
console.log('Página                  | ID=overview | Hero Badge | Glow | Stats | CTAs');
console.log('-'.repeat(80));

for (const page of pages) {
  const filePath = path.join('docs/presentations', page);
  
  if (!fs.existsSync(filePath)) {
    console.log(`${page.padEnd(23)} | NO EXISTE`);
    continue;
  }
  
  const content = fs.readFileSync(filePath, 'utf8');
  
  // Encontrar el hero
  const heroMatch = content.match(/<header class="hero"[^>]*>([\s\S]*?)<\/header>/);
  
  if (!heroMatch) {
    console.log(`${page.padEnd(23)} | NO TIENE HERO`);
    continue;
  }
  
  const hero = heroMatch[0];
  const heroTag = heroMatch[0].split('>')[0] + '>';
  
  const hasIdOverview = heroTag.includes('id="overview"');
  const hasHeroBadge = hero.includes('class="hero-badge"') || hero.includes('hero-badge mb-3');
  const hasGlow = hero.includes('class="glow"');
  const hasStats = hero.includes('class="stat-n"');
  const hasCTA = hero.includes('btn-gv') || hero.includes('btn-gv-alt');
  
  console.log(
    `${page.padEnd(23)} | ${(hasIdOverview ? '✅' : '❌').padEnd(11)} | ` +
    `${(hasHeroBadge ? '✅' : '❌').padEnd(10)} | ` +
    `${(hasGlow ? '✅' : '❌').padEnd(4)} | ` +
    `${(hasStats ? '✅' : '❌').padEnd(5)} | ` +
    `${hasCTA ? '✅' : '❌'}`
  );
}

console.log('\n' + '='.repeat(80));
console.log('\n📝 RESUMEN:');
console.log('✅ = Tiene el elemento');
console.log('❌ = No tiene el elemento o está incompleto');
