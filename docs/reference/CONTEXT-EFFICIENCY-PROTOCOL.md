# Context Efficiency Protocol

**versión:** 1.0 (Apr 20, 2026)  
**Effective:** Immediate

Defines how to maintain and improve context efficiency across all workspace interactions to
achieve > 70% efficiency rating.

## 1. Efficiency Targets

### 1.1 Metrics

- **Target Efficiency Rating**: > 70%
- **Warning Threshold**: < 60%
- **Critical Threshold**: < 50%

### 1.2 Measurement

Efficiency is measured by:

- Prompt average length < 1302 characters
- Reduced repeated constraints
- Proper use of references instead of full content
- Effective memory tiering utilization

## 2. Automatic Compaction

### 2.1 Trigger

Automatic compaction triggers at ~15k tokens with 90% retention.

### 2.2 Preserved Content Types

During compaction, these content types are preserved:

- FIXME
- TODO
- BUG
- decisión
- RESULT

### 2.3 Configuration

Pre-compact hook located at: `scripts/utilities/pre-compact-hook.ps1` Configuration:
`scripts/utilities/context-efficiency-config.json`

## 3. Engram Optimization

### 3.1 Proactive Save Triggers

Additional to standard Engram protocol, save context efficiency optimizations:

- When performing optimization work > 5 minutes
- After implementing efficiency improvements
- When discovering new optimization techniques

### 3.2 Reference Usage

Always reference existing Engram entries instead of repeating full content:

- Use `engram mem_search` before explaining concepts
- Reference observation IDs in communications
- Link to previous decisións rather than re-explaining

### 3.3 Redundancy Reduction

Reduce redundancy by:

- Pre-searching Engram for similar work
- Using standardized references
- Consolidating duplicate information
- Removing repeated constraints in follow-up prompts

## 4. Memory Tiering

### 4.1 Hot Memory (Active Session)

- Retention: None (current session only)
- Duration: Current session
- Content: Active working context

### 4.2 Warm Memory (Recent)

- Retention: 90%
- Duration: 1 day
- Content: Recently accessed information

### 4.3 Cold Memory (Archive)

- Retention: 70%
- Duration: 7 days
- Content: Historical archive information

## 5. Prompt Optimization

### 5.1 Length Management

Maintain average prompt length under 1302 characters by:

- Using concise language
- Referencing instead of repeating
- Breaking complex requests into smaller parts
- Using bullet points instead of paragraphs

### 5.2 Constraint Reduction

Avoid repeated constraints by:

- Defining them once and referencing
- Using configuration files
- Leveraging Engram for context recall
- Removing obvious or redundant requirements

### 5.3 Reference Patterns

Use references effectively:

- `[Reference: engram-obs-1234]` for Engram entries
- `[See: docs/reference/FILE.md]` for documentation
- `[Based on: previous-work-id]` for prior implementations

## 6. Implementation Requirements

### 6.1 Session Start

At session start, automatically:

- Run context efficiency optimization script
- Load previous session's efficiency metrics
- Apply known efficiency patterns
- Set efficiency monitoring

### 6.2 During Work

Throughout the session:

- Monitor context efficiency continuously
- Trigger auto-compaction when threshold reached
- Save optimization discoveries to Engram
- Reference previous work instead of repeating

### 6.3 Session End

At session end:

- Report final efficiency rating
- Save efficiency metrics to Engram
- Document improvements made
- Generate optimization recommendations

## 7. Tools and Scripts

### 7.1 Primary Scripts

- `scripts/utilities/optimize-engram-usage.ps1`: Main optimization script
- `scripts/utilities/pre-compact-hook.ps1`: Automatic compaction hook
- `scripts/utilities/session-autostart.cmd`: Enhanced startup with optimization

### 7.2 Configuration Files

- `scripts/utilities/context-efficiency-config.json`: Efficiency configuration
- `scripts/utilities/session-autostart.config.json`: Session configuration with efficiency settings

## 8. Monitoring and Alerts

### 8.1 Status Checks

Regular status checks via:

- `gv.ps1 status`: Show current efficiency rating
- `gv.ps1 diagnose`: Detailed efficiency analysis
- `engram mem_search "efficiency"`: Find related optimizations

### 8.2 Alerting

System alerts when:

- Efficiency drops below 60%: Warning level
- Efficiency drops below 50%: Critical level
- Auto-compaction triggered: Informational
- Optimization opportunities detected: Suggestións

## 9. Best Practices

### 9.1 Communication

- Be concise in explanations
- Reference documentation instead of repeating
- Use bullet points for clarity
- Link to Engram entries for details

### 9.2 Documentation

- Keep documents focused and concise
- Use references to external sources
- Maintain single source of truth
- Update documentation with efficiency improvements

### 9.3 Code Changes

- Explain the "why" not just the "what"
- Reference related Engram entries
- Keep comments concise but meaningful
- Remove obsolete or redundant code/comments

