#!/usr/bin/env bash
set -euo pipefail

READABILITY_VERSION="0.5.0"
BUNDLE_OUTPUT="assets/readability-bundle.js"
URL="https://unpkg.com/@mozilla/readability@${READABILITY_VERSION}/Readability.js"
READERABLE_URL="https://unpkg.com/@mozilla/readability@${READABILITY_VERSION}/Readability-readerable.js"

cd "$(dirname "$0")/.."

mkdir -p assets

echo "Downloading Readability.js v${READABILITY_VERSION}..."
curl -fL --progress-bar -o /tmp/readability.js "$URL"

echo "Downloading Readability-readerable.js v${READABILITY_VERSION}..."
curl -fL --progress-bar -o /tmp/readability-readerable.js "$READERABLE_URL"

cat /tmp/readability-readerable.js /tmp/readability.js > "$BUNDLE_OUTPUT"
rm /tmp/readability.js /tmp/readability-readerable.js

sed -i '' '/if (typeof module === "object") {/{N;N;N;d;}' "$BUNDLE_OUTPUT"

echo "Saved combined bundle to ${BUNDLE_OUTPUT}"
