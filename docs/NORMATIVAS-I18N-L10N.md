# NORMATIVAS-I18N-L10N.md — Internationalization & Localization Standards

Version: 1.0.0
Last updated: 2026-05-11
Framework: ECMA-402 (Intl API) + Unicode CLDR + ICU MessageFormat

---

## 1. PROPOSITO

Define los estándares de internacionalizacion (i18n) y localizacion (l10n) para todo el stack Gentle-Vanguard. Aplica a interfaces de usuario, mensajes del sistema, documentacion generada, y contenido producido por agentes. Garantiza que todo output sea locale-aware, traducible, y culturalmente apropiado.

---

## 2. PRINCIPIOS RECTORES

| Principio | Descripcion |
|-----------|-------------|
| Separation | Contenido traducible separado del codigo (no hardcode strings) |
| Locale-first | Todo texto se mueve a archivos de locale desde el primer commit |
| Pluralization | Soporte nativo de plurales complejos (1, 2-4, 5+ en eslavo, etc.) |
| RTL support | Layout responsivo a direccion de texto (LTR/RTL) |
| Cultural awareness | Formatos de fecha, moneda, numeros, direcciones segun locale |

---

## 3. TECNOLOGIAS RECOMENDADAS

| Plataforma | Libreria | Formato |
|------------|----------|---------|
| JavaScript/TypeScript | react-intl / FormatJS | ICU MessageFormat |
| Python | Babel + Django i18n | .po / .mo + gettext |
| PowerShell | Resource strings | .psd1 con hashtable |
| React Native | react-intl + IntlProvider | ICU MessageFormat |
| General | i18next | JSON resource bundles |

### 3.1 Stack Gentle-Vanguard (default)

Preferir **FormatJS (ICU MessageFormat)** para consistencia cross-plataforma:

```javascript
// CORRECTO: Separacion de contenido
import { defineMessages } from 'react-intl'

const messages = defineMessages({
  welcome: {
    id: 'app.welcome',
    defaultMessage: 'Welcome, {name}!',
    description: 'Welcome message shown on login'
  },
  items: {
    id: 'app.items.count',
    defaultMessage: '{count, plural, one {# item} other {# items}}',
    description: 'Item count with pluralization'
  }
})

// USO:
<FormattedMessage {...messages.welcome} values={{ name: user.name }} />

// INCORRECTO: Hardcode de strings
<h1>Welcome, {user.name}!</h1>
```

---

## 4. CONTROLES OBLIGATORIOS

### 4.1 String Externalization

1. **MUST** externalizar todo string visible al usuario (incluyendo warnings, errors, tooltips)
2. **MUST** usar IDs semanticos (e.g., `auth.login.error.invalidCredentials`, no `error_1`)
3. **MUST** incluir `description` en cada mensaje para contexto del traductor
4. **MUST NOT** concatenar strings para formar mensajes (usar placeholders con valores)
5. **MUST NOT** usar strings como IDs (usar keys unicos estables)

### 4.2 Plurals & Gender

| Regla | Implementacion |
|-------|----------------|
| Plurales complejos | Usar ICU `{count, plural, one {...} other {...}}` |
| Ordinales | Usar `{count, selectordinal, one {...} other {...}}` |
| Genero | Usar `{name, select, male {...} female {...} other {...}}` |
| Offset | Usar `{count, offset:1 plural, ...}` para rangos inclusivos |

### 4.3 Dates, Times & Calendars

```javascript
// CORRECTO: Usar Intl API nativa o libreria
const date = new Intl.DateTimeFormat('es-AR', {
  year: 'numeric',
  month: 'long',
  day: 'numeric'
}).format(new Date())
// → "11 de mayo de 2026"

const relative = new Intl.RelativeTimeFormat('es-AR', { numeric: 'auto' })
  .format(-1, 'day')
// → "ayer"

// INCORRECTO: Formato hardcodeado
`${date.getDate()}/${date.getMonth() + 1}/${date.getFullYear()}`
```

1. **MUST** usar `Intl.DateTimeFormat` o `Intl.RelativeTimeFormat` para fechas
2. **MUST** usar `Intl.NumberFormat` para numeros, monedas, porcentajes
3. **MUST** almacenar fechas en ISO 8601 (UTC) y convertir solo al mostrar
4. **SHOULD** soportar calendarios alternativos (Hijri, Buddhist, Japanese) si aplica

### 4.4 Numbers & Currencies

```javascript
// CORRECTO
const price = new Intl.NumberFormat('es-AR', {
  style: 'currency',
  currency: 'ARS',
  currencyDisplay: 'narrowSymbol'
}).format(1234.56)
// → "$1.234,56"

// INCORRECTO
`$${value.toFixed(2)}`
```

1. **MUST** usar `Intl.NumberFormat` para todo formato numerico
2. **MUST** especificar `currency` explicitamente (nunca asumir USD)
3. **MUST** usar compact notation solo cuando el espacio es limitado
4. **SHOULD** alinear decimales en columnas de tablas

### 4.5 RTL & Bidi Support

1. **MUST** usar `dir="auto"` en elementos con contenido mixto LTR/RTL
2. **MUST** evitar propiedades CSS direccionales hardcodeadas (left/right)
3. **MUST** usar `inset-inline-start` / `inset-inline-end` sobre `left` / `right`
4. **MUST** definir `html[dir="rtl"]` en estilos base
5. **SHOULD** testear layout en locale Arabe, Hebreo

```css
/* CORRECTO */
.sidebar {
  inset-inline-start: 0; /* left en LTR, right en RTL */
}

/* INCORRECTO */
.sidebar {
  left: 0;
}
```

### 4.6 Locale File Structure

```
locales/
├── en-US/
│   ├── common.json
│   ├── auth.json
│   ├── dashboard.json
│   └── errors.json
├── es-AR/
│   ├── common.json
│   ├── auth.json
│   ├── dashboard.json
│   └── errors.json
├── pt-BR/
│   ├── common.json
│   └── ...
├── en.json          # Fallback (locale agnostic)
└── index.js         # Dynamic import loader
```

1. **MUST** mantener un archivo `en.json` como fallback universal
2. **MUST** cargar solo los namespaces necesarios (lazy loading)
3. **MUST** usar estructura jerarquica plana (max 3 niveles)
4. **SHOULD** mantener keys consistentes entre idiomas
5. **SHOULD** auditar keys faltantes en CI

---

## 5. LOCALES SOPORTADOS (Fase 1)

| Locale | Region | RTL | Prioridad |
|--------|--------|-----|-----------|
| en-US | United States | No | P0 (base) |
| es-AR | Argentina | No | P0 (base) |
| es | Spanish (generic) | No | P1 |
| pt-BR | Brazil | No | P1 |
| en-GB | United Kingdom | No | P2 |
| fr-FR | France | No | P2 |
| de-DE | Germany | No | P2 |
| ja-JP | Japan | No | P3 |
| zh-CN | China (Simplified) | No | P3 |
| ar-SA | Saudi Arabia | Si | P3 |

---

## 6. HERRAMIENTAS DE VERIFICACION

### 6.1 Linting

| Herramienta | Uso | Frecuencia |
|-------------|-----|------------|
| eslint-plugin-i18n-json | Validar archivos locale JSON | Cada PR |
| eslint-plugin-formatjs | Detectar strings hardcodeados | Cada commit |
| i18next-scanner | Extraer keys del codigo | Pre-commit |
| locale-compare | Comparar completitud entre locales | CI semanal |

### 6.2 CI Integration

```yaml
- name: i18n validation
  run: |
    npx eslint-plugin-i18n-json --check locales/
    npx i18next-scanner --config i18next-scanner.config.js
```

---

## 7. COMPLIANCE CHECKPOINTS

TODO implementacion DEBE verificar:

1. [ ] Todo string visible externalizado a archivos de locale
2. [ ] IDs semanticos con contexto de traduccion
3. [ ] Plurales usan ICU MessageFormat (nunca concatenacion)
4. [ ] Fechas formateadas con Intl.DateTimeFormat
5. [ ] Numeros/monedas formateados con Intl.NumberFormat
6. [ ] Layout usa propiedades logicas (inset-inline-start no left)
7. [ ] `dir="auto"` en contenido generado
8. [ ] Fallback locale (en.json) presente y completo
9. [ ] Sin hardcode de strings en JSX/componentes
10. [ ] Sin valores de prueba (lorem ipsum, test) en locales
11. [ ] Lazy loading de namespaces configurado
12. [ ] Sin keys faltantes entre idiomas (CI gate)

---

## 8. REFERENCIAS

| Resource | Path |
|----------|------|
| ICU MessageFormat | unicode-org.github.io/icu |
| ECMA-402 Intl API | tc39.es/ecma402 |
| Unicode CLDR | cldr.unicode.org |
| FormatJS Documentation | formatjs.io |
| i18next Documentation | i18next.com |
| Development Standards | `rules/DEVELOPMENT-STANDARDS.md` |
| Code Standards | `rules/NORMATIVAS-CODIGO.md` |

---

_Version: 1.0.0 — 2026-05-11 — Status: ACTIVE_

