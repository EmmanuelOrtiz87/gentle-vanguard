# Fermi Estimation Examples

## Example 1: Data Storage Needs

**Question:** How much storage will our new feature need in Year 1?

**Decomposition:** Storage = Users × Events/User/Day × Event Size × Days × Replication

| Factor | Estimate | Confidence |
|---|---|---|
| Users (DAU average) | 150,000 | High |
| Events/user/day | 50 | Medium |
| Event size | 500 bytes | High |
| Days | 365 | Certain |
| Replication | 3x | High |

**Calculation:** 150,000 × 50 × 500 × 365 × 3 = 4.1 TB

**Result:** ~4 TB (range: 1-15 TB). Standard database tier sufficient; ~$500/month.

---

## Example 2: API Rate Capacity

**Question:** Can our API handle Black Friday traffic?

**Decomposition:** Required RPS = Peak DAU × Req/Session × Sessions/Day × Peak Multiplier / 3600

**Calculation:** (500,000 × 30 × 2 × 5) / 3,600 ≈ 40,000 RPS

**Result:** 40,000 RPS peak. Current capacity: 10,000 RPS. Need 4x increase + auto-scaling to 60K RPS.

---

## Example 3: Market Size

**Question:** How many potential customers for our developer tool?

**Decomposition:** TAM = Software Companies × Segment% × Devs/Company × Adoption% × Price

**Calculation:** 50,000 × 30 × 20% = 300,000 users. Revenue = 300,000 × $50 × 12 = $180M/year TAM.

**Result:** TAM ~$180M/year. Serviceable: $10-20M/year. Market size justifies investment if capturing 5%+.
