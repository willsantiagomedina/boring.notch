#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."

mkdir -p build/artifacts
# Personal builds must not replace themselves with upstream releases.
/usr/libexec/PlistBuddy -c 'Add :BNDisableUpdates bool true' boringNotch/Info.plist
xcodebuild -version
xcodebuild build \
  -project boringNotch.xcodeproj \
  -scheme boringNotch \
  -configuration Release \
  -destination 'generic/platform=macOS' \
  -derivedDataPath build/DerivedData \
  -resultBundlePath build/Build.xcresult \
  CODE_SIGN_STYLE=Manual \
  CODE_SIGN_IDENTITY=- \
  DEVELOPMENT_TEAM= \
  'ARCHS=arm64 x86_64' \
  ONLY_ACTIVE_ARCH=NO \
  2>&1 | tee build/build.log

app='build/DerivedData/Build/Products/Release/Boring Notch.app'
test -d "$app"
codesign --verify --deep --strict --verbose=2 "$app"
lipo -verify_arch arm64 x86_64 "$app/Contents/MacOS/Boring Notch"
# Preserve bundle symlinks and executable permissions inside the artifact.
ditto -c -k --sequesterRsrc --keepParent "$app" build/artifacts/Boring-Notch.zip
shasum -a 256 build/artifacts/Boring-Notch.zip > build/artifacts/SHA256SUMS.txt
git rev-parse HEAD > build/artifacts/SOURCE_COMMIT.txt
