#!/usr/bin/env bash
set -euo pipefail

# extract-mobile-changelog.sh — Extract changelog entries from mobile repo
#
# Reads .sync-state.json to find the last synced commit, then generates
# a draft changelog from mobile commits that touched the controller.
#
# Usage:
#   ./scripts/extract-mobile-changelog.sh [--mobile-path /path/to/metamask-mobile]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SYNC_STATE="$PROJECT_ROOT/.sync-state.json"

MOBILE_PATH=""

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --mobile-path)
      MOBILE_PATH="$2"
      shift 2
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

# Read mobile path from sync state if not provided
if [[ -z "$MOBILE_PATH" ]]; then
  MOBILE_PATH=$(python3 -c "import json; print(json.load(open('$SYNC_STATE')).get('mobileRepoPath') or '')" 2>/dev/null || true)
fi

if [[ -z "$MOBILE_PATH" || ! -d "$MOBILE_PATH" ]]; then
  echo "Error: Mobile repo path not found."
  echo "Provide --mobile-path or run sync first."
  exit 1
fi

# Read last synced commit
LAST_COMMIT=$(python3 -c "import json; print(json.load(open('$SYNC_STATE')).get('lastSyncedCommit') or '')" 2>/dev/null || true)

if [[ -z "$LAST_COMMIT" ]]; then
  echo "Warning: No previous sync commit found. Showing recent commits only."
  RANGE="HEAD~20..HEAD"
else
  RANGE="$LAST_COMMIT..HEAD"
fi

CONTROLLER_PATH="app/controllers/perps/"

echo "# Changelog Draft"
echo ""
echo "## [Unreleased]"
echo ""
echo "Commits affecting \`$CONTROLLER_PATH\` since last sync:"
echo ""

# Get commits that touched the controller directory
COMMITS=$(cd "$MOBILE_PATH" && git log --oneline --no-merges "$RANGE" -- "$CONTROLLER_PATH" 2>/dev/null || true)

if [[ -z "$COMMITS" ]]; then
  echo "(No new commits found affecting the controller since last sync)"
  exit 0
fi

# Categorize commits by conventional commit prefix
ADDED=""
FIXED=""
CHANGED=""
OTHER=""

while IFS= read -r line; do
  HASH=$(echo "$line" | awk '{print $1}')
  MSG=$(echo "$line" | cut -d' ' -f2-)

  if echo "$MSG" | grep -qiE '^feat[:(]'; then
    ADDED="${ADDED}\n- ${MSG} (${HASH})"
  elif echo "$MSG" | grep -qiE '^fix[:(]'; then
    FIXED="${FIXED}\n- ${MSG} (${HASH})"
  elif echo "$MSG" | grep -qiE '^(refactor|chore|perf|style|build)[:(]'; then
    CHANGED="${CHANGED}\n- ${MSG} (${HASH})"
  else
    OTHER="${OTHER}\n- ${MSG} (${HASH})"
  fi
done <<< "$COMMITS"

if [[ -n "$ADDED" ]]; then
  echo "### Added"
  echo -e "$ADDED"
  echo ""
fi

if [[ -n "$FIXED" ]]; then
  echo "### Fixed"
  echo -e "$FIXED"
  echo ""
fi

if [[ -n "$CHANGED" ]]; then
  echo "### Changed"
  echo -e "$CHANGED"
  echo ""
fi

if [[ -n "$OTHER" ]]; then
  echo "### Other"
  echo -e "$OTHER"
  echo ""
fi

echo "---"
echo "Review the above, edit as needed, and paste into CHANGELOG.md"
