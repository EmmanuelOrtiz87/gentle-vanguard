---
name: content-output-skill
description: >
  Unified content generation skill for all output types: technical documentation, internal reports,
  marketing content, social media posts, persuasive copy, storytelling, speeches, and external
  communication. Covers complete content lifecycle: strategy  creation  distribution  metrics.
  Trigger: "post", "twitter", "linkedin", "redes", "social", "marketing", "promocionar", "publicar",
  "anuncio", "lanzamiento", "demo", "video", "branding", "logo", "copywriting", "persuasivo",
  "storytelling", "discurso", "presentacion", "expo", "congreso", "workshop", "reddit", "discord",
  "whatsapp", "informe", "report", "reporte", "documentación", "docs", "publicacion", "comunicacion"
license: Apache-2.0
metadata:
  author: workspace-local
  versión: '3.0'
---

# Content Output Skill (v3.0)

## Purpose

Unified skill for generating all types of content output from Gentle-Vanguard:

- **Technical Docs**: API docs, README, guides, references
- **Internal Reports**: Session metrics, costs, performance
- **External Communication**: Marketing, social media, presentations
- **Speeches**: Conferences, workshops, demos

Part of the workflow: Input Processing Output (Docs + Communication)

## Content Types

| Type            | Platform      | Format             | Purpose                        |
| --------------- | ------------- | ------------------ | ------------------------------ |
| **Tweet/X**     | Twitter/X     | 280 chars + thread | Quick announcement, engagement |
| **LinkedIn**    | LinkedIn      | 3000 chars + media | Professional reach, B2B        |
| **Instagram**   | Instagram     | Caption + hashtags | Visual brand                   |
| **Reddit**      | Reddit        | Text + links       | Community discussion, feedback |
| **Discord**     | Discord       | Embed + CTA        | Community engagement           |
| **WhatsApp**    | WhatsApp      | Broadcast message  | Direct reach, groups           |
| **Blog Post**   | Web           | MD HTML            | SEO, deep content              |
| **Demo Script** | Video         | 2-3 min            | Product demo                   |
| **Speech**      | Presentations | 5-30 min           | Conferences, workshops         |

---

## TECHNICAL DOCUMENTATION

### Types (from `documentation-skill`)

| Type          | Purpose                  | Output                |
| ------------- | ------------------------ | --------------------- |
| **README**    | Project entry point      | `README.md`           |
| **API Docs**  | Auto-generated from code | OpenAPI/Swagger       |
| **Guides**    | How-to tutorials         | `docs/guides/*.md`    |
| **Reference** | Technical specs          | `docs/reference/*.md` |
| **Changelog** | versión history          | `CHANGELOG.md`        |

### Documentation Standards

```
REQUIRE:
- All public APIs require docstrings
- README minimum: description + quick start
- Changelog for all releases

PREFER:
- Usage examples inline
- Code comments for complex logic
- Diagrams for architecture
```

### See Also

- `skills/documentation-governance/SKILL.md` - Full governance rules
- `docs/TOKEN-CONTEXT-STANDARDS.md` - Detailed standards

---

## INTERNAL REPORTS

### Types

| Type               | Trigger               | Output                   |
| ------------------ | --------------------- | ------------------------ |
| **Session Report** | "informe sesiónes"    | `docs/sessions/metrics/` |
| **Cost Report**    | "informe costos"      | Token usage, USD         |
| **Performance**    | "informe performance" | Velocity metrics         |
| **Executive**      | "resumen ejecutivo"   | Board-ready summary      |

### Quick Commands

```powershell
# Session metrics
.\scripts\utilities\session-metrics-collector.ps1 -Period 7days

# Cost analysis
.\scripts\utilities\token-telemetry.ps1 -CostPer1MTokens 15

# Executive summary
.\scripts\utilities\generate-executive-summary.ps1
```

### See Also

- `skills/reporting-skill/SKILL.md` - Full reporting details

---

## COPYWRITING PERSUASIVO

### Frameworks

#### AIDA (Attention, Interest, Desire, Action)

```
A - Attention: Hook inicial shocking o pregunta
I - Interest: Desarrollar con datos/historias
D - Desire: Mostrar beneficios tangibles
A - Action: CTA claro
```

#### PAS (Problem, Agitation, Solution)

```
P - Problem: Describir el dolor del usuario
A - Agitation: Intensificar sin resolver
S - Solution: Presentar Gentle-Vanguard como solucin
```

#### BAB (Before, After, Bridge)

```
B - Before: Estado actual del usuario
A - After: Estado deseada con Gentle-Vanguard
B - Bridge: Cmo llegar del Before al After
```

### Tcnicas de Persuasin

1. **Social Proof**: "X equipos ya lo usan"
2. **Autoridad**: "Usado por developers de Y"
3. **Escasez**: "Solo disponibles hasta..."
4. **Urgencia**: "ltima semana para..."
5. **Consenso**: "El 90% recomienda..."
6. **Reciprocidad**: "Gratis por tiempo limitado"

### Templates Persuasivos

#### Announce Feature

```
 [PROBLEMA QUE RESUELVE]

[CONTEXTO - 1-2 oraciones]

 SOLUCIN: [FEATURE NAME]

[BENEFICIO PRINCIPAL]

 [CTA]

#Gentle-VanguardStack
```

#### Testimonial Request

```
Ya usas Gentle-Vanguard?
Cuntanos tu experiencia

Tu feedback nos ayuda a mejorar.
[#Gentle-VanguardStack]
```

---

## STORYTELLING AUDIOVISUAL

### Struktura deHistoria

#### Hero's Journey Adaptado

```
1. ORDINARIO: El developer sin herramientas
2. LLAMADO: Descubrir Gentle-Vanguard
3. PRUEBAS: Learning curve, configuración
4. MENTOR: Skills y documentacin
5. TRANSFORMACIN: Productividad X10
6. REGRESO: Compartir con el equipo
```

### Story Formats

#### Thread de Twitter

```
 1/x
Cmo pas de 0 a 100 tasks/semana con AI...

[SETUP - contexto breve]

Thread

2/x
El problema: context hell, sesiónes perdidas...
Cada vez que iniciaba, tardaba 30min solo en recapitular.

3/x
Ento encontr Gentle-Vanguard:
- Engram: memoria persistente
- Auto-delegation: 70% tiempo recuperado
- Token guard: 40% menos tokens

[CONTINUA...]
```

#### LinkedIn Story Post

```
 De developer frustrado a 10x productivity

Hace 3 meses, mi workflow era un desastre:

 Context switching entre 5 proyectos
 Perda 30min cada maana recapitando
 No tena forma de medir mi progreso

Hoy:
 memoria persistente via Engram
 Auto-delegation a subagentes
 Reporting automtico

El cambio no fue el tool. Fue el sistema.

Thread below

#Productivity #AI #Development
```

---

## SPEECHES & PRESENTACIONES

### estructura de Discurso

#### Opening (30-60 segundos)

```
[HOOK]
"Cuntas veces han perdido 30min recapitando lo que hicieron ayer?"

[CONTEXT]
"Yo perda eso cada maana. Durante meses."

[THESIS]
"Hoy les voy mostrar cmo lo resolv."

[ROADMAP]
"3 cosas: el problema, la solucin, los resultados."
```

#### Presentacin tech conference (15 min)

```
0:00-1:00  Hook + Introduccin
1:00-4:00  Problema (con datos)
4:00-9:00  Solucin Gentle-Vanguard
9:00-13:00 Demo live
13:00-14:00  Resultados + CTA
14:00-15:00 Q&A
```

#### Workshop intro (30 min)

```
0:00-5:00   Por qu aqu (pain compartido)
5:00-12:00  Conceptos core
12:00-25:00Hands-on: setup bsico
25:00-30:00 Q&A + prximos pasos
```

### Speaking Tips

1. **3 segundos rule**: Nuevo hook cada 3 min
2. **Visuals**: screenshots > diagrams > text
3. **Pausas**: Silencio despus de key points
4. **Repeticin**: Say it three ways
5. **CTA**: Sempre terminar con action

## Gentle-Vanguard Stack Description Templates

### Short (Twitter/X - 280 chars)

```
# Gentle-VanguardStack
 AI Development Workspace
- Session tracking & metrics
- Auto-delegation con orquestador
- Reporting on-demand
- Token efficiency
#DevTools #AI #OpenCode
```

### Medium (LinkedIn - 2-3 paragraphs)

```
 Presentando Gentle-Vanguard: Mi AI Development Workspace

Gentle-Vanguard es un workspace agnstico para desarrollo AI-first que incluye:

 Session Management con tracking de mtricas
 Auto-delegation que routedareas subagentes especializados
 Reporting on-demand para gerencia
 Token Guard para eficiencia de contexto
 Workflow orchestrator integrado

Ideal para equipos que usan AI assistants (OpenCode, Claude, Cursor).

#Gentle-VanguardStack #AIDevelopment #OpenCode #DevTools
```

### Long (Blog Post)

Ver: `docs/marketing/gentle-vanguard-stack-blog-post.md`

---

## PLATFORM SPECIFICS

### Reddit (r/programming, r/devops, r/ArtificialIntelligence)

#### Post Types

```
- SHOW_RHNTHONIC: "I built X, feedback?" [Screenshots + code]
- QUESTION: "[Topic] - best practices?" [Context + specific Q]
- DISCUSSION: "[Hot take] on [topic]" [Controversial opinion]
- TUTORIAL: "How to [achieve result] in [steps]" [Step-by-step]
```

#### Reddit Template

```
**Context**: [Brief background - 2-3 lines]

**What I built**: [Description]

**The problem it solves**: [Pain point]

**Looking for**:
- Feedback on [specific areas]
- Suggestións for [improvements]
- Questions welcome

[Link to repo in comments]
```

---

### Discord (Community Servers)

#### Message Types

```
- ANNOUNCEMENT: New feature release with emoji + links
- QUESTION: Thread con preguntas especficas
- SHOWCASE: Screenshot + "look what I made"
- POLL: Voting embeds para feedback
```

#### Discord Template

```
 **Nuevo en Gentle-Vanguard [v2.x]**

[Feature description]

 What's new:
- [Feature 1]
- [Feature 2]

 Get it: [Link]
 Feedback: [Channel link]

#Gentle-VanguardStack
```

---

### WhatsApp (Broadcasts + Groups)

#### Message Types

```
- BROADCAST: Announcement short + link
- GROUP: Discussion topic
- STATUS: Milestone achieved
```

#### WhatsApp Template

```
 Gentle-Vanguard Update v2.x

[1-liner sobre lo nuevo]

 [Link to full post]

Preguntas? Responde aqu
#Gentle-VanguardStack
```

---

## Logo & Branding

### Gentle-Vanguard Logo (Text-based)

```









     F O U N D A T I O N


```

### ASCII Art Alternative

```








       GENTLE_VANGUARD

```

## Hashtags

| Category | Hashtags                        |
| -------- | ------------------------------- |
| Stack    | #Gentle-VanguardStack #AIDevelopment |
| Tools    | #OpenCode #Claude #Cursor       |
| Spanish  | #DevES #desarrolloES            |
| General  | #DevTools #AI #Productivity     |

## Posting Schedule

| Day       | Content           |
| --------- | ----------------- |
| Monday    | Feature highlight |
| Wednesday | Tutorial/Tip      |
| Friday    | Week recap        |

## Best Practices

1. **Keep it short** - Lead with the value proposition
2. **Use visuals** - Screenshots, ASCII art, diagrams
3. **Include CTA** - "Try it at" or "Learn more"
4. **Engage** - Ask questions, invite discussion
5. **Cross-post** - Adapt for each platform

## Usage

```powershell
# Generate a tweet about the stack
# Use this skill to create 3-5 variations

# Generate LinkedIn post
# Use to create professional announcement

# Create demo script
# Use for video content
```

## Metrics to Track

- Impressions (views)
- Engagements (likes, comments, shares)
- Click-throughs (link clicks)
- Conversións (installs, signups)

---

_Skill versión: 3.0_  
_Last updated: 2026-04-27_

