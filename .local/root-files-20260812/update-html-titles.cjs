const fs = require('fs');

// Read the file
const filePath = 'gentle-vanguard-presentation-v8.html';
let content = fs.readFileSync(filePath, 'utf-8');

// Remove version prefixes from section titles
content = content.replace(/<h2>v5\.0\+ Convergence Layer<\/h2>/g, '<h2>Convergence Layer</h2>');
content = content.replace(/<h2>v5\.1\+ Multi-Tenant Isolation<\/h2>/g, '<h2>Multi-Tenant Isolation</h2>');
content = content.replace(/<h2>v6\.0\+ Autonomous Review<\/h2>/g, '<h2>Autonomous Review</h2>');
content = content.replace(/<h2>v6\.4\+ MCP Native<\/h2>/g, '<h2>MCP Native</h2>');
content = content.replace(/<h2>Stage #8 Trust Layer<\/h2>/g, '<h2>Trust Layer</h2>');

// Write back
fs.writeFileSync(filePath, content);
console.log('HTML updated successfully');
console.log('Version prefixes removed from section titles');
