# Compute the package prefix (triplet install root for this port)
get_filename_component(_IMPORT_PREFIX "${CMAKE_CURRENT_LIST_DIR}/../.." ABSOLUTE)

# Load our targets
include("${CMAKE_CURRENT_LIST_DIR}/presentmon-sdkTargets.cmake")