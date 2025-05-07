#!/usr/bin/env bash
set -euo pipefail

###############################################################################
# bump_poetry_version.sh
#
# Safely bumps the version in pyproject.toml using `poetry version`.
#
# - Version format: YYYY.MM.BUILD (PEP 440 compliant)
# - Resets BUILD to 1 if the month has changed
# - Otherwise increments BUILD
# - Commits the change and creates an annotated Git tag
# - Pushes both commit and tag to the remote
# - Reverts everything if git tag or git push fails
#
# USAGE:
#   ./bump_poetry_version.sh          # Runs safely (aborts if working tree is dirty)
#   ./bump_poetry_version.sh --force # Skips working tree clean check
###############################################################################

current_branch=$(git rev-parse --abbrev-ref HEAD)

if [[ "$current_branch" != "main" ]]; then
  echo "Error: You must be on the 'main' branch to bump the version. Current branch: $current_branch"
  exit 1
fi

FORCE=false

if [[ "${1:-}" == "--force" ]]; then
  FORCE=true
fi

# Ensure poetry is installed
if ! command -v poetry &> /dev/null; then
  echo "❌ poetry is not installed. Please install it first."
  exit 1
fi

# Make sure poetry.lock is up to date
poetry lock --quiet

# Ensure git is clean unless --force
if [[ "$FORCE" == false ]]; then
  if [[ -n $(git status --porcelain) ]]; then
    echo "❌ Git working directory is not clean. Use --force to override."
    git status
    exit 1
  fi
else
  echo "⚠️ Skipping Git clean check (forced)"
fi

# Read current version
CURRENT_VERSION=$(poetry version -s)
IFS='.' read -r CUR_YEAR CUR_MONTH CUR_BUILD <<< "$CURRENT_VERSION"

# Get current date
NOW_YEAR=$(date +%Y)
NOW_MONTH=$(date +%-m)

# Calculate new version
if [[ "$CUR_YEAR" -ne "$NOW_YEAR" || "$CUR_MONTH" -ne "$NOW_MONTH" ]]; then
  NEW_VERSION="$NOW_YEAR.$NOW_MONTH.1"
else
  NEW_BUILD=$((CUR_BUILD + 1))
  NEW_VERSION="$CUR_YEAR.$CUR_MONTH.$NEW_BUILD"
fi

echo "🔄 Bumping version: $CURRENT_VERSION → $NEW_VERSION"

# Update version in pyproject.toml
poetry version "$NEW_VERSION"

# Commit change
git add pyproject.toml
git commit -m "Bump version to $NEW_VERSION"

# Create annotated tag
if ! git tag -a "$NEW_VERSION" -m "New release $NEW_VERSION"; then
  echo "❌ git tag failed — reverting version bump..."
  poetry version "$CURRENT_VERSION"
  git reset --hard HEAD~1
  echo "✅ Reverted to version $CURRENT_VERSION"
  exit 1
fi

# Push commit and tag
exit 0
if ! ( git push && git push origin "$NEW_VERSION" ); then
  echo "❌ git push failed — reverting version bump..."
  poetry version "$CURRENT_VERSION"
  git reset --hard HEAD~1
  git tag -d "$NEW_VERSION"
  echo "✅ Reverted to version $CURRENT_VERSION"
  exit 1
fi

echo "✅ Version bumped, committed, tagged, and pushed: $NEW_VERSION"

