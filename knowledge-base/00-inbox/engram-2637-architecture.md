---
created: 2026-08-08 04:00:41
tags: [engram, architecture]
engram_id: 2637
type: architecture
---

# Skill Analysis: External Skills for Gentle-Vanguard Stack

**What**: Analyzed 23 external skills from BA有哪些 (Build/Design/Research/Marketing) and 2 external tools (witr, firecrawl) for potential integration into Gentle-Vanguard.

**Why**: User requested to analyze which skills could benefit the stack and whether witr/firecrawl functionality should be natively implemented.

**Analysis Results**:

## Build Skills (6 skills)

| Skill | Stack Fit | Verdict | Reasoning |
|-------|-----------|---------|-----------|
| **Superpowers** (Plans before writes) | ✅ HIGH | ABSORB | Replaces/Enhances `planning-and-task-breakdown` with more structured pre-write planning. Aligns with spec-driven development |
| **GStack** (23 skills in one) | ⚠️ MEDIUM | INSPECT | Likely overlaps with our 49 skills. Need to check for gaps vs duplicates |
| **Caveman** (No-fluff) | ❌ LOW | SKIP | Conflicts with `cognitive-doc-design` and documentation goals |
| **Ponytail** (One-liner outputs) | ❌ LOW | SKIP | Too constrained; limits debugging/troubleshooting depth |
| **Codex** (Codex inside Claude) | ❌ NO | SKIP | Circular/counter-productive in this stack context |
| **I-Have-ADHD** (Straight to answer) | ❌ LOW | SKIP | Conflicts with doubt-driven-development and thorough analysis |

## Design Skills (6 skills)

| Skill | Stack Fit | Verdict | Reasoning |
|-------|-----------|---------|-----------|
| **UI-UX-Pro-Max** (Fonts & color palettes) | ✅ HIGH | ABSORB | Enhances `frontend-ui-engineering` with design system capabilities |
| **Taste-Skill** (Premium designs) | ✅ MEDIUM | ABSORB | Complements existing frontend skill with aesthetic polish |
| **Impeccable** (UI polish) | ⚠️ MEDIUM | CONSIDER | Overlap with Taste-Skill below? Needs deduplication |
| **Hyperframes** (Webpage→video) | ⚠️ LOW | SKIP | Very specific use case, not core stack functionality |
| **Emil** (Beautiful animations) | ✅ MEDIUM | ABSORB | Extends our animations beyond GSAP fundamentals |
| **GSAP** (Smooth animations) | ⚠️ NATIVE | EXISTS | We already have this functionality via dashboard/web components |

## Research Skills (6 skills)

| Skill | Stack Fit | Verdict | Reasoning |
|-------|-----------|---------|-----------|
| **Skill-Creator** (Build Claude skills) | ❌ NO | SKIP | Meta-skill; we use skills directly, not through another tool |
| **Graphify** (Visual maps from notes) | ⚠️ MEDIUM | SKIP | We have graphify-nativ in graphify-out/, no need for external |
| **Last30Days** (Latest discussions) | ✅ HIGH | ABSORB | Fills gap in research capabilities for trend tracking |
| **Agent-Browser** (Claude uses websites) | ✅ HIGH | ABSORB | Significant gap - no native web browsing capability |
| **Find-Skills** (Find right skill) | ⚠️ NATIVE | EXISTS | Our `using-agent-skills` already does this |
| **Claude-HUD** (Live actions visibility) | ✅ MEDIUM | ABSORB | Enhances observability beyond current dashboard |

## Marketing Skills (4 skills)

| Skill | Stack Fit | Verdict | Reasoning |
|-------|-----------|---------|-----------|
| **Remotion** (Videos with React) | ⚠️ LOW | SKIP | Specific tool, not a skill pattern |
| **MarketingSkills** (40 skills pack) | ⚠️ MEDIUM | INSPECT | Need to check overlap with existing `marketing-content-writer` |
| **Humanizer** (Remove AI sound) | ✅ MEDIUM | ABSORB | Enhances technical-writing with AI-neutral tone |
| **Social-Media-Skills** (Content workflows) | ❌ LOW | SKIP | Out of scope for development stack |

## External Tools Analysis

### witr (19.8k ⭐) - pranshuparmar/witr

**"Why is this running?"** - Trace process chain causality

| Aspect | Assessment |
|--------|------------|
| **Language** | Go (single static binary) |
| **Platform** | Linux, macOS, Windows, FreeBSD |
| **Use Case** | Debug running processes, ports, containers, files |
| **Stack Fit** | ✅ HIGH for debugging; partially overlaps with maintenance-watchtower |
| **Verdict** | **NATIVE INTEGRATION** - Add as optional dependency or absorb core logic in watchtower |

**Why native**:
- Complements our maintenance-watchtower.ts (834 lines) |
- Fills gap: "doubt-driven-development" in maintenance context |
- Single binary = easy integration |
- Would enhance "debugging-and-error-recovery" skill |

### firecrawl (162.9k ⭐) - firecrawl/firecrawl

**"Context API for web"** - Search, scrape, extract at scale

| Aspect | Assessment |
|--------|------------|
| **Language** | TypeScript/API-based |
| **Features** | Search, Scrape, Crawl, Map, Batch scrape, Interact via Actions |
| **Output** | Clean Markdown, HTML, screenshots, structured JSON |
| **Stack Fit** | VERY HIGH |
| **Verdict** | **NATIVE IMPLEMENTATION HIGHLY RECOMMENDED** |

**Why native**:
- **Agent-Browser gap**: firecrawl replaces/supersedes "Agent-Browser" skill |
- **Document processing**: Enhances `document-processor` with web content |
- **Research capability**: Enables `Last30Days` functionality |
- **Context engineering**: Web context compression for prompts |
- Built for LLM consumption (token-efficient output) |
| | **Scalable**: Handles proxies, rate limits, JS execution |
| | **TypeScript**: Native language match |

---

**Where**: .opencode/skills/ analysis, external repo inspection

**Learned**:
1. **3 HIGH priority absorbs**: Superpowers, Agent-Browser (via firecrawl), UI-UX-Pro-Max, Last30Days, Witr
2. **4 MEDIUM priority inspects**: GStack, MarketingSkills, Taste-Skill, Emil, Humanizer, Impeccable
3. **GitHub repos provide excellent data**: witr = 19.8k stars, firecrawl = 162.9k stars - both proven validations of concepts
4. **Firecrawl is the biggest gap-filler**: All research skills (Last30Days, Agent-Browser) could be satisfied by native firecrawl integration

---
*Imported from Engram on 2026-09-06*
