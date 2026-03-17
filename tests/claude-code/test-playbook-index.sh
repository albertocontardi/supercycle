#!/usr/bin/env bash
# Test: Playbook Index creation
# Verifies that after a session with successful workflows, retrospective creates/updates Playbook Index

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"

echo "=== Test: Playbook Index ==="
echo ""

TEST_DIR=$(create_test_project)
mkdir -p "$TEST_DIR/.claude/reports/skill_audit_notes"
cd "$TEST_DIR"

# Create a quick note with a successful workflow
cat > "$TEST_DIR/.claude/reports/skill_audit_notes/$(date +%Y-%m-%d)_quick.md" <<'EOF'
# Quick Retrospective

## Metrics
| Metric | Value |
|--------|-------|
| tasks_completed | 2 |
| tasks_failed | 0 |

## Recurring errors
(none)

## Successful workflows
- Firebase function deploy — workflow: systematic-debugging → test-driven-development → verification-before-completion — duration: ~15min — notes: tested with emulator first, deployed single function, then batch

## Tags
#session #deploy
EOF

# Create changelog
cat > "$TEST_DIR/.claude/reports/SKILL_CHANGELOG.md" <<'EOF'
## 2026-03-17 10:00 — INVOKE
**Skill:** systematic-debugging
**Task:** Pre-deploy check
EOF

# Test 1: Retrospective creates Playbook Index
echo "Test 1: Playbook Index created from successful workflow..."

output=$(run_claude "Run /retrospective. Focus on Phase 1 — extract the successful workflow from the quick note and create PLAYBOOK_INDEX.md. Show the Phase 1 results and stop before Phase 2." 90 "Write,Read,Bash,Glob,Grep")

if [ -f "$TEST_DIR/.claude/reports/PLAYBOOK_INDEX.md" ]; then
    echo "  [PASS] PLAYBOOK_INDEX.md created"
else
    echo "  [FAIL] PLAYBOOK_INDEX.md not found"
    exit 1
fi

echo ""

# Test 2: Playbook contains the workflow
echo "Test 2: Playbook contains successful workflow..."

playbook_content=$(cat "$TEST_DIR/.claude/reports/PLAYBOOK_INDEX.md")

if assert_contains "$playbook_content" "deploy\|Deploy" "Has deploy task type"; then
    :
else
    exit 1
fi

if assert_contains "$playbook_content" "SUCCESS\|success" "Has success outcome"; then
    :
else
    exit 1
fi

echo ""
echo "=== All Playbook Index tests passed ==="

cleanup_test_project "$TEST_DIR"
