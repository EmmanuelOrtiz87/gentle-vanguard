import * as fs from 'fs';
import * as path from 'path';

const corrections = [
  // Páginas que necesitan agregar id="overview" al hero
  { 
    file: 'memory-knowledge.html', 
    fix: 'add-id-overview',
    description: 'Agregar id="overview" al hero'
  },
  { 
    file: 'dashboard.html', 
    fix: 'add-id-overview',
    description: 'Agregar id="overview" al hero'
  },
  { 
    file: 'health.html', 
    fix: 'add-id-overview',
    description: 'Agregar id="overview" al hero'
  },
  { 
    file: 'operations-cloud.html', 
    fix: 'add-id-overview',
    description: 'Agregar id="overview" al hero'
  },
  { 
    file: 'patterns-conventions.html', 
    fix: 'add-id-overview',
    description: 'Agregar id="overview" al hero'
  },
  { 
    file: 'quickstart.html', 
    fix: 'add-id-overview',
    description: 'Agregar id="overview" al hero'
  },
];

console.log('CORRIGIENDO HEROES\n' + '='.repeat(60));

for (const item of corrections) {
  const filePath = path.join('docs/presentations', item.file);
  
  if (!fs.existsSync(filePath)) {
    console.log(`❌ ${item.file} - No existe`);
    continue;
  }
  
  let content = fs.readFileSync(filePath, 'utf8');
  
  if (item.fix === 'add-id-overview') {
    // Verificar si ya tiene id="overview"
    if (content.includes('<header class="hero" id="overview">')) {
      console.log(`✓ ${item.file} - Ya tiene id="overview"`);
      continue;
    }
    
    // Reemplazar <header class="hero"> por <header class="hero" id="overview">
    // Pero hay variaciones posibles, manejar casos
    const original = content;
    
    // Caso 1: <header class="hero">
    content = content.replace(
      /<header class="hero"[^>]*>/,
      '<header class="hero" id="overview">'
    );
    
    if (content !== original) {
      fs.writeFileSync(filePath, content);
      console.log(`✅ ${item.file} - id="overview" agregado`);
    } else {
      console.log(`⚠️  ${item.file} - No se pudo aplicar cambio`);
    }
  }
}

console.log('\n' + '='.repeat(60));
console.log('✅ Proceso completado');
