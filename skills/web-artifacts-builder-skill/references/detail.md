</div>
```

---

## Design Guidelines

### Always Include

1. **Modern aesthetic** - Dark theme, clean lines
2. **Responsive** - Works on mobile
3. **Accessible** - Proper contrast, keyboard nav
4. **Interactive** - Real functionality, not just visual
5. **Self-contained** - No external deps except well-known CDNs

### CSS Best Practices

```css
:root {
  --bg-primary: #0f172a;
  --bg-secondary: #1e293b;
  --text-primary: #f8fafc;
  --text-secondary: #94a3b8;
  --accent: #3b82f6;
  --accent-hover: #2563eb;
  --success: #22c55e;
  --warning: #f59e0b;
  --error: #ef4444;
}

body {
  background: var(--bg-primary);
  color: var(--text-primary);
  font-family: 'Inter', system-ui, sans-serif;
}

.card {
  background: var(--bg-secondary);
  border-radius: 12px;
  padding: 1.5rem;
  box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1);
}
```

---

## Common Patterns

### 1. Dashboard

```html
<!-- Full dashboard with charts, tables, controls -->
<div class="dashboard">
  <header>...</header>
  <aside>Sidebar</aside>
  <main>Content</main>
</div>
```

### 2. Form

```html
<!-- Interactive form with validation -->
<form>
  <input type="text" required />
  <input type="email" required />
  <textarea></textarea>
  <button type="submit">Submit</button>
</form>
```

### 3. Data Table

```html
<table>
  <thead>
    <tr>
      <th>Name</th>
      <th>Value</th>
    </tr>
  </thead>
  <tbody>
    <!-- Dynamic rows -->
  </tbody>
</table>
```

---

## Integration

### Display as Artifact

When generating artifact code:

1. Use complete DOCTYPE and meta tags
2. Include all inline styles
3. Add proper CDNs for frameworks
4. Test in isolation first
5. Provide clear description

### Gentle-Vanguard Integration

```powershell
# Generate artifact
.\gv.ps1 artifact create dashboard --template sales

# Preview in browser
.\gv.ps1 artifact preview output.html
```

---

## Examples

### Calculator

```html
<!DOCTYPE html>
<html>
  <head>
    <style>
      * {
        box-sizing: border-box;
      }
      body {
        display: grid;
        place-items: center;
        min-height: 100vh;
        margin: 0;
        background: #0f172a;
        color: #f8fafc;
        font-family: system-ui;
      }
      button {
        background: #3b82f6;
        color: white;
        border: none;
        padding: 1rem 2rem;
        font-size: 1.5rem;
        border-radius: 8px;
        cursor: pointer;
        transition: transform 0.1s;
      }
      button:active {
        transform: scale(0.95);
      }
      .result {
        font-size: 3rem;
        font-weight: bold;
      }
    </style>
  </head>
  <body>
    <div style="text-align:center">
      <div class="result" id="r">0</div>
      <div style="margin-top:1rem">
        <button onclick="r.textContent=eval(r.textContent)">=</button>
      </div>
    </div>
  </body>
</html>
```

### Drag & Drop List

```html
<!-- Reorderable list component -->
<ul id="list">
  <li drable="true">Item 1</li>
  <li drable="true">Item 2</li>
</ul>
<script>
  // Standard Drag and Drop API
</script>
```

---

## Validacin

Before output, verify:

1.  HTML syntax vlido
2.  CSS sin errores
3.  JS funcional
4.  CDNs accesibles
5.  Responsive funciona