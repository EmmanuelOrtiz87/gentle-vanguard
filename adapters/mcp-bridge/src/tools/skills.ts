import { z } from 'zod';
import { readdirSync, existsSync, readFileSync } from 'fs';
import { join } from 'path';

export function registerSkillTools(server: any, foundationRoot: string) {
  const skillsRoot = join(foundationRoot, 'skills');

  // List available skills
  server.tool(
    'foundation_skill_list',
    'List all available Foundation skills with descriptions and triggers',
    {
      category: z.string().optional().describe('Filter by category: frontend, backend, testing, workflow, etc.'),
    },
    async (args: any) => {
      try {
        if (!existsSync(skillsRoot)) {
          return {
            content: [{ type: 'text', text: 'No skills directory found.' }],
            isError: false,
          };
        }

        const skills = readdirSync(skillsRoot, { withFileTypes: true })
          .filter(dirent => dirent.isDirectory())
          .map(dirent => {
            const skillPath = join(skillsRoot, dirent.name, 'SKILL.md');
            const hasSkillFile = existsSync(skillPath);
            return {
              name: dirent.name,
              path: join(skillsRoot, dirent.name),
              hasSkillFile,
            };
          });

        const category = args.category || '';
        const filtered = category
          ? skills.filter(s => s.name.toLowerCase().includes(category.toLowerCase()))
          : skills;

        const skillList = filtered.map(s => 
          `- **${s.name}** ${s.hasSkillFile ? '✅' : '❌ No SKILL.md'}`
        ).join('\n');

        return {
          content: [{ type: 'text', text: `Available Skills (${filtered.length}):\n\n${skillList}` }],
          isError: false,
        };
      } catch (error: any) {
        return {
          content: [{ type: 'text', text: `Failed to list skills: ${error.message || error}` }],
          isError: true,
        };
      }
    }
  );

  // Load specific skill
  server.tool(
    'foundation_skill_load',
    'Get skill content for loading into AI context',
    {
      skillName: z.string().describe('Skill name (e.g., angular-spa-skill, react-19-skill)'),
    },
    async (args: any) => {
      try {
        const skillName = args.skillName;
        const skillPath = join(skillsRoot, skillName, 'SKILL.md');
        
        if (!existsSync(skillPath)) {
          return {
            content: [{ type: 'text', text: `Skill not found: ${skillName}` }],
            isError: true,
          };
        }

        const skillContent = readFileSync(skillPath, 'utf-8');

        return {
          content: [{ type: 'text', text: skillContent }],
          isError: false,
        };
      } catch (error: any) {
        return {
          content: [{ type: 'text', text: `Failed to load skill: ${error.message || error}` }],
          isError: true,
        };
      }
    }
  );
}
