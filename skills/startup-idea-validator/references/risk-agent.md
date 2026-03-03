# Devil's Advocate Agent — Detailed Evaluation Criteria

## Risk Scoring Rubric (0-100, where 100 = extremely risky)

### Regulatory & Legal Risk (0-20 points)
- **0-5**: No regulatory concerns; standard software business
- **6-10**: Minor compliance requirements (GDPR, standard ToS)
- **11-15**: Industry-specific regulations that require legal review
- **16-20**: Heavy regulatory burden; potential for shutdown or fines

### Market Risk (0-20 points)
- **0-5**: Proven demand; people already pay for similar solutions
- **6-10**: Demand exists but unproven at this price/format
- **11-15**: Speculative demand based on trends, not validated behavior
- **16-20**: No evidence of willingness to pay; solution assumes behavior change

### Execution Risk (0-20 points)
- **0-5**: Straightforward build; well-understood technology stack
- **6-10**: Moderate complexity; requires some specialized skills
- **11-15**: High complexity; multiple integration points, real-time requirements
- **16-20**: Requires breakthroughs, novel algorithms, or unproven infrastructure

### Distribution Risk (0-20 points)
- **0-5**: Clear organic distribution channel; SEO, marketplace, or viral loop
- **6-10**: Distribution possible but requires consistent content or outreach
- **11-15**: Depends on partnerships, platform access, or paid acquisition
- **16-20**: No clear distribution; "if you build it they will come" assumption

### Capital & Sustainability Risk (0-20 points)
- **0-5**: Can reach profitability with < $10K; bootstrappable
- **6-10**: Needs $10-50K; manageable for a solo founder
- **11-15**: Needs $50-250K; requires external funding or savings runway
- **16-20**: Needs > $250K before any revenue; venture-scale risk

## Failure Scenario Framework

For each idea, construct exactly 5 failure scenarios from these categories:

1. **Demand Collapse**: Users try it but don't retain; the problem isn't painful enough
2. **Competitive Response**: An incumbent adds this feature in weeks
3. **Distribution Failure**: Cannot acquire users at sustainable cost
4. **Regulatory Kill**: Government action, platform policy change, or legal challenge
5. **Execution Stall**: Technical debt, scope creep, or founder burnout before product-market fit
6. **Margin Squeeze**: Unit economics don't work at scale
7. **Platform Risk**: Dependency on a third-party API, marketplace, or algorithm
8. **Timing Mismatch**: Too early (market not ready) or too late (market captured)

Select the 5 most likely from the above for each idea.

## Kill or Continue Decision Framework

**KILL** if any of these are true:
- Risk Score > 75
- Any single risk category scores 18+
- No plausible path to $10K MRR in 12 months
- Regulatory risk could result in legal liability for the founder
- Requires user behavior change AND has no clear distribution

**CONTINUE** if:
- Risk Score < 60
- No single category above 15
- Clear path to first paying customer within 90 days
- Risks are manageable with standard mitigations

**CONDITIONAL CONTINUE** if:
- Risk Score 60-75
- Specific risks are high but addressable
- Provide explicit conditions that must be true for viability
