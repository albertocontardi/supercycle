---
name: retrospective
description: >
  End-of-session and weekly skill system retrospective.
  Run /retrospective quick at the end of every session to log patterns and errors.
  Run /retrospective weekly for a full audit: prune unused skills, reactivate dormant ones, create or modify skills.
  Never activates automatically — explicit invocation only.
disable-model-invocation: true
---

# Retrospective

Meta-skill for evolving your Claude Code skill system over time.
Analyzes sessions, identifies recurring patterns, and maintains skills through a tracked changelog.

## Invocation

- **`/retrospective quick`** — End of session. Logs patterns and errors. ~1 minute.
- **`/retrospective`** — Full weekly audit. Analyzes, modifies, creates, archives skills. ~5 minutes.

**Never activates automatically.** Explicit invocation only.

## Core principle: dormant skills get reactivated, not removed

Before archiving any unused skill, always ask: *is there a recurring error pattern in the session notes that this skill could have prevented?*

If yes — the skill isn't useless, it's invisible. Its `description` no longer matches how problems surface in conversation. Fix the description; don't archive the skill.

```
skill not invoked in 30+ days
        │
        ▼
recurring error pattern that this skill could resolve?
        │
       YES ──► REACTIVATE: update description to match actual trigger context
        │
        NO
        │
        ▼
CANDIDATE-REMOVAL: propose archival (never deletion)
```

This is the most important judgment call in the full audit. A dormant skill that prevents a known recurring error is institutional memory. Removing it means rediscovering the same problem later.

## Key paths

All paths are relative to the project root.

```
.claude/skills/                            # project skills
.claude/reports/SKILL_CHANGELOG.md         # changelog (single source of truth)
.claude/reports/skill_audit_notes/         # quick session notes
.claude/reports/SKILL_AUDIT_[date].md      # full audit reports
.claude/skills/_archived/                  # archived (not deleted) skills
```

On first run, create any missing directories automatically.

---

## QUICK MODE (`/retrospective quick`)

Fast analysis of the current session. Run at the end of every session.

### Procedure

1. **Review the current session** and identify:
   - Tasks executed (with outcome: OK / PROBLEMATIC)
   - Errors encountered and how they were resolved
   - Instructions the user had to repeat or correct
   - Skills that were useful
   - Skills that were missing or inadequate
   - Workarounds used to bypass limitations

2. **Collect session metrics** (count from the session):

| Metric | How to count |
|--------|-------------|
| `tasks_completed` | Tasks finished successfully |
| `tasks_failed` | Tasks that failed or required rollback |
| `errors_encountered` | Distinct errors hit during session |
| `errors_recurring` | Errors that appeared 2+ times in this session |
| `skills_invoked` | Distinct skills loaded during session |
| `skills_available` | Total skills in `.claude/skills/` |
| `user_corrections` | Times the user corrected or repeated an instruction |
| `workarounds_used` | Times a workaround was used instead of a skill |

3. **Save notes** to `.claude/reports/skill_audit_notes/[YYYY-MM-DD_HH-MM]_quick.md`:

```markdown
# Quick Retrospective — [date] [time]

## Metrics
| Metric | Value |
|--------|-------|
| tasks_completed | N |
| tasks_failed | N |
| errors_encountered | N |
| errors_recurring | N |
| skills_invoked | N |
| skills_available | N |
| user_corrections | N |
| workarounds_used | N |

## Tasks executed
- [task] — [OK / PROBLEMATIC: why]

## Recurring errors
- [error] — resolved via: [method] — occurrences: N

## Repeated user instructions
- "[instruction]" — repeated N times

## Skills invoked
- [skill] — [useful / not useful / should have been invoked but wasn't]

## Gaps identified
- [description] — [type: new skill / modify existing skill]

## Workarounds used
- [workaround] — [could this become a skill?]

## Successful workflows
- [task] — workflow: [skill1 → skill2 → skill3] — duration: ~[N]min — notes: [what worked]

## Tags
#session #[area]
```

4. **Show summary** to the user (5 lines max):
   - N errors logged
   - N gaps identified
   - Most used skill
   - Skill coverage: N invoked / N available (N%)
   - Top recommendation for next session

---

## FULL MODE (`/retrospective`)

Complete audit in 6 phases. Execute in order. Do not skip phases.

---

### PHASE 0 — DATA COLLECTION

Data sources (in priority order):

1. **Quick audit notes** — read all files in `.claude/reports/skill_audit_notes/`:
   - Focus on the most recent ones (last 7 days)

2. **Changelog** — read `.claude/reports/SKILL_CHANGELOG.md` to understand modification history

3. **Project memory** — if a MEMORY.md or similar exists, scan for skill-related entries

4. **Pattern search** — targeted search across notes, not full file reads:
   - Look for: recurring errors, repeated instructions, workarounds, skill mentions

---

### PHASE 1 — PATTERN ANALYSIS

From collected data, extract:

**Error patterns** — same error seen 2+ times:
```
Error: [description]
Occurrences: N
Resolved via: [method]
Covered by skill? YES/NO — [skill name or GAP]
```

**Repeated instructions** — same instruction given 2+ times:
```
Instruction: "[text]"
Repeated: N times
Automatable? YES/NO — [how]
```

**Recurring workflows** — identical operation sequences:
```
Workflow: [name]
Steps: [list]
Existing skill? YES/NO — [skill name or GAP]
```

#### Update Pattern Index

After extracting patterns, update `.claude/reports/PATTERN_INDEX.md` for the Predictive Shield:

1. Read existing `PATTERN_INDEX.md` (or create with header if missing)
2. For each error pattern identified above:
   - If it matches an existing pattern in the index: increment `occurrences`, update `last_seen`
   - If it's new: add it with triggers extracted from the task context where the error occurred
3. For patterns in the index not seen this period: keep as-is (patterns don't expire, but mark as `resolved` if not seen in 90+ days AND the associated skill is ACTIVE)
4. Write updated `PATTERN_INDEX.md`

**Trigger extraction:** from the task description where the error occurred, extract nouns, technology names (firebase, react, python), action verbs (deploy, migrate, fix), and system names (hosting, functions, firestore). Minimum 3 triggers per pattern, maximum 8.

See `skills/predictive-shield/SKILL.md` for the full Pattern Index format.

#### Update Playbook Index

After pattern analysis, extract successful workflows:

1. Read existing `.claude/reports/PLAYBOOK_INDEX.md` (or create with header if missing)
2. From quick notes, extract entries in "Successful workflows" sections
3. For each successful workflow:
   - If a playbook with matching `task_type` exists: increment `occurrences`, update `success_rate`
   - If new: create a new playbook entry with `occurrences: 1`, `success_rate: 1/1`
4. For playbooks where a matching error pattern was found (same task_type): record as failure, update `success_rate`
5. Write updated `PLAYBOOK_INDEX.md`

See `skills/predictive-shield/SKILL.md` for the full Playbook Index format.

#### Community Pattern Sharing

**Send** (only if `.claude/supercycle-config.json` has `community_sharing: true`):
1. Collect all patterns from Pattern Index with `source: session` or `source: confirmed` (NOT `source: bootstrap`)
2. Anonymize: strip any field that could contain project-specific info
3. POST to `https://supercycle-patterns.albertocontardi.workers.dev/patterns` with stack tag and user_hash
4. Log in report: "Shared [N] patterns with community"

**Receive** (ALWAYS, regardless of opt-in):
1. GET from `https://supercycle-patterns.albertocontardi.workers.dev/patterns/[stack]`
2. Save to `.claude/reports/COMMUNITY_PATTERNS.md` (local cache)
3. The Predictive Shield uses this cache at next session start (Level 6)

Receiving is always active because it sends no user data — it only downloads public aggregated patterns.

---

### PHASE 2 — EXISTING SKILL ANALYSIS

Discover all project skills:
- Search for `SKILL.md` files under `.claude/skills/` recursively

For each skill, apply the following decision logic in order:

**Step 1 — Determine raw activity status from changelog:**
- **ACTIVE** — invoked in the last 14 days
- **INACTIVE** — not invoked in the last 14 days

**Step 2 — For every INACTIVE skill, apply the reactivation check:**

> Does a recurring error pattern from Phase 1 exist that this skill could have prevented or resolved?

- **YES → REACTIVATE**: the skill is dormant because its `description` no longer matches how the problem surfaces, not because it's useless. Propose updating the description to be more specific and trigger-friendly. Do not propose archival.
- **NO, inactive < 30 days → DORMANT**: flag for monitoring, no action yet.
- **NO, inactive 30+ days → CANDIDATE-REMOVAL**: propose archival (not deletion).

**Output table:**

| Skill | Last invocation | Status | Proposed action |
|-------|----------------|--------|-----------------|
| [name] | [date] | ACTIVE | — |
| [name] | [date] | REACTIVATE | Update description: [reason] |
| [name] | [date] | DORMANT | Monitor |
| [name] | never | CANDIDATE-REMOVAL | Archive |

These thresholds (14d / 30d) are defaults. Adjust them if your project cadence is slower.

#### Health Score

For each skill, compute a health score (0–100) to prioritize actions:

```
health_score = (invocation_recency × 40) + (error_relevance × 35) + (freshness × 25)
```

| Component | 100 (best) | 50 | 0 (worst) |
|-----------|-----------|-----|-----------|
| `invocation_recency` | Invoked in last 7 days | Invoked in last 30 days | Never invoked or 30+ days ago |
| `error_relevance` | Matches 2+ current error patterns | Matches 1 pattern | No matching patterns |
| `freshness` | Modified in last 14 days | Modified in last 60 days | Never modified or 60+ days ago |

**How to use the score:**
- **70–100**: Healthy. No action needed.
- **40–69**: Attention needed. Check if description needs update or skill needs modification.
- **0–39**: Critical. Either reactivate (if error_relevance > 0) or candidate for removal.

Add the health score column to the output table:

| Skill | Last invocation | Health | Status | Proposed action |
|-------|----------------|--------|--------|-----------------|
| [name] | [date] | 85 | ACTIVE | — |
| [name] | [date] | 35 | REACTIVATE | Update description: [reason] |
| [name] | never | 12 | CANDIDATE-REMOVAL | Archive |

Sort the table by health score ascending — sickest skills first, so the most urgent actions are at the top.

---

### PHASE 2.5 — DEPENDENCY GRAPH

Skills don't operate in isolation. Map how they chain together.

#### Known dependency chains

These are the standard SuperCycle chains. Verify each is intact:

```
brainstorming → writing-plans → executing-plans/subagent-driven-development
                                        ↓
                              test-driven-development
                                        ↓
                              verification-before-completion
                                        ↓
                              requesting-code-review → receiving-code-review
                                        ↓
                              finishing-a-development-branch
```

```
systematic-debugging → test-driven-development → verification-before-completion
```

```
using-supercycle (bootstrap) → all skills
                             → retrospective (end of session)
```

#### Check for broken chains

For each chain, verify that every skill in the sequence is present and not CANDIDATE-REMOVAL. A broken chain means the workflow has a gap.

```markdown
### Chain: brainstorm → plan → execute
- brainstorming: ACTIVE ✓
- writing-plans: ACTIVE ✓
- executing-plans: DORMANT ⚠ — chain weakened
- subagent-driven-development: ACTIVE ✓

### Chain: debug → test → verify
- systematic-debugging: ACTIVE ✓
- test-driven-development: ACTIVE ✓
- verification-before-completion: CANDIDATE-REMOVAL ✗ — CHAIN BROKEN
```

**A broken chain is automatically HIGH priority in the action plan**, regardless of the individual skill's status. If any skill in a chain is CANDIDATE-REMOVAL, it must be reconsidered — removing it breaks the workflow.

#### Custom chains

If the project has domain-specific skill chains (e.g., `security-check → gdpr-check → deploy`), document them in `.claude/reports/SKILL_DEPENDENCIES.md`. The retrospective reads this file to check custom chains in addition to the standard ones.

Format for custom chains:
```markdown
## Custom Dependency Chains

### Chain: [name]
[skill-a] → [skill-b] → [skill-c]
Description: [when this chain activates]
```

---

### PHASE 3 — GAP ANALYSIS

For each pattern found in Phase 1 without a corresponding skill:

```markdown
### GAP: [descriptive name]

**Evidence:** [pattern/error, with frequency]
**Type:** New skill / Modify [existing skill]
**Priority:** HIGH / MEDIUM / LOW

HIGH = recurring error, 3+ occurrences, significant time wasted
HIGH = broken dependency chain (automatic — any chain break is HIGH)
MEDIUM = repeated workflow, 2+ occurrences, moderate time savings
MEDIUM = skill with health score 0–39 that needs intervention
LOW = optimization, 1 occurrence, nice-to-have
```

---

### PHASE 4 — ACTION PLAN

Before acting, present the complete plan to the user:

```markdown
## Retrospective Action Plan — [date]

### Skills to REACTIVATE (N)
1. [name] — description update: [what changes and why]

### Skills to CREATE (N)
1. [name] — PRIORITY [X] — resolves: [gap]

### Skills to MODIFY (N)
1. [name] — change: [surgical description]

### Skills CANDIDATE FOR REMOVAL (N)
1. [name] — last invocation: [date] — confirm archival?

### No action needed (N)
1. [name] — ACTIVE, working well
```

Note: REACTIVATE is listed first — it's the most important action and the most commonly overlooked.

**Wait for explicit confirmation** before proceeding to Phase 5.
- If the user approves all: proceed.
- If the user approves partially: execute only approved actions.

---

### PHASE 5 — EXECUTION

Execute approved actions in order:

#### 5a. Reactivate dormant skills

Update the `description` in frontmatter to be more specific and trigger-friendly:
- Add explicit triggers: "Use when...", "Invoke every time..."
- Reference the specific error pattern that motivated reactivation
- Make the description "pushy" — Claude tends to undertrigger skills

#### 5b. Modify existing skills (surgical patch)

Change ONLY the specific parts indicated. Do not rewrite working skills.

#### 5c. Create new skills

For each new skill, create the directory and SKILL.md:

Minimum SKILL.md structure:
```yaml
---
name: [name]
description: [when to use — be explicit about triggers]
---
# [Skill Name]
[instructions]
```

#### 5d. Archive removal candidates

Only if explicitly confirmed by the user:
```
# Move to archive instead of deleting
.claude/skills/_archived/[skill-name]_[date]/
```

**Never delete directly** — always archive.

---

### PHASE 6 — CHANGELOG UPDATE

After every modification, append to `.claude/reports/SKILL_CHANGELOG.md`:

```markdown
## [YYYY-MM-DD HH:MM] — [type: CREATE | MODIFY | REACTIVATE | ARCHIVE]

**Skill:** [name]
**Path:** [full path]
**Motivation:** [pattern/error that motivated the action, with frequency]
**What changed:**
- [specific change 1]
- [specific change 2]
**Original priority:** HIGH / MEDIUM / LOW
```

The changelog is the **source of truth for skill activity**:
- A skill with no recent changelog entries = DORMANT
- A skill that never appeared = CANDIDATE-REMOVAL
- A skill with many recent changes = ACTIVE and evolving

---

## FINAL OUTPUT

Generate report in `.claude/reports/SKILL_AUDIT_[YYYY-MM-DD].md`:

```markdown
# Retrospective Report — [date]

## Session Metrics (aggregated from quick notes since last audit)

| Metric | This period | Previous period | Trend |
|--------|------------|-----------------|-------|
| Sessions logged | N | N | ↑/↓/→ |
| Tasks completed | N | N | ↑/↓/→ |
| Tasks failed | N | N | ↑/↓/→ |
| Errors encountered | N | N | ↑/↓/→ |
| Errors recurring | N | N | ↑/↓/→ |
| Avg skills invoked/session | N | N | ↑/↓/→ |
| Skill coverage (invoked/available) | N% | N% | ↑/↓/→ |
| User corrections | N | N | ↑/↓/→ |
| Workarounds used | N | N | ↑/↓/→ |

**Key trends:** [1-2 sentence interpretation. Example: "Recurring errors dropped from 5 to 2 since the firebase-cors skill was reactivated. Skill coverage increased from 30% to 45%."]

## Summary
- Total skills: N
- Active (14d): N
- Reactivated today: N
- Dormant (monitoring): N
- Archived today: N
- Created today: N
- Modified today: N
- Remaining gaps: N

## Skill Health

| Skill | Health | Invocation | Relevance | Freshness | Status | Action taken |
|-------|--------|-----------|-----------|-----------|--------|--------------|
| [name] | 85 | 40/40 | 25/35 | 20/25 | ACTIVE | — |
| [name] | 35 | 0/40 | 35/35 | 0/25 | REACTIVATED | Description updated |
| [name] | 12 | 0/40 | 0/35 | 12/25 | ARCHIVED | Moved to _archived/ |

## Dependency Chains

| Chain | Status | Broken at |
|-------|--------|-----------|
| brainstorm → plan → execute | ✓ Intact | — |
| debug → test → verify | ⚠ Weakened | verification-before-completion (DORMANT) |
| [custom chain] | ✗ Broken | [skill name] |

## Patterns identified
| Pattern | Frequency | Covered by |
|---------|-----------|------------|
| [description] | N times | [skill or GAP] |

## Actions executed
1. [action with detail]

## Remaining gaps
1. [gap] — reason: [why not covered now]

## Recommendations for next session
1. [concrete recommendation]
```

Also append metrics summary to `.claude/reports/METRICS_HISTORY.md` (create if missing):

```markdown
## [YYYY-MM-DD]

| Metric | Value |
|--------|-------|
| sessions | N |
| tasks_completed | N |
| tasks_failed | N |
| errors_recurring | N |
| skill_coverage | N% |
| avg_health_score | N |
| chains_intact | N/N |
```

This file accumulates over time and enables trend analysis across audits.

---

## Rules

1. **Reactivate before removing** — always apply the reactivation check before proposing archival. Unused ≠ useless.
2. **Propose before acting** — in Phase 4 always present the plan and wait for confirmation
3. **Surgical patches** — modify only what's needed, don't rewrite working skills
4. **Archive, never delete** — removed skills go to `_archived/` with date
5. **Data, not opinions** — every proposal must cite evidence (pattern, frequency)
6. **Changelog always** — every skill system change gets logged
7. **Efficiency** — use targeted searches to extract data, don't read entire files
8. **No duplicates** — before creating, verify a similar skill doesn't already exist
9. **Bootstrap on first run** — create missing directories and an empty changelog automatically
