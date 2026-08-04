---
name: code-review-standards
description: Combined production-risk review framework and codebase-verified checklist (correctness, security, data integrity, performance, maintainability, architecture, testing, change impact, plus frontend lifecycle/state checks).
disable-model-invocation: true
---

# Code Review Standards

Review as if this ships to production today: strict on real risk, pragmatic on scope, no style bikeshedding. State assumptions and uncertainties explicitly rather than asserting past them. Not limited to PR time — run this while implementing too, not only as a final gate.

Every finding must clear the **trigger path** bar: a concrete input or state that actually walks the code through the flaw. No trigger path, no finding — cut the hypothetical rather than hedge it into the report. Items marked with a file reference are checks that previously found a real bug; verify a new finding against the codebase the same way, not hypothetically.

**Pattern match is not a finding.** Spotting a shape that looks risky (user input near a query, an unguarded-looking route, a missing-looking null check) is a lead, not a conclusion — trace the actual call path before reporting it. Before flagging:
- Check whether sanitization, authorization, or validation already handles it elsewhere in the path (a middleware, a shared helper, a caller-side guard) — don't assume a flaw just because the handling isn't in the line you're looking at.
- Prefer proof over hypothesis: where feasible, point to (or write) a failing test or a concrete reproduction that actually crosses the trust boundary, not just an assertion that it "could" happen under some input.
- Weigh reachability against the real environment this ships into — a state that's theoretically constructible but never reachable through this app's actual inputs/config isn't worth a Finding; note it under Optional Notes instead if worth mentioning at all.

---

## Load the applicable checklist

Inspect every changed file before beginning the review.

- Read `references/backend.md` completely when the change touches `backend/`, database migrations, persistence, API behavior, or server-side events.
- Read `references/frontend.md` completely when the change touches `frontend/`, UI behavior, hooks, stores, client caching, i18n, or realtime client state.
- Read both for cross-stack changes.
- When impact is uncertain, read both.

The core checks below apply regardless of stack — run them alongside whichever reference file(s) you loaded.

---

## Core Review Checklist

### 1. Correctness

- null/undefined handling and defensive branches
- edge cases, bounds, and unexpected states
- condition logic and branching correctness
- async behavior, error propagation, and retry safety
- state mutation side effects
- type contract mismatches

### 2. Security & Access Control

- authentication and resource ownership enforcement
- permission validation at route and service boundaries
- injection risks (SQL, command, template)
- unsafe HTML rendering and XSS exposure
- secrets and sensitive data leakage in logs/errors

Focus especially on API routes/controllers, admin/privileged actions, payment/auth flows, and write operations. Applies across backend, frontend, shared code, and media processing — not backend-only.

### 3. Maintainability & Clarity

- function/method/component complexity
- naming clarity and specificity
- duplicated logic and missing extraction
- magic values and unexplained constants
- poor abstractions and overly nested code
- **Stale references**: do comments, identifiers, docs, or config still point to code, files, mockups, or values this change removed, renamed, or replaced?

### 4. Architecture & Consistency

Respect existing patterns: service/repository boundaries, established validation and error handling, naming conventions, minimal refactor scope during risk-focused reviews.

- backward compatibility for shared data structures and stable public interfaces across package boundaries (`shared/`)

Flag: new frameworks/abstractions without strong justification, refactoring unrelated code during a risk review, mixing concerns across existing layer boundaries.

- **Minimum-code check**: could the same behavior be achieved with meaningfully less code — fewer branches, no new abstraction, no speculative config/flags?

### 5. Testing Coverage

Verify changed behavior is tested for: success and failure paths, edge cases and state transitions, permission/authorization-sensitive paths, integration boundaries, regression-prone areas. Flag high-risk gaps only.

- **Test meaningfulness**: would this test actually fail if the logic were wrong, or does it just replay the code's own steps and assert the code's own output? A test that can't fail on a plausible bug is slop — flag it.

### 6. Change Impact

Unintended downstream effects on: existing API contracts, shared components and libraries, database behavior and schema, event/socket/realtime flows, transaction and cache boundaries.

### 7. Performance

- redundant API/database calls
- expensive loops on hot paths

Same trigger-path bar applies: a performance finding needs a realistic path that hits the hot spot, not a worst-case hypothetical. See `references/backend.md` for query/index-specific checks and `references/frontend.md` for rerender-churn checks.

**Media processing (Python)**: robust request validation and error handling, safe subprocess and I/O usage, clear contracts with backend callers — no dedicated reference file; apply the core checks above directly.

---

## Finding Quality

Every finding states, in order: exact location (file + function/section), the trigger path, the user/business/operational impact, and the smallest safe fix.

**Merge policy**:
- P0 and P1 findings block merge until addressed or the user explicitly accepts the risk.
- A review with only genuinely minor P2 issues should approve. Omit those P2 issues from Findings rather than turning minor cleanup into a merge gate.
- Include legitimate P2 findings only when the same review already has at least one independently merge-blocking P0 or P1 finding. Because the PR already requires another fix round, the author can address the minor issues in that round as well; every included Finding must be resolved before approval.
- Do not promote a P2 to P1 merely to make it merge-blocking. Severity must continue to reflect actual impact.

**Severity** (P0/P1/P2 — relative impact and urgency only, does not itself gate merge):
- **P0 (Critical)** — production outage, security vulnerability, data corruption, transaction inconsistency, crash.
- **P1 (Important)** — significant logic flaw, maintainability risk, missing edge-case handling, realistic performance issue.
- **P2 (Minor)** — readability, naming, or anything else worth fixing but easy to miss at a glance.

## Output Format

- **Summary**: 2-4 line overall assessment.
- **Findings**: ordered P0 → P2, each as Problem / Impact / Suggested Fix. Include P2 findings only when at least one P0 or P1 finding already blocks merge.
- **Optional Notes**: non-blocking suggestions (style nits, optional simplifications) that don't belong under Findings, or `None`.
- **Testing Gaps**: high-risk missing tests, or `None`.
- **Final Recommendation**: Approve when there are no P0/P1 findings, including when only minor P2 issues were found and omitted; Request changes when one or more P0/P1 findings remain.

## Growing this checklist

This list is not fixed — it grows every time a gap it should have caught turns up. Detect the moment automatically, don't wait to be told: a bug slips through that one of these checks would have caught, the user corrects an approach in one of the areas above, or a review catches something this checklist missed.

When that happens, before continuing:

1. Check whether an existing item already covers it. If so, sharpen that item's wording instead of adding a near-duplicate.
2. If it's genuinely new, verify it against the current codebase the same way the existing items were verified (a real file/pattern it references, not a hypothetical).
3. Propose the exact bullet to the user — cross-stack items go in this file, backend-only items in `references/backend.md`, frontend-only items in `references/frontend.md` — in the same "**Name**: question + why it matters" format as the existing items, and only edit after they confirm. A review pass should stay read-only over these files unless the user explicitly asks for the update.
