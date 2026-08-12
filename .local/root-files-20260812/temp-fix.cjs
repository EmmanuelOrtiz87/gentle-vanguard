const fs = require('fs');
const path = require('path');

const filePath = path.join(process.cwd(), 'src/core/maintenance-watchtower.ts');
let content = fs.readFileSync(filePath, 'utf-8');

const oldCode = `  const bridgeTs = join(ROOT, 'src/mcp-bridge.ts');
  if (fileExists(bridgeTs)) {
    try {
      const r = spawnSync('npx', ['tsx', 'src/mcp-bridge.ts', '--action', 'verify'], {
        cwd: ROOT,
        stdio: 'pipe',
        timeout: 10000,
        encoding: 'utf-8',
      });
      const output = (r.stdout ?? '') + (r.stderr ?? '');
      // Bridge is healthy if skill-server.js is OK (external tools like cursor/windsurf/cline are optional)
      const healthOk = /OK|PASS|healthy|Bridge status: OK|^True$|skill-server\\.js: OK/.test(output);
      const detail = healthOk ? (output.includes('skill-server.js: OK') ? 'skill-server ready' : '') : '';
      addResult('mcp', 'bridge health', healthOk ? 'PASS' : 'WARN', detail, 'verify');
    } catch {
      addResult('mcp', 'bridge health', 'WARN', 'Not accessible', 'verify');
    }
  } else {
    addResult('mcp', 'bridge health', 'WARN', 'Script not found', 'verify');
  }`;

const newCode = `  // Check MCP bridge files directly instead of running the script (which starts a server)
  const bridgeTs = join(ROOT, 'src/mcp/mcp-bridge.ts');
  const skillServerJs = join(ROOT, 'dist/scripts/mcp/skill-server.js');
  const mcpConfig = join(ROOT, 'config/mcp-config.sd.json');
  
  if (fileExists(bridgeTs) && fileExists(skillServerJs) && fileExists(mcpConfig)) {
    try {
      const config = readJson(mcpConfig);
      const mcpEnabled = config?.mcp?.enabled === true;
      addResult(
        'mcp', 
        'bridge health', 
        mcpEnabled ? 'PASS' : 'WARN', 
        mcpEnabled ? 'bridge ready, MCP enabled' : 'MCP disabled in config', 
        'verify'
      );
    } catch {
      addResult('mcp', 'bridge health', 'WARN', 'Config parse error', 'verify');
    }
  } else {
    const missing = [];
    if (!fileExists(bridgeTs)) missing.push('mcp-bridge.ts');
    if (!fileExists(skillServerJs)) missing.push('skill-server.js');
    if (!fileExists(mcpConfig)) missing.push('mcp-config.sd.json');
    addResult('mcp', 'bridge health', 'WARN', \`Missing: \${missing.join(', ')}\`, 'verify');
  }`;

if (content.includes(oldCode)) {
  content = content.replace(oldCode, newCode);
  fs.writeFileSync(filePath, content);
  console.log('✓ Archivo actualizado correctamente');
} else {
  console.log('⚠ No se encontró el código exacto a reemplazar');
  console.log('Buscando...');
  // Intentar encontrar la línea
  if (content.includes("'src/mcp-bridge.ts'")) {
    console.log('✓ Se encontró referencia a src/mcp-bridge.ts');
  }
}
