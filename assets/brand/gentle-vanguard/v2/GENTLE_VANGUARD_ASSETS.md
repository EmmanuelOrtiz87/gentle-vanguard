# Gentle Vanguard — SVG Asset System v2.0

## Objetivo

Este paquete reemplaza la familia de assets antigua por una familia **100% SVG** de la nueva identidad Gentle Vanguard.

El sistema que consume estos assets no necesita interpretar una imagen PNG/JPG: cada logo e icono está construido con **paths SVG, gradients y shapes vectoriales**.

## Corrección del símbolo

La referencia nueva mostraba el GV con un desequilibrio visual: mayor margen a la izquierda y riesgo de que la V pareciera cortada.

La versión v2:
- centra el GV matemática y visualmente;
- mantiene la G y la V completas;
- reserva 15–20% de safe area;
- utiliza un canvas estándar 1024×1024;
- usa 800 px de ancho de marca dentro del canvas;
- mantiene proporciones sin deformación.

## Estructura

```text
assets/
└── brand/
    └── gentle-vanguard/
        └── v2/
            ├── svg/
            │   ├── icons/
            │   │   ├── gv-master-gradient.svg
            │   │   ├── gv-transparent.svg
            │   │   ├── gv-white.svg
            │   │   ├── gv-black.svg
            │   │   ├── gv-cyan.svg
            │   │   ├── gv-violet.svg
            │   │   ├── gv-currentColor.svg
            │   │   ├── app-icon-dark.svg
            │   │   ├── app-icon-light.svg
            │   │   ├── app-icon-gradient.svg
            │   │   ├── app-icon-maskable.svg
            │   │   ├── android-foreground.svg
            │   │   ├── android-background.svg
            │   │   ├── favicon.svg
            │   │   └── safari-pinned-tab.svg
            │   └── logos/
            │       ├── logo-horizontal.svg
            │       ├── logo-horizontal-dark-text.svg
            │       ├── logo-vertical.svg
            │       └── logo-vertical-dark-text.svg
            ├── asset-manifest.json
            └── brand.tokens.json
```

## Assets recomendados

### App

`icons/app-icon-dark.svg`

### Logo principal

`logos/logo-horizontal.svg`

### Símbolo aislado

`icons/gv-master-gradient.svg`

### Favicon

`icons/favicon.svg`

### Android

`icons/android-foreground.svg`
`icons/android-background.svg`

### UI con color controlado por CSS

`icons/gv-currentColor.svg`

## Paleta

```text
Midnight Navy    #0B1020
Electric Blue    #1E40AF
Tech Cyan        #06B6D4
Vanguard Violet  #8B5CF6
Soft White       #F8FAFC
Black            #050A14
```

Gradiente:

```text
#6E4DEB → #7B63E8 → #06B6D4
```

## Reglas

No:
- cortar G o V;
- estirar el símbolo;
- cambiar proporciones;
- desplazar el símbolo dentro de su canvas;
- añadir sombras o contornos arbitrarios;
- sustituir el SVG por un screenshot.

Sí:
- escalar proporcionalmente;
- utilizar SVG directamente;
- generar PNG/ICO/ICNS desde el SVG cuando una plataforma lo exija;
- conservar safe area.

## Web

```html
<img
  src="/assets/brand/gentle-vanguard/v2/svg/icons/gv-master-gradient.svg"
  alt="Gentle Vanguard"
  width="48"
  height="48"
/>
```

Favicon:

```html
<link
  rel="icon"
  type="image/svg+xml"
  href="/assets/brand/gentle-vanguard/v2/svg/icons/favicon.svg"
/>
```

## React / Vite

```jsx
import gv from "./assets/brand/gentle-vanguard/v2/svg/icons/gv-master-gradient.svg";

<img src={gv} alt="Gentle Vanguard" />
```

## Next.js

```jsx
import Image from "next/image";
import gv from "@/assets/brand/gentle-vanguard/v2/svg/icons/gv-master-gradient.svg";

<Image src={gv} alt="Gentle Vanguard" width={48} height={48} />
```

## Flutter

Con `flutter_svg`:

```dart
SvgPicture.asset(
  'assets/brand/gentle-vanguard/v2/svg/icons/gv-master-gradient.svg',
);
```

## Android

Usar:
- foreground: `android-foreground.svg`
- background: `android-background.svg`

Si el build nativo exige Vector Drawable XML, importar el SVG en Android Studio. El SVG continúa siendo la fuente maestra.

## iOS

Mantener el SVG como fuente de diseño y exportar los PNG requeridos por Xcode desde él. No crear variantes dibujadas manualmente por tamaño.

## PWA

El master continúa siendo SVG. Para máxima compatibilidad del manifest, generar desde él PNG 192×192 y 512×512 cuando el navegador/instalador no acepte SVG.

## Integración en el proyecto local

El ZIP contiene la ruta relativa:

```text
assets/brand/gentle-vanguard/v2/
```

Por lo tanto, para tu proyecto:

```text
C:\Workspace_local\gentle-vanguard\assets\brand\gentle-vanguard\v2\
```

No se mezclan los archivos con la versión vieja. Esto permite mantener `legacy` durante la transición.

## Verificación automática

Todos los SVG de este paquete fueron generados sin etiquetas `<image>`, por lo que no dependen de PNG/JPG incrustados.

El sistema debe considerar:

```text
SVG = fuente maestra
PNG/ICO/ICNS = derivados
```

## Versión

```text
Gentle Vanguard
Asset System v2.0
Formato maestro: SVG
Estado: NEW / CENTERED / APPLICATION READY
```
