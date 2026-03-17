# SuperCycle

A complete development lifecycle for AI coding agents.

SuperCycle combines [Superpowers](https://github.com/obra/superpowers) — the battle-tested skill framework for structured development workflows — with a predictive intelligence layer that learns from your sessions and prevents errors before they happen.

```
SESSION START                          SESSION END
      │                                     │
      ▼                                     ▼
 Predictive Shield (6 levels)      Auto-retrospective
 scans task, checks structure,     captures patterns,
 consults playbooks & community    updates indexes,
      │                            logs successful workflows
      ▼                                     │
 brainstorm → plan → implement              │
 → test → review → ship                     │
 (adaptive workflow)                        │
      │                                     │
      └──────────── next session ───────────┘
              starts stronger, warns smarter
```

## The problem with skill systems

Skill systems decay silently:
- Skills go unused because their description no longer matches how you talk about problems
- The same errors recur because no skill prevents them
- Workarounds accumulate that should be skills but never get formalized
- Successful workflows are forgotten — you reinvent them every time

Superpowers forces discipline during a session. Retrospective maintains the system between sessions. Predictive Shield prevents errors before they happen. Together they close the loop.

## Install

### Manual (all platforms — recommended)

```bash
git clone https://github.com/albertocontardi/supercycle.git /tmp/supercycle

# Claude Code
mkdir -p ~/.claude/skills
cp -r /tmp/supercycle/skills/* ~/.claude/skills/

# Codex
mkdir -p ~/.agents/skills
ln -s /tmp/supercycle/skills ~/.agents/skills/supercycle
```

No additional setup. On first session, SuperCycle bootstraps the Pattern Index from your project stack automatically.

## Quick Start

**Session 1 — you describe a feature to build:**
1. Claude loads `using-supercycle` via the session hook
2. **Pattern Index Bootstrap**: SuperCycle detects your stack (Firebase, React, Python, etc.) and generates 20-30 predictive patterns from known issues for that stack
3. **Community opt-in**: one-time prompt to enable anonymous pattern sharing (optional)
4. **Predictive Shield** runs its 6-level analysis on your task description
5. Skills enforce discipline: brainstorm → plan → implement → test → verify
6. At session end, the auto-retrospective captures what happened — no manual step needed

**After a week — you run `/retrospective`:**
- Full audit with health scores, dependency chain checks, playbook analysis
- Proposes skill changes and waits for your approval
- Updates Pattern Index and Playbook Index
- Shares anonymous patterns with community (if opted in)
- Downloads community patterns to improve your predictions

**After a month:**
- Bootstrap patterns confirmed by real experience get promoted
- Successful workflows become proven playbooks
- The Shield proposes adaptive workflows based on your track record
- Community patterns from other developers improve your predictions

## Predictive Shield — 6 Levels

The Shield runs at session start, producing one compact report.

| Level | Name | What it does | Needs history? |
|-------|------|-------------|----------------|
| 1 | Historical Pattern Matching | Matches task against Pattern Index | Yes |
| 2 | Structural Analysis | Counts layers and cross-layer interfaces | No |
| 3 | Temporal Context | Checks audit freshness, project gaps | No |
| 4 | Playbook Matching | Finds proven workflows for the task type | Yes |
| 5 | Adaptive Workflow | Proposes personalized workflow | Yes |
| 6 | Community Patterns | Advisory insights from other developers | Yes (community) |

```
⚡ Predictive Shield Report

📐 Structure: 3 layers, HIGH
🕐 Context: 12 days since audit, MEDIUM
⚠️ Historical: 2 pattern matches
✅ Playbook: "Firebase deploy" — 87% success rate
🔄 Workflow: playbook → verify → review (skip brainstorm — proven path)
🌐 Community: 1 relevant insight

Pre-activating: firebase-cors, verification-before-completion
```

Levels 2 and 3 work from day 1, with zero history.

## Playbook Index

The retrospective tracks successful workflows, not just errors. When you complete a task successfully, the workflow is recorded. After enough repetitions, it becomes a **proven playbook**.

The Shield uses playbooks to suggest workflows: "this task type has an 87% success rate with this specific workflow — use it instead of the default."

## Community Patterns

SuperCycle can share anonymous error patterns with a community of developers on the same stack.

**What gets shared:** error keywords, description, resolution, severity, stack tags, anonymous hash.
**What NEVER gets shared:** source code, file paths, project names, personal information.

Sharing is opt-in. Receiving is always active (it sends no user data). The community data is advisory — the Shield shows community insights but never auto-adds them to your local indexes.

Architecture: patterns flow through a Cloudflare Worker to the repo's `community-patterns/` directory, aggregated by a GitHub Action, and served back to users via the Worker's GET endpoint.

## Skills included

### From Superpowers (by Jesse Vincent)

| Skill | When it activates |
|-------|------------------|
| `brainstorming` | Before writing any code — forces design conversation |
| `writing-plans` | Breaks approved design into 2–5 min tasks with exact file paths |
| `executing-plans` | Dispatches subagents per task with two-stage review |
| `subagent-driven-development` | Orchestrates parallel subagents for complex tasks |
| `test-driven-development` | Enforces RED → GREEN → REFACTOR |
| `systematic-debugging` | Structured root-cause analysis before any fix |
| `using-git-worktrees` | Isolated branch + clean test baseline |
| `finishing-a-development-branch` | Pre-merge checklist |
| `requesting-code-review` | Prepares and submits PR |
| `receiving-code-review` | Processes review feedback |
| `dispatching-parallel-agents` | Runs multiple agents in parallel |
| `verification-before-completion` | Validates work before declaring done |
| `writing-skills` | Creates new skills following best practices |

### Original (SuperCycle)

| Skill | When it activates |
|-------|------------------|
| `using-supercycle` | Session start — bootstrap, shield trigger, opt-in, auto-retrospective |
| `predictive-shield` | Session start — 6-level analysis, pattern/playbook matching, community |
| `retrospective` | Manual (`/retrospective`) or auto (end of session for quick mode) |
| `writing-supercycle-skills` | When creating skills — extends `writing-skills` with lifecycle patterns |

## Agents included

| Agent | When it activates |
|-------|------------------|
| `code-reviewer` | After completing a major project step |

## File structure

```
.claude/
  skills/
    using-supercycle/SKILL.md
    predictive-shield/SKILL.md
    retrospective/SKILL.md
    brainstorming/
    writing-plans/
    ...
    _archived/                          # archived skills, never deleted
  reports/
    SKILL_CHANGELOG.md                  # source of truth for skill activity
    SKILL_DEPENDENCIES.md               # custom dependency chains
    PATTERN_INDEX.md                    # error patterns for Shield
    PLAYBOOK_INDEX.md                   # successful workflows
    COMMUNITY_PATTERNS.md              # cached community patterns
    METRICS_HISTORY.md                  # metrics across audits
    skill_audit_notes/                  # quick session notes
    SKILL_AUDIT_[date].md              # full audit reports
  supercycle-config.json                # community sharing preference

infrastructure/
  cloudflare-worker/                    # community patterns worker
    wrangler.toml
    src/index.js
    README.md

community-patterns/
  inbox/                                # temporary files from worker
  aggregated/                           # final files served by worker

.github/
  workflows/
    aggregate-patterns.yml              # aggregation action
```

## Privacy

- **Pattern Index**: local only, never shared unless you opt in
- **Playbook Index**: local only, never shared
- **Community sharing**: opt-in, anonymous (SHA-256 hash), no code/paths/names
- **Community receiving**: always active, downloads public data, sends nothing
- **Cross-project learning**: local filesystem only, no network
- **supercycle-config.json**: contains only a boolean and a hash

## Tests

```bash
cd tests/claude-code
./run-supercycle-tests.sh
```

| Test | What it covers |
|------|---------------|
| `test-using-supercycle.sh` | Session start discipline, end-of-session auto-retrospective, subagent stop |
| `test-retrospective-quick.sh` | Note file creation, metrics, successful workflows, summary |
| `test-retrospective-full.sh` | Action plan, confirmation gate, changelog, playbook update |
| `test-retrospective-reactivation.sh` | Dormant skill + matching error → REACTIVATE not archive |
| `test-predictive-shield.sh` | Pattern matching, structural analysis, risk prioritization |
| `test-writing-supercycle-skills.sh` | Robust description, reactivation hooks, changelog integration |
| `test-bootstrap.sh` | Stack detection → Pattern Index generation with bootstrap patterns |
| `test-community-sharing.sh` | Opt-in → anonymized payload, no paths/names |
| `test-playbook-index.sh` | Successful workflow → playbook creation/update |

## Syncing Superpowers

```bash
./scripts/sync-superpowers.sh --check     # check for updates
./scripts/sync-superpowers.sh --dry-run   # preview changes
./scripts/sync-superpowers.sh v4.2.0      # sync specific version
```

## Platform support

| Platform | Session hook | Skill discovery | Manual fallback |
|----------|-------------|-----------------|-----------------|
| Claude Code | ✅ automatic | ✅ native | `/using-supercycle` |
| Cursor | ✅ automatic | ✅ native | `/using-supercycle` |
| Gemini CLI | ✅ via GEMINI.md | ✅ native | — |
| Codex | ❌ no hook | ✅ via symlink | `/using-supercycle` |
| Other | ❌ no hook | depends | `/using-supercycle` |

## Credits

SuperCycle includes [Superpowers](https://github.com/obra/superpowers) by **Jesse Vincent** ([@obra](https://github.com/obra)), used under the MIT License. Superpowers is the foundation — SuperCycle adds the predictive intelligence layer.

See [CREDITS.md](CREDITS.md) for details.

## License

MIT — see [LICENSE](LICENSE).

Superpowers skills are MIT — see [LICENSE.superpowers](LICENSE.superpowers).
