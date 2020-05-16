#!/bin/bash

set -eo pipefail #Stop execution in case if any commands fail

xcodebuild -project StravaTools.xcodeproj \
-scheme StravaTools
-destination platform=iOS\ Simulator,OS=13.4.1,name=iPhone\ 11 \
CODE_SIGN_STYLE="Manual" \
CODE_SIGN_IDENTITY="" \
CODE_SIGNING_REQUIRED=NO \
CODE_SIGNING_ALLOWED=NO \
test | xcpretty
