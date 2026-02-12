#!/usr/bin/env bash
set -euo pipefail

# sync-from-mobile.sh — Sync PerpsController source from MetaMask Mobile
#
# Usage:
#   ./scripts/sync-from-mobile.sh --mobile-path /path/to/metamask-mobile [--branch main]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SYNC_STATE="$PROJECT_ROOT/.sync-state.json"

MOBILE_PATH=""
BRANCH=""

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --mobile-path)
      MOBILE_PATH="$2"
      shift 2
      ;;
    --branch)
      BRANCH="$2"
      shift 2
      ;;
    *)
      echo "Unknown option: $1"
      echo "Usage: $0 --mobile-path /path/to/metamask-mobile [--branch main]"
      exit 1
      ;;
  esac
done

if [[ -z "$MOBILE_PATH" ]]; then
  echo "Error: --mobile-path is required"
  echo "Usage: $0 --mobile-path /path/to/metamask-mobile [--branch main]"
  exit 1
fi

CONTROLLER_SRC="$MOBILE_PATH/app/controllers/perps"

# Step 1: Validate mobile path
if [[ ! -d "$CONTROLLER_SRC" ]]; then
  echo "Error: Controller directory not found at $CONTROLLER_SRC"
  echo "Make sure --mobile-path points to the root of metamask-mobile"
  exit 1
fi

echo "==> Syncing from $CONTROLLER_SRC"

# Step 2: Optionally checkout branch
if [[ -n "$BRANCH" ]]; then
  echo "==> Checking out branch '$BRANCH' in mobile repo..."
  (cd "$MOBILE_PATH" && git checkout "$BRANCH")
fi

# Step 3: Get mobile commit hash before sync
MOBILE_COMMIT=$(cd "$MOBILE_PATH" && git rev-parse HEAD)
MOBILE_BRANCH=$(cd "$MOBILE_PATH" && git rev-parse --abbrev-ref HEAD)
echo "==> Mobile commit: $MOBILE_COMMIT (branch: $MOBILE_BRANCH)"

# Step 4: Wipe src/ (preserving project-specific files like global.d.ts)
echo "==> Cleaning src/..."
# Back up project-specific files that aren't synced from mobile
BACKUP_DIR=$(mktemp -d)
if [[ -f "$PROJECT_ROOT/src/global.d.ts" ]]; then
  cp "$PROJECT_ROOT/src/global.d.ts" "$BACKUP_DIR/"
fi
rm -rf "$PROJECT_ROOT/src"
mkdir -p "$PROJECT_ROOT/src"
# Restore project-specific files
if [[ -f "$BACKUP_DIR/global.d.ts" ]]; then
  cp "$BACKUP_DIR/global.d.ts" "$PROJECT_ROOT/src/"
fi
rm -rf "$BACKUP_DIR"

# Step 5: Copy controller code, excluding tests and mocks
echo "==> Copying controller code..."
rsync -a \
  --exclude='*.test.ts' \
  --exclude='__mocks__/' \
  --exclude='__tests__/' \
  --exclude='__fixtures__/' \
  --exclude='__snapshots__/' \
  "$CONTROLLER_SRC/" "$PROJECT_ROOT/src/"

# Step 6: Validate no mobile-specific imports
echo "==> Validating no mobile-specific imports..."
VIOLATIONS=$(grep -rn "from '\.\./\.\." "$PROJECT_ROOT/src/" --include="*.ts" 2>/dev/null || true)
if [[ -n "$VIOLATIONS" ]]; then
  echo "ERROR: Found imports reaching outside the controller directory!"
  echo "These mobile-specific imports must be fixed before syncing:"
  echo ""
  echo "$VIOLATIONS"
  echo ""
  echo "Fix these in the mobile repo first, then re-run sync."
  # Clean up the broken sync
  rm -rf "$PROJECT_ROOT/src"
  mkdir -p "$PROJECT_ROOT/src"
  exit 1
fi
echo "    No mobile-specific imports found."

# Step 7: Update .sync-state.json
echo "==> Updating .sync-state.json..."
SYNC_DATE=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
cat > "$SYNC_STATE" << EOF
{
  "lastSyncedCommit": "$MOBILE_COMMIT",
  "lastSyncedBranch": "$MOBILE_BRANCH",
  "lastSyncedDate": "$SYNC_DATE",
  "mobileRepoPath": "$MOBILE_PATH"
}
EOF

# Count synced files
FILE_COUNT=$(find "$PROJECT_ROOT/src" -name "*.ts" | wc -l | tr -d ' ')
echo ""
echo "==> Sync complete!"
echo "    Files synced: $FILE_COUNT"
echo "    From commit:  $MOBILE_COMMIT"
echo "    Branch:       $MOBILE_BRANCH"
echo "    Date:         $SYNC_DATE"
echo ""
echo "Next steps:"
echo "  1. yarn install  (if new dependencies)"
echo "  2. yarn build    (verify TypeScript compilation)"
echo "  3. yarn lint:eslint (verify ESLint passes)"
echo "  4. yarn sync:changelog (generate changelog draft)"
