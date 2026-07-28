#!/usr/bin/env bash
set -euo pipefail

TAG="${1:-${GITHUB_REF_NAME:-}}"

if [[ -z "$TAG" ]]; then
  echo "Error: version tag is required."
  echo "Usage: $0 v1.0.8-rc.2"
  exit 1
fi

MAJOR=""
MINOR=""
PATCH=""
SEQUENCE=""
APP_VERSION=""
RELEASE_TYPE=""

if [[ "$TAG" =~ ^v([0-9]+)\.([0-9]+)\.([0-9]+)-rc\.([0-9]+)$ ]]; then
  MAJOR="${BASH_REMATCH[1]}"
  MINOR="${BASH_REMATCH[2]}"
  PATCH="${BASH_REMATCH[3]}"
  SEQUENCE="${BASH_REMATCH[4]}"

  APP_VERSION="${MAJOR}.${MINOR}.${PATCH}"
  RELEASE_TYPE="rc"

  if (( SEQUENCE < 1 || SEQUENCE > 98 )); then
    echo "Error: RC number must be between 1 and 98."
    exit 1
  fi

elif [[ "$TAG" =~ ^v([0-9]+)\.([0-9]+)\.([0-9]+)$ ]]; then
  MAJOR="${BASH_REMATCH[1]}"
  MINOR="${BASH_REMATCH[2]}"
  PATCH="${BASH_REMATCH[3]}"

  APP_VERSION="${MAJOR}.${MINOR}.${PATCH}"
  SEQUENCE=99
  RELEASE_TYPE="release"

else
  echo "Error: unsupported tag format: $TAG"
  echo "Expected:"
  echo "  v1.0.8-rc.2"
  echo "  v1.0.8"
  exit 1
fi

if (( MINOR > 99 )); then
  echo "Error: minor version must be between 0 and 99."
  exit 1
fi

if (( PATCH > 99 )); then
  echo "Error: patch version must be between 0 and 99."
  exit 1
fi

BUILD_NUMBER=$(( 10#$MAJOR * 1000000 + 10#$MINOR * 10000 + 10#$PATCH * 100 + 10#$SEQUENCE ))

ANDROID_MAX_VERSION_CODE=2100000000

if (( BUILD_NUMBER > ANDROID_MAX_VERSION_CODE )); then
  echo "Error: versionCode exceeds Android limit."
  echo "Calculated: $BUILD_NUMBER"
  exit 1
fi

echo "Tag:          $TAG"
echo "App version:  $APP_VERSION"
echo "Release type: $RELEASE_TYPE"
echo "Build number: $BUILD_NUMBER"

if [[ -n "${GITHUB_ENV:-}" ]]; then
  {
    echo "APP_VERSION=$APP_VERSION"
    echo "BUILD_NUMBER=$BUILD_NUMBER"
    echo "RELEASE_TYPE=$RELEASE_TYPE"
  } >> "$GITHUB_ENV"
fi