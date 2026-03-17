#!/usr/bin/env bash
# sync-superpowers.sh — Update Superpowers skills from upstream
#
# Reads SUPERPOWERS_VERSION, downloads that tag from GitHub,
# replaces Superpowers skills in skills/, and reports changes.
#
# Usage:
#   ./scripts/sync-superpowers.sh              # sync pinned version
#   ./scripts/sync-superpowers.sh v4.2.0       # sync specific version (also updates pin)
#   ./scripts/sync-superpowers.sh --check      # check for new versions without syncing
#   ./scripts/sync-superpowers.sh --dry-run    # show what would change without writing

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
VERSION_FILE="$PROJECT_ROOT/SUPERPOWERS_VERSION"
MANIFEST_FILE="$PROJECT_ROOT/SUPERPOWERS_SKILLS.txt"
SKILLS_DIR="$PROJECT_ROOT/skills"
REPO_URL="https://github.com/obra/superpowers"

# SuperCycle-owned skills — NEVER overwritten
PROTECTED_SKILLS=(
    "retrospective"
    "using-supercycle"
    "writing-supercycle-skills"
)

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info()  { printf "${GREEN}[INFO]${NC} %s\n" "$1"; }
log_warn()  { printf "${YELLOW}[WARN]${NC} %s\n" "$1"; }
log_error() { printf "${RED}[ERROR]${NC} %s\n" "$1"; }

# Read current pinned version
current_version=$(cat "$VERSION_FILE" | tr -d '[:space:]')

# Parse args
DRY_RUN=false
CHECK_ONLY=false
TARGET_VERSION="$current_version"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --dry-run) DRY_RUN=true; shift ;;
        --check)   CHECK_ONLY=true; shift ;;
        v*)        TARGET_VERSION="$1"; shift ;;
        *)         log_error "Unknown argument: $1"; exit 1 ;;
    esac
done

# Check mode: query GitHub for latest release
if [ "$CHECK_ONLY" = true ]; then
    log_info "Current pinned version: $current_version"
    log_info "Checking GitHub for latest release..."

    latest=$(curl -s "https://api.github.com/repos/obra/superpowers/releases/latest" \
        | grep '"tag_name"' | head -1 | sed 's/.*"tag_name": "\(.*\)".*/\1/')

    if [ -z "$latest" ]; then
        log_error "Could not fetch latest release from GitHub"
        exit 1
    fi

    if [ "$latest" = "$current_version" ]; then
        log_info "Already up to date: $current_version"
    else
        log_warn "New version available: $latest (current: $current_version)"
        printf "  Run: ./scripts/sync-superpowers.sh %s\n" "$latest"
    fi
    exit 0
fi

log_info "Syncing Superpowers $TARGET_VERSION (current: $current_version)"

# Download the target version
TMPDIR=$(mktemp -d)
ARCHIVE_URL="$REPO_URL/archive/refs/tags/$TARGET_VERSION.tar.gz"

log_info "Downloading $ARCHIVE_URL..."
if ! curl -sL "$ARCHIVE_URL" -o "$TMPDIR/superpowers.tar.gz"; then
    log_error "Failed to download $TARGET_VERSION — does the tag exist?"
    rm -rf "$TMPDIR"
    exit 1
fi

# Extract
log_info "Extracting..."
tar -xzf "$TMPDIR/superpowers.tar.gz" -C "$TMPDIR"
EXTRACTED_DIR=$(find "$TMPDIR" -maxdepth 1 -type d -name "superpowers-*" | head -1)

if [ -z "$EXTRACTED_DIR" ] || [ ! -d "$EXTRACTED_DIR/skills" ]; then
    log_error "Extracted archive does not contain skills/ directory"
    rm -rf "$TMPDIR"
    exit 1
fi

# Read manifest
MANIFEST_SKILLS=()
while IFS= read -r line; do
    line=$(echo "$line" | sed 's/#.*//' | tr -d '[:space:]')
    [ -n "$line" ] && MANIFEST_SKILLS+=("$line")
done < "$MANIFEST_FILE"

# Detect changes
UPSTREAM_SKILLS=()
for dir in "$EXTRACTED_DIR/skills"/*/; do
    skill_name=$(basename "$dir")
    UPSTREAM_SKILLS+=("$skill_name")
done

# Find new skills (in upstream but not in manifest)
NEW_SKILLS=()
for skill in "${UPSTREAM_SKILLS[@]}"; do
    found=false
    for manifest_skill in "${MANIFEST_SKILLS[@]}"; do
        [ "$skill" = "$manifest_skill" ] && found=true && break
    done
    if [ "$found" = false ]; then
        # Check it's not a protected skill
        protected=false
        for p in "${PROTECTED_SKILLS[@]}"; do
            [ "$skill" = "$p" ] && protected=true && break
        done
        [ "$protected" = false ] && NEW_SKILLS+=("$skill")
    fi
done

# Find removed skills (in manifest but not in upstream)
REMOVED_SKILLS=()
for skill in "${MANIFEST_SKILLS[@]}"; do
    found=false
    for upstream_skill in "${UPSTREAM_SKILLS[@]}"; do
        [ "$skill" = "$upstream_skill" ] && found=true && break
    done
    [ "$found" = false ] && REMOVED_SKILLS+=("$skill")
done

# Find updated skills (in both, content differs)
UPDATED_SKILLS=()
UNCHANGED_SKILLS=()
for skill in "${MANIFEST_SKILLS[@]}"; do
    upstream_path="$EXTRACTED_DIR/skills/$skill"
    local_path="$SKILLS_DIR/$skill"

    if [ ! -d "$upstream_path" ]; then
        continue  # already in REMOVED_SKILLS
    fi

    if [ ! -d "$local_path" ]; then
        NEW_SKILLS+=("$skill")
        continue
    fi

    # Compare content (recursive diff)
    if diff -rq "$upstream_path" "$local_path" > /dev/null 2>&1; then
        UNCHANGED_SKILLS+=("$skill")
    else
        UPDATED_SKILLS+=("$skill")
    fi
done

# Report
echo ""
echo "========================================="
echo "  Superpowers Sync Report"
echo "  $current_version → $TARGET_VERSION"
echo "========================================="
echo ""
printf "  Updated:   %d skills\n" "${#UPDATED_SKILLS[@]}"
printf "  New:       %d skills\n" "${#NEW_SKILLS[@]}"
printf "  Removed:   %d skills\n" "${#REMOVED_SKILLS[@]}"
printf "  Unchanged: %d skills\n" "${#UNCHANGED_SKILLS[@]}"
echo ""

[ ${#UPDATED_SKILLS[@]} -gt 0 ] && printf "  Updated: %s\n" "${UPDATED_SKILLS[@]}"
[ ${#NEW_SKILLS[@]} -gt 0 ]     && printf "  New:     %s\n" "${NEW_SKILLS[@]}"
[ ${#REMOVED_SKILLS[@]} -gt 0 ] && printf "  Removed: %s\n" "${REMOVED_SKILLS[@]}"
echo ""

if [ "$DRY_RUN" = true ]; then
    log_info "Dry run — no files changed."
    rm -rf "$TMPDIR"
    exit 0
fi

# Apply changes
for skill in "${UPDATED_SKILLS[@]}"; do
    log_info "Updating: $skill"
    rm -rf "$SKILLS_DIR/$skill"
    cp -r "$EXTRACTED_DIR/skills/$skill" "$SKILLS_DIR/$skill"
done

for skill in "${NEW_SKILLS[@]}"; do
    log_info "Adding new: $skill"
    cp -r "$EXTRACTED_DIR/skills/$skill" "$SKILLS_DIR/$skill"
done

for skill in "${REMOVED_SKILLS[@]}"; do
    log_warn "Upstream removed: $skill — keeping local copy (remove manually if desired)"
done

# Update agents directory if it exists upstream
if [ -d "$EXTRACTED_DIR/agents" ]; then
    log_info "Updating agents/"
    rm -rf "$PROJECT_ROOT/agents"
    cp -r "$EXTRACTED_DIR/agents" "$PROJECT_ROOT/agents"
fi

# Update version pin
printf "%s\n" "$TARGET_VERSION" > "$VERSION_FILE"
log_info "Version pinned to $TARGET_VERSION"

# Update manifest
{
    echo "# Superpowers skills included in SuperCycle"
    echo "# One skill directory name per line"
    echo "# Updated automatically by sync-superpowers.sh on $(date +%Y-%m-%d)"
    for skill in "${UPSTREAM_SKILLS[@]}"; do
        # Skip protected skills
        protected=false
        for p in "${PROTECTED_SKILLS[@]}"; do
            [ "$skill" = "$p" ] && protected=true && break
        done
        [ "$protected" = false ] && echo "$skill"
    done
} > "$MANIFEST_FILE"

log_info "Manifest updated"

# Cleanup
rm -rf "$TMPDIR"

echo ""
echo "========================================="
echo "  Sync complete: $TARGET_VERSION"
echo "========================================="
echo ""
echo "Next steps:"
echo "  1. Review changes: git diff skills/"
echo "  2. Run tests: cd tests/claude-code && ./run-supercycle-tests.sh"
echo "  3. Commit: git add -A && git commit -m 'chore: sync superpowers $TARGET_VERSION'"
echo ""
