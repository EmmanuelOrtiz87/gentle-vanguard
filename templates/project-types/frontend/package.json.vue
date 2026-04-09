{
  "name": "{{project-name}}",
  "private": true,
  "version": "0.0.0",
  "type": "module",
  "scripts": {
    "dev": "vite",
    "build": "vue-tsc && vite build",
    "preview": "vite preview",
    "lint": "eslint . --ext vue,js,jsx,ts,tsx --report-unused-disable-directives --max-warnings 0",
    "lint:fix": "eslint . --ext vue,js,jsx,ts,tsx --fix",
    "test": "vitest",
    "typecheck": "vue-tsc --noEmit",
    "format": "prettier --write \"**/*.{vue,js,ts,tsx,css}\""
  },
  "dependencies": {
    "vue": "^3.4.0"
  },
  "devDependencies": {
    "@vitejs/plugin-vue": "^5.0.0",
    "@vue/tsconfig": "^0.5.0",
    "typescript": "^5.3.0",
    "vite": "^5.0.0",
    "vitest": "^1.2.0",
    "vue-tsc": "^1.8.0",
    "eslint": "^8.56.0",
    "prettier": "^3.2.0"
  }
}
