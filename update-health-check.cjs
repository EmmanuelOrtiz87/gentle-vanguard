const fs = require('fs');

// Read the health check file
let content = fs.readFileSync('src/core/maintenance-watchtower.ts', 'utf-8');

// Update paths for moved files
content = content.replace(/src\/skill-embedder\.ts/g, 'src/skills/skill-embedder.ts');
content = content.replace(/src\/mcp-manager\.ts/g, 'src/mcp/mcp-manager.ts');
content = content.replace(/src\/mcp-gateway\.ts/g, 'src/mcp/mcp-gateway.ts');
content = content.replace(/src\/privacy-gateway\.ts/g, 'src/security/privacy-gateway.ts');
content = content.replace(/src\/security-orchestrator\.ts/g, 'src/security/security-orchestrator.ts');
content = content.replace(/src\/audit-pipeline\.ts/g, 'src/v4.0-Infrastructure/audit-pipeline.ts');

fs.writeFileSync('src/core/maintenance-watchtower.ts', content);
console.log('Health check paths updated');
