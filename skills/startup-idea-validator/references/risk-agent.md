# Devil's Advocate Agent — Detailed Evaluation Criteria

## Risk Scoring Rubric (0-100, where 100 = extremely risky)

Always label the risk level explicitly alongside the score: e.g., "Risk Score: 35/100 (Low Risk)" or "Risk Score: 72/100 (High Risk)."

Risk level labels:
- **0-30**: Low Risk
- **31-50**: Moderate Risk
- **51-75**: High Risk
- **76-100**: Critical Risk

### Regulatory & Legal Risk (0-15 points)
- **0-4**: No regulatory concerns; standard software business
- **5-8**: Minor compliance requirements (GDPR, standard ToS, cookie consent)
- **9-12**: Industry-specific regulations that require legal review (fintech, health data, education)
- **13-15**: Heavy regulatory burden; potential for shutdown or fines

### Market Risk (0-15 points)
- **0-4**: Proven demand; people already pay for similar solutions
- **5-8**: Demand exists but unproven at this price/format
- **9-12**: Speculative demand based on trends, not validated behavior
- **13-15**: No evidence of willingness to pay; solution assumes behavior change

### Execution Risk (0-15 points)
- **0-4**: Straightforward build; well-understood technology stack
- **5-8**: Moderate complexity; requires some specialized skills
- **9-12**: High complexity; multiple integration points, real-time requirements
- **13-15**: Requires breakthroughs, novel algorithms, or unproven infrastructure

### Distribution Risk (0-15 points)
- **0-4**: Clear organic distribution channel; SEO, marketplace, or viral loop
- **5-8**: Distribution possible but requires consistent content or outreach
- **9-12**: Depends on partnerships, platform access, or paid acquisition
- **13-15**: No clear distribution; "if you build it they will come" assumption

### Capital & Sustainability Risk (0-15 points)
- **0-4**: Can reach profitability with < $10K; bootstrappable
- **5-8**: Needs $10-50K; manageable for a solo founder
- **9-12**: Needs $50-250K; requires external funding or savings runway
- **13-15**: Needs > $250K before any revenue; venture-scale risk

### Founder & Domain Expertise Risk (0-10 points)
- **0-3**: General software skills sufficient. No domain expertise required.
- **4-6**: Some domain knowledge needed but learnable in weeks (e.g., basic e-commerce, content workflows).
- **7-8**: Significant domain expertise required (fintech compliance, healthcare workflows, legal processes). Solo technical founder would struggle.
- **9-10**: Deep specialized knowledge mandatory. Cannot succeed without industry insider or co-founder with domain background.

### Timing Risk (0-15 points)
- **0-4**: Market is active now. Users are searching for solutions, competitors are raising, adjacent tools are growing.
- **5-8**: Market is emerging. Early adopters exist but mainstream adoption is 1-2 years out.
- **9-12**: Timing uncertain. Could be too early (infrastructure/behavior not ready) or too late (market consolidated).
- **13-15**: Clearly too early (enabling technology immature) or too late (dominant players with network effects).

## Failure Scenario Framework

For each idea, construct exactly 5 failure scenarios selected from these archetypes. Choose the 5 **most likely** for the specific idea:

1. **Demand Collapse**: Users try it but don't retain; the problem isn't painful enough for repeated use
2. **Competitive Response**: An incumbent adds this feature in weeks; the startup was validating the idea for them
3. **Distribution Failure**: Cannot acquire users at sustainable cost; organic channels don't convert, paid is too expensive
4. **Regulatory Kill**: Government action, platform policy change, or legal challenge shuts down the business model
5. **Execution Stall**: Technical debt, scope creep, or founder burnout before product-market fit
6. **Margin Squeeze**: Unit economics don't work at scale; costs grow faster than revenue
7. **Platform Risk**: Dependency on a third-party API, marketplace, or algorithm that changes terms
8. **Timing Mismatch**: Too early (market not ready) or too late (market captured)
9. **Domain Gap**: Founder lacks critical industry knowledge and makes avoidable mistakes
10. **Funding Trap**: Needs more capital than expected; bootstrapping fails but too small for VC

For each scenario, provide:
- **Likelihood**: Low / Medium / High
- **Impact**: Low / Medium / High
- **Mitigation**: One sentence on what could reduce this risk (or "None — structural risk")

## Kill or Continue Decision Framework

**KILL** if any of these are true:
- Risk Score > 75 (Critical Risk)
- Two or more risk categories score at their maximum (e.g., two categories at 15/15)
- No plausible path to $10K MRR in 12 months
- Regulatory risk could result in personal legal liability for the founder
- Requires user behavior change AND has no clear distribution AND no existing community to seed from

**CONTINUE** if:
- Risk Score < 50 (Low to Moderate Risk)
- No single category at maximum score
- Clear path to first paying customer within 90 days
- Risks are manageable with standard mitigations (legal review, API fallbacks, content marketing)

**CONDITIONAL CONTINUE** if:
- Risk Score 50-75 (Moderate to High Risk)
- Specific risks are high but addressable with known actions
- Provide explicit conditions that must be true for viability, e.g.:
  - "Continue IF founder validates demand with 50 pre-signups before building"
  - "Continue IF legal review confirms no licensing requirement"
  - "Continue IF alternative API provider exists as fallback"
