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
-scheme SitumWayfinding-Example \
-allowProvisioningUpdates clean build 2>&1 | tee ./build/buildWayfinding.log
#  \ PROVISIONING_PROFILE_SPECIFIER='$(APPLE_PROV_PROFILE_UUID)' CODE_SIGN_IDENTITY='$(APPLE_CERTIFICATE_SIGNING_IDENTITY)'

# Change dir if debug release
if [ "$BUILD_TYPE" == "Release" ]; then
	cd "build/derivedData/Build/Products/Release-iphoneos"
else
	cd "build/derivedData/Build/Products/Debug-iphoneos"
fi

#If example app isnt generated throw error
if [ ! -d "SitumWayfinding_Example.app" ]; then
    echo "App not found"
    exit 1
fi
