#!/bin/sh

BUILD_TYPE="Release"

if [ ! -z "$1" ]; then
BUILD_TYPE=$1
fi

if [ ! -d "build/" ]; then
  mkdir build
  touch build/buildWayfinding.log
fi

xcodebuild -workspace ./Example/SitumWayfinding.xcworkspace \
-configuration $BUILD_TYPE \
-derivedDataPath "build/derivedData" \
-scheme SitumWayfinding-Example clean build 2>&1 | tee ./build/buildWayfinding.log

# Change dir if debug release
if [ "$BUILD_TYPE" == "Release" ]; then
cd "build/derivedData/Build/Products/Release-iphoneuniversal"
else
cd "build/derivedData/Build/Products/Debug-iphoneuniversal"
fi