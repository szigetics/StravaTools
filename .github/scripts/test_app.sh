#!/bin/bash

set -eo pipefail #Stop execution in case if any commands fail

xcodebuild -project StravaTools.xcodeproj \
-scheme StravaTools
-destination platform=iOS\ Simulator,OS=13.4.1,name=iPhone\ 11 \
test | xcpretty
