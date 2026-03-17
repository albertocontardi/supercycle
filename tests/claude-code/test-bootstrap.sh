#!/usr/bin/env bash
# Test: Pattern Index bootstrap
# Verifies that on a project with package.json + firebase.json, bootstrap generates a Pattern Index

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"

echo "=== Test: Pattern Index bootstrap ==="
echo ""

TEST_DIR=$(create_test_project)
mkdir -p "$TEST_DIR/.claude/reports"
cd "$TEST_DIR"

# Create a Firebase + Node.js project
cat > "$TEST_DIR/package.json" <<'EOF'
{ "name": "test-project", "dependencies": { "firebase-admin": "^12.0.0", "express": "^4.18.0" } }
EOF

cat > "$TEST_DIR/firebase.json" <<'EOF'
{ "hosting": { "public": "public" }, "functions": { "source": "functions" } }
EOF

mkdir -p "$TEST_DIR/functions"

# Test 1: Bootstrap generates Pattern Index
echo "Test 1: Bootstrap generates Pattern Index..."

output=$(run_claude "This is a new project. Check if the Pattern Index needs bootstrapping. If PATTERN_INDEX.md doesn't exist or has fewer than 5 patterns, bootstrap it by detecting the stack and generating common patterns. Show what you generated." 120 "Write,Read,Bash,Glob,Grep")

if assert_contains "$output" "firebase\|Firebase\|FIREBASE" "Detects Firebase stack"; then
    :
else
    exit 1
fi

echo ""

# Test 2: Pattern Index file exists and has patterns
echo "Test 2: Pattern Index file created..."

if [ -f "$TEST_DIR/.claude/reports/PATTERN_INDEX.md" ]; then
    echo "  [PASS] PATTERN_INDEX.md created"
else
    echo "  [FAIL] PATTERN_INDEX.md not found"
    exit 1
fi

pattern_content=$(cat "$TEST_DIR/.claude/reports/PATTERN_INDEX.md")

if assert_contains "$pattern_content" "source: bootstrap" "Patterns marked as bootstrap"; then
    :
else
    exit 1
fi

echo ""

# Test 3: Has at least 5 patterns
echo "Test 3: Has sufficient patterns..."

pattern_count=$(grep -c "^### " "$TEST_DIR/.claude/reports/PATTERN_INDEX.md" || echo "0")
if [ "$pattern_count" -ge 5 ]; then
    echo "  [PASS] Has $pattern_count patterns (>= 5)"
else
    echo "  [FAIL] Only $pattern_count patterns (need >= 5)"
    exit 1
fi

echo ""
echo "=== All bootstrap tests passed ==="

cleanup_test_project "$TEST_DIR"
