---
name: writing-supercycle-skills
description: Guide for writing skills that integrate with the SuperCycle lifecycle system. Use when creating new skills for SuperCycle, when a skill needs to interact with the retrospective system, or when designing skills that should evolve over time via the changelog. Extends writing-skills with SuperCycle-specific patterns.
---

# Writing SuperCycle Skills

This skill extends `writing-skills` with patterns specific to the SuperCycle lifecycle system.
Read `writing-skills` first for general skill authoring principles, then apply the additional patterns here.

## The two types of SuperCycle skills

**Session skills** — active during work, loaded on demand:
- Brainstorming, TDD, debugging, code review
- Standard `writing-skills` patterns apply
- Should integrate with the changelog: log when they're invoked so retrospective can track activity

**Lifecycle skills** — manage the system itself:
- `retrospective`, `using-supercycle`
- Special patterns apply (see below)
- Should never be invoked automatically (`disable-model-invocation: true`)

## Changelog integration

Any skill that performs meaningful work should leave a trace in the changelog so retrospective can track whether it's being used.

At the end of a skill's execution, if the skill made significant changes or completed a workflow, append to `.claude/reports/SKILL_CHANGELOG.md`:

```markdown
## [YYYY-MM-DD HH:MM] — INVOKE

**Skill:** [skill-name]
**Task:** [brief description of what was done]
```

This is lightweight — just enough for retrospective to know the skill was active. It prevents the skill from being incorrectly classified as DORMANT.

## Dormancy-resistant descriptions

The most common failure mode: a skill becomes dormant not because it's useless, but because its `description` no longer matches how the user talks about the problem it solves.

Write descriptions that are robust to linguistic drift:

```yaml
# Fragile — tied to a specific phrase
description: Use when the user asks to "configure CORS headers"

# Robust — covers the underlying problem in multiple phrasings
description: Use when deploying Firebase Cloud Functions, when CORS errors appear
  on Firebase endpoints, when Cloud Functions return 403 or CORS-related errors,
  or when setting up Firebase function headers. Invoke automatically when the user
  mentions Firebase functions and HTTP errors together.
```

Rules:
- Include the underlying problem, not just the action
- Include symptom phrasing ("CORS error", "403 on function") not just solution phrasing ("configure CORS")
- Make it "pushy" — Claude undertriggers. Use "Invoke automatically when...", "Always use when..."

## Reactivation hooks

If your skill solves a specific class of error that might recur, add a `## When this skill prevents` section:

```markdown
## When this skill prevents

This skill prevents:
- CORS errors on Firebase Cloud Functions (recurring in ~40% of Firebase deployments)
- Manual header configuration that gets forgotten after function updates

If retrospective finds CORS or Firebase function errors in session notes,
this skill should be reactivated with an updated description.
```

Retrospective uses this section to match dormant skills against error patterns.

## Lifecycle skill patterns

For skills that manage the system itself (like retrospective):

**Always use `disable-model-invocation: true`** — lifecycle skills have side effects (modifying other skills, writing files). Never let Claude invoke them autonomously.

**Explicit phase structure** — lifecycle skills should have numbered phases with clear entry/exit conditions. No ambiguity about what has been done and what hasn't.

**Propose before acting** — always present a plan and wait for explicit confirmation before modifying the skill system. The user must stay in control.

**Archive, never delete** — when removing skills, move to `_archived/` with a date suffix. Deleted skills can't be recovered; archived ones can.

**Changelog always** — every modification to the skill system (create, modify, reactivate, archive) must be logged in `SKILL_CHANGELOG.md` with motivation and evidence.

## Health score awareness

Every skill gets a health score (0–100) computed by the retrospective. When writing a skill, design it to stay healthy:

- **Invocation recency** (40% of score): a skill that's never invoked scores 0 here. Write descriptions that trigger reliably — this is the single biggest factor.
- **Error relevance** (35% of score): a skill that matches current error patterns scores high. Add a `## When this skill prevents` section so the retrospective can match it against session errors.
- **Freshness** (25% of score): a skill that was recently modified scores high. If you notice a skill drifting (description no longer matches reality), update it — even a small patch resets the freshness clock.

A skill below 40 health is in the critical zone. Below 40 with error_relevance > 0 means it needs reactivation. Below 40 with error_relevance = 0 means it's a removal candidate.

## Dependency chains

Skills often work in sequences. When writing a skill that depends on another skill's output, or that feeds into another skill, declare the chain.

**In your SKILL.md**, add a `## Chain position` section:

```markdown
## Chain position

**Upstream:** brainstorming (receives approved design)
**Downstream:** executing-plans, subagent-driven-development (receives implementation plan)
```

**In `.claude/reports/SKILL_DEPENDENCIES.md`**, register any custom chains your skill participates in:

```markdown
## Custom Dependency Chains

### Chain: security-deploy
security-check → gdpr-check → pre-deploy-checklist → firebase-deploy
Description: Full compliance verification before any production deployment
```

The retrospective checks all chains during the full audit. If any skill in a chain is CANDIDATE-REMOVAL, the chain is flagged as broken and the removal is blocked until the user explicitly confirms.

**Design principle:** a skill in a chain should fail gracefully if its upstream skill wasn't invoked. Don't hard-depend — reference the expected input but provide fallback instructions for when the user skips directly to your skill.

## Playbook Index integration

Skills participate in workflows that get tracked by the Playbook Index (`.claude/reports/PLAYBOOK_INDEX.md`). When writing a skill, consider how it fits into successful workflows:

**Declare your workflow position.** In your `## Chain position` section, specify not just upstream/downstream skills but also the typical workflow sequences your skill participates in. This helps the retrospective build accurate playbooks.

```markdown
## Chain position

**Upstream:** brainstorming (receives approved design)
**Downstream:** executing-plans (receives implementation plan)
**Typical workflows:** brainstorm → plan → execute, debug → plan → execute
```

**Record successful completions.** If your skill completes a meaningful unit of work, the retrospective's quick mode captures it in "Successful workflows". Design your skill to have a clear completion signal so the workflow can be logged accurately.

**Support adaptive workflows.** The Predictive Shield (Level 5) may propose skipping or adding steps based on playbook data. Your skill should work both as part of the full workflow and when invoked directly (e.g., skipping brainstorming for a proven playbook). Don't hard-require that upstream skills ran first — provide fallback instructions.

**Task type keywords.** Playbooks match by `task_type` keywords. When writing your skill's description, include the same keywords that would appear in a playbook's `task_type` field, so the Shield can connect tasks to playbooks via your skill.

## Testing your skill

Before adding a skill to SuperCycle:

1. **Trigger test** — does Claude load the skill when you describe the problem in natural language? Try 3 different phrasings.
2. **Dormancy test** — if this skill wasn't invoked for 30 days, would retrospective correctly identify whether it's relevant to current error patterns?
3. **Changelog test** — after running the skill, is there an entry in the changelog so retrospective knows it was active?
4. **Health score test** — after 2 weeks of use, what health score would this skill get? If invocation_recency would be 0, the description needs work.
5. **Chain test** — if this skill is part of a chain, does removing it break the workflow? If yes, it's correctly positioned.

## Checklist

Before submitting a skill to SuperCycle:

- [ ] `description` uses robust, symptom-based phrasing
- [ ] `disable-model-invocation: true` if skill has side effects
- [ ] Changelog integration present (for session skills)
- [ ] `## When this skill prevents` section (if skill prevents a recurring error class)
- [ ] `## Chain position` section (if skill is part of a dependency chain)
- [ ] Test in `tests/claude-code/test-[skill-name].sh`
- [ ] Added to skill table in `README.md`
- [ ] `writing-skills` base principles followed
