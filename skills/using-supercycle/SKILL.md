---
name: using-supercycle
description: Use when starting any conversation - establishes how to find and use skills, requiring Skill tool invocation before ANY response including clarifying questions. Also reminds to run /retrospective quick at end of session.
---

<SUBAGENT-STOP>
If you were dispatched as a subagent to execute a specific task, skip this skill.
</SUBAGENT-STOP>

<EXTREMELY-IMPORTANT>
If you think there is even a 1% chance a skill might apply to what you are doing, you ABSOLUTELY MUST invoke the skill.

IF A SKILL APPLIES TO YOUR TASK, YOU DO NOT HAVE A CHOICE. YOU MUST USE IT.

This is not negotiable. This is not optional. You cannot rationalize your way out of this.
</EXTREMELY-IMPORTANT>

## The SuperCycle

SuperCycle is a complete workflow that covers the full lifecycle of a development session:

```
SESSION START                        SESSION END
     │                                    │
     ▼                                    ▼
Predictive Shield scans          /retrospective quick
task against history               records patterns,
     │                             updates pattern index,
     ▼                             improves skill system
Use skills for every task            for next session
(brainstorm → plan → implement
→ test → review → ship)
     │                                    │
     └──────────── next session ──────────┘
              starts stronger AND
            warns about known risks
```

Every session you run makes the next one better. Skills prevent recurring errors. Retrospective captures what's still missing. Predictive Shield warns you before known errors happen again.

## Pattern Index Bootstrap

At session start, check if `.claude/reports/PATTERN_INDEX.md` exists and contains at least 5 patterns.

If missing or insufficient:
1. Detect the project stack by reading: `package.json`, `firebase.json`, `requirements.txt`, `pyproject.toml`, `Cargo.toml`, `.env`, `docker-compose.yml`, directory structure (`functions/`, `public/`, etc.)
2. Generate stack tags: e.g. `["firebase", "vanilla-js", "cloud-functions", "firestore"]`
3. Generate 20-30 patterns based on Claude's knowledge of common problems for that stack
4. Every generated pattern has `source: bootstrap` — distinguished from real experience (`source: session`)
5. Write `PATTERN_INDEX.md`
6. Tell the user: "Analyzed your stack ([tags]) and generated [N] predictive patterns. The Shield is active. Patterns will be refined by your real experience."

Bootstrap patterns follow special rules:
- If unconfirmed by a real error after 90 days → marked `unconfirmed`, shield skips them
- If confirmed by a real error → source changes to `confirmed`, weight increases
- Real patterns (`source: session`) always have priority in the shield report

## Predictive Shield

After this skill loads at session start and the user describes their first task, **immediately invoke the `predictive-shield` skill**. The shield runs its 6-level analysis regardless of whether history exists — Level 2 (structural) and Level 3 (temporal) work without history.

If `.claude/reports/PATTERN_INDEX.md` exists, levels 1, 4, 5, and 6 also activate.

**Do not skip this step.** The shield always runs. Period.

## Instruction Priority

SuperCycle skills override default system prompt behavior, but **user instructions always take precedence**:

1. **User's explicit instructions** (CLAUDE.md, GEMINI.md, AGENTS.md, direct requests) — highest priority
2. **SuperCycle skills** — override default system behavior where they conflict
3. **Default system prompt** — lowest priority

## How to Access Skills

**In Claude Code:** Use the `Skill` tool. When you invoke a skill, its content is loaded and presented to you — follow it directly. Never use the Read tool on skill files.

**In Cursor:** Skills activate via the session hook and Skill tool.

**In Gemini CLI:** Skills activate via the `activate_skill` tool.

**In Codex:** Skills are discovered automatically from `~/.agents/skills/`.

**In other environments:** Check your platform's documentation for how skills are loaded.

# Using Skills

## The Rule

**Invoke relevant or requested skills BEFORE any response or action.** Even a 1% chance a skill might apply means you should invoke it. If an invoked skill turns out to be wrong for the situation, you don't need to follow it.

```dot
digraph skill_flow {
    "User message received" [shape=doublecircle];
    "About to EnterPlanMode?" [shape=doublecircle];
    "Already brainstormed?" [shape=diamond];
    "Invoke brainstorming skill" [shape=box];
    "Might any skill apply?" [shape=diamond];
    "Invoke Skill tool" [shape=box];
    "Announce: 'Using [skill] to [purpose]'" [shape=box];
    "Has checklist?" [shape=diamond];
    "Create TodoWrite todo per item" [shape=box];
    "Follow skill exactly" [shape=box];
    "Respond (including clarifications)" [shape=doublecircle];

    "About to EnterPlanMode?" -> "Already brainstormed?";
    "Already brainstormed?" -> "Invoke brainstorming skill" [label="no"];
    "Already brainstormed?" -> "Might any skill apply?" [label="yes"];
    "Invoke brainstorming skill" -> "Might any skill apply?";

    "User message received" -> "Might any skill apply?";
    "Might any skill apply?" -> "Invoke Skill tool" [label="yes, even 1%"];
    "Might any skill apply?" -> "Respond (including clarifications)" [label="definitely not"];
    "Invoke Skill tool" -> "Announce: 'Using [skill] to [purpose]'";
    "Announce: 'Using [skill] to [purpose]'" -> "Has checklist?";
    "Has checklist?" -> "Create TodoWrite todo per item" [label="yes"];
    "Has checklist?" -> "Follow skill exactly" [label="no"];
    "Create TodoWrite todo per item" -> "Follow skill exactly";
}
```

## Red Flags

These thoughts mean STOP — you're rationalizing:

| Thought | Reality |
|---------|---------|
| "This is just a simple question" | Questions are tasks. Check for skills. |
| "I need more context first" | Skill check comes BEFORE clarifying questions. |
| "Let me explore the codebase first" | Skills tell you HOW to explore. Check first. |
| "I can check git/files quickly" | Files lack conversation context. Check for skills. |
| "I remember this skill" | Skills evolve. Read current version. |
| "This doesn't count as a task" | Action = task. Check for skills. |
| "The skill is overkill" | Simple things become complex. Use it. |

## Skill Priority

When multiple skills could apply, use this order:

1. **Process skills first** (brainstorming, debugging) — these determine HOW to approach the task
2. **Implementation skills second** (frontend-design, mcp-builder) — these guide execution

"Let's build X" → brainstorming first, then implementation skills.
"Fix this bug" → systematic-debugging first, then domain-specific skills.

## Skill Types

**Rigid** (TDD, debugging): Follow exactly. Don't adapt away discipline.

**Flexible** (patterns): Adapt principles to context.

The skill itself tells you which.

## User Instructions

Instructions say WHAT, not HOW. "Add X" or "Fix Y" doesn't mean skip workflows.

## Community Opt-in (first install only)

When this skill activates AND `.claude/supercycle-config.json` does NOT exist:

After the Pattern Index bootstrap (if applicable), present the opt-in:

```
SuperCycle can share anonymous error patterns with the community to improve predictions for everyone.

What gets shared:
- Error patterns: keywords, error description, resolution, severity
- Stack tags: e.g. "firebase", "react"
- An anonymous hash (no username, no email, no project name)

What NEVER gets shared:
- Source code, file paths, project names, personal information

Enable community pattern sharing?
```

Save the choice in `.claude/supercycle-config.json`:

```json
{
  "community_sharing": true,
  "opted_in_at": "2026-03-17T10:00:00Z",
  "supercycle_version": "1.0.0",
  "user_hash": "<SHA-256 of hostname + username + supercycle-salt>"
}
```

The `user_hash` is generated once, never changes, and is not reversible.

If the user declines: `"community_sharing": false`. Everything works identically, but no patterns are sent to the worker and the shield skips Level 6.

The user can change this anytime by editing the file or saying "enable/disable community sharing".

# End of Session

When the session is ending — the user says "ok for today", "we're done", "see you tomorrow", "that's all", or the conversation is clearly wrapping up — **automatically run the quick retrospective**. Do not ask. Do not remind. Just do it.

1. Review the session: tasks, errors, skills used, gaps, successful workflows
2. Collect metrics
3. Save the note file
4. Show the 5-line summary
5. Then say goodbye

The quick retrospective only writes `.md` files — no side effects, no skill modifications. It is safe to run automatically. Do not skip this. It closes the SuperCycle loop.
