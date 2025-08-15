# Compute the package prefix (triplet install root for this port)
get_filename_component(_IMPORT_PREFIX "${CMAKE_CURRENT_LIST_DIR}/../.." ABSOLUTE)

# run dependency targets
include(CMakeFindDependencyMacro)
find_dependency(presentmon-sdk CONFIG)  # make sure the sdk package/targets are loaded first

# Load our targets
include("${CMAKE_CURRENT_LIST_DIR}/presentmon-wrapperTargets.cmake")