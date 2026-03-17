# Contributing to SuperCycle

## What to contribute

SuperCycle has two distinct layers and contributions are welcome to both.

**Superpowers layer** (skills inherited from obra/superpowers):
For bugs or improvements to the core development workflow skills (brainstorming, TDD, debugging, etc.), contribute upstream to [obra/superpowers](https://github.com/obra/superpowers). SuperCycle pulls these in as-is — fixes there benefit everyone.

**SuperCycle layer** (original skills):
Contributions here should target the lifecycle management skills: `retrospective`, `using-supercycle`, and any new skill that fits the "evolve the system between sessions" pattern.

## How to contribute

1. Fork the repo
2. Create a branch: `git checkout -b my-improvement`
3. Make your changes
4. Run the test suite (see below)
5. Open a PR with a clear description of what changed and why

## Running tests

Tests require Claude Code CLI installed and authenticated.

```bash
# Run all SuperCycle original skill tests (~5 minutes)
cd tests/claude-code
./run-supercycle-tests.sh

# Run a specific test
./run-supercycle-tests.sh --test test-retrospective-quick.sh
```

Tests only cover the original SuperCycle skills. Superpowers skills are tested upstream.

## Adding a new skill

If you want to add a skill that fits the SuperCycle lifecycle pattern:

1. Create `.claude/skills/[skill-name]/SKILL.md`
2. Follow the [Agent Skills standard](https://agentskills.io) for frontmatter
3. Use `disable-model-invocation: true` if the skill has side effects or should only run manually
4. Add a test in `tests/claude-code/test-[skill-name].sh`
5. Add the skill to the table in `README.md`

A good SuperCycle skill answers one of these questions:
- Does it help maintain the skill system between sessions?
- Does it capture knowledge that would otherwise be lost at session end?
- Does it prevent a recurring class of errors?

## Modifying the retrospective skill

The `retrospective` skill is the core of SuperCycle. Before modifying it:

- The "Core principle" section (dormant → reactivate vs archive) is the architectural foundation — changes here need strong justification
- The 6-phase structure is intentional — adding phases needs a clear reason
- The changelog as source of truth is non-negotiable — don't introduce alternative activity tracking

## Modifying using-supercycle

`using-supercycle` is injected at every session start via the hook. Keep it focused:
- Skill discipline (check skills before acting)
- End-of-session reminder
- Platform-specific tool access

Don't add workflow logic here — that belongs in individual skills.

## Code style

- Shell scripts: `set -euo pipefail`, quote all variables, use `printf` over `echo` for output
- SKILL.md: single-line YAML descriptions (multiline breaks the indexer), explicit trigger language in descriptions
- Tests: follow the pattern in `test-helpers.sh`, one test file per skill, clear `[PASS]`/`[FAIL]` output

## Questions

Open an issue. Response time is best-effort.
