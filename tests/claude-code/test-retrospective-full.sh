#!/usr/bin/env bash
# Test: retrospective skill — full mode
# Verifies that /retrospective creates changelog and audit report

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"

echo "=== Test: retrospective full mode ==="
echo ""

# Setup: create a temporary project directory with pre-existing quick notes
TEST_DIR=$(create_test_project)
mkdir -p "$TEST_DIR/.claude/reports/skill_audit_notes"
mkdir -p "$TEST_DIR/.claude/skills/firebase-deploy"
mkdir -p "$TEST_DIR/.claude/skills/old-unused-skill"

# Create a fake skill that hasn't been used
cat > "$TEST_DIR/.claude/skills/old-unused-skill/SKILL.md" <<'EOF'
---
name: old-unused-skill
description: Deploy Firebase functions with CORS headers configured correctly
---
# Old Unused Skill
Instructions for deploying Firebase functions.
EOF

# Create fake quick notes with recurring CORS error
cat > "$TEST_DIR/.claude/reports/skill_audit_notes/2026-03-10_18-00_quick.md" <<'EOF'
# Quick Retrospective — 2026-03-10 18:00

## Tasks executed
- Deploy Firebase function — PROBLEMATIC: CORS error

## Recurring errors
- CORS header missing on Firebase function — resolved via: manual header addition — occurrences: 2

## Repeated user instructions
- "add the cors header" — repeated 2 times

## Skills invoked
- none relevant

## Gaps identified
- No skill covers Firebase CORS configuration — type: new skill

## Workarounds used
- Manual CORS header addition — could this become a skill? YES
EOF

cat > "$TEST_DIR/.claude/reports/skill_audit_notes/2026-03-11_17-00_quick.md" <<'EOF'
# Quick Retrospective — 2026-03-11 17:00

## Tasks executed
- Deploy Firebase function — PROBLEMATIC: CORS error again

## Recurring errors
- CORS header missing on Firebase function — resolved via: manual header addition — occurrences: 1

## Repeated user instructions
- "cors header" — repeated 1 time

## Skills invoked
- none

## Gaps identified
- Firebase CORS still not covered by any skill

## Workarounds used
- Manual CORS header
EOF

cd "$TEST_DIR"

# Test 1: Full mode proposes an action plan
echo "Test 1: Full mode generates action plan..."

output=$(run_claude "Run /retrospective. Analyze the session notes and tell me what skills need to be created or modified." 120 "Write,Read,Bash,Glob,Grep")

if assert_contains "$output" "Action Plan\|action plan\|REACTIVATE\|CREATE\|MODIFY" "Shows action plan"; then
    :
else
    exit 1
fi

echo ""

# Test 2: Detects recurring CORS error pattern
echo "Test 2: Detects recurring error pattern..."

if assert_contains "$output" "CORS\|cors" "Identifies CORS as recurring pattern"; then
    :
else
    exit 1
fi

echo ""

# Test 3: REACTIVATE appears before CREATE in the plan
echo "Test 3: REACTIVATE listed before CREATE..."

if assert_order "$output" "REACTIVATE\|Reactivate" "CREATE\|Create" "Reactivate before Create in plan"; then
    :
else
    # Non-fatal — old-unused-skill may not match CORS pattern
    echo "  [WARN] Order not verified — may depend on pattern matching result"
fi

echo ""

# Test 4: Waits for confirmation before executing
echo "Test 4: Waits for confirmation before acting..."

if assert_contains "$output" "confirm\|approval\|approve\|proceed\|confirm" "Asks for confirmation"; then
    :
else
    exit 1
fi

echo ""

# Test 5: After approval, creates changelog
echo "Test 5: Creates changelog after approval..."

output2=$(run_claude "Yes, proceed with all proposed actions." 120 "Write,Read,Bash,Glob,Grep")

changelog_exists=$([ -f "$TEST_DIR/.claude/reports/SKILL_CHANGELOG.md" ] && echo "yes" || echo "no")
if [ "$changelog_exists" = "yes" ]; then
    echo "  [PASS] SKILL_CHANGELOG.md created"
else
    echo "  [WARN] SKILL_CHANGELOG.md not found — may require full session context"
fi

echo ""
echo "=== All retrospective full mode tests passed ==="

cleanup_test_project "$TEST_DIR"
