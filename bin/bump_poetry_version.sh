#!/bin/bash
set -euo pipefail

###############################################################################
# bump_poetry_version.sh
#
# Safely bumps the version in pyproject.toml using `poetry version`.
# - Resets BUILD to 1 if the month has changed (YYYY.MM.1)
# - Otherwise increments BUILD (YYYY.MM.n+1)
# - Uses Git to commit and tag the new version
#
# USAGE:
#   ./bump_poetry_version.sh          # Run safely (fails if uncommitted changes)
#   ./bump_poetry_version.sh --force # Force run even with uncommitted changes
#
# REQUIREMENTS:
# - `poetry` must be installed and available in PATH
# - Git working directory must be initialized
#
# OUTPUT:
# - Updates [tool.poetry].version in pyproject.toml
# - Creates Git commit and tag (e.g., "2025.5.1")
###############################################################################

FORCE=false

# Parse optional --force flag
if [[ "${1:-}" == "--force" ]]; then
  FORCE=true
fi

# Ensure poetry is installed
if ! command -v poetry &> /dev/null; then
  echo "❌ poetry is not installed. Please install it first."
  exit 1
fi

# Check that git working directory is clean
if [[ "$FORCE" == false ]]; then
  if [[ -n $(git status --porcelain) ]]; then
    echo "❌ Git working directory is not clean. Use --force to override."
    git status
    exit 1
  fi
else
  echo "⚠️ Skipping Git clean check (forced)"
fi

# Get current version from pyproject.toml
CURRENT_VERSION=$(poetry version -s)
IFS='.' read -r CUR_YEAR CUR_MONTH CUR_BUILD <<< "$CURRENT_VERSION"

# Get current date
NOW_YEAR=$(date +%Y)
NOW_MONTH=$(date +%-m)

# Determine next version
if [[ "$CUR_YEAR" -ne "$NOW_YEAR" || "$CUR_MONTH" -ne "$NOW_MONTH" ]]; then
  NEW_VERSION="$NOW_YEAR.$NOW_MONTH.1"
else
  NEW_BUILD=$((CUR_BUILD + 1))
  NEW_VERSION="$CUR_YEAR.$CUR_MONTH.$NEW_BUILD"
fi

echo "🔄 Bumping version: $CURRENT_VERSION → $NEW_VERSION"

# Update version using poetry
poetry version "$NEW_VERSION"

# Commit and tag
git add pyproject.toml
git commit -m "Bump version to $NEW_VERSION"
git tag "$NEW_VERSION"
git push && git push origin "$NEW_VERSION"

echo "✅ Version bumped and tagged as $NEW_VERSION"

