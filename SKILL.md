---
name: supercycle
description: Development lifecycle framework — loads at every session start. Activates Predictive Shield, skill enforcement, and auto-retrospective at session end. Entry point for all SuperCycle sub-skills.
---

<SUBAGENT-STOP>
If you were dispatched as a subagent to execute a specific task, skip this skill entirely.
</SUBAGENT-STOP>

## SuperCycle — Session Bootstrap

This is the root entry point. It loads automatically at every session start.

### What SuperCycle Does

```
SESSION START                        SESSION END
     │                                    │
     ▼                                    ▼
Predictive Shield scans          Auto-retrospective
task against history               records patterns,
     │                             updates pattern index
     ▼
Use skills for every task
(brainstorm → plan → implement
→ test → review → ship)
     │                                    │
     └──────────── next session ──────────┘
              starts stronger AND
            warns about known risks
```

### Session Start Actions

1. **Pattern Index Bootstrap**: If `.claude/reports/PATTERN_INDEX.md` is missing, detect project stack and generate initial patterns
2. **Predictive Shield**: After the user describes their first task, invoke the `predictive-shield` skill for 6-level risk analysis
3. **Skill Enforcement**: Before ANY response, check if a sub-skill applies. Even 1% chance = invoke it.

### Available Sub-Skills

| Skill | When to use |
|-------|-------------|
| `predictive-shield` | Automatically at session start after first task described |
| `brainstorming` | Before planning any feature or solution |
| `writing-plans` | When creating implementation plans |
| `executing-plans` | When implementing from a plan |
| `systematic-debugging` | When debugging any issue |
| `subagent-driven-development` | When task benefits from parallel agents |
| `test-driven-development` | When writing tests |
| `retrospective` | Automatically at session end |
| `writing-skills` | When creating or improving skills |
| `verification-before-completion` | Before marking any task as done |
| `using-git-worktrees` | When isolating work in branches |
| `dispatching-parallel-agents` | When parallelizing work |
| `receiving-code-review` | When reviewing code |
| `requesting-code-review` | When asking for review |
| `finishing-a-development-branch` | When wrapping up a branch |

### Instruction Priority

1. **User's explicit instructions** (CLAUDE.md, direct requests) — highest
2. **SuperCycle skills** — override defaults
3. **Default system prompt** — lowest

### Session End

When the session is ending — user says "ok for today", "we're done", "that's all" — **automatically run the quick retrospective**. Do not ask. Just do it.

1. Review session: tasks, errors, skills used, gaps
2. Save note to `.claude/reports/skill_audit_notes/`
3. Show 5-line summary
4. Say goodbye
