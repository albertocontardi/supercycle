#!/usr/bin/env bash
# SuperCycle test runner — covers only original SuperCycle skills
# Superpowers skills are tested in the original obra/superpowers repo

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "========================================"
echo "  SuperCycle Test Suite"
echo "  Testing original SuperCycle skills"
echo "========================================"
echo ""

PASS=0
FAIL=0
TESTS=(
    "test-using-supercycle.sh"
    "test-retrospective-quick.sh"
    "test-retrospective-full.sh"
    "test-retrospective-reactivation.sh"
    "test-writing-supercycle-skills.sh"
    "test-predictive-shield.sh"
    "test-bootstrap.sh"
    "test-community-sharing.sh"
    "test-playbook-index.sh"
)

for test in "${TESTS[@]}"; do
    test_path="$SCRIPT_DIR/$test"
    if [ ! -f "$test_path" ]; then
        echo "[SKIP] $test — file not found"
        continue
    fi

    chmod +x "$test_path"
    echo "Running: $test"
    echo "----------------------------------------"

    if bash "$test_path"; then
        PASS=$((PASS + 1))
        echo "----------------------------------------"
        echo "[PASS] $test"
    else
        FAIL=$((FAIL + 1))
        echo "----------------------------------------"
        echo "[FAIL] $test"
    fi
    echo ""
done

echo "========================================"
echo "  Results: $PASS passed, $FAIL failed"
echo "========================================"

if [ "$FAIL" -gt 0 ]; then
    exit 1
fi
exit 0
