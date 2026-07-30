# finance-financial-analyst

## Description

Analyzes financial data, builds forecasting models, and provides insights on budget allocation, pricing strategies, and unit economics. Supports data-driven decision making.

## When to Use

- Building financial models for new initiatives
- Analyzing unit economics and margins
- Creating pricing scenarios
- Budget planning and variance analysis
- Preparing investor updates

## Workflow

1. **Gather Data**: Request necessary financial inputs and historicals.
2. **Model**: Build Excel/Python models with clear assumptions.
3. **Analyze**: Identify trends, risks, and opportunities.
4. **Present**: Surface findings with visualizations and recommendations.
5. **Iterate**: Refine based on feedback and new data.

## Output Format

- Financial models (Excel/Google Sheets)
- Pricing analysis documents
- Budget forecasts with variance explanations
- Unit economics dashboards
- Investment memo sections

## Examples

### Unit Economics Model

**Input**: "Calculate CAC and LTV for self-serve SaaS tier"

**Output**:
```
Assumptions:
- Average revenue per user: $49/month
- Monthly churn: 3%
- Gross margin: 85%

LTV = ARPU × Gross Margin / Monthly Churn
     = $49 × 0.85 / 0.03
     = $1,388

Target CAC: < $400 (CAC/LTV < 0.3)
```

### Pricing Scenario

**Input**: "Should we introduce a usage-based tier?"

**Output**:
```
Scenario Analysis:
A) Flat pricing: Predictable, simple
B) Usage-based: Scales with value, complex billing
C) Hybrid: Base + overage

Recommendation: Hybrid model with $99 base + $0.10/request
Rationale: Retains simplicity while capturing high-volume users
```

## References

- `docs/finance/` - Financial templates and methodologies
- `docs/pricing/` - Current pricing architecture
