#!/usr/bin/env bash
set -euo pipefail

BUILD_DIR="${1:-build}"
PLUGIN_NAME="dir-watch-media"
TARGET_PLUGIN_ROOT="${HOME}/Library/Application Support/obs-studio/plugins"
TARGET_BUNDLE_DIR="${TARGET_PLUGIN_ROOT}/${PLUGIN_NAME}.plugin"
TARGET_MACOS_DIR="${TARGET_BUNDLE_DIR}/Contents/MacOS"
TARGET_RESOURCES_DIR="${TARGET_BUNDLE_DIR}/Contents/Resources"
TARGET_INFO_PLIST="${TARGET_BUNDLE_DIR}/Contents/Info.plist"

mkdir -p "${TARGET_MACOS_DIR}"
mkdir -p "${TARGET_RESOURCES_DIR}"

ARTIFACT=""
if [ -f "${BUILD_DIR}/${PLUGIN_NAME}.so" ]; then
  ARTIFACT="${BUILD_DIR}/${PLUGIN_NAME}.so"
elif [ -f "${BUILD_DIR}/${PLUGIN_NAME}.dylib" ]; then
  ARTIFACT="${BUILD_DIR}/${PLUGIN_NAME}.dylib"
fi

if [ -z "${ARTIFACT}" ]; then
  echo "Built plugin artifact not found in ${BUILD_DIR}."
  echo "Expected ${PLUGIN_NAME}.so or ${PLUGIN_NAME}.dylib"
  exit 1
fi

cp "${ARTIFACT}" "${TARGET_MACOS_DIR}/${PLUGIN_NAME}"
chmod +x "${TARGET_MACOS_DIR}/${PLUGIN_NAME}"
codesign --force --sign - "${TARGET_MACOS_DIR}/${PLUGIN_NAME}"

# Install locale data
if [ -d "data/locale" ]; then
  mkdir -p "${TARGET_RESOURCES_DIR}/locale"
  cp data/locale/*.ini "${TARGET_RESOURCES_DIR}/locale/"
fi

# Read version from CMakeLists.txt
VERSION=$(grep 'project(dir-watch-media VERSION' CMakeLists.txt | sed 's/.*VERSION \([0-9.]*\)).*/\1/')

cat > "${TARGET_INFO_PLIST}" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleExecutable</key>
  <string>${PLUGIN_NAME}</string>
  <key>CFBundleIdentifier</key>
  <string>com.exeldro.${PLUGIN_NAME}</string>
  <key>CFBundleInfoDictionaryVersion</key>
  <string>6.0</string>
  <key>CFBundleName</key>
  <string>${PLUGIN_NAME}</string>
  <key>CFBundlePackageType</key>
  <string>BNDL</string>
  <key>CFBundleShortVersionString</key>
  <string>${VERSION}</string>
  <key>CFBundleSupportedPlatforms</key>
  <array>
    <string>MacOSX</string>
  </array>
  <key>CFBundleVersion</key>
  <string>${VERSION}</string>
  <key>LSMinimumSystemVersion</key>
  <string>11.0</string>
</dict>
</plist>
EOF

echo "Installed ${ARTIFACT} -> ${TARGET_MACOS_DIR}/${PLUGIN_NAME}"
echo "Bundle: ${TARGET_BUNDLE_DIR}"
