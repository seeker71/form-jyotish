#!/bin/sh
# Build the release binary and wrap it as a self-contained FormJyotish.app in this folder: the app, the
# kernel's fkwu runtime, the engine's compiled image and the ephemeris. BUILD overrides the build number,
# which is otherwise the count of commits.
set -e
cd "$(dirname "$0")"
kernel="${KERNEL:-../coherence-kernel}"
build="${BUILD:-$(git rev-list --count HEAD)}"
swift build -c release
# one run of each door brings its compiled image up to date with its sources
printf '2451545.0 28.6139 77.2090 mean lahiri 5.5\n' | "$kernel/fkwu" engine/chart-run.bml >/dev/null 2>&1
printf '2451545.0 30 mean lahiri\n' | "$kernel/fkwu" engine/transit-run.bml >/dev/null 2>&1
app=FormJyotish.app
rm -rf "$app"
mkdir -p "$app/Contents/MacOS" "$app/Contents/Resources/payload/engine" "$app/Contents/Resources/payload/data"
cp .build/release/FormJyotish "$app/Contents/MacOS/FormJyotish"
cp "$kernel/fkwu" "$app/Contents/Resources/payload/fkwu"
cp -p engine/chart-run.bml.fkb engine/transit-run.bml.fkb "$app/Contents/Resources/payload/engine/"
cp data/de440s.bsp "$app/Contents/Resources/payload/data/de440s.bsp"
cat > "$app/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleName</key><string>Form Jyotish</string>
  <key>CFBundleIdentifier</key><string>org.coherence.FormJyotish</string>
  <key>CFBundleExecutable</key><string>FormJyotish</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>0.$build</string>
  <key>CFBundleVersion</key><string>$build</string>
  <key>LSMinimumSystemVersion</key><string>14.0</string>
  <key>NSHighResolutionCapable</key><true/>
</dict>
</plist>
PLIST
# no Developer ID is at hand: the app is signed ad hoc, which lets it run here and lets macOS keep its
# permissions across updates, but a copy fetched through a browser must be allowed once in System Settings
codesign --force --sign - "$app/Contents/Resources/payload/fkwu"
codesign --force --sign - "$app"
echo "built $app (build $build)"
