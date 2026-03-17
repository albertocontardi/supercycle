#!/usr/bin/env bash
# Test: retrospective reactivation mechanism
# Verifies that dormant skills matching a recurring error get REACTIVATED, not archived

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"

echo "=== Test: reactivation mechanism (dormant skill + matching error = REACTIVATE) ==="
echo ""

TEST_DIR=$(create_test_project)
mkdir -p "$TEST_DIR/.claude/reports/skill_audit_notes"
mkdir -p "$TEST_DIR/.claude/skills/firebase-cors"
mkdir -p "$TEST_DIR/.claude/skills/old-irrelevant-skill"

# Create a dormant skill that MATCHES the recurring error
cat > "$TEST_DIR/.claude/skills/firebase-cors/SKILL.md" <<'EOF'
---
name: firebase-cors
description: Handle Firebase Cloud Functions setup
---
# Firebase CORS Skill
Instructions for configuring Firebase Cloud Functions.
Always add CORS headers when deploying functions.
EOF

# Create a dormant skill that does NOT match any error
cat > "$TEST_DIR/.claude/skills/old-irrelevant-skill/SKILL.md" <<'EOF'
---
name: old-irrelevant-skill
description: Something about Trello integration
---
# Old Irrelevant Skill
Instructions for Trello webhooks.
EOF

# Empty changelog = both skills are INACTIVE
cat > "$TEST_DIR/.claude/reports/SKILL_CHANGELOG.md" <<'EOF'
# Skill Changelog
EOF

# Quick notes with recurring CORS error
cat > "$TEST_DIR/.claude/reports/skill_audit_notes/2026-03-15_quick.md" <<'EOF'
# Quick Retrospective — 2026-03-15

## Recurring errors
- CORS error on Firebase Cloud Functions — resolved via: manual header addition — occurrences: 3

## Gaps identified
- Firebase CORS configuration not automated
EOF

cd "$TEST_DIR"

# Test 1: Dormant skill matching error → REACTIVATE, not archive
echo "Test 1: Dormant skill matching error gets REACTIVATE status..."

output=$(run_claude "Run /retrospective. Both firebase-cors and old-irrelevant-skill are dormant (never in changelog). Analyze the session notes and determine what to do with each skill." 120 "Write,Read,Bash,Glob,Grep")

if assert_contains "$output" "REACTIVATE\|reactivate\|Reactivate" "Proposes reactivation for matching skill"; then
    :
else
    exit 1
fi

echo ""

# Test 2: Matching skill is NOT proposed for archival
echo "Test 2: Matching skill NOT proposed for removal..."

if assert_not_contains "$output" "archive firebase-cors\|remove firebase-cors\|Archive.*firebase-cors" "Does not propose archiving firebase-cors"; then
    :
else
    exit 1
fi

echo ""

# Test 3: Non-matching dormant skill IS proposed for archival
echo "Test 3: Non-matching dormant skill proposed for archival..."

if assert_contains "$output" "old-irrelevant\|CANDIDATE\|archive\|Archive" "Proposes archiving irrelevant skill"; then
    :
else
    exit 1
fi

echo ""

# Test 4: Core principle is applied — description update proposed for matching skill
echo "Test 4: Description update proposed for reactivated skill..."

if assert_contains "$output" "description\|trigger\|CORS\|cors" "Proposes description update referencing the error"; then
    :
else
    exit 1
fi

echo ""
echo "=== All reactivation mechanism tests passed ==="

cleanup_test_project "$TEST_DIR"
