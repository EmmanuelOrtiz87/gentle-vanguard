# 🛍️ MALABIS - Tienda de Ropa Online

Página web moderna y dinámica para promocionar la tienda de ropa **Malabis** ubicada en Rawson, San Juan, Argentina.

## 📍 Ubicación

**Calle Mendoza entre Calvento y Progreso**  
A pasitos del Café América  
Rawson - San Juan - Argentina

## 🎯 Características Principales

### 1. **Catálogo de Productos**
- 24 productos distribuidos en 6 categorías
- Visualización dinámica con emojis representativos
- Filtrado por categoría en tiempo real
- Información detallada de cada producto (nombre, descripción, precio)

### 2. **Categorías de Ropa**
- 👔 **Formal** - Trajes, camisas, pantalones elegantes
- 👕 **Informal** - Remeras, jeans, hoodies, shorts
- 🏃 **Deportiva** - Conjuntos deportivos, zapatillas, accesorios
- 👗 **De Fiesta** - Vestidos, trajes de gala, blusas brillantes
- 👜 **Accesorios** - Cinturones, gorros, bufandas, bolsos
- 🎨 **Por Encargo** - Diseños personalizados, bordados, estampados

### 3. **Sistema de Reserva (No es un carrito tradicional)**
- Selecciona productos y cantidades
- Visualiza el total en tiempo real
- Envía la reserva al dueño
- Recibe confirmación instantánea
- El cliente debe realizar un depósito para confirmar

### 4. **Sistema de Notificaciones**
- **Para el Cliente**: Confirmación inmediata de reserva
- **Para el Dueño**: Notificación de nuevo pedido (simulada en consola)
- Detalles completos del pedido (ID, fecha, total, artículos)
- Información de ubicación de la tienda

### 5. **Diseño Moderno**
- Colores llamativos y vibrantes
- Gradientes atractivos
- Animaciones suaves
- Interfaz intuitiva y fácil de usar
- Totalmente responsive (móvil, tablet, desktop)

### 6. **Rendimiento Optimizado**
- Carga rápida de la página
- Lazy loading de imágenes
- LocalStorage para persistencia del carrito
- Animaciones CSS optimizadas
- Código JavaScript eficiente

## 🚀 Cómo Usar

### Instalación
1. Descarga o clona los archivos del proyecto
2. Abre `index.html` en tu navegador web
3. ¡Listo! La página está lista para usar

### Flujo de Compra
1. **Explora** - Navega por las categorías de productos
2. **Selecciona** - Elige productos y cantidades
3. **Agrega** - Haz clic en "Agregar" para añadir al carrito
4. **Revisa** - Verifica tu reserva en el panel lateral
5. **Envía** - Presiona "Enviar Reserva" para confirmar
6. **Confirma** - Recibirás confirmación con ID de pedido

## 🎨 Paleta de Colores

| Color | Código | Uso |
|-------|--------|-----|
| Rojo Coral | #FF6B6B | Primario, botones principales |
| Turquesa | #4ECDC4 | Secundario, acentos |
| Amarillo | #FFE66D | Acento, totales |
| Gris Oscuro | #2C3E50 | Texto, fondos oscuros |
| Gris Claro | #ECF0F1 | Fondos, elementos secundarios |

## 📱 Responsive Design

- **Desktop** (1200px+): Grid de 4-5 productos
- **Tablet** (768px-1199px): Grid de 2-3 productos
- **Móvil** (480px-767px): Grid de 2 productos
- **Móvil Pequeño** (<480px): Grid de 1 producto

## 🔧 Estructura de Archivos

```
malabis-store/
├── index.html              # Página principal
├── css/
│   └── style.css          # Estilos CSS
├── js/
│   ├── app.js             # Lógica principal
│   └── notifications.js   # Sistema de notificaciones
└── README.md              # Este archivo
```

## 📊 Base de Datos de Productos

La aplicación incluye 24 productos precargados:

### Formal (4 productos)
- Traje Ejecutivo - $15,000
- Camisa Formal - $3,500
- Pantalón Formal - $5,000
- Corbata Premium - $1,200

### Informal (4 productos)
- Remera Casual - $1,500
- Jeans Premium - $4,500
- Hoodie Moderno - $3,200
- Shorts Casual - $2,000

### Deportiva (4 productos)
- Conjunto Deportivo - $4,500
- Zapatillas Running - $6,000
- Medias Deportivas - $800
- Campera Deportiva - $5,500

### De Fiesta (4 productos)
- Vestido Elegante - $8,000
- Traje de Gala - $18,000
- Blusa Brillante - $4,000
- Pantalón Fiesta - $5,500

### Accesorios (4 productos)
- Cinturón Cuero - $1,800
- Gorro Invierno - $900
- Bufanda Elegante - $1,500
- Bolso Moda - $3,500

### Por Encargo (4 productos)
- Diseño Personalizado - Consultar
- Bordado Personalizado - Consultar
- Estampado Especial - Consultar
- Confección a Medida - Consultar

## 🔔 Sistema de Notificaciones

### Notificación al Cliente
Cuando el cliente envía una reserva, recibe:
- Confirmación de reserva
- ID único del pedido
- Fecha y hora
- Total a pagar
- Próximos pasos (depósito, confirmación)
- Ubicación de la tienda

### Notificación al Dueño
El dueño recibe notificación (simulada en consola) con:
- ID del pedido
- Fecha y hora
- Artículos solicitados
- Total del pedido
- Cantidad de items
- Estado: Pendiente de confirmación

## 🛠️ Comandos de Depuración

Abre la consola del navegador (F12) y usa estos comandos:

```javascript
// Ver estadísticas
malabisDebug.stats()

// Ver pedidos pendientes
malabisDebug.pending()

// Ver todos los pedidos
malabisDebug.orders()

// Confirmar un pedido (como dueño)
malabisDebug.confirmOrder('MAL-12345678')

// Rechazar un pedido
malabisDebug.rejectOrder('MAL-12345678', 'Stock agotado')

// Activar/desactivar notificaciones
malabisDebug.toggleNotifications()

// Obtener notificaciones del dueño
malabisDebug.getOwnerNotifications()

// Obtener notificaciones del cliente
malabisDebug.getCustomerNotifications()

// Limpiar todo
malabisDebug.clearAll()

// Ver ayuda
malabisDebug.help()
```

## 💾 Persistencia de Datos

- El carrito se guarda automáticamente en localStorage
- Si cierras la página, tu carrito se mantiene
- Los datos se limpian al enviar la reserva

## 🎯 Funcionalidades Futuras

- Integración con WhatsApp para notificaciones reales
- Sistema de login para clientes
- Historial de pedidos
- Métodos de pago integrados
- Seguimiento de pedidos en tiempo real
- Galería de fotos de productos reales
- Sistema de comentarios y reseñas
- Cupones y descuentos

## 📝 Notas Técnicas

- **HTML5**: Semántica moderna
- **CSS3**: Gradientes, flexbox, grid, animaciones
- **JavaScript Vanilla**: Sin dependencias externas
- **LocalStorage**: Persistencia de datos del cliente
- **Responsive**: Mobile-first design
- **Accesible**: Estructura semántica y contraste adecuado

## 🚀 Optimizaciones de Rendimiento

- ✅ Carga rápida (sin imágenes pesadas, solo emojis)
- ✅ Lazy loading de elementos
- ✅ CSS optimizado y minificado
- ✅ JavaScript eficiente
- ✅ Animaciones con GPU acceleration
- ✅ LocalStorage para caché del carrito

## 📄 Licencia

Proyecto desarrollado para Malabis - Tienda de Ropa  
Rawson - San Juan - Argentina

---

**Versión**: 1.0.0  
**Última actualización**: Mayo 2026  
**Estado**: Demo funcional listo para presentación