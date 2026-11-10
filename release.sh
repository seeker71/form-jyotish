#!/bin/sh
# Publish this commit as a release the app can update itself from: build the app, zip it, publish
# FormJyotish.zip with its SHA-256 under the tag build-N, N being the count of commits.
set -e
cd "$(dirname "$0")"
[ -z "$(git status --porcelain)" ] || { echo "commit first: the build number is the count of commits"; exit 1; }
build=$(git rev-list --count HEAD)
./make-app.sh
rm -f FormJyotish.zip FormJyotish.zip.sha256
ditto -c -k --keepParent FormJyotish.app FormJyotish.zip
shasum -a 256 FormJyotish.zip | cut -d' ' -f1 > FormJyotish.zip.sha256
git push origin main
gh release create "build-$build" FormJyotish.zip FormJyotish.zip.sha256 --title "Build $build" --notes "$(git log -1 --format=%s)"
echo "published build-$build"
