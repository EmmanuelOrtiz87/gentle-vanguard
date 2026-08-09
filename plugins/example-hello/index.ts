#!/usr/bin/env node
/**
 * example-hello — entry point del plugin.
 *
 * Se puede ejecutar como CLI (proceso separado):
 *   npx tsx plugins/example-hello/index.ts
 * o usarse como biblioteca exportando run().
 *
 * El plugin manager NUNCA importa este archivo en su propio proceso; lo lanza
 * como subproceso vía runNpxTsxSync cuando un hook lo requiere o el usuario
 * lo invoca explícitamente.
 */

export function run(...args: string[]): string {
  const payload = args.length > 0 ? ` (${args.join(' ')})` : '';
  return `Hello from plugin${payload}`;
}

if (process.argv[1] && import.meta.url === new URL(`file://${process.argv[1].replace(/\\/g, '/')}`).href) {
  console.log(run(...process.argv.slice(2)));
}
