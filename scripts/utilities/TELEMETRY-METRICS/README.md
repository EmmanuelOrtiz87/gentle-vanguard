# TELEMETRY-METRICS

Centralized management reporting system for Gentle-Vanguard.

## Purpose

Single CSV file per month containing ALL workspace activity metrics for executive visibility.

## Report Format

**File**: `reports/MANAGEMENT-REPORT-YYYY-MM.csv`

**Columns**:

- SessionID: Unique session identifier
- Date: Session date (YYYY-MM-DD)
- User: Who ran the session
- Project: Project worked on
- TokensIn: Input tokens consumed
- TokensOut: Output tokens generated
- SkillsUsed: Skills loaded (semicolon-separated)
- SystemsTriggered: Autonomous systems activated
- ActionsPerformed: What was done
- Outcome: COMPLETE/ESCALATED/PENDING
- IssuesFound: Number of issues found
- Duration(min): Session duration in minutes
- Cost(USD): Estimated cost (tokens rate)
- Notes: Additional context

## Monthly Rotation

When month changes:

1. Script notifies: " Month changed! Export reports/MANAGEMENT-REPORT-YYYY-MM.csv"
2. User exports old file (Excel-ready, filterable)
3. Run with `-ForceNewMonth` to create new empty file
4. New file starts fresh for new month

This preserves history (one file per month) without data loss.

## Usage

```powershell
# Generate/update current month report
.\scripts\utilities\TELEMETRY-METRICS\generate-management-report.ps1

# Force new month (after exporting old file)
.\scripts\utilities\TELEMETRY-METRICS\generate-management-report.ps1 -ForceNewMonth
```

## Automation

Recommended: Add to session-close hook to auto-append sessions.

## Data Sources

- `.session/*.json` - Session data, duration, outcome
- `.telemetry/*.json` - Token usage, initialization data
- Engram memory - Skills used, actions performed, issues
- `scripts/adaptive/*` - Autonomous system triggers

## Skill

Management reporting skill available at:
`~/.config/opencode/skills/management-reporting-skill/SKILL.md`

Triggers: "management report", "generar informe", "reporte gerencial"
