#!/bin/bash
# Test script to validate workflow logic locally
# This tests the bash script parts of the workflows without needing GitHub API

set -e

echo "=========================================="
echo "Testing GitHub Actions Workflow Logic"
echo "=========================================="
echo ""

# Test 1: Check for breaking/feat commits logic
echo "Test 1: Check for breaking/feat commits"
echo "----------------------------------------"

# Create a test git repo
TEST_DIR=$(mktemp -d)
cd "$TEST_DIR"
git init
git config user.name "Test User"
git config user.email "test@example.com"

# Create some test commits
echo "test" > file1.txt
git add file1.txt
git commit -m "fix: test fix commit"

echo "test2" > file2.txt
git add file2.txt
git commit -m "feat: test feature commit"

echo "test3" > file3.txt
git add file3.txt
git commit -m "docs: test docs commit"

# Test the commit checking logic
LAST_TAG=$(git describe --tags --abbrev=0 2>/dev/null || echo "")
if [ -z "$LAST_TAG" ]; then
  COMMITS=$(git log --oneline)
else
  COMMITS=$(git log ${LAST_TAG}..HEAD --oneline)
fi

HAS_BREAKING=false
HAS_FEAT=false

while IFS= read -r commit; do
  MSG=$(echo "$commit" | cut -d' ' -f2-)
  if echo "$MSG" | grep -qiE "BREAKING CHANGE|!:"; then
    HAS_BREAKING=true
  elif echo "$MSG" | grep -qiE "^feat"; then
    HAS_FEAT=true
  fi
done <<< "$COMMITS"

if [ "$HAS_BREAKING" = true ] || [ "$HAS_FEAT" = true ]; then
  echo "✓ Found feat commit, should skip auto-release"
else
  echo "✗ Should have found feat commit"
  exit 1
fi

# Cleanup
cd - > /dev/null
rm -rf "$TEST_DIR"

echo ""
echo "Test 2: Version increment logic"
echo "--------------------------------"

# Test version increment
CURRENT_VERSION="1.0.0"
IFS='.' read -r MAJOR MINOR PATCH <<< "$CURRENT_VERSION"
PATCH=$((PATCH + 1))
NEW_VERSION="${MAJOR}.${MINOR}.${PATCH}"

if [ "$NEW_VERSION" = "1.0.1" ]; then
  echo "✓ Patch version increment: $CURRENT_VERSION -> $NEW_VERSION"
else
  echo "✗ Expected 1.0.1, got $NEW_VERSION"
  exit 1
fi

# Test feature version increment
CURRENT_VERSION="1.0.1"
IFS='.' read -r MAJOR MINOR PATCH <<< "$CURRENT_VERSION"
MINOR=$((MINOR + 1))
PATCH=0
NEW_VERSION="${MAJOR}.${MINOR}.${PATCH}"

if [ "$NEW_VERSION" = "1.1.0" ]; then
  echo "✓ Feature version increment: $CURRENT_VERSION -> $NEW_VERSION"
else
  echo "✗ Expected 1.1.0, got $NEW_VERSION"
  exit 1
fi

# Test breaking version increment
CURRENT_VERSION="1.1.0"
IFS='.' read -r MAJOR MINOR PATCH <<< "$CURRENT_VERSION"
MAJOR=$((MAJOR + 1))
MINOR=0
PATCH=0
NEW_VERSION="${MAJOR}.${MINOR}.${PATCH}"

if [ "$NEW_VERSION" = "2.0.0" ]; then
  echo "✓ Breaking version increment: $CURRENT_VERSION -> $NEW_VERSION"
else
  echo "✗ Expected 2.0.0, got $NEW_VERSION"
  exit 1
fi

echo ""
echo "Test 3: startsWith function check"
echo "--------------------------------"

# Test startsWith logic (simulating GitHub Actions)
HEAD_COMMIT_MESSAGE="Merge pull request #1 from feature-branch"
if [[ "$HEAD_COMMIT_MESSAGE" == Merge* ]]; then
  echo "✓ startsWith check passed for merge commit"
else
  echo "✗ startsWith check failed"
  exit 1
fi

HEAD_COMMIT_MESSAGE="fix: some fix"
if [[ ! "$HEAD_COMMIT_MESSAGE" == Merge* ]]; then
  echo "✓ startsWith check passed for non-merge commit"
else
  echo "✗ startsWith check failed"
  exit 1
fi

echo ""
echo "=========================================="
echo "✓ All workflow logic tests passed!"
echo "=========================================="

