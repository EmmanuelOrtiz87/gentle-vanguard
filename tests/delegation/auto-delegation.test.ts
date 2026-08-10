#!/usr/bin/env node
/**
 * Test de Delegación Automática - Valida el sistema de routing
 *
 * Prueba que las tareas se asignen a los agentes correctos
 * basándose en keywords y patrones del routing-table.json
 */

import { readFileSync } from 'fs';

interface RoutingTable {
  agents: Record<
    string,
    {
      code: string;
      domains: string[];
      keywords: string[];
    }
  >;
  domains: Record<
    string,
    {
      primary: string;
      confidence: number;
    }
  >;
  overrides: Array<{
    pattern: string;
    agent: string;
    confidence: number;
  }>;
}

interface Recommendation {
  domain: string;
  recommended: string;
  confidence: number;
  alternatives: string[];
  source: string;
}

// Cargar tabla de routing
const table: RoutingTable = JSON.parse(
  readFileSync('.session/routing/routing-table.json', 'utf-8'),
);

function recommendAgent(task: string): Recommendation {
  const taskLower = task.toLowerCase();

  // Check overrides primero (keywords)
  for (const o of table.overrides) {
    if (o.keywords.some((k: string) => taskLower.includes(k.toLowerCase()))) {
      return {
        domain: 'matched',
        recommended: o.agent,
        confidence: o.confidence,
        alternatives: [],
        source: 'routing-table',
      };
    }
  }

  // Fallback: check keywords de agentes
  for (const [agentName, agentInfo] of Object.entries(table.agents)) {
    if (agentInfo.keywords.some((k) => taskLower.includes(k.toLowerCase()))) {
      return {
        domain: agentInfo.domains[0] || 'general',
        recommended: agentName,
        confidence: 0.8,
        alternatives: Object.keys(table.agents)
          .filter((a) => a !== agentName)
          .slice(0, 2),
        source: 'keyword-match',
      };
    }
  }

  // Default fallback
  return {
    domain: 'general',
    recommended: 'sdd-explore',
    confidence: 0.6,
    alternatives: ['sdd-apply', 'sdd-design'],
    source: 'fallback',
  };
}

// Casos de prueba
const tests = [
  {
    task: 'explorar requisitos de un nuevo feature',
    expected: 'sdd-explore',
    desc: 'BA exploration',
  },
  { task: 'diseñar arquitectura de API REST', expected: 'sdd-design', desc: 'SAD design' },
  { task: 'implementar componente React', expected: 'sdd-apply', desc: 'DEV implementation' },
  { task: 'crear tests unitarios', expected: 'sdd-verify', desc: 'QA testing' },
  { task: 'documentar API', expected: 'doc-agent', desc: 'DOC documentation' },
  { task: 'configurar CI/CD pipeline', expected: 'ops-agent', desc: 'OPS operations' },
  { task: 'auditar seguridad', expected: 'gov-agent', desc: 'GOV governance' },
  { task: 'arreglar bug en produccion', expected: 'sdd-apply', desc: 'DEV bugfix' },
];

console.log('=== PRUEBA DE DELEGACION AUTOMATICA ===\n');

let passed = 0;
const results: Array<{ task: string; expected: string; got: string; success: boolean }> = [];

for (const test of tests) {
  const result = recommendAgent(test.task);
  const success = result.recommended === test.expected;

  results.push({
    task: test.desc,
    expected: test.expected,
    got: result.recommended,
    success,
  });

  if (success) {
    passed++;
    console.log(
      '✅',
      test.desc.padEnd(25),
      test.task.substring(0, 35).padEnd(38),
      '→',
      result.recommended,
      `(conf: ${result.confidence})`,
    );
  } else {
    console.log(
      '❌',
      test.desc.padEnd(25),
      test.task.substring(0, 35).padEnd(38),
      '→',
      result.recommended,
      `(esperado: ${test.expected})`,
    );
  }
}

console.log('\n=== RESULTADO ===');
console.log('Total casos:', tests.length);
console.log('Exitosos:', passed);
console.log('Tasa:', ((passed / tests.length) * 100).toFixed(0) + '%');

if (passed === tests.length) {
  console.log('\n🎉 SISTEMA DE DELEGACION: OPERATIVO');
  console.log('✅ Todos los agentes asignados correctamente');
  console.log('✅ Routing table funcionando');
  console.log('✅ Keywords matching operativo');
} else {
  console.log('\n⚠️  Algunos casos fallaron - revisar routing table');
}

// Exportar resultado para verificacion
const report = {
  timestamp: new Date().toISOString(),
  total: tests.length,
  passed,
  rate: passed / tests.length,
  results,
  status: passed === tests.length ? 'PASS' : 'PARTIAL',
};

console.log('\nReporte JSON:');
console.log(JSON.stringify(report, null, 2));

// Exit code para CI
process.exit(passed === tests.length ? 0 : 1);
