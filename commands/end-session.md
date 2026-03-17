---
description: "Run the full 6-phase SuperCycle retrospective. Use at end of session to evolve the skill system."
---

Run the FULL SuperCycle retrospective now. Follow the `retrospective` skill exactly — all 6 phases in order.

## Phase 0 — Data Collection
- Read all quick audit notes from `.claude/reports/skill_audit_notes/` (focus on last 7 days)
- Read `.claude/reports/SKILL_CHANGELOG.md` for modification history
- Scan project memory for skill-related entries
- Search notes for: recurring errors, repeated instructions, workarounds, skill mentions

## Phase 1 — Pattern Analysis
- Extract error patterns (2+ occurrences) and repeated instructions (2+ times)
- **Update Pattern Index** (`.claude/reports/PATTERN_INDEX.md`):
  - New errors: add with `source: session`
  - Existing patterns that recurred: increment occurrences, update last_seen
  - Bootstrap patterns confirmed by real error: change source to `confirmed`
  - Bootstrap patterns unconfirmed 90+ days: mark `unconfirmed`
- **Update Playbook Index** (`.claude/reports/PLAYBOOK_INDEX.md`):
  - Extract "Successful workflows" from quick notes
  - Update or create playbook entries with success rates
- **Community sharing** (if `.claude/supercycle-config.json` has `community_sharing: true`):
  - POST session/confirmed patterns to worker endpoint
- **Community receiving** (ALWAYS):
  - GET community patterns and save to `.claude/reports/COMMUNITY_PATTERNS.md`

## Phase 2 — Skill Analysis
- Discover all `SKILL.md` files under `.claude/skills/`
- Classify each: ACTIVE (invoked in 14d) / INACTIVE
- For every INACTIVE skill: check if a recurring error pattern could have been prevented by it
  - YES → REACTIVATE (update description)
  - NO + inactive < 30d → DORMANT
  - NO + inactive 30d+ → CANDIDATE-REMOVAL
- Compute health score (0-100) per skill: `invocation_recency * 40 + error_relevance * 35 + freshness * 25`
- Check dependency chains for breaks

## Phase 3 — Gap Analysis
- For each pattern without a covering skill: create a GAP entry
- Priority: HIGH (3+ occurrences or broken chain) / MEDIUM / LOW

## Phase 4 — Action Plan
Present the complete plan:
- Skills to REACTIVATE
- Skills to CREATE
- Skills to MODIFY
- Skills CANDIDATE FOR REMOVAL

**STOP HERE. Wait for explicit user confirmation before proceeding.**

## Phase 5 — Execution
Execute ONLY approved actions:
- Reactivate: update descriptions to match actual trigger context
- Create: new SKILL.md with frontmatter, triggers, prevention section
- Modify: surgical patches only
- Archive: move to `.claude/skills/_archived/[name]_[date]/`

## Phase 6 — Changelog & Report
- Append all changes to `.claude/reports/SKILL_CHANGELOG.md`
- Generate `.claude/reports/SKILL_AUDIT_[date].md` with full metrics, health scores, chains, actions
- Append to `.claude/reports/METRICS_HISTORY.md`
- Show summary and close session
