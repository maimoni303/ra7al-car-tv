#!/bin/bash
# Build on any Mac (e.g. the iMac): generates the project, runs tests, outputs an unsigned IPA.
set -euo pipefail
cd "$(dirname "$0")"
command -v xcodegen >/dev/null || brew install xcodegen
xcodegen generate
xcodebuild test -project RA7ALCarTV.xcodeproj -scheme RA7ALCarTV \
  -destination 'platform=iOS Simulator,name=iPhone 16' CODE_SIGNING_ALLOWED=NO
xcodebuild build -project RA7ALCarTV.xcodeproj -scheme RA7ALCarTV -configuration Release \
  -sdk iphoneos -derivedDataPath build CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO CODE_SIGN_IDENTITY=""
rm -rf Payload && mkdir Payload
cp -R build/Build/Products/Release-iphoneos/RA7ALCarTV.app Payload/
zip -qry RA7AL-CarTV-unsigned.ipa Payload
echo "Done: $(pwd)/RA7AL-CarTV-unsigned.ipa"
