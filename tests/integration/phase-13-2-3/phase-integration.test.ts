import { describe, it } from 'node:test';
import assert from 'node:assert/strict';
import { existsSync, readFileSync } from 'node:fs';
import { resolve } from 'node:path';

const ROOT = resolve(import.meta.dirname, '..', '..', '..');
const CONFIG_PATH = resolve(ROOT, 'config/session-autostart.config.json');

interface PipelineStep {
  id: string;
  enabled?: boolean;
}

interface SessionAutostartConfig {
  pipeline?: {
    steps?: PipelineStep[];
  };
}

function readPipelineSteps(): PipelineStep[] {
  const config = JSON.parse(readFileSync(CONFIG_PATH, 'utf8')) as SessionAutostartConfig;
  return config.pipeline?.steps ?? [];
}

function hasEnabledStep(id: string): boolean {
  return readPipelineSteps().some((step) => step.id === id && step.enabled === true);
}

describe('Phase 1.3 / 2 / 3 integration', () => {
  describe('Distributed tracing', () => {
    it('tracing-instrument source exists', () => {
      assert.equal(existsSync(resolve(ROOT, 'src/monitor/tracing-instrument.ts')), true);
    });

    it('tracing step is configured in the pipeline', () => {
      assert.equal(hasEnabledStep('tracing-init'), true);
    });
  });

  describe('State persistence', () => {
    it('checkpoint-manager source exists', () => {
      assert.equal(existsSync(resolve(ROOT, 'src/ops/checkpoint-manager.ts')), true);
    });

    it('checkpoint step is configured in the pipeline', () => {
      assert.equal(hasEnabledStep('checkpoint-auto-create'), true);
    });
  });

  describe('Audit pipeline', () => {
    it('audit-pipeline source exists', () => {
      assert.equal(existsSync(resolve(ROOT, 'src/infrastructure/audit-pipeline.ts')), true);
    });

    it('audit step is configured in the pipeline', () => {
      assert.equal(hasEnabledStep('audit-pipeline-init'), true);
    });
  });
});
