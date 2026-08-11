#!/usr/bin/env npx tsx
/**
 * Direct Execution System - Ejecución directa sin delegación a subagentes
 * 
 * Cuando la delegación mediante GGA/opencode no funciona por problemas
 * de asignación de modelo, este sistema permite ejecutar tareas directamente
 * desde el orquestador usando el modelo correcto (kimi-2-5).
 * 
 * Uso:
 *   import { executeDirect } from './direct-execution.js';
 *   const result = await executeDirect('explore', 'analizar código', context);
 */

import { spawn } from 'child_process';
import { join } from 'path';

const ROOT = process.cwd();

interface DirectExecutionResult {
  success: boolean;
  output?: string;
  error?: string;
  duration: number;
  model: string;
}

/**
 * Ejecuta una tarea de agente directamente sin delegar a subagente.
 * Usa el modelo del orquestador (kimi-2-5) explícitamente.
 * 
 * @param agentType - Tipo de agente ('explore', 'apply', 'verify', 'design', 'doc')
 * @param task - Descripción de la tarea
 * @param context - Contexto opcional
 * @returns Resultado de la ejecución
 */
export async function executeDirect(
  agentType: 'explore' | 'apply' | 'verify' | 'design' | 'doc',
  task: string,
  context?: string
): Promise<DirectExecutionResult> {
  const startTime = Date.now();
  const model = process.env.ORCHESTRATOR_MODEL || 'kimi-2-5';
  
  console.log(`[DirectExecution] Ejecutando ${agentType} directamente con modelo: ${model}`);
  
  // Mapeo de tipos de agente a scripts
  const agentScripts: Record<string, string> = {
    explore: join(ROOT, 'src', 'agents', 'sdd-explore.ts'),
    apply: join(ROOT, 'src', 'agents', 'sdd-apply.ts'),
    verify: join(ROOT, 'src', 'agents', 'sdd-verify.ts'),
    design: join(ROOT, 'src', 'agents', 'sdd-design.ts'),
    doc: join(ROOT, 'src', 'agents', 'doc-agent.ts'),
  };
  
  const scriptPath = agentScripts[agentType];
  if (!scriptPath) {
    return {
      success: false,
      error: `Agente desconocido: ${agentType}`,
      duration: Date.now() - startTime,
      model,
    };
  }
  
  return new Promise((resolve) => {
    const args = [
      'tsx',
      scriptPath,
      '--task', task,
      '--model', model,
    ];
    
    if (context) {
      args.push('--context', context);
    }
    
    const child = spawn('npx', args, {
      cwd: ROOT,
      stdio: ['pipe', 'pipe', 'pipe'],
      env: {
        ...process.env,
        AGENT_MODEL: model,
        FORCE_MODEL: model,
        ORCHESTRATOR_MODEL: model,
      },
      timeout: 300000,
    });
    
    let stdout = '';
    let stderr = '';
    
    child.stdout?.on('data', (data) => {
      stdout += data.toString();
    });
    
    child.stderr?.on('data', (data) => {
      stderr += data.toString();
    });
    
    child.on('close', (code) => {
      const duration = Date.now() - startTime;
      
      if (code === 0) {
        console.log(`[DirectExecution] ✅ Éxito en ${duration}ms`);
        resolve({
          success: true,
          output: stdout.trim(),
          duration,
          model,
        });
      } else {
        console.error(`[DirectExecution] ❌ Fallo (código ${code}) en ${duration}ms`);
        resolve({
          success: false,
          output: stdout.trim(),
          error: stderr.trim() || `Exit code: ${code}`,
          duration,
          model,
        });
      }
    });
    
    child.on('error', (err) => {
      const duration = Date.now() - startTime;
      console.error(`[DirectExecution] ❌ Error: ${err.message}`);
      resolve({
        success: false,
        error: err.message,
        duration,
        model,
      });
    });
  });
}

// CLI directa
if (require.main === module) {
  const args = process.argv.slice(2);
  const agentType = args[0] as 'explore' | 'apply' | 'verify' | 'design' | 'doc';
  const task = args[1];
  const context = args[2];
  
  if (!agentType || !task) {
    console.log('Usage: npx tsx src/direct-execution.ts <agent> "task" [context]');
    console.log('Agents: explore, apply, verify, design, doc');
    process.exit(1);
  }
  
  executeDirect(agentType, task, context)
    .then((result) => {
      console.log(JSON.stringify(result, null, 2));
      process.exit(result.success ? 0 : 1);
    })
    .catch((err) => {
      console.error('Error:', err);
      process.exit(1);
    });
}

export type { DirectExecutionResult };
