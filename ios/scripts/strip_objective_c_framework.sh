#!/bin/sh
# Removes stale Flutter native-assets objective_c.framework.
# That binary is often tagged IOSSIMULATOR and App Store Connect rejects it.
# Safe with path_provider_foundation 2.5.1 (plugin impl, does not need this FFI framework).

set -e

FW_PATHS="
${TARGET_BUILD_DIR}/${WRAPPER_NAME}/Frameworks/objective_c.framework
${TARGET_BUILD_DIR}/${FRAMEWORKS_FOLDER_PATH}/objective_c.framework
${BUILT_PRODUCTS_DIR}/${WRAPPER_NAME}/Frameworks/objective_c.framework
"

for FW in $FW_PATHS; do
  if [ -d "$FW" ]; then
    echo "warning: Removing objective_c.framework (App Store simulator platform fix): $FW"
    rm -rf "$FW"
  fi
done

# Clear cached native-assets copies so the next embed does not bring them back.
if [ -n "$SRCROOT" ]; then
  CACHE_DIRS="
  ${SRCROOT}/../build/native_assets/ios/objective_c.framework
  ${SRCROOT}/../.dart_tool/hooks_runner/shared/objective_c
  "
  for DIR in $CACHE_DIRS; do
    if [ -e "$DIR" ]; then
      echo "warning: Clearing objective_c native-assets cache: $DIR"
      rm -rf "$DIR"
    fi
  done
fi

exit 0
