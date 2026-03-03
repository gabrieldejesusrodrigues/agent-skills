# Product Specialist Agent — Detailed Evaluation Criteria

## Scoring Rubric (0-100)

### Problem-Solution Fit (0-25 points)
- **20-25**: Acute, frequent pain point with clear evidence of demand (forums, complaints, workarounds). Users are already solving this manually with spreadsheets, scripts, or cobbled-together tools.
- **15-19**: Real problem but infrequent or low severity. Some evidence of manual workarounds.
- **10-14**: Nice-to-have; users have acceptable alternatives and aren't actively seeking solutions.
- **0-9**: Solution looking for a problem. No evidence of existing user behavior to validate demand.

### UX Clarity & Simplicity (0-20 points)
- **16-20**: Core value deliverable in under 3 clicks/interactions; obvious onboarding. User understands the product in one sentence.
- **11-15**: Moderate learning curve; requires some explanation but value is clear after first use.
- **6-10**: Complex workflow; users need training or documentation to get started.
- **0-5**: Unclear how a user would even start. Requires multiple sessions to understand value.

### Differentiation (0-20 points)

This measures "why would a user choose this over alternatives" — distinct from Defensibility which measures "why can't someone copy it."

- **16-20**: Unique approach to the problem that competitors cannot replicate without fundamental product changes. Novel workflow, unique data source, or structural integration advantage.
- **11-15**: Meaningful differences in approach, focus, or target segment. Competitors could replicate but would need to make strategic shifts.
- **6-10**: Superficial differences only (better UI, minor feature additions). Same core approach as existing solutions.
- **0-5**: Commodity; indistinguishable from existing solutions. Competes purely on price or marketing.

### Defensibility (0-10 points)

This measures "what prevents cloning" — distinct from Differentiation which measures "why choose this."

- **8-10**: Strong switching costs, data network effects, or ecosystem lock-in that compounds over time.
- **5-7**: Moderate switching costs or brand potential. Users accumulate some value that's hard to migrate.
- **3-4**: Low barriers; easily cloned by incumbents in a sprint.
- **0-2**: No defensibility; this is a feature for an existing platform, not a standalone product.

### Retention & Engagement (0-15 points)
- **12-15**: Daily or weekly use case. Users would notice immediately if the product disappeared. Natural habit loop.
- **8-11**: Regular use (weekly/monthly) with clear triggers. Users would seek a replacement if it disappeared.
- **4-7**: Occasional use. Useful but not embedded in a workflow. Easy to forget about.
- **0-3**: One-time or rare use. No recurring engagement pattern.

### MVP Feasibility (0-10 points)
- **8-10**: Single developer can ship working MVP in 30 days with standard tools. No exotic dependencies.
- **5-7**: MVP achievable in 60 days; requires some integrations but all well-documented.
- **3-4**: MVP requires 90+ days or specialized expertise beyond standard web development.
- **0-2**: Not feasible as MVP; requires extensive infrastructure, partnerships, or regulatory clearance.

## Platform & API Dependency Check

For every idea, explicitly identify:
- **Critical API dependencies**: Does the MVP break if a single third-party API changes pricing, terms, or availability? (e.g., OpenAI rate limits, Stripe Connect, social media APIs)
- **Platform risk level**: None (self-contained) / Low (uses commodity APIs with alternatives) / High (depends on a single platform's goodwill)

Flag any idea where a single API provider could kill the product overnight.

## Engineering Complexity Rating

- **Low**: Standard CRUD app, API integrations, basic auth. One developer, 2-4 weeks.
- **Medium**: Real-time features, complex data pipelines, multiple third-party integrations. 4-8 weeks.
- **High**: ML/AI beyond API calls, complex state management, regulatory compliance requirements, multi-tenant architecture. 8-12+ weeks.

## Feature vs Company Test

A **feature** if:
- Solves a narrow problem within an existing platform's scope
- No independent pricing power
- Incumbents could add this in a sprint
- No standalone distribution channel
- No recurring engagement pattern

A **company** if:
- Addresses a workflow broad enough for independent monetization
- Creates its own data or network effects over time
- Requires dedicated go-to-market
- Users would pay for it standalone
- Has a natural retention loop
