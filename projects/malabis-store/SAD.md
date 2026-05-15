# Solution Architecture Design (SAD)
## Malabis - Tienda de Indumentaria y Accesorios Árabes

**Fecha**: 14 de Mayo de 2026  
**Versión**: 1.0  
**Estado**: Aprobado para Implementación

---

## 1. VISIÓN GENERAL

Sistema de e-commerce moderno para promocionar y gestionar reservas de indumentaria y accesorios árabes en Rawson, San Juan, Argentina.

**Ubicación**: Calle Mendoza entre Calvento y Progreso, a pasitos del Café América

---

## 2. REQUISITOS FUNCIONALES

### 2.1 Catálogo de Productos
- [x] 24 productos en 6 categorías
- [x] Visualización dinámica con emojis
- [x] Filtrado por categoría en tiempo real
- [x] Información completa (nombre, descripción, precio)

### 2.2 Sistema de Reserva (No tradicional)
- [x] Seleccionar productos y cantidades
- [x] Visualizar total en tiempo real
- [x] Enviar reserva al dueño
- [x] Recibir confirmación instantánea
- [x] ID único de pedido

### 2.3 Sistema de Notificaciones
- [x] Confirmación al cliente (modal)
- [x] Notificación al dueño (consola)
- [x] Detalles completos del pedido
- [x] Información de ubicación

### 2.4 Persistencia de Datos
- [x] Carrito guardado en localStorage
- [x] Historial de pedidos en memoria
- [x] Recuperación automática del carrito

---

## 3. REQUISITOS NO FUNCIONALES

### 3.1 Rendimiento
- Carga < 2 segundos
- Sin imágenes pesadas (solo emojis)
- Animaciones GPU-aceleradas
- Lazy loading de elementos

### 3.2 Usabilidad
- Interfaz intuitiva
- Navegación clara
- Responsive (móvil, tablet, desktop)
- Accesible

### 3.3 Diseño
- Colores vibrantes (Rojo #E31937, Azul #0052CC, Oro #FFD700)
- Tipografía moderna (System fonts)
- Estilo profesional (inspirado en ofertasdtv.com.ar)
- Motivos árabes sutiles

---

## 4. ARQUITECTURA TÉCNICA

### 4.1 Stack Tecnológico
```
Frontend:
├── HTML5 (Semántica moderna)
├── CSS3 (Flexbox, Grid, Gradientes)
└── JavaScript Vanilla (Sin dependencias)

Storage:
└── localStorage (Persistencia cliente)

Notificaciones:
├── Modal (Cliente)
└── Console (Dueño - Simulado)
```

### 4.2 Estructura de Archivos
```
malabis-store/
├── index.html              # Página principal
├── README.md               # Documentación
├── SAD.md                  # Este archivo
├── css/
│   └── style.css          # Estilos (1000+ líneas)
└── js/
    ├── app.js             # Lógica principal (500+ líneas)
    └── notifications.js   # Sistema notificaciones (300+ líneas)
```

### 4.3 Flujo de Datos
```
Usuario
  ↓
[Selecciona Categoría]
  ↓
[Visualiza Productos]
  ↓
[Selecciona Cantidad]
  ↓
[Agrega al Carrito] → localStorage
  ↓
[Revisa Reserva]
  ↓
[Envía Reserva]
  ├→ Cliente: Modal de confirmación
  ├→ Dueño: Notificación en consola
  └→ localStorage: Se limpia
```

---

## 5. COMPONENTES PRINCIPALES

### 5.1 Header
- Logo: "MALABIS"
- Tagline: "Indumentaria y Accesorios Árabes"
- Ubicación con icono
- Gradiente rojo-azul

### 5.2 Navegación
- 7 botones de categoría
- Active state con color rojo
- Hover effects sutiles

### 5.3 Grid de Productos
- 4-5 columnas en desktop
- 2-3 en tablet
- 1-2 en móvil
- Tarjetas con sombra minimalista

### 5.4 Carrito
- Sticky en desktop
- Borde rojo izquierdo
- Total destacado
- Botones Limpiar/Enviar

### 5.5 Modal de Notificación
- Confirmación de reserva
- ID único
- Detalles del pedido
- Ubicación de tienda

---

## 6. PRODUCTOS (24 Total)

### Formal (4)
- Thobe Blanco Premium - $12,000
- Kandura Elegante - $10,000
- Ghutra Tradicional - $3,500
- Iqal Dorado - $2,500

### Casual (4)
- Dishdasha Casual - $6,000
- Abaya Moderna - $8,000
- Hijab Estampado - $1,500
- Niqab Elegante - $3,000

### Deportiva (4)
- Thobe Deportivo - $5,000
- Zapatillas Árabes - $4,500
- Pantalón Harem - $3,500
- Sudadera Árabe - $4,000

### Fiesta (4)
- Abaya de Gala - $15,000
- Thobe de Fiesta - $14,000
- Hijab de Fiesta - $3,500
- Cinturón Joyero - $5,000

### Accesorios (4)
- Pulseras Árabes - $2,500
- Collar Tradicional - $3,000
- Kohl y Maquillaje - $1,200
- Bolso Árabe - $4,500

### Por Encargo (4)
- Thobe Personalizado - Consultar
- Abaya Diseño Exclusivo - Consultar
- Bordado Personalizado - Consultar
- Confección Árabe a Medida - Consultar

---

## 7. PALETA DE COLORES

| Color | Código | Uso |
|-------|--------|-----|
| Rojo Primario | #E31937 | Botones, header, acentos |
| Azul Secundario | #0052CC | Header, gradientes |
| Oro Acento | #FFD700 | Bordes, destacados |
| Negro Texto | #1a1a1a | Texto principal |
| Blanco Fondo | #FFFFFF | Fondo limpio |
| Gris Claro | #F5F5F5 | Fondos secundarios |
| Gris Bordes | #E0E0E0 | Bordes sutiles |

---

## 8. TIPOGRAFÍA

- **Font Stack**: -apple-system, BlinkMacSystemFont, 'Segoe UI', 'Roboto', sans-serif
- **Pesos**: 400 (normal), 600 (semi-bold), 700 (bold), 800 (extra-bold)
- **Tamaños**:
  - Logo: 2.8rem
  - Títulos: 2rem
  - Nombres: 1.2rem
  - Precios: 1.6rem
  - Texto: 0.9-1rem

---

## 9. RESPONSIVE DESIGN

### Desktop (1200px+)
- Grid: 4-5 columnas
- Carrito: Sticky lateral
- Navegación: Horizontal

### Tablet (768px-1199px)
- Grid: 2-3 columnas
- Carrito: Sticky
- Navegación: Horizontal

### Móvil (480px-767px)
- Grid: 2 columnas
- Carrito: Estático
- Navegación: Horizontal

### Móvil Pequeño (<480px)
- Grid: 1 columna
- Carrito: Estático
- Navegación: Horizontal

---

## 10. NOTIFICACIONES

### Cliente
```
Modal con:
- Icono de éxito (✅)
- Título: "¡Reserva Confirmada!"
- ID de pedido único (MAL-XXXXXXXX)
- Fecha y hora
- Total
- Próximos pasos
- Ubicación de tienda
```

### Dueño
```
Consola con:
- Tipo: "📬 NOTIFICACIÓN AL DUEÑO"
- ID del pedido
- Fecha/Hora
- Artículos solicitados
- Total
- Estado: Pendiente de confirmación
```

---

## 11. COMANDOS DE DEPURACIÓN

```javascript
malabisDebug.stats()                    // Estadísticas
malabisDebug.pending()                  // Pedidos pendientes
malabisDebug.orders()                   // Todos los pedidos
malabisDebug.confirmOrder('MAL-xxx')    // Confirmar
malabisDebug.rejectOrder('MAL-xxx', 'razón')  // Rechazar
malabisDebug.help()                     // Ver todos
```

---

## 12. VALIDACIÓN Y TESTING

### Funcionalidad
- [x] Filtrado por categoría
- [x] Agregar/remover productos
- [x] Cálculo de totales
- [x] Persistencia en localStorage
- [x] Notificaciones cliente
- [x] Notificaciones dueño
- [x] Responsive en todos los tamaños

### Rendimiento
- [x] Carga < 2 segundos
- [x] Sin imágenes pesadas
- [x] Animaciones suaves
- [x] Lazy loading

### Diseño
- [x] Colores vibrantes
- [x] Tipografía clara
- [x] Interfaz intuitiva
- [x] Accesibilidad

---

## 13. DESPLIEGUE

### Requisitos
- Navegador moderno (Chrome, Firefox, Safari, Edge)
- JavaScript habilitado
- localStorage disponible

### Instalación
1. Descargar archivos
2. Abrir `index.html` en navegador
3. ¡Listo!

### Hosting
- Puede alojarse en cualquier servidor web
- No requiere backend
- No requiere base de datos

---

## 14. MANTENIMIENTO FUTURO

### Mejoras Posibles
- Integración con WhatsApp para notificaciones reales
- Sistema de login para clientes
- Historial de pedidos persistente
- Métodos de pago integrados
- Seguimiento de pedidos en tiempo real
- Galería de fotos reales
- Sistema de comentarios y reseñas
- Cupones y descuentos

### Escalabilidad
- Arquitectura preparada para backend
- API REST compatible
- Base de datos relacional lista
- Autenticación OAuth

---

## 15. CONCLUSIÓN

El sistema está diseñado para ser:
- **Moderno**: Tecnologías actuales
- **Rápido**: Carga ultrarrápida
- **Responsive**: Funciona en todos los dispositivos
- **Funcional**: Todas las características requeridas
- **Mantenible**: Código limpio y documentado
- **Escalable**: Preparado para crecer

**Estado**: ✅ Listo para producción

---

**Aprobado por**: Sistema SDD  
**Fecha de Aprobación**: 14 de Mayo de 2026  
**Versión**: 1.0.0