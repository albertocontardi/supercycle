---
name: predictive-shield
description: >
  Activates at session start after using-supercycle, and before any task begins.
  Six-level analysis engine: pattern matching, structural analysis, temporal context,
  playbook-based guidance, adaptive workflows, and community patterns.
  Warns proactively about likely errors and pre-activates relevant skills.
  Use whenever a new task is described and .claude/reports/skill_audit_notes/ contains prior sessions.
  Also activates when the user says "deploy", "fix", "build", "migrate", "refactor", or describes
  any task that has historically caused errors.
---

# Predictive Shield

Prevent errors before they happen. Six levels of analysis, one unified report.

## Core principle

The best error is one that never occurs. Retrospective looks backward. Predictive Shield looks forward.

```
Traditional:  task → error → fix → retrospective logs it → maybe prevented next time
Shield:       task described → 6-level analysis → warn NOW → error never happens
```

## When this activates

1. **Session start** — after `using-supercycle` loads, when the user describes their first task
2. **New task** — when the user pivots to a substantially different task mid-session
3. **High-risk keywords** — deploy, migrate, refactor, merge, release, production, upgrade

## The 6 levels

All levels run in cascade. Each adds information to a single unified report. The report is presented ONCE before any work begins.

---

### Level 1 — Historical Pattern Matching

Confronts the current task against the Pattern Index.

#### Procedure

1. Extract **task signals** from the user's description:
   ```
   Task signals = keywords + technologies + action type + target files/systems
   ```
   Examples:
   - "Deploy the Cloud Functions" → signals: `deploy`, `cloud-functions`, `firebase`
   - "Fix the login page" → signals: `fix`, `login`, `auth`, `frontend`
   - "Migrate to the new API" → signals: `migrate`, `api`, `breaking-change`

2. Read the **Pattern Index** from `.claude/reports/PATTERN_INDEX.md`
   - If the file doesn't exist and bootstrap hasn't run, scan last 10 quick notes to build it on the fly

3. Match task signals against pattern triggers:
   - **Match**: 2+ signals overlap with a pattern's triggers
   - **Weak match**: 1 signal overlaps AND pattern has 3+ occurrences

4. Assess risk per match:

| Risk | Criteria |
|------|----------|
| **HIGH** | Pattern occurred 3+ times AND no skill currently prevents it |
| **MEDIUM** | Pattern occurred 2+ times OR occurred once with significant time wasted |
| **LOW** | Pattern occurred once, was resolved quickly |

5. For `source: bootstrap` patterns, lower confidence by one level (HIGH→MEDIUM, MEDIUM→LOW, LOW→skip)

---

### Level 2 — Structural Analysis

Analyzes the STRUCTURE of the task to find cross-layer risk, independent of history.

#### Procedure

1. From the user's input, identify which layers the task touches:
   - frontend, backend/Cloud Functions, Firestore rules, hosting config, auth, external APIs, CI/CD, database, styling/CSS, testing

2. Count the layers involved.

3. For each interface between layers (e.g., frontend ↔ Cloud Functions, Cloud Functions ↔ Firestore), check if a skill exists that covers that interface point.

4. Interfaces without a covering skill = structural gaps.

#### Risk assessment

- 1 layer = LOW
- 2 layers = MEDIUM
- 3+ layers = HIGH
- Each uncovered interface adds one level (MEDIUM → HIGH)

This level works from day 1, with zero history. It detects complexity before errors happen.

---

### Level 3 — Temporal Context

Analyzes the CONDITIONS around the current session.

#### Data to collect

From the filesystem and quick notes:

| Data point | How to get it |
|-----------|---------------|
| `days_since_last_full_audit` | Age of most recent `SKILL_AUDIT_*.md` file |
| `sessions_since_last_audit` | Count quick notes after the most recent audit |
| `session_gap` | Days between today and the most recent quick note |
| `day_of_week` | Current day (Monday after weekend = higher risk) |

#### Correlations to flag

- `sessions_since_last_audit > 10` → "Sono passate [N] sessioni dall'ultimo audit. Il tasso di errore storicamente sale dopo 10+. Consiglio: `/retrospective` prima di procedere."
- `session_gap > 7` → "[N] giorni dall'ultima sessione su questo progetto. Rischio di errori da contesto perso elevato."
- `days_since_last_full_audit > 14` → "L'ultimo audit completo risale a [N] giorni fa. Il Pattern Index potrebbe non essere aggiornato."

#### Risk assessment

- All values within normal range = LOW
- One flag = MEDIUM
- Two+ flags = HIGH

---

### Level 4 — Playbook Matching (Generative Prediction)

Not just "watch out" but "here's how to do it well". Uses the Playbook Index.

#### Procedure

1. Read `.claude/reports/PLAYBOOK_INDEX.md`
2. If the Playbook Index exists, match the current task's signals against playbook `task_type` fields
3. If a match is found:

**success_rate > 75%:**
```
✅ Proven Playbook: "[playbook name]" — [N/M] success rate
Recommended workflow:
1. [step 1]
2. [step 2]
3. [step 3]

This workflow succeeded [X]% of the time for this task type.
Use it? (Standard brainstorm → plan → execute is always available as fallback)
```

**success_rate < 50%:**
```
⚠️ Known Difficult Task: "[playbook name]" — [N/M] success rate
Previous attempts failed when: [extracted from notes]
Consider: [suggestion based on failure patterns]
```

4. If no Playbook Index exists or no match, skip this level silently.

#### Playbook Index format

`.claude/reports/PLAYBOOK_INDEX.md`:

```markdown
# Playbook Index
<!-- Auto-generated by retrospective. Do not edit manually. -->
<!-- Last updated: [YYYY-MM-DD] -->

## Playbooks

### [playbook-id]: [short description]
- task_type: [keywords that identify this type of task]
- workflow_used: [ordered list of skills invoked]
- steps_taken: [key actions beyond the standard workflow]
- outcome: SUCCESS / PARTIAL / FAILED
- duration_minutes: [estimated time]
- occurrences: [N]
- success_rate: [N/M]
- notes: [useful context]
```

---

### Level 5 — Adaptive Workflow

Based on levels 1-4, proposes a PERSONALIZED workflow instead of always defaulting to brainstorm → plan → execute.

#### Logic

1. **Playbook match with success_rate > 75%** → propose that playbook's workflow
2. **Simple task** (1 layer, no risk patterns, no temporal flags) → propose abbreviated workflow: skip brainstorming, go to implement + verify
3. **Complex task** (3+ layers, HIGH risk patterns, or success_rate < 50%) → propose extended workflow: brainstorm + plan + execute with extra checkpoints + verify
4. **First time for this task type** (no playbook match) → use standard workflow

The user can always override with "use the standard workflow".

---

### Level 6 — Community Patterns

Consults community patterns downloaded from the Cloudflare Worker, if available.

#### Procedure

1. Read `.claude/reports/COMMUNITY_PATTERNS.md` (local cache, updated by retrospective)
2. If the file exists, match task signals against community pattern triggers
3. Only show patterns with `reporters >= 3`
4. Community patterns that are NOT already in the local Pattern Index get shown separately

Community patterns are advisory only — they are never added to the local Pattern Index automatically. If the user actually encounters the error, the retrospective adds it to the local index with `confirmed_from_community: true`.

---

## The Unified Report

All 6 levels produce ONE compact report, presented BEFORE work begins:

```
⚡ Predictive Shield Report

📐 Structure: [N] layers, [risk level]
🕐 Context: [N] days since audit, [risk level]
⚠️ Historical: [N] pattern matches
✅ Playbook: [available/none] — [success rate if available]
🔄 Workflow: [suggested workflow]
🌐 Community: [N] relevant insights

[Details only for HIGH risk items and playbook suggestion]

Pre-activating: [skill1], [skill2]
```

If EVERYTHING is LOW risk and no playbook exists:

```
⚡ Predictive Shield — no significant risks detected. Proceeding with standard workflow.
```

**Rules:**
- Maximum 5 historical patterns shown (prioritize by risk × occurrences)
- One line per pattern — no walls of text
- Community insights only if they add value beyond local patterns
- Don't spam warnings when nothing is wrong

---

## Pre-activation

For each HIGH risk match with an associated skill:
- Load the skill immediately
- Announce: "Pre-activating [skill] based on: [brief reason]"

For MEDIUM risk:
- Flag the skill name, don't auto-load
- The user decides

---

## The Pattern Index

`.claude/reports/PATTERN_INDEX.md` — compact, machine-readable file.

### Format

```markdown
# Pattern Index
<!-- Auto-generated by retrospective. Do not edit manually. -->
<!-- Last updated: [YYYY-MM-DD] -->

## Patterns

### [pattern-id]: [short description]
- triggers: [comma-separated keywords]
- error: [what goes wrong]
- resolution: [how to fix it]
- skill: [skill that prevents/resolves, or "none"]
- occurrences: [N]
- last_seen: [YYYY-MM-DD]
- severity: [HIGH/MEDIUM/LOW]
- source: [bootstrap/session/confirmed]
```

### Source field

- `bootstrap` — auto-generated from stack detection, never confirmed by real experience. Expires after 90 days if unconfirmed.
- `session` — derived from real errors in user sessions. High confidence.
- `confirmed` — a bootstrap pattern that was later confirmed by a real error. Highest confidence.

### Trigger extraction rules

- Extract nouns and technical terms from the task context
- Include technology names (firebase, react, python, etc.)
- Include action verbs (deploy, migrate, fix, build, refactor)
- Include system names (hosting, functions, firestore, auth)
- Minimum 3 triggers per pattern, maximum 8

---

## Retrospective integration

The retrospective updates BOTH indexes during the full audit:

**Pattern Index** — in PHASE 1 (Pattern Analysis):
1. Read existing `PATTERN_INDEX.md` (or create if missing)
2. For each new error pattern: add with `source: session`
3. For each existing pattern that recurred: increment occurrences, update last_seen
4. For each bootstrap pattern confirmed by a real error: change source to `confirmed`
5. For patterns not seen in 90+ days with `source: bootstrap`: mark as `unconfirmed` (shield skips these)
6. Write updated index

**Playbook Index** — in PHASE 1, after pattern analysis:
1. Read existing `PLAYBOOK_INDEX.md` (or create if missing)
2. Extract "Successful workflows" from quick notes
3. For each successful workflow: update or create playbook entry
4. Write updated index

---

## Chain position

**Upstream:** using-supercycle (bootstrap)
**Downstream:** brainstorming (receives task with risk context), all other skills (pre-activated)

## When this skill prevents

This skill prevents:
- Recurring errors the user has already solved before
- Time wasted re-discovering known solutions
- Structural complexity blind spots (cross-layer issues)
- Context loss after project gaps
- Reinventing workflows that already have proven playbooks

## Edge cases

**Empty history:** If no quick notes exist AND no Pattern Index exists AND bootstrap hasn't run, the shield runs only Level 2 (structural analysis) and Level 3 (temporal context). These work without history.

**Too many matches:** Show top 5 by risk × occurrences. No walls of warnings.

**False positives:** The report is advisory, not blocking. Over time, triggers get refined by retrospective.

**Stale patterns:** Patterns with `source: bootstrap` that go unconfirmed for 90 days are marked `unconfirmed` and skipped. Patterns with `source: session` don't expire but can be marked `resolved` if not seen in 90+ days AND the associated skill is ACTIVE.
