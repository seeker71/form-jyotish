#!/bin/sh
# Build the release binary and wrap it as a self-contained FormJyotish.app in this folder, for Apple Silicon
# and Intel Macs alike: the app as one universal binary, and for each processor the kernel's fkwu runtime with
# the engine images that runtime compiled (an image runs only under the build that wrote it), and the ephemeris.
# The Intel runtime is compiled from the kernel's one C file and run here through Rosetta to write its images. BUILD overrides the build number,
# which is otherwise the count of commits.
set -e
cd "$(dirname "$0")"
kernel="${KERNEL:-../coherence-kernel}"
build="${BUILD:-$(git rev-list --count HEAD)}"
swift build -c release --arch arm64 --arch x86_64
# one run of each door brings its compiled image up to date with its sources
app=FormJyotish.app
rm -rf "$app"
payload="$app/Contents/Resources/payload"
mkdir -p "$app/Contents/MacOS" "$payload/data"
cp .build/apple/Products/Release/FormJyotish "$app/Contents/MacOS/FormJyotish"
mkdir -p .build/intel
if [ ! -x .build/intel/fkwu ] || [ "$kernel/runtime/fkwu-uni.c" -nt .build/intel/fkwu ] || [ tools/intel-seed.swift -nt .build/intel/fkwu ]; then
  swift tools/intel-seed.swift "$kernel/runtime/fkwu-uni.c" .build/intel/fkwu-uni.c
  cc -O2 -arch x86_64 -mmacosx-version-min=11.0 -I "$kernel/runtime" -o .build/intel/fkwu .build/intel/fkwu-uni.c 2>/dev/null
  # signed before it writes an image: an image is bound to the bytes of the runtime that wrote it
  codesign --force --sign - .build/intel/fkwu
fi
# Intel first, Apple Silicon last, so the images left beside the sources are this Mac's own
for arch in x86_64 arm64; do
  if [ "$arch" = arm64 ]; then runtime="$kernel/fkwu"; else runtime=.build/intel/fkwu; fi
  printf '2451545.0 28.6139 77.2090 mean lahiri 5.5\n' | arch "-$arch" "$runtime" engine/chart-run.bml 2>/dev/null | grep -q '"grahas"' || { echo "the $arch runtime gave no chart"; exit 1; }
  printf '2451545.0 30 mean lahiri\n' | arch "-$arch" "$runtime" engine/transit-run.bml 2>/dev/null | grep -q '"events"' || { echo "the $arch runtime gave no transits"; exit 1; }
  mkdir -p "$payload/$arch/engine"
  cp "$runtime" "$payload/$arch/fkwu"
  cp -p engine/chart-run.bml.fkb engine/transit-run.bml.fkb "$payload/$arch/engine/"
  codesign --force --sign - "$payload/$arch/fkwu"
  # the carried image must run under the carried runtime, from a folder that holds nothing else
  probe=".build/probe-$arch"; rm -rf "$probe"; mkdir -p "$probe"; cp -R "$payload/$arch/engine" "$probe/engine"; ln -s "$PWD/data" "$probe/data"
  (cd "$probe" && printf '2451545.0 28.6139 77.2090 mean lahiri 5.5\n' | arch "-$arch" "../../$payload/$arch/fkwu" engine/chart-run.bml.fkb 2>/dev/null | grep -q '"grahas"') || { echo "the $arch image does not run from the payload"; exit 1; }
done
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
  <key>LSMinimumSystemVersion</key><string>13.0</string>
  <key>NSHighResolutionCapable</key><true/>
</dict>
</plist>
PLIST
# no Developer ID is at hand: the app is signed ad hoc, which lets it run here and lets macOS keep its
# permissions across updates, but a copy fetched through a browser must be allowed once in System Settings
codesign --force --sign - "$app"
echo "built $app (build $build): $(lipo -archs "$app/Contents/MacOS/FormJyotish")"
