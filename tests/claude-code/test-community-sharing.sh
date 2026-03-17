#!/usr/bin/env bash
# Test: Community sharing anonymization
# Verifies that with opt-in active, retrospective produces an anonymized payload

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"

echo "=== Test: Community sharing anonymization ==="
echo ""

TEST_DIR=$(create_test_project)
mkdir -p "$TEST_DIR/.claude/reports/skill_audit_notes"
cd "$TEST_DIR"

# Create opt-in config
cat > "$TEST_DIR/.claude/supercycle-config.json" <<'EOF'
{ "community_sharing": true, "user_hash": "a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2" }
EOF

# Create a Pattern Index with session patterns
cat > "$TEST_DIR/.claude/reports/PATTERN_INDEX.md" <<'EOF'
# Pattern Index

## Patterns

### cors-issue: CORS on deploy
- triggers: deploy, firebase, cors
- error: CORS header missing after deployment
- resolution: Add CORS middleware
- skill: none
- occurrences: 3
- last_seen: 2026-03-17
- severity: HIGH
- source: session
EOF

# Test 1: Retrospective mentions sharing
echo "Test 1: Retrospective mentions community sharing..."

output=$(run_claude "Run /retrospective. When you reach the community sharing step in Phase 1, describe what payload you would send. Do NOT actually make a network call. Just show the anonymized payload. Stop after that." 90 "Write,Read,Bash,Glob,Grep")

if assert_contains "$output" "pattern\|Pattern\|cors\|CORS" "Includes pattern data"; then
    :
else
    exit 1
fi

echo ""

# Test 2: No file paths in output
echo "Test 2: No file paths in sharing payload..."

if assert_not_contains "$output" "/home\|/Users\|C:\\\\" "No absolute paths in output"; then
    :
else
    exit 1
fi

echo ""

# Test 3: No project names
echo "Test 3: No project-specific names..."

if assert_not_contains "$output" "test-project\|TEST_DIR" "No project names in output"; then
    :
else
    exit 1
fi

echo ""
echo "=== All community sharing tests passed ==="

cleanup_test_project "$TEST_DIR"
