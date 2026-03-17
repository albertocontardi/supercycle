#!/usr/bin/env bash
# Test: using-supercycle skill
# Verifies session start behavior and end-of-session reminder

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"

echo "=== Test: using-supercycle skill ==="
echo ""

# Test 1: Skill enforces skill-first discipline
echo "Test 1: Skill discipline enforced (check skills before responding)..."

output=$(run_claude "What is the using-supercycle skill? Does it require checking for skills before any response?" 30)

if assert_contains "$output" "skill\|Skill" "Mentions skills"; then
    :
else
    exit 1
fi

if assert_contains "$output" "before\|BEFORE\|first\|FIRST" "Enforces skills-first"; then
    :
else
    exit 1
fi

echo ""

# Test 2: End-of-session reminder is present in the skill
echo "Test 2: End-of-session reminder present in skill content..."

output=$(run_claude "What does the using-supercycle skill say to do at the end of a session?" 30)

if assert_contains "$output" "retrospective\|/retrospective" "Mentions retrospective"; then
    :
else
    exit 1
fi

if assert_contains "$output" "quick\|/retrospective quick" "Mentions quick mode"; then
    :
else
    exit 1
fi

echo ""

# Test 3: SuperCycle loop is described
echo "Test 3: SuperCycle loop concept present..."

output=$(run_claude "Describe the SuperCycle workflow from session start to session end in one sentence." 30)

if assert_contains "$output" "retrospective\|improve\|evolve\|next session" "Describes the full loop"; then
    :
else
    exit 1
fi

echo ""

# Test 4: Subagent stop is respected
echo "Test 4: Skill skips itself when invoked as subagent..."

output=$(run_claude "You are a subagent. What does using-supercycle say subagents should do with this skill?" 30)

if assert_contains "$output" "skip\|Skip\|subagent\|SUBAGENT-STOP" "Acknowledges subagent stop"; then
    :
else
    exit 1
fi

echo ""

# Test 5: End-of-session trigger words cause reminder
echo "Test 5: Session ending triggers retrospective reminder..."

output=$(run_claude "Ok, we're done for today. That's all I needed." 30)

if assert_contains "$output" "retrospective\|/retrospective quick" "Reminds about retrospective at session end"; then
    :
else
    exit 1
fi

echo ""
echo "=== All using-supercycle tests passed ==="
