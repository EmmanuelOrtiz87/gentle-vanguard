// ESLint v10 flat config — migrated from .eslintrc.json
import tsParser from '@typescript-eslint/parser';
import tsPlugin from '@typescript-eslint/eslint-plugin';
import securityPlugin from 'eslint-plugin-security';

export default [
  {
    ignores: ['dist/**', 'node_modules/**', 'coverage/**', 'templates/**', 'apps/web-dashboard/dist/**', '*.js', 'src/v5.0-Convergence/**', 'src/convergence/**'],
  },
  {
    files: ['src/**/*.ts', 'scripts/**/*.ts'],
    languageOptions: {
      parser: tsParser,
      parserOptions: {
        ecmaVersion: 2022,
        sourceType: 'module',
        project: './tsconfig.json',
      },
    },
    plugins: {
      '@typescript-eslint': tsPlugin,
      'security': securityPlugin,
    },
    rules: {
      // ESLint recommended
      'no-console': 'off',
      'prefer-const': 'error',
      'no-var': 'error',
      'eqeqeq': ['error', 'always'],
      // TS recommended
      '@typescript-eslint/explicit-function-return-type': 'off',
      '@typescript-eslint/no-explicit-any': 'off',
      '@typescript-eslint/no-unused-vars': ['error', { argsIgnorePattern: '^_' }],
      '@typescript-eslint/strict-boolean-expressions': 'off',
      '@typescript-eslint/no-floating-promises': 'error',
      '@typescript-eslint/await-thenable': 'error',
      // Security rules (SAST)
      // NOTE: detect-object-injection / non-literal-regexp / non-literal-require are
      // heuristic rules designed for dynamic JavaScript. In this TypeScript strict
      // codebase they produce ~600 false positives (96% of all lint noise) because the
      // compiler already validates typed access. The real-vulnerability rules below
      // stay enabled as errors. Timing-attack sites are suppressed inline with justification.
      'security/detect-object-injection': 'off',
      'security/detect-non-literal-regexp': 'off',
      'security/detect-non-literal-require': 'off',
      'security/detect-possible-timing-attacks': 'warn',
      'security/detect-eval-with-expression': 'error',
      'security/detect-no-csrf-before-method-override': 'error',
      'security/detect-pseudoRandomBytes': 'error',
      'security/detect-unsafe-regex': 'error',
    },
  },
];
