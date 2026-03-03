# Business & Market Analyst Agent — Detailed Evaluation Criteria

## Scoring Rubric (0-100)

### Market Size (0-20 points)
- **16-20**: TAM > $10B, SAM > $1B, SOM > $10M achievable in 3 years
- **11-15**: TAM $1-10B, reasonable SAM, SOM > $1M in 2 years
- **6-10**: TAM < $1B or niche market, SOM < $1M in first 2 years
- **0-5**: Tiny or nonexistent market; hobby-scale opportunity

### TAM/SAM/SOM Calculation Method
- **TAM**: Total addressable market. Use top-down (industry reports) or bottom-up (number of potential users x average revenue per user).
- **SAM**: Serviceable addressable market. TAM filtered by geography, segment, and go-to-market reach.
- **SOM**: Serviceable obtainable market. Realistic capture in 12-24 months given resources and competition. Show your math with explicit assumptions.

### Unit Economics & LTV:CAC (0-25 points)

This is the most important category for bootstrapped startups.

- **20-25**: LTV:CAC ratio > 3:1. Payback period < 3 months. Clear unit economics with proven willingness to pay at the target price point.
- **15-19**: LTV:CAC ratio 2-3:1. Payback period 3-6 months. Pricing benchmarked against what users currently pay for alternatives.
- **10-14**: LTV:CAC unclear but plausible. No direct pricing benchmarks from alternatives. Requires experimentation.
- **0-9**: No clear unit economics. CAC likely exceeds LTV. Users don't currently pay for anything similar.

**Required calculations:**
- **ARPU** (Average Revenue Per User): Based on pricing research of alternatives, not aspirational pricing.
- **Estimated CAC**: Based on the most likely acquisition channel (organic, content, paid, partnerships).
- **LTV**: ARPU x (1 / monthly churn rate). Use realistic churn: 5-10% monthly for B2C, 3-5% for B2B.
- **Payback period**: CAC / monthly ARPU.

### Revenue Model Clarity (0-20 points)
- **16-20**: Obvious monetization; users already pay for similar products; clear pricing benchmarks exist. Anchor pricing to what users currently spend on alternatives.
- **11-15**: Viable model but requires market education or novel pricing structure.
- **6-10**: Monetization possible but unproven in this segment. No direct pricing comparables.
- **0-5**: No clear path to revenue; relies on scale-then-monetize logic.

### Competitive Landscape (0-20 points)
- **16-20**: White space or weak incumbents; no dominant player. Clear gap in existing offerings.
- **11-15**: 1-2 competitors but with clear gaps exploitable by a focused entrant.
- **6-10**: 3+ competitors; market is being addressed but not saturated. Differentiation is possible.
- **0-5**: Saturated market with well-funded incumbents; red ocean.

### Speed to First Revenue (0-15 points)
- **12-15**: Revenue within 30 days of launch (direct sales, freemium conversion, marketplace listing).
- **8-11**: Revenue within 60-90 days; requires some user base building.
- **4-7**: Revenue in 3-6 months; requires marketplace dynamics or enterprise sales cycles.
- **0-3**: Revenue 6+ months out; depends on scale, partnerships, or regulatory clearance.

## B2B vs B2C Adjustment

The dynamics are fundamentally different. Always identify which model applies and adjust analysis:

| Factor | B2C | B2B |
|--------|-----|-----|
| Target ARPU | $5-30/month | $50-500+/month |
| Customers needed for $10K MRR | 333-2,000 | 20-200 |
| Typical churn | 5-10% monthly | 3-5% monthly |
| Conversion (free→paid) | 2-5% | 10-20% |
| Sales cycle | Minutes to days | Days to weeks |
| CAC tolerance | Low ($5-50) | Higher ($50-500) |
| Distribution | SEO, viral, marketplace | Content, outbound, partnerships |

## Revenue Projection Guidelines

All projections must state **explicit assumptions** for each variable. No hand-waving.

### Month 6 Estimate
- State the traffic/lead source and expected volume
- State the conversion rate (benchmarked against the B2B/B2C table above)
- State the ARPU (benchmarked against existing alternatives)
- State the monthly churn rate
- Assume organic growth only (no paid acquisition)
- Formula: `MRR = (cumulative signups x conversion rate x ARPU) - churn`

### Month 12 Estimate
- Allow for modest paid acquisition starting Month 4
- State the CAC and monthly ad spend assumed
- Assume 15-25% month-over-month growth for successful execution (justify which end of the range)
- Account for pricing optimization and upsell potential
- Formula: same as above + paid acquisition funnel

### Pricing Benchmark Validation
- Research what users currently pay for the closest alternatives
- If no direct alternative exists, find adjacent solutions in the same workflow
- Price anchoring: the startup should price within 0.5x-2x of the closest alternative unless there's a clear justification for premium or discount
- Flag any idea where the proposed price is > 3x what users currently pay for alternatives

## Competitive Research Requirements
- Identify top 3-5 competitors with URLs
- Note their funding, team size, and years in market
- Note their pricing (free tier, paid plans, enterprise)
- Identify specific gaps in their offering that the new entrant could exploit
- Assess likelihood of incumbent response to new entrant (low = niche they ignore, high = core to their roadmap)
