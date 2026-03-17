#!/usr/bin/env bash
# Test: writing-supercycle-skills compliance
# Verifies that a skill created following the guide has required patterns

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"

echo "=== Test: writing-supercycle-skills compliance ==="
echo ""

TEST_DIR=$(create_test_project)
mkdir -p "$TEST_DIR/.claude/skills"
mkdir -p "$TEST_DIR/.claude/reports"

# Create an empty changelog
cat > "$TEST_DIR/.claude/reports/SKILL_CHANGELOG.md" <<'EOF'
# Skill Changelog
EOF

cd "$TEST_DIR"

# Test 1: Ask Claude to create a skill following the writing-supercycle-skills guide
echo "Test 1: Skill created via guide has robust description..."

output=$(run_claude "Using the writing-supercycle-skills skill as your guide, create a new skill called 'firebase-deploy' that helps with deploying Firebase Cloud Functions. The skill should prevent CORS errors and missing headers. Write it to .claude/skills/firebase-deploy/SKILL.md" 120 "Write,Read,Bash,Skill")

# Verify the skill file was created
if [ -f "$TEST_DIR/.claude/skills/firebase-deploy/SKILL.md" ]; then
    echo "  [PASS] Skill file created"
else
    echo "  [FAIL] Skill file not created"
    exit 1
fi

echo ""

# Test 2: Check for frontmatter with name and description
echo "Test 2: Has valid frontmatter..."

skill_content=$(cat "$TEST_DIR/.claude/skills/firebase-deploy/SKILL.md")

if assert_contains "$skill_content" "^---" "Has frontmatter delimiter"; then
    :
else
    exit 1
fi

if assert_contains "$skill_content" "name:" "Has name field"; then
    :
else
    exit 1
fi

if assert_contains "$skill_content" "description:" "Has description field"; then
    :
else
    exit 1
fi

echo ""

# Test 3: Description is robust (not fragile single-phrase)
echo "Test 3: Description uses symptom-based phrasing..."

# Extract description line(s) — robust descriptions mention symptoms, not just actions
if assert_contains "$skill_content" "CORS\|cors\|error\|403\|header" "Description references symptoms/errors"; then
    :
else
    exit 1
fi

echo ""

# Test 4: Has "When this skill prevents" section
echo "Test 4: Has reactivation hook section..."

if assert_contains "$skill_content" "When this skill prevents\|prevent" "Has prevention/reactivation section"; then
    :
else
    echo "  [WARN] No explicit 'When this skill prevents' section — recommended by guide"
fi

echo ""

# Test 5: Verify changelog integration mention
echo "Test 5: References changelog integration..."

# The skill should mention logging or changelog somewhere
if assert_contains "$skill_content" "changelog\|CHANGELOG\|log" "Mentions changelog integration"; then
    :
else
    echo "  [WARN] No changelog integration mention — recommended by guide"
fi

echo ""
echo "=== All writing-supercycle-skills tests passed ==="

cleanup_test_project "$TEST_DIR"
