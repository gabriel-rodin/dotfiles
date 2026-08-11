# Synthesized Phase Planning

Use this only for a large plan with several independently deliverable outcomes but no explicit phases.

Extract implementation items from detailed tasks, dependencies, acceptance criteria, tests, documentation, release, and operational requirements. Exclude background prose, duplicate summaries, individual files, and individual test assertions.

Cluster items by:

1. hard dependency and delivery order;
2. shared product or technical outcome;
3. ownership or overlapping files when that improves sequencing; and
4. release, MVP, or quality boundaries already implied by the plan.

Do not use arbitrary equal-sized buckets. Keep tightly coupled work together and assign every item exactly once. Give each phase a concise title, one outcome, its item keys, dependencies, and a derived definition of done.

Present the complete map for approval before any GitHub mutation. On retries, preserve an approved map unless the plan materially changed; propose changed assignments explicitly rather than silently generating new phase identities.
