#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PACKAGE_SCRIPT="$ROOT_DIR/apps/cmd-ime-swift/scripts/package.sh"
RELEASE_WORKFLOW="$ROOT_DIR/.github/workflows/release.yml"

assert_contains() {
    local file="$1"
    local expected="$2"
    grep -Fq "$expected" "$file" || {
        echo "missing contract: $expected" >&2
        exit 1
    }
}

assert_not_contains() {
    local file="$1"
    local unexpected="$2"
    ! grep -Fq "$unexpected" "$file" || {
        echo "unexpected legacy contract: $unexpected" >&2
        exit 1
    }
}

assert_contains "$PACKAGE_SCRIPT" \
    'https://github.com/agiletec-inc/cmd-ime/releases/latest/download/appcast.xml'
assert_not_contains "$PACKAGE_SCRIPT" \
    'https://raw.githubusercontent.com/agiletec-inc/cmd-ime/appcast/appcast.xml'

# The cumulative input must come from a stable GitHub Release asset. Explicit
# exclusions keep draft/prerelease releases out of the public latest feed.
assert_contains "$RELEASE_WORKFLOW" \
    'gh release list --limit 100 --exclude-drafts --exclude-pre-releases'
assert_contains "$RELEASE_WORKFLOW" \
    "gh release download \"\$RELEASE_TAG\" --pattern appcast.xml"
assert_contains "$RELEASE_WORKFLOW" \
    'stable GitHub Releases exist, but none has a non-empty appcast.xml asset'

# An empty or malformed prior feed, and an empty generated feed, must never be
# moved into place. Re-running a version must retain the prior feed unchanged.
assert_contains "$RELEASE_WORKFLOW" \
    'prior appcast input is empty; refusing to overwrite the feed'
assert_contains "$RELEASE_WORKFLOW" \
    "generated appcast is empty or missing v\${VERSION}; refusing to overwrite the feed"
assert_contains "$RELEASE_WORKFLOW" \
    "appcast.xml already contains v\${VERSION}; keeping the prior feed byte-for-byte"

# Existing clients still consume the branch during migration; removal is
# tracked separately and the branch writer must remain until that issue closes.
assert_contains "$RELEASE_WORKFLOW" 'Publish appcast.xml to appcast branch'
assert_contains "$RELEASE_WORKFLOW" '#137'

echo "PASS: appcast release-asset contract"
