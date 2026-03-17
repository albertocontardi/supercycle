#!/usr/bin/env bash
# Test: retrospective skill — quick mode
# Verifies that /retrospective quick generates a note file in skill_audit_notes/

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"

echo "=== Test: retrospective quick mode ==="
echo ""

# Setup: create a temporary project directory
TEST_DIR=$(create_test_project)
mkdir -p "$TEST_DIR/.claude/reports/skill_audit_notes"

cd "$TEST_DIR"

# Test 1: /retrospective quick generates a note file
echo "Test 1: Quick mode generates note file..."

output=$(run_claude "Run /retrospective quick. We had a session where we deployed a Firebase function but got a CORS error twice. We had to add the cors header manually both times." 90 "Write,Read,Bash")

if assert_contains "$output" "skill_audit_notes\|quick\|retrospective" "Mentions output location"; then
    :
else
    exit 1
fi

# Check file was actually created
note_files=$(find "$TEST_DIR/.claude/reports/skill_audit_notes" -name "*_quick.md" 2>/dev/null | wc -l)
if [ "$note_files" -gt 0 ]; then
    echo "  [PASS] Note file created in skill_audit_notes/"
else
    echo "  [FAIL] No note file found in skill_audit_notes/"
    exit 1
fi

echo ""

# Test 2: Note file contains expected sections
echo "Test 2: Note file has correct structure..."

note_file=$(find "$TEST_DIR/.claude/reports/skill_audit_notes" -name "*_quick.md" | head -1)
note_content=$(cat "$note_file")

if assert_contains "$note_content" "Recurring errors\|recurring errors" "Has recurring errors section"; then
    :
else
    exit 1
fi

if assert_contains "$note_content" "Gaps identified\|gaps identified" "Has gaps section"; then
    :
else
    exit 1
fi

if assert_contains "$note_content" "CORS\|cors\|header" "Captures the actual error"; then
    :
else
    exit 1
fi

echo ""

# Test 3: Summary is shown to user
echo "Test 3: Summary shown to user..."

if assert_contains "$output" "error\|gap\|recommendation" "Shows summary with key info"; then
    :
else
    exit 1
fi

echo ""
echo "=== All retrospective quick tests passed ==="

cleanup_test_project "$TEST_DIR"
