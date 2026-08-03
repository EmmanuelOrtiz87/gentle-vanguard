#!/usr/bin/env python3
"""
Skill mapper - Analiza y corrige el mapeo entre skills virtuales y físicas
"""

import json
import sys
from pathlib import Path

# Skills físicas existentes
PHYSICAL_SKILLS = [
    "ab-testing", "api-and-interface-design", "browser-testing-with-devtools",
    "ci-cd-and-automation", "code-review-and-quality", "code-simplification",
    "context-engineering", "dashboard", "debugging-and-error-recovery",
    "deprecation-and-migration", "documentation-and-adrs", "doubt-driven-development",
    "engram-auto-update", "frontend-ui-engineering", "gentle-ai-monitor",
    "git-workflow-and-versioning", "idea-refine", "incremental-implementation",
    "interview-me", "knowledge-base", "live-traceability", "maintenance",
    "observability", "observability-and-instrumentation", "performance-optimization",
    "planning-and-task-breakdown", "safety", "security-and-hardening",
    "shipping-and-launch", "source-driven-development", "spec-driven-development",
    "test-driven-development", "using-agent-skills", "validate-stack"
]

# Mapeo propuesto: virtual -> física
SKILL_MAPPING = {
    # Agentes core
    "sdd-lifecycle": "spec-driven-development",
    "judgment-day": "validate-stack",
    "session-workflow-skill": "context-engineering",
    "docker-devops-skill": "ci-cd-and-automation",
    "documentation-governance": "documentation-and-adrs",
    "script-governance-skill": "validate-stack",
    "project-orchestrator-skill": "planning-and-task-breakdown",
    "reporting-skill": "documentation-and-adrs",
    "code-review-orchestrator-skill": "code-review-and-quality",
    "release-management-skill": "shipping-and-launch",
    "self-diagnosis-skill": "debugging-and-error-recovery",
    "daily-workflow": "planning-and-task-breakdown",
    "business-telemetry-skill": "observability-and-instrumentation",
    "premortem-skill": "validate-stack",
    "codegraph-skill": "validate-stack",
    "sia-skill": "spec-driven-development",
    "maintenance-skill": "maintenance",
    "knowledge-base-skill": "knowledge-base",
    # Gitflow
    "gitflow-orchestrator-skill": "git-workflow-and-versioning",
    "git-workflow-skill": "git-workflow-and-versioning",
    "branch-pr": "git-workflow-and-versioning",
}

# Skills que necesitan ser creadas
MISSING_SKILLS = [
    "marketing-content-writer",
    "sales-account-executive",
    "finance-financial-analyst",
    "hr-talent-acquisition",
    "legal-compliance-officer",
]

def analyze_skills():
    """Analizar el estado actual de skills"""
    config_path = Path("config/auto-delegation.json")
    
    with open(config_path, "r", encoding="utf-8") as f:
        config = json.load(f)
    
    agent_codes = config.get("agentCodeToSkill", {})
    skill_profiles = config.get("skillToAgentProfile", {})
    
    virtual_skills = set(agent_codes.values())
    profile_skills = set(skill_profiles.keys())
    physical_normalized = {s.replace("-", "_") for s in PHYSICAL_SKILLS}
    
    print(f"Total skills en agentCodeToSkill: {len(virtual_skills)}")
    print(f"Total skills en skillToAgentProfile: {len(profile_skills)}")
    print(f"Total skills físicas: {len(PHYSICAL_SKILLS)}")
    print()
    
    # Skills sin SKILL.md físico
    unmapped = []
    for skill in virtual_skills:
        normalized = skill.replace("-", "_")
        if normalized not in physical_normalized:
            if skill in SKILL_MAPPING:
                print(f"[OK] {skill} -> {SKILL_MAPPING[skill]}")
            else:
                unmapped.append(skill)
                print(f"[MISSING] {skill} -> necesita SKILL.md")
    
    print()
    print(f"Skills sin mapear: {len(unmapped)}")
    return unmapped

def main():
    unmapped = analyze_skills()
    
    if unmapped and "--fix" in sys.argv:
        print("\nGenerando skill-creation-plan.json...")
        plan = {
            "missing_skills": MISSING_SKILLS,
            "unmapped_skills": unmapped,
            "suggested_mapping": SKILL_MAPPING
        }
        with open("reports/skill-creation-plan.json", "w", encoding="utf-8") as f:
            json.dump(plan, f, indent=2)
        print("Plan guardado en reports/skill-creation-plan.json")

if __name__ == "__main__":
    main()
