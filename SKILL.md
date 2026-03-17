---
name: supercycle
description: Development lifecycle framework — loads at every session start. Activates Predictive Shield, skill enforcement, and FULL retrospective (6 phases) at session end. Entry point for all SuperCycle sub-skills.
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
Predictive Shield scans          FULL retrospective (6 phases)
task against history               pattern + playbook indexes,
     │                             skill health scores,
     ▼                             gap analysis, action plan
Use skills for every task          (wait for user confirm),
(brainstorm → plan → implement     execute approved actions
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

When the session is ending — user says "basta per oggi", "ok per oggi", "abbiamo finito", "we're done", "that's all" — **automatically run the FULL retrospective** (all 6 phases). Do not ask. Just do it.

1. Phase 0: Data collection (quick notes, changelog, memory)
2. Phase 1: Pattern analysis + update Pattern Index + update Playbook Index + community sharing
3. Phase 2: Skill analysis with health scores + dependency chain check
4. Phase 3: Gap analysis
5. Phase 4: Action plan — **present to user and WAIT for confirmation**
6. Phase 5: Execute approved actions (create/modify/reactivate/archive skills)
7. Phase 6: Changelog update + full report + say goodbye
