#!/bin/bash
# This script automatically sets the version and short version string of
# an Xcode project from the Git repository containing the project.
#
# To use this script in Xcode, add the script's path to a "Run Script" build
# phase for your application target.

set -o errexit
set -o nounset

# First, check for git in $PATH
hash git 2>/dev/null || { echo >&2 "Git required, not in path.  Aborting build number update script."; exit 0; }

# Run Script build phases that operate on product files of the target that
# defines them should use the value of this build setting [TARGET_BUILD_DIR].
INFO_PLIST="${TARGET_BUILD_DIR}/${INFOPLIST_PATH}"

# Build version (closest-tag-or-branch "-" commits-since-tag "-" short-hash dirty-flag)
# Bundle version starts with the total number of commits
BUILD_VERSION=$(git describe --tags --always --dirty=+)
BUNDLE_VERSION=$(git rev-list --count HEAD)

# Use the latest tag for short version (expected tag format "vn[.n[.n]]")
# or if there are no tags, we make up version 0.0.<commit count>
LATEST_TAG=$(git describe --tags --match 'v*' --abbrev=0 2>/dev/null) || LATEST_TAG="HEAD"
if [ $LATEST_TAG = "HEAD" ]; then
    SHORT_VERSION="0.0.$BUNDLE_VERSION"
else
    COMMIT_COUNT_SINCE_TAG=$(git rev-list --count ${LATEST_TAG}..HEAD)
    if [ $COMMIT_COUNT_SINCE_TAG -eq 0 ]; then
        SHORT_VERSION=${LATEST_TAG##v}
    else
        SHORT_VERSION=${LATEST_TAG##v}.${COMMIT_COUNT_SINCE_TAG}
    fi
fi

# Append a ".1" to the bundle version if the working dir is dirty
if [ -n "$(git status --porcelain)" ]; then
    BUNDLE_VERSION="${BUNDLE_VERSION}.1"
fi

# For debugging:
echo "BUILD VERSION: $BUILD_VERSION"
echo "LATEST_TAG: $LATEST_TAG"
echo "SHORT VERSION: $SHORT_VERSION"
echo "BUNDLE_VERSION: $BUNDLE_VERSION"

/usr/libexec/PlistBuddy -c "Add :CFBundleBuildVersion string $BUILD_VERSION" "$INFO_PLIST" 2>/dev/null || /usr/libexec/PlistBuddy -c "Set :CFBundleBuildVersion $BUILD_VERSION" "$INFO_PLIST"
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $SHORT_VERSION" "$INFO_PLIST"
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $BUNDLE_VERSION" "$INFO_PLIST"
