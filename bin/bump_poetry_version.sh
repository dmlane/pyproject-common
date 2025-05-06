#!/bin/bash
set -euo pipefail

###############################################################################
# bump_poetry_version.sh
#
# Safely bumps the version in pyproject.toml using `poetry version`.
# - Resets BUILD to 1 if the month has changed (YYYY.MM.1)
# - Otherwise increments BUILD (YYYY.MM.n+1)
# - Uses Git to commit and tag the new version
# - Reverts the change if git push fails
#
# USAGE:
#   ./bump_poetry_version.sh          # Run safely (fails if uncommitted changes)
#   ./bump_poetry_version.sh --force # Force run even with uncommitted changes
###############################################################################

set -xv
FORCE=false

if [[ "${1:-}" == "--force" ]]; then
  FORCE=true
fi

# Ensure poetry is installed
if ! command -v poetry &> /dev/null; then
  echo "❌ poetry is not installed. Please install it first."
  exit 1
fi

# Check git is clean
if [[ "$FORCE" == false ]]; then
  if [[ -n $(git status --porcelain) ]]; then
    echo "❌ Git working directory is not clean. Use --force to override."
    git status
    exit 1
  fi
else
  echo "⚠️ Skipping Git clean check (forced)"
fi

# Capture current version
CURRENT_VERSION=$(poetry version -s)
IFS='.' read -r CUR_YEAR CUR_MONTH CUR_BUILD <<< "$CURRENT_VERSION"

NOW_YEAR=$(date +%Y)
NOW_MONTH=$(date +%-m)

if [[ "$CUR_YEAR" -ne "$NOW_YEAR" || "$CUR_MONTH" -ne "$NOW_MONTH" ]]; then
  NEW_VERSION="$NOW_YEAR.$NOW_MONTH.1"
else
  NEW_BUILD=$((CUR_BUILD + 1))
  NEW_VERSION="$CUR_YEAR.$CUR_MONTH.$NEW_BUILD"
fi

echo "🔄 Bumping version: $CURRENT_VERSION → $NEW_VERSION"

# Update version
poetry version "$NEW_VERSION"

# Commit and tag
git add pyproject.toml
git commit -m "Bump version to $NEW_VERSION"
git tag "$NEW_VERSION"

# Try pushing changes
if ! git push && git push origin "$NEW_VERSION"; then
  echo "❌ Git push failed — reverting version..."

  # Revert pyproject.toml version
  poetry version "$CURRENT_VERSION"

  # Reset git state
  git reset --hard HEAD~1
  git tag -d "$NEW_VERSION"

  echo "✅ Reverted to version $CURRENT_VERSION. Exiting with failure."
  exit 1
fi

echo "✅ Version bumped and pushed: $NEW_VERSION"

