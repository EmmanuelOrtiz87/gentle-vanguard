import { Server } from "@modelcontextprotocol/sdk/server/index.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import {
  CallToolRequestSchema,
  ListToolsRequestSchema,
  ListResourcesRequestSchema,
  ReadResourceRequestSchema,
} from "@modelcontextprotocol/sdk/types.js";
import { readFileSync, readdirSync, existsSync } from "fs";
import { join, resolve, dirname } from "path";
import { fileURLToPath } from "url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);
const ROOT = resolve(__dirname, "../../..");
const REGISTRY_PATH = join(ROOT, ".atl", "skill-registry.md");
const SKILLS_DIR = join(ROOT, "skills");

interface ParsedSkill {
  name: string;
  description: string;
  agent: string;
  triggers: string[];
  detail: string;
}

function parseRegistryLine(line: string): { name: string; agent: string; triggers: string[] } | null {
  const parts = line.split("|").map((s) => s.trim());
  if (parts.length < 4) return null;
  const agent = parts[1];
  const name = parts[2];
  const rawTriggers = parts[3] || "";
  const triggers = rawTriggers
    .split(",")
    .map((t) => t.trim().replace(/^"|"$/g, ""))
    .filter((t) => t.length > 0 && t !== "...");
  if (!name || name.startsWith("-")) return null;
  if (name.includes("\\") || name.includes("/") || name === "Path") return null;
  if (agent === "File") return null;
  return { name, agent, triggers };
}

function parseFrontmatter(filePath: string): { name?: string; description?: string } {
  try {
    const content = readFileSync(filePath, "utf-8");
    if (!content.startsWith("---")) return {};
    const end = content.indexOf("---", 3);
    if (end === -1) return {};
    const fm = content.slice(3, end).trim();
    const name = fm.match(/^name:\s*(.+)$/m)?.[1]?.trim();
    const descMatch = fm.match(/^description:\s*(.+)$/m);
    let description = descMatch?.[1]?.trim().replace(/^>\s*/, "");
    if (!description) {
      const multiMatch = fm.match(new RegExp("^description:\\s*\\n(?:^>\\s*(.+)$", "m"));
      description = multiMatch?.[1]?.trim();
    }
    return { name, description };
  } catch {
    return {};
  }
}

function buildSkillMap(): Map<string, ParsedSkill> {
  const map = new Map<string, ParsedSkill>();
  if (!existsSync(REGISTRY_PATH)) return map;

  const lines = readFileSync(REGISTRY_PATH, "utf-8").split("\n");
  let inMapping = false;

  for (const line of lines) {
    if (line.includes("| Agent") && line.includes("| Skill")) {
      inMapping = true;
      continue;
    }
    if (!inMapping) continue;
    if (line.startsWith("#") || line.trim().length === 0) continue;
    if (!line.includes("|")) continue;

    const parsed = parseRegistryLine(line);
    if (!parsed) continue;

    const skillDir = join(SKILLS_DIR, parsed.name);
    const skillMdPath = join(skillDir, "SKILL.md");
    const fm = existsSync(skillMdPath) ? parseFrontmatter(skillMdPath) : {};

    let detail = "";
    const refDetail = join(skillDir, "references", "detail.md");
    if (existsSync(refDetail)) {
      try {
        detail = readFileSync(refDetail, "utf-8").slice(0, 500);
      } catch {}
    }

    map.set(parsed.name, {
      name: parsed.name,
      description: fm.description || parsed.name,
      agent: parsed.agent,
      triggers: parsed.triggers,
      detail,
    });
  }
  return map;
}

function buildSummaryTable(skills: Map<string, ParsedSkill>): string {
  const agents = new Map<string, number>();
  for (const s of skills.values()) {
    agents.set(s.agent, (agents.get(s.agent) || 0) + 1);
  }
  let table = "| Agent | Skills |\n|-------|--------|\n";
  for (const [agent, count] of agents) {
    table += `| ${agent} | ${count} |\n`;
  }
  return table;
}

const skills = buildSkillMap();

const server = new Server(
  { name: "gentle-vanguard-skills", version: "1.0.0" },
  { capabilities: { tools: {}, resources: {} } }
);

server.setRequestHandler(ListToolsRequestSchema, async () => ({
  tools: [
    {
      name: "list_skills",
      description: "List all skills with agent mappings, count per agent, and summary",
      inputSchema: {
        type: "object",
        properties: {
          agent: {
            type: "string",
            description: "Filter by agent code (e.g., DEV, QA, GOV, DOC, OPS)",
          },
          search: {
            type: "string",
            description: "Search skills by name or trigger keyword",
          },
        },
      },
    },
    {
      name: "get_skill",
      description: "Get detailed information about a specific skill by name",
      inputSchema: {
        type: "object",
        properties: {
          name: { type: "string", description: "Skill name (e.g., react-19-skill, judgment-day)" },
        },
        required: ["name"],
      },
    },
    {
      name: "search_skills",
      description: "Search skills by keyword across name, description, triggers, and detail content",
      inputSchema: {
        type: "object",
        properties: {
          query: { type: "string", description: "Search keyword" },
        },
        required: ["query"],
      },
    },
  ],
}));

server.setRequestHandler(CallToolRequestSchema, async (request) => {
  const { name, arguments: args } = request.params;

  switch (name) {
    case "list_skills": {
      const filterAgent = args?.agent as string | undefined;
      const filterSearch = args?.search as string | undefined;
      let filtered = Array.from(skills.values());

      if (filterAgent) {
        const re = new RegExp(filterAgent.replace(/-/g, "[- ]").replace(/\*/g, ".*"), "i");
        filtered = filtered.filter((s) => re.test(s.agent));
      }
      if (filterSearch) {
        const q = filterSearch.toLowerCase();
        filtered = filtered.filter(
          (s) =>
            s.name.toLowerCase().includes(q) ||
            s.description.toLowerCase().includes(q) ||
            s.triggers.some((t) => t.toLowerCase().includes(q))
        );
      }

      const summary = buildSummaryTable(skills);
      const list = filtered
        .map((s) => `- **${s.name}** (_${s.agent}_) — ${s.triggers.slice(0, 3).join(", ")}`)
        .join("\n");

      return {
        content: [
          { type: "text", text: `**Skills**: ${filtered.length} / ${skills.size}\n\n${summary}\n\n### Skills\n${list}` },
        ],
      };
    }

    case "get_skill": {
      const skillName = args?.name as string;
      const skill = skills.get(skillName);
      if (!skill) {
        return {
          content: [{ type: "text", text: `Skill "${skillName}" not found` }],
          isError: true,
        };
      }

      const dir = join(SKILLS_DIR, skillName);
      const files = existsSync(dir)
        ? readdirSync(dir, { recursive: true })
            .filter((f) => f.toString().endsWith(".md"))
            .map((f) => f.toString())
        : [];

      let fullDetail = skill.detail;
      if (!fullDetail) {
        const skillMdPath = join(dir, "SKILL.md");
        if (existsSync(skillMdPath)) {
          fullDetail = readFileSync(skillMdPath, "utf-8").slice(0, 2000);
        }
      }

      return {
        content: [
          {
            type: "text",
            text: [
              `## ${skill.name}`,
              `**Agent**: ${skill.agent}`,
              `**Description**: ${skill.description}`,
              `**Triggers**: ${skill.triggers.join(", ") || "(none)"}`,
              `**Files**: ${files.length > 0 ? files.join(", ") : "(skill directory only)"}`,
              ``,
              fullDetail ? `### Detail\n${fullDetail.slice(0, 1500)}` : "",
            ]
              .filter(Boolean)
              .join("\n"),
          },
        ],
      };
    }

    case "search_skills": {
      const query = (args?.query as string)?.toLowerCase();
      if (!query) {
        return { content: [{ type: "text", text: "Query is required" }], isError: true };
      }

      const results = Array.from(skills.values()).filter(
        (s) =>
          s.name.toLowerCase().includes(query) ||
          s.description.toLowerCase().includes(query) ||
          s.triggers.some((t) => t.toLowerCase().includes(query)) ||
          s.detail.toLowerCase().includes(query)
      );

      if (results.length === 0) {
        return { content: [{ type: "text", text: `No skills found matching "${query}"` }] };
      }

      return {
        content: [
          {
            type: "text",
            text: [
              `**Search results for "${query}"**: ${results.length} skills`,
              ``,
              ...results.map(
                (s) => `- **${s.name}** (_${s.agent}_) — ${s.triggers.slice(0, 2).join(", ")}`
              ),
            ].join("\n"),
          },
        ],
      };
    }

    default:
      return { content: [{ type: "text", text: `Unknown tool: ${name}` }], isError: true };
  }
});

server.setRequestHandler(ListResourcesRequestSchema, async () => ({
  resources: [
    {
      uri: "skill://registry",
      name: "Skill Registry",
      description: "Full skill registry with agent mappings and triggers",
      mimeType: "text/markdown",
    },
    ...Array.from(skills.keys()).map((name) => ({
      uri: `skill://${name}`,
      name: `Skill: ${name}`,
      description: skills.get(name)?.description || name,
      mimeType: "text/markdown",
    })),
  ],
}));

server.setRequestHandler(ReadResourceRequestSchema, async (request) => {
  const uri = request.params.uri;

  if (uri === "skill://registry") {
    const lines = [
      `# Skill Registry (${skills.size} skills)`,
      ``,
      buildSummaryTable(skills),
      ``,
      `## All Skills`,
      ...Array.from(skills.values()).map(
        (s) => `- **${s.name}** — ${s.agent} — ${s.triggers.slice(0, 3).join(", ")}`
      ),
    ];
    return {
      contents: [{ uri, mimeType: "text/markdown", text: lines.join("\n") }],
    };
  }

  const skillName = uri.replace("skill://", "");
  const skill = skills.get(skillName);
  if (!skill) {
    throw new Error(`Skill not found: ${skillName}`);
  }

  return {
    contents: [
      {
        uri,
        mimeType: "text/markdown",
        text: [
          `# ${skill.name}`,
          `**Agent**: ${skill.agent}`,
          `**Description**: ${skill.description}`,
          `**Triggers**: ${skill.triggers.join(", ") || "(none)"}`,
          ``,
          skill.detail ? `## Detail\n${skill.detail}` : "",
        ]
          .filter(Boolean)
          .join("\n"),
      },
    ],
  };
});

async function main() {
  const transport = new StdioServerTransport();
  await server.connect(transport);
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
