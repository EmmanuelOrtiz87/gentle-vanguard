# 🚀 PLAN DE ACCIÓN - COMPLETAR FUNCIONALIDADES PENDIENTES

> **Objetivo**: Llevar Gentle-Vanguard al 100% de operatividad en todas las herramientas

---

## 📊 ESTADO ACTUAL

```
Core Stack:        ████████████████████ 100% ✅
Agentes:           ████████████████████ 100% ✅
Skills:            ████████████████████ 100% ✅
CMS:               ████████████████████ 100% ✅
Image Studio:      ████████████████░░░░  80% ⚠️
Video Generation:  ████████████░░░░░░░░  60% ⚠️
Social Poster:     ████████████░░░░░░░░  60% ⚠️
Contract Viewer:   ░░░░░░░░░░░░░░░░░░░░   0% ❌
Product Pages:     ░░░░░░░░░░░░░░░░░░░░   0% ❌
```

---

## 🎯 FASE 1: COMPLETAR IMAGE STUDIO (Prioridad: ALTA)

### 1.1 Video Frames Generator (Image Studio v1.1)

**Objetivo**: Agregar capacidad de generar secuencias de frames para video animado

**Capacidades a agregar**:

- [ ] Panel de frames con timeline
- [ ] Generación de keyframes
- [ ] Interpolación entre frames
- [ ] Exportar como secuencia PNG/frames/
- [ ] Opcional: Generar MP4 via FFmpeg

**Implementación**:

```javascript
class VideoFrameGenerator {
  frames = [];
  frameRate = 30;

  generateSequence(config) {
    // Generar N frames con progresión
    for (let i = 0; i < config.frameCount; i++) {
      const progress = i / (config.frameCount - 1);
      this.generateFrame(progress, config);
    }
  }

  generateFrame(progress, config) {
    // Canvas para cada frame
    // Animar parámetros basado en progress
  }

  exportSequence() {
    // Descargar ZIP con frames
    // Opcional: Render MP4 via WASM FFmpeg
  }
}
```

**Tiempo estimado**: 2-3 horas **Complejidad**: Media **Dependencias**: Canvas API, (optional)
ffmpeg.wasm

---

### 1.2 Batch Processing

**Capacidad**: Generar múltiples variantes de un template simultáneamente

**Implementación**:

```javascript
// Ejemplo: "Generate 5 banner variations"
// Produce: variant_01.png, variant_02.png, etc.
batchGenerate({ count: 5, seed: 'doc-gentle', variations: ['color', 'complexity', 'effects'] });
```

**Tiempo estimado**: 45 minutos **Complejidad**: Baja

---

### 1.3 Presets Personalizables

**Capacidad**: Guardar configuraciones personalizadas del usuario

**Implementación**:

```javascript
localStorage.setItem(
  'studio-presets',
  JSON.stringify([
    { name: 'Doc-Gentle Brand', template: 'neon-cyberpunk', palette: 'neon', complexity: 6 },
  ]),
);
```

**Tiempo estimado**: 30 minutos **Complejidad**: Baja

---

## 🎬 FASE 2: VIDEO GENERATION COMPLETO (Prioridad: ALTA)

### 2.1 Video Studio HTML

**Nuevo archivo**: `docs/presentations/video-studio.html`

**Capacidades**:

- [ ] Generador de frames secuenciales
- [ ] Timeline con preview de frames
- [ ] Animaciones predefinidas (zoom, pan, fade)
- [ ] Transiciones entre escenas
- [ ] Audio overlay (opcional)
- [ ] Exportar:
  - [ ] Secuencia PNG
  - [ ] GIF animado
  - [ ] MP4 (WebCodecs API o FFmpeg WASM)

**Algoritmos de animación**:

```javascript
const animations = {
  zoomIn: { scale: { start: 1, end: 1.5 } },
  panLeft: { x: { start: 0, end: -0.2 } },
  fade: { opacity: { start: 0, end: 1 } },
  rotate: { rotation: { start: 0, end: 360 } },
  pulse: { scale: { keyframes: [1, 1.1, 1] } },
};
```

**Tiempo estimado**: 4-5 horas **Complejidad**: Alta **Dependencias**: Image Studio base, (optional)
FFmpeg.wasm

---

### 2.2 SDK de Video Nativo

**Nuevo archivo**: `src/video-studio.ts`
<!-- REF-OBSOLETA: src/video-studio.ts no existe (ruta migrada o eliminada) -->

**API para programación**:

```typescript
import { VideoStudio } from './video-studio';

const video = new VideoStudio({
  width: 1920,
  height: 1080,
  fps: 30,
});

video.addScene({
  duration: 5,
  generator: 'network',
  animation: 'zoomIn',
  transition: 'fade',
});

video.addScene({
  duration: 3,
  generator: 'particles',
  animation: 'panLeft',
  transition: 'slide',
});

await video.render('demo.mp4');
```

**Tiempo estimado**: 3-4 horas **Complejidad**: Alta

---

## 📱 FASE 3: SOCIAL POSTER COMPLETO (Prioridad: MEDIA-ALTA)

### 3.1 Social Post Generator HTML

**Nuevo archivo**: `docs/presentations/social-poster.html`

**Capacidades**:

- [ ] Templates de posts predefinidos (200+)
- [ ] WYSIWYG editor visual
- [ ] Auto-hashtags y mentions
- [ ] Preview en tiempo real para cada plataforma
- [ ] Scheduling simulado
- [ ] Exportar CSV/JSON de contenido

**Integraciones a implementar** (modo simulado primero):

- [ ] LinkedIn API (modo simulado)
- [ ] Twitter/X API (modo simulado)
- [ ] Instagram Basic Display API (modo simulado)
- [ ] Buffer API (modo simulado)

**Mode Simulado**:

```javascript
// Primero implementar modo local
const socialPoster = {
  mode: 'simulation', // 'simulation' | 'production'
  platform: 'linkedin',
  content: generatedPost,
  schedule: '2026-08-15T10:00:00Z',

  simulatePost() {
    // Guardar en localStorage como "scheduled"
    // Mostrar preview realista
    return {
      success: true,
      simulated: true,
      url: 'https://linkedin.com/post/simulated-123',
      preview: this.generatePreview(),
    };
  },
};
```

**Tiempo estimado**: 5-6 horas **Complejidad**: Media-Alta **Dependencias**: Content templates,
Image Studio

---

### 3.2 Content Calendar Simulado

**Capacidad**: Planificar posts en calendario visual

**Implementación**:

- Calendario semanal/mensual
- Drag & drop de posts
- Sugerencias de horarios óptimos
- Métricas simuladas (engagement)

**Tiempo estimado**: 2-3 horas **Complejidad**: Media

---

## 📄 FASE 4: CONTRACT VIEWER (Prioridad: MEDIA)

### 4.1 Contract Viewer HTML

**Nuevo archivo**: `docs/presentations/contract-viewer.html`

**Capacidades**:

- [ ] Listar todos los contratos
- [ ] Preview de contrato con markdown renderizado
- [ ] Firmar digitalmente (simulado)
- [ ] Estado de contrato (draft, sent, signed, expired)
- [ ] Comparar versiones
- [ ] Exportar PDF
- [ ] Historial de cambios

**Datos**:

```javascript
const contracts = [
  {
    id: 'GV-CONSULTING-2025',
    type: 'consulting',
    client: 'Cliente Ejemplo',
    status: 'signed',
    amount: 15000,
    signed: '2025-03-15',
    expires: '2025-09-15',
  },
  // ... más contratos
];
```

**Contratos a manejar**:

1. Consulting Services Agreement
2. SLA Agreement
3. Privacy Policy
4. Terms of Service

**Tiempo estimado**: 3-4 horas **Complejidad**: Media **Dependencias**: md-viewer.html (ya existe)

---

## 🏪 FASE 5: PRODUCT PAGES (Prioridad: MEDIA)

### 5.1 Product Showcase HTML

**Nuevo archivo**: `docs/presentations/product-pages.html`

**Capacidades**:

- [ ] Listado de productos/servicios
- [ ] Landing page por producto
- [ ] Generador de landing pages
- [ ] A/B testing simulado
- [ ] Analytics simulado

**Productos a mostrar**:

1. Doc-Gentle - Documentación automatizada - $5,000-$10,000
2. Gentle-AI Core - Stack completo - $15,000-$50,000
3. Gentle-AI Training - Capacitación - $1,500/día
4. Agente Custom - Desarrollo - $500/día
5. Consulting Services - Consultoría - Cotización

**Tiempo estimado**: 3-4 horas **Complejidad**: Media **Dependencias**: Image Studio (para assets)

---

## 🔧 FASE 6: MEJORAS TÉCNICAS (Prioridad: CONTINUA)

### 6.1 Web Research Integration

**Capacidad**: Integrar web crawler existente con CMS

**Uso desde asistente**:

```
Usuario: "Research sobre últimas tendencias de AI"
Asistente: "Buscando información..." → Abre web-research.html
```

**Tiempo estimado**: 2 horas **Complejidad**: Media **Dependencias**: src/web-research-select.ts (ya
existe)

---

### 6.2 Offline Storage Centralizado

**Nuevo**: Unificar storage en Nexus DB + LocalStorage

**Implementación**:

```javascript
// Unified Storage API
const gvStorage = {
  // Session-level (localStorage)
  session: { set, get, remove },

  // Persistent (Nexus DB)
  persistent: { save, load, query },

  // Offline-first (Service Worker + IndexedDB)
  offline: { save, sync, queue },
};
```

**Tiempo estimado**: 4-5 horas **Complejidad**: Alta **Dependencias**: Nexus DB, Service Worker

---

## 📅 CRONOGRAMA SUGERIDO

### Semana 1 (Fase 1-2)

| Día       | Tarea                      | Horas |
| --------- | -------------------------- | ----- |
| Lunes     | Video Frame Generator      | 4h    |
| Martes    | Video Studio HTML          | 5h    |
| Miércoles | Video SDK                  | 4h    |
| Jueves    | Batch Processing + Presets | 2h    |
| Viernes   | Testing Video              | 3h    |

### Semana 2 (Fase 3)

| Día       | Tarea                      | Horas |
| --------- | -------------------------- | ----- |
| Lunes     | Social Post Generator UI   | 5h    |
| Martes    | Templates + Editor         | 4h    |
| Miércoles | Content Calendar           | 3h    |
| Jueves    | API Integration (simulado) | 4h    |
| Viernes   | Testing Social             | 3h    |

### Semana 3 (Fase 4-5)

| Día       | Tarea               | Horas |
| --------- | ------------------- | ----- |
| Lunes     | Contract Viewer     | 4h    |
| Martes    | Contract Management | 3h    |
| Miércoles | Product Pages UI    | 4h    |
| Jueves    | Product Generator   | 3h    |
| Viernes   | Integration Testing | 4h    |

### Semana 4 (Fase 6 + Testing)

| Día       | Tarea                    | Horas |
| --------- | ------------------------ | ----- |
| Lunes     | Web Research Integration | 4h    |
| Martes    | Offline Storage          | 5h    |
| Miércoles | End-to-End Testing       | 4h    |
| Jueves    | Documentation            | 3h    |
| Viernes   | Final Polish             | 4h    |

**Total**: ~80 horas (4 semanas)

---

## 🎨 ESPECIFICACIONES DE DISEÑO

### Estilo Visual (Consistente)

```css
:root {
  /* Backgrounds */
  --bg0: #0a0e1a;
  --bg1: #111827;
  --bg2: #1f2937;

  /* Colors */
  --p: #22d3ee;   /* Primary */
  --s: #a78bfa;   /* Secondary */
  --a: #34d399;   /* Accent */

  /* Text */
  --text: #e2e8f0;
  --text-dim: #94a3b8;
  --text-faint: #64748b;
}

/* Componentes */
.btn-gv {
  background: linear-gradient(135deg, var(--p), var(--s));
  color: var(--bg0);
  font-weight: 600;
  border-radius: 8px;
  padding: 0.75rem 1.5rem;
}

.card-gv {
  background: var(--bg1);
  border: 1px solid var(--bg2);
  border-radius: 12px;
}

/* Gradients */
.gradient-p { linear-gradient(135deg, #22d3ee, #a78bfa); }
.gradient-g { linear-gradient(135deg, #34d399, #22d3ee); }
.gradient-w { linear-gradient(135deg, #fbbf24, #f87171); }
```

### Iconography

- Bootstrap Icons (ya en uso)
- Lucide Icons (para nuevos componentes)
- Custom SVG icons (si necesario)

### Typography

- **Primary**: Inter
- **Mono**: JetBrains Mono
- **Fallback**: system-ui

---

## 🔗 INTEGRACIONES NECESARIAS

### CMS Integration

Toda herramienta nueva debe:

1. ✅ Tener botón en resources-index.html sidebar
2. ✅ Ser accesible desde asistente IA
3. ✅ Compartir storage (localStorage/Nexus)
4. ✅ Exportar assets a directorio export/
5. ✅ Tener preview/thumbnail en lista

### Account Integration

```javascript
// Perfil de usuario compartido
const userProfile = {
  name: 'Usuario',
  email: 'user@example.com',
  avatar: localStorage.getItem('user-avatar'),
  preferences: JSON.parse(localStorage.getItem('user-prefs')),
  apiKeys: {
    linkedin: null, // Se configura
    twitter: null,
    instagram: null,
  },
};

// API Configuration
const apiConfig = {
  mode: 'simulation', // 'simulation' | 'production'
  verbose: true,
  fallback: true,
};
```

---

## 📊 CRITERIOS DE ÉXITO

### Definition of Done

Para cada herramienta:

- [ ] ✅ Archivo HTML funcional standalone
- [ ] ✅ Integración con resources-index.html
- [ ] ✅ Accesible desde asistente IA
- [ ] ✅ Documentación en README
- [ ] ✅ 3+ casos de uso documentados
- [ ] ✅ Export funcional (PNG/SVG/JSON)
- [ ] ✅ Responsive design
- [ ] ✅ Modo simulado funcional
- [ ] ✅ Tests manuales pass
- [ ] ✅ Sin errores en consola

---

## 🚀 PROXIMOS PASOS INMEDIATOS

1. **Implementar Video Studio** (Prioridad #1)
   - Crear video-studio.html
   - Timeline de frames
   - Export secuencia PNG
   - Preview GIF

2. **Completar Social Poster** (Prioridad #2)
   - Editor WYSIWYG
   - Templates
   - Preview multi-plataforma

3. **Agregar Contract Viewer** (Prioridad #3)
   - Listar contratos
   - Preview markdown
   - Estado tracking

4. **Mejorar Image Studio** (Prioridad #4)
   - Animación de frames
   - Batch processing
   - Presets

5. **Crear Product Pages** (Prioridad #5)
   - Showcases
   - Generator
   - Analytics simulado

---

## 💡 RECURSOS Y REFERENCIAS

### Para Video:

- [FFmpeg.wasm](https://github.com/ffmpegwasm/ffmpeg.wasm) - Compilar video en el navegador
- [WebCodecs API](https://developer.mozilla.org/en-US/docs/Web/API/WebCodecs_API) - Native video
  encoding
- [Canvas CaptureStream](https://developer.mozilla.org/en-US/docs/Web/API/HTMLCanvasElement/captureStream)

### Para Social:

- [LinkedIn API](https://docs.microsoft.com/en-us/linkedin/)
- [Twitter API v2](https://developer.twitter.com/en/docs/twitter-api)
- [Instagram Basic Display](https://developers.facebook.com/docs/instagram-basic-display-api)

### Para Animaciones:

- [Lottie](https://airbnb.io/lottie/) - Animaciones JSON
- [GSAP](https://greensock.com/gsap/) - Timeline animations
- [Canvas Confetti](https://github.com/catdad/canvas-confetti) - Efectos

---

## ✅ CHECKLIST DE IMPLEMENTACIÓN

- [ ] Fase 1: Video Frame Generator
- [ ] Fase 1: Batch Processing
- [ ] Fase 1: Presets
- [ ] Fase 2: Video Studio HTML
- [ ] Fase 2: Video SDK
- [ ] Fase 3: Social Post Generator
- [ ] Fase 3: Content Calendar
- [ ] Fase 4: Contract Viewer
- [ ] Fase 5: Product Pages
- [ ] Fase 6: Web Research Integration
- [ ] Fase 6: Offline Storage
- [ ] Documentation complete
- [ ] Testing e2e
- [ ] Release v1.0 Tools Suite

---

**¿Iniciar implementación de Fase 1 (Video Studio)?** 🎬
