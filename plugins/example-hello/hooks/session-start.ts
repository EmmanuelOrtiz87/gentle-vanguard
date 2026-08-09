#!/usr/bin/env node
/**
 * example-hello — hook del evento session-start.
 *
 * Se ejecuta como proceso separado por el hook runner del plugin-manager
 * (nunca se importa en el proceso principal del stack).
 */

console.log('Hello from plugin — hook session-start ejecutado');
process.exit(0);
