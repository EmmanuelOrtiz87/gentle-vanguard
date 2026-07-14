import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    include: ['tests/eval/**/*.test.ts'],
    testTimeout: 30000,
    hookTimeout: 10000,
    reporters: ['verbose'],
    pool: 'forks',
    poolOptions: {
      forks: {
        singleFork: true,
      },
    },
  },
});
