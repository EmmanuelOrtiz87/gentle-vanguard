# Pendientes Críticos - Gentle-Vanguard
## Resumen Ejecutivo para Acción Inmediata

**Fecha**: 2026-08-10  
**Item**: Pendientes Principales

---

## 🎯 TOP 5 PENDIENTES CRÍTICOS (Esta Semana)

### 🔴 #1: Persistencia del CMS (Máxima Prioridad)
**Dónde**: `docs/presentations/resources-index.html`  
**Problema**: Los archivos generados se pierden al cerrar el navegador
**Solución**: Implementar localStorage

```javascript
// Código pendiente a agregar:
function saveToLocalStorage(asset) {
  const assets = JSON.parse(localStorage.getItem('gv-assets') || '[]');
  assets.push({
    id: Date.now(),
    name: asset.name,
    type: asset.type, // 'image', 'video', 'post'
    content: asset.content, // Base64 o data URL
    createdAt: new Date().toISOString()
  });
  localStorage.setItem('gv-assets', JSON.stringify(assets));
}

// Al generar:
function generateImage() {
  const svg = generateSVG();
  saveToLocalStorage({
    name: 'imagen-' + Date.now() + '.svg',
    type: 'image',
    content: 'data:image/svg+xml;base64,' + btoa(svg)
  });
}
```

**Tiempo**: 2-3 horas

---

### 🔴 #2: Exportar PNG desde el CMS
**Dónde**: Panel de Imágenes en resources-index.html  
**Problema**: Solo exporta SVG, la mayoría necesita PNG
**Solución**: Agregar botón "Convertir a PNG"

```javascript
// Agregar función:
function exportAsPNG(svgElement) {
  const canvas = document.createElement('canvas');
  const ctx = canvas.getContext('2d');
  const img = new Image();
  
  img.onload = function() {
    canvas.width = img.width;
    canvas.height = img.height;
    ctx.drawImage(img, 0, 0);
    canvas.toBlob(function(blob) {
      // Descargar blob como PNG
    });
  };
  
  img.src = 'data:image/svg+xml;base64,' + btoa(svg);
}
```

**Tiempo**: 1 hora

---

### 🔴 #3: Navegación Consistente
**Dónde**: Todas las páginas .html excepto resources-index  
**Problema**: Falta link al CMS en el menú superior
**Solución**: Agregar este item a nav:

```html
<li class="nav-item">
  <a class="nav-link" href="resources-index.html">
    <i class="bi bi-grid me-1"></i>CMS
  </a>
</li>
```

**Páginas a actualizar** (10 min cada una):
- [ ] architecture.html
- [ ] dashboard.html
- [ ] autonomy.html
- [ ] agents-pipeline.html
- [ ] memory-knowledge.html
- [ ] patterns-conventions.html

**Tiempo Total**: 1 hora

---

### 🔴 #4: Implementar Doc-Gentle (Primeros pasos)
**Dónde**: `apps/doc-gentle/`  
**Estado**: Solo especificación, no código
**Comenzar con**:

```bash
mkdir apps/doc-gentle/src
cd apps/doc-gentle

# package.json ya existe, instalar dependencias:
npm install

# Crear estructura:
touch src/{App,Layout,Upload,Viewer,Summary}.tsx
touch src/main.tsx
```

**MVP Mínimo** (2 días):
1. Pantalla de subir PDF
2. Mostrar texto extraído
3. Input para preguntar
4. Mostrar respuesta

---

### 🔴 #5: Agregar Tests para Componentes Nuevos
**Dónde**: `tests/unit/`  
**Faltan tests**:

```typescript
// tests/unit/cms-storage.test.ts
test('should save to localStorage', () => {
  saveAsset({ name: 'test.svg', content: '<svg/>' });
  expect(localStorage.getItem('gv-assets')).toContain('test.svg');
});

// tests/unit/image-generator.test.ts
test('should generate SVG', () => {
  const svg = generateImage({ title: 'Test' });
  expect(svg).toContain('<svg');
  expect(svg).toContain('Test');
});

// tests/unit/video-agent.test.ts
test('should generate frames', () => {
  const frames = generateFrames(['Step 1', 'Step 2']);
  expect(frames).toHaveLength(2);
});
```

**Tiempo**: 2-3 horas

---

## 📋 PENDIENTES DE MEDIANA IMPORTANCIA (Mes Siguiente)

### 🟡 #6: Compilación Real de Video
**Problema**: Solo frames HTML, no MP4  
**Soluciones**:
- **A) FFmpeg nativo**: Requiere usuario tenga FFmpeg instalado
- **B) FFmpeg.wasm**: Agrega 25MB al bundle
- **C** Documentar proceso manual**

**Recomendación**: Opción C por ahora (instrucciones claras)

---

### 🟡 #7: Historial en CMS
**Feature**: Ver todos los assets generados previamente  
**Beneficio**: Reutilizar, modificar, descargar de nuevo

```javascript
// Agregar sección "Historial"
const assets = JSON.parse(localStorage.getItem('gv-assets') || '[]');
assets.forEach(asset => {
  // Mostrar en grid con thumbnail, fecha, botones
});
```

---

### 🟡 #8: Mejorar UI del Chat
**Problema**: Chat básico, no interactivo  
**Mejoras**:
- Botones de acción rápida
- Indicador "escribiendo..."
- Avatares visuales
- Formato Markdown en respuestas

---

### 🟡 #9: Previews Realistas
**Problema**: Preview muy básico  
**Solución**: Mostrar cómo se vería en cada red social
- Vista previa de LinkedIn feed
- Vista previa de Instagram
- Mockup de Twitter/X

---

### 🟡 #10: Landing de Doc-Gentle
**Dónde**: `docs/presentations/doc-gentle.html`  
**Contenido**:
- Hero con valor proposition
- Demo video (generado con Video Agent)
- Features list
- Pricing
- CTA "Comenzar ahora"

---

## ✅ QUÉ ESTÁ COMPLETAMENTE LISTO

| Componente | Estado | Notas |
|------------|--------|-------|
| Stack principal | ✅ | 100% operativo |
| Orquestación | ✅ | 21 agentes funcionando |
| Health checks | ✅ | 82/82 pasando |
| Tests core | ✅ | 103 tests pasando |
| Presentaciones | ✅ | 12 páginas HTML completas |
| CMS Dashboard | ✅ | Panel principal operativo |
| Visor Markdown | ✅ | md-viewer.html funciona |
| Agente chat | ✅ | Básico pero operativo |
| Generador SVG | ✅ | Funciona nativo |
| Generador posts | ✅ | 3 idiomas |
| Contratos | ✅ | Legales listos |
| Theme toggle | ✅ | Claro/oscuro |

---

## 📊 COMPARATIVO: ANTES vs DESPUÉS

### Antes de estos pendientes:
```
Funcionalidad:    70%
UX:              60%
Persistencia:     0%
Polish:          50%
```

### Después de estos pendientes:
```
Funcionalidad:    95%
UX:              90%
Persistencia:   100%
Polish:          85%
```

---

## ⏱️ TIEMPO TOTAL ESTIMADO

| Tarea | Tiempo | Costo |
|-------|--------|-------|
| #1 Persistencia CMS | 3h | Bajo |
| #2 Export PNG | 1h | Bajo |
| #3 Navegación | 1h | Bajo |
| #4 Tests | 3h | Bajo |
| #5 Doc-Gentle MVP | 2 días | Medio |
| Total | ~3 días | ~$500-1000 |

---

## 🎁 BONUS: Quick Wins (30 min cada uno)

1. **Agregar favicon** al CMS
2. **Título dinámico** según sección
3. **Keyboard shortcut** Ctrl+Enter para enviar chat
4. **Toast notifications** para "Generado exitosamente"
5. **Progress bar** en generación de video

---

## 🚀 PRÓXIMO CICLO DE DESARROLLO

**Semana 1**: Críticos (#1-#5)  
**Semana 2**: Doc-Gentle MVP  
**Semana 3**: Polish + Tests  
**Semana 4**: Landing + Launch

---

**¿Comenzamos con la persistencia del CMS?** 🔴
