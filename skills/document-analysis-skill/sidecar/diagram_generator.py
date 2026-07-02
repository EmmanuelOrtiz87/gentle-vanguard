import re, subprocess, tempfile, os
from typing import Any

MERMAID_TEMPLATES = {
    "flowchart": "```mermaid\nflowchart {direction}\n{content}\n```",
    "sequence": "```mermaid\nsequenceDiagram\n{content}\n```",
    "class": "```mermaid\nclassDiagram\n{content}\n```",
    "state": "```mermaid\nstateDiagram-v2\n{content}\n```",
    "gantt": "```mermaid\ngantt\n    title {title}\n    dateFormat  YYYY-MM-DD\n    section {section}\n{content}\n```",
    "pie": "```mermaid\npie title {title}\n{content}\n```",
    "er": "```mermaid\nerDiagram\n{content}\n```",
    "mindmap": "```mermaid\nmindmap\n{content}\n```",
    "timeline": "```mermaid\ntimeline\n    title {title}\n{content}\n```",
    "gitgraph": "```mermaid\ngitGraph\n{content}\n```",
    "c4_context": "```mermaid\nC4Context\n{content}\n```",
    "c4_container": "```mermaid\nC4Container\n{content}\n```",
    "c4_component": "```mermaid\nC4Component\n{content}\n```",
}

PLANTUML_TEMPLATES = {
    "flowchart": "@startuml\n{content}\n@enduml", "sequence": "@startuml\n{content}\n@enduml",
    "class": "@startuml\n{content}\n@enduml", "usecase": "@startuml\n{content}\n@enduml",
    "activity": "@startuml\n{content}\n@enduml", "component": "@startuml\n{content}\n@enduml",
    "state": "@startuml\n{content}\n@enduml", "object": "@startuml\n{content}\n@enduml",
}

PATTERN_LIBRARY = {
    "api_flow": {"mermaid": ("sequence", ["participant Client", "participant API", "participant Database",
        "Client->>API: HTTP Request", "API->>Database: Query", "Database-->>API: Results", "API-->>Client: HTTP Response"]),
        "plantuml": ("sequence", ["actor Client", "participant API", "participant Database",
            "Client -> API: HTTP Request", "API -> Database: Query", "Database --> API: Results", "API --> Client: HTTP Response"])},
    "microservices": {"mermaid": ("flowchart", ["subgraph API Gateway", "    GW[Gateway]", "end",
        "subgraph Services", "    A[Auth Service]", "    B[Billing Service]", "    C[Catalog Service]", "    D[Notification Service]", "end",
        "GW --> A", "GW --> B", "GW --> C", "GW --> D"]),
        "plantuml": ("component", ["package API_Gateway {", "    [Gateway]", "}", "package Services {",
            "    [Auth Service]", "    [Billing Service]", "    [Catalog Service]", "    [Notification Service]", "}",
            "Gateway --> [Auth Service]", "Gateway --> [Billing Service]", "Gateway --> [Catalog Service]", "Gateway --> [Notification Service]"])},
}

def _natural_to_mermaid_lines(description, diagram_type):
    lines = []
    if diagram_type == "flowchart":
        for s in re.split(r'[.;]', description):
            s = s.strip()
            if not s: continue
            if '->' in s or '-->' in s or '->>' in s: lines.append(f"    {s}")
            elif ' if ' in s.lower(): lines.append(f"    if{{${s}}}")
            else: lines.append(f"    N{len(lines)}[{s}]")
    elif diagram_type == "sequence":
        for s in re.split(r'[.;]', description):
            s = s.strip()
            if not s: continue
            if '->' in s or '-->' in s: lines.append(f"    {s}")
            elif 'participant' in s.lower() or 'actor' in s.lower(): lines.append(f"    {s}")
            else: lines.append(f"    Note over N{len(lines)}: {s}")
    else: lines.append(f"    {description}")
    return lines

def generate_mermaid(description, diagram_type="flowchart"):
    diagram_type = diagram_type.lower()
    if diagram_type not in MERMAID_TEMPLATES: diagram_type = "flowchart"
    template_data = PATTERN_LIBRARY.get(description.lower().replace(" ", "_"))
    if template_data and template_data["mermaid"][0] == diagram_type:
        content = "\n".join(f"    {line}" for line in template_data["mermaid"][1])
        return MERMAID_TEMPLATES[diagram_type].format(content=content, direction="TD", title=description.title(), section="Main")
    raw_lines = _natural_to_mermaid_lines(description, diagram_type)
    content = "\n".join(raw_lines)
    return MERMAID_TEMPLATES[diagram_type].format(content=content, direction="TD", title=description.title(), section="Main")

def generate_plantuml(description, diagram_type="sequence"):
    diagram_type = diagram_type.lower()
    if diagram_type not in PLANTUML_TEMPLATES: diagram_type = "sequence"
    template_data = PATTERN_LIBRARY.get(description.lower().replace(" ", "_"))
    if template_data and template_data["plantuml"][0] == diagram_type:
        content = "\n".join(f"    {line}" for line in template_data["plantuml"][1])
        return PLANTUML_TEMPLATES[diagram_type].format(content=content)
    raw_lines = _natural_to_mermaid_lines(description, diagram_type)
    content = "\n".join(raw_lines)
    return PLANTUML_TEMPLATES[diagram_type].format(content=content)

def render_to_svg(mermaid_code):
    try:
        with tempfile.NamedTemporaryFile(mode="w", suffix=".mmd", delete=False, encoding="utf-8") as f:
            f.write(mermaid_code.replace("```mermaid", "").replace("```", "").strip()); mmd_path = f.name
        svg_path = mmd_path.replace(".mmd", ".svg")
        result = subprocess.run(["mmdc", "-i", mmd_path, "-o", svg_path], capture_output=True, text=True, timeout=30)
        if result.returncode != 0 or not os.path.exists(svg_path): return None
        with open(svg_path, "r", encoding="utf-8") as f: svg = f.read()
        return svg
    except (FileNotFoundError, subprocess.TimeoutExpired, Exception): return None
    finally:
        for p in [mmd_path, svg_path]:
            try:
                if os.path.exists(p): os.unlink(p)
            except Exception: pass
