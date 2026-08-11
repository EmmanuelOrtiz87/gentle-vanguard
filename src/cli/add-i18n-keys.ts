import * as fs from 'fs';

const filePath = 'docs/presentations/assets/js/i18n-content.js';
let content = fs.readFileSync(filePath, 'utf8');

// Claves para agregar
const keysEN = `  c_mdviewer_desc: 'Markdown viewer with real-time rendering',
  c_resources_desc: 'Central resource hub with indexed materials',
  c_socialpost_desc: 'Social media content generator',
  c_videostudio_desc: 'Native video generation with AI',
  sec_mdviewer: 'Markdown Viewer',
  sec_resources: 'Resource Index',
  sec_socialpost: 'Social Post Studio',
  sec_videostudio: 'Video Studio',
  c_mdviewer_content: 'View and render Markdown documentation',
  c_resources_content: 'Browse all available resources',
  c_socialpost_content: 'Generate social media content',
  c_videostudio_content: 'Create videos using AI generation',
`;

const keysES = `  c_mdviewer_desc: 'Visor de Markdown con renderizado en tiempo real',
  c_resources_desc: 'Hub central de recursos con materiales indexados',
  c_socialpost_desc: 'Generador de contenido para redes sociales',
  c_videostudio_desc: 'Generación nativa de video con IA',
  sec_mdviewer: 'Visor Markdown',
  sec_resources: 'Índice de Recursos',
  sec_socialpost: 'Estudio de Posts Sociales',
  sec_videostudio: 'Estudio de Video',
  c_mdviewer_content: 'Ver y renderizar documentación Markdown',
  c_resources_content: 'Explorar todos los recursos disponibles',
  c_socialpost_content: 'Generar contenido para redes sociales',
  c_videostudio_content: 'Crear videos usando generación con IA',
`;

// Insertar claves EN antes de }; window.__GV_CONTENT.es
const enMarker = '  c_securitygovernance_98:\n    \'Estructura del stack de seguridad y gobernanza — del núcleo de agentes al ciclo\r\n          ejecutivo autónomo.\',';
if (content.includes(enMarker) && !content.includes('c_mdviewer_desc:')) {
  content = content.replace(enMarker, enMarker + '\n' + keysEN);
  console.log('✅ EN keys added');
} else if (content.includes('c_mdviewer_desc:')) {
  console.log('✓ EN keys already exist');
}

// Insertar claves ES antes de }; window.__GV_CONTENT.pt-BR o final
const esEndMarker = 'window.__GV_CONTENT.pt-BR';
if (content.includes(esEndMarker) && !content.includes('sec_videostudio:')) {
  // Encontrar el }; antes de window.__GV_CONTENT.pt-BR
  const esBlock = content.substring(0, content.indexOf(esEndMarker));
  const lastBrace = esBlock.lastIndexOf('};');
  if (lastBrace > 0) {
    const before = content.substring(0, lastBrace);
    const after = content.substring(lastBrace);
    content = before + '\n' + keysES + after;
    console.log('✅ ES keys added');
  }
}

fs.writeFileSync(filePath, content);
console.log('✅ File saved');
