#!/usr/bin/env bash

set -e
set -o pipefail

swift build
swift build -c release
swift test

if [[ "$TRAVIS_OS_NAME" == "osx" ]]; then
    swift package generate-xcodeproj
    xcodebuild -project $1.xcodeproj -scheme $1 -sdk macosx10.12 -destination arch=x86_64 -configuration Debug -enableCodeCoverage YES test | xcpretty
fi
