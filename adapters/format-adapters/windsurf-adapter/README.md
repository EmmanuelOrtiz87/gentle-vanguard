# Windsurf Adapter

Converts Foundation skills to Windsurf plugin format.

---
## Windsurf Plugin Format

Windsurf uses a proprietary plugin system. Research needed to determine:
- Plugin directory location
- Plugin manifest format
- How skills are loaded and triggered
- Context injection method

---
## Status

🚧 **Research Needed**

To implement this adapter, we need:
1. Install Windsurf IDE
2. Analyze plugin system (check `~/.windsurf/` directory)
3. Create `SKILL.md` → `plugin.md` converter
4. Test with a simple skill (e.g., `react-19-skill`)

---
## Planned Implementation

```javascript
// adapter.js (planned)
const fs = require('fs');
const path = require('path');

function convertSkillToWindsurf(skillPath, outputPath) {
  const skillContent = fs.readFileSync(skillPath, 'utf-8');
  
  // Parse Foundation SKILL.md format
  const parsed = parseSkillMarkdown(skillContent);
  
  // Convert to Windsurf format (TBD)
  const windsurfFormat = {
    name: parsed.name,
    triggers: parsed.trigger,
    instructions: parsed.content,
    // ...Windsurf-specific fields
  };
  
  fs.writeFileSync(outputPath, JSON.stringify(windsurfFormat, null, 2));
}
```

---
## Next Steps

1. Research Windsurf plugin system
2. Implement converter
3. Test with 3-5 Foundation skills
4. Document windsurf-specific gotchas
