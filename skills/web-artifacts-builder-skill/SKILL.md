---
name: web-artifacts-builder-skill
description: >
  Build interactive web artifacts: single-page HTML, React components, prototypes. Trigger: "web
  artifact", "html component", "interactive demo", "prototype", "single page", "runnable code",
  "rich preview"
license: Apache-2.0
metadata:
  author: gentle-vanguard
  versión: '1.0'
allowed-tools: Read, Edit, Write, Glob, Grep, Bash, Task
---

# Web Artifacts Builder Skill

Build interactive web artifacts that render directly in browser as single-page applications or
components.

## When to Use

**USE this skill when:**

- User needs interactive UI demo
- Rapid prototyping
- Single-page tools
- Code that runs standalone
- Visual components for documentation

**DON'T use when:**

- Full application required
- State management across pages
- Server-side rendering needed
- Database integration

---

## Artifact Types

### 1. Single HTML Page

```html
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>My Tool</title>
    <style>
      :root {
        --primary: #3b82f6;
        --bg: #0f172a;
        --text: #f1f5f9;
      }
      body {
        font-family: system-ui, sans-serif;
        background: var(--bg);
        color: var(--text);
        min-height: 100vh;
        margin: 0;
      }
    </style>
  </head>
  <body>
    <main style="padding: 2rem;">
      <h1>Interactive Tool</h1>
      <!-- Content -->
    </main>
    <script>
      // Interactive logic
    </script>
  </body>
</html>
```

### 2. React Component (Standalone)

```html
<script src="https://unpkg.com/react@18/umd/react.development.js" crossorigin></script>
<script src="https://unpkg.com/react-dom@18/umd/react-dom.development.js" crossorigin></script>
<script src="https://unpkg.com/@babel/standalone/babel.min.js"></script>

<div id="root"></div>

<script type="text/babel">
  function App() {
    const [count, setCount] = React.useState(0);
    return (
      <div style={{ padding: '2rem' }}>
        <h1>Counter: {count}</h1>
        <button onClick={() => setCount((c) => c + 1)}>Increment</button>
      </div>
    );
  }
  ReactDOM.createRoot(document.getElementById('root')).render(<App />);
</script>
```

### 3. Vue 3 Component

```html
<script type="module">
  import { createApp, ref } from 'https://unpkg.com/vue@3/dist/vue.esm-browser.js';
  createApp({
    setup() {
      const count = ref(0);
      return { count };
    },
  }).mount('#app');
</script>
<div id="app">
  <button @click="count++">Count: {{ count }}</button>

  --- > **Referencia detallada**: [ eferences/detail.md](references/detail.md)
</div>
```
