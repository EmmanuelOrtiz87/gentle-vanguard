#!/usr/bin/env node

/**
 * Test de captura de tokens en tiempo real
 * Verifica si las optimizaciones en tokens están funcionando realmente
 */

import { execSync } from 'child_process';
import { existsSync, readFileSync, writeFileSync } from 'fs';
import { join, resolve } from 'path';

const ROOT = resolve(process.cwd());

console.log('🔍 Test de captura de tokens en tiempo real...');

// 1. Verificar que el sistema esté listo
console.log('\n1. Verificando estado del sistema...');
try {
    const result = execSync('npx tsx src/token-budget-guard.ts -Mode status -Quiet', {
        cwd: ROOT,
        encoding: 'utf-8'
    });
    console.log('✅ Token Guard está funcionando:');
    console.log('   ' + result.trim());
} catch (error) {
    console.log('⚠️  Error al verificar Token Guard:', error.message);
}

// 2. Verificar que los archivos de configuración estén actualizados
console.log('\n2. Verificando configuraciones actualizadas...');

const configs = [
    'config/token-budget-guard.json',
    'config/output-compression.json'
];

configs.forEach(config => {
    const fullPath = join(ROOT, config);
    if (existsSync(fullPath)) {
        try {
            const content = readFileSync(fullPath, 'utf-8');
            const configObj = JSON.parse(content);
            console.log(`✅ ${config}:`);
            if (config.includes('token-budget')) {
                console.log(`   - Límite diario: ${configObj.tokenBudget.limits.daily} tokens`);
            }
            if (config.includes('output-compression')) {
                console.log(`   - Perfil ultra: ${configObj.profiles.ultra.maxTokens} tokens`);
            }
        } catch (e) {
            console.log(`⚠️  Error leyendo ${config}: ${e.message}`);
        }
    } else {
        console.log(`❌ ${config}: No encontrado`);
    }
});

// 3. Revisar si hemos guardado tokens en el archivo de métricas
console.log('\n3. Revisando archivo de métricas...');
const metricsFile = join(ROOT, 'docs', 'sessions', 'metrics', 'token-guard-usage.csv');
if (existsSync(metricsFile)) {
    try {
        const lines = readFileSync(metricsFile, 'utf-8').split('\n').filter(l => l.trim());
        console.log(`✅ Archivo de métricas encontrado: ${lines.length} líneas`);
        if (lines.length > 1) {
            console.log('Última línea:');
            console.log('   ' + lines[lines.length - 1]);
        }
    } catch (e) {
        console.log(`⚠️  Error leyendo métricas: ${e.message}`);
    }
} else {
    console.log('⚠️  Archivo de métricas no encontrado (puede ser normal)');
}

// 4. Probar el guard de tokens con una acción simulada
console.log('\n4. Probando guard con acción simulada...');

try {
    const result = execSync('npx tsx src/token-budget-guard.ts -Mode check -Task "test" -Risk "low" -Record -Quiet', {
        cwd: ROOT,
        encoding: 'utf-8'
    });
    console.log('✅ Guard ejecutado con éxito:');
    console.log('   ' + result.trim());
    
    // Verificar si se actualizó el archivo de métricas
    if (existsSync(metricsFile)) {
        const lines = readFileSync(metricsFile, 'utf-8').split('\n').filter(l => l.trim());
        console.log(`\n🔄 Verificando actualización de métricas: ${lines.length} líneas`);
        if (lines.length > 1) {
            console.log('Última línea tras prueba:');
            console.log('   ' + lines[lines.length - 1]);
        }
    }
} catch (error) {
    console.log('⚠️  Error ejecutando prueba:', error.message);
}

// 5. Verificar versión del sistema
console.log('\n5. Información del sistema...');
try {
    const version = require('./package.json').version;
    console.log(`✅ Versión del stack: ${version}`);
    console.log(`✅ Directorio de trabajo: ${ROOT}`);
    
    // Verificar si existe el directorio de configuración
    const configDir = join(ROOT, 'config');
    if (existsSync(configDir)) {
        console.log(`✅ Directorio de configuración: OK`);
        const files = require('fs').readdirSync(configDir).filter(f => f.endsWith('.json')).slice(0, 5);
        console.log(`   Archivos clave: ${files.join(', ')}`);
    }
} catch (e) {
    console.log(`⚠️  Error verificando sistema: ${e.message}`);
}

console.log('\n🎯 Test completado - verificar errores para solucionar problemas de captura de tokens');
