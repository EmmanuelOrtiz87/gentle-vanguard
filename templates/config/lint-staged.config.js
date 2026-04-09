import { defineConfig } from 'lint-staged';

export default defineConfig({
  '*.{ts,tsx}': ['eslint --fix', 'prettier --write'],
  '*.{js,json,css,md}': ['prettier --write']
});
