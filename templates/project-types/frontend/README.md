# Frontend Templates

This directory contains frontend framework templates. Copy the appropriate `package.*.json` to
`package.json` based on your chosen framework.

## Framework Templates

| Framework    | Package File          | TypeScript Config        |
| ------------ | --------------------- | ------------------------ |
| React + Vite | `package.react.json`  | `tsconfig.node.json`     |
| Vue 3 + Vite | `package.vue.json`    | `tsconfig.node.vue.json` |
| Next.js 14   | `package.nextjs.json` | Uses Next.js built-in    |
| Angular + Nx | `package.nx.json`     | Uses Nx built-in         |

## Usage

### React

```bash
cp package.react.json package.json
npm install
```

### Vue

```bash
cp package.vue.json package.json
npm install
```

### Next.js

```bash
cp package.nextjs.json package.json
npm install
```

### Angular (with Nx)

```bash
cp package.nx.json package.json
npm install
```

## Structure

```
frontend/
 src/
    components/   # Reusable UI components
    pages/        # Route pages
    hooks/        # Custom React/Vue hooks
    services/     # API clients
    utils/        # Utility functions
 public/           # Static assets
 tests/            # Test files
 package.*.json    # Framework-specific package files
 tsconfig.*.json   # Framework-specific TypeScript configs
```
