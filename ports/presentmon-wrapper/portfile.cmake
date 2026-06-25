# Include helpers
include(${CMAKE_CURRENT_LIST_DIR}/helpers.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/../presentmon-sdk/helpers.cmake)

# patching v2.4.1 to fix extraneous include of Log.h in wrapper (not required AND causes vcpkg build to fail)
vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH_ROOT
    REPO           GameTechDev/PresentMon
    REF            v2.5.1
    SHA512         630baf18681e5c7157c7dd315338a7ed8cccd43ae1c90fe169195936393287b6d771e10dddc8e95847fc27edd960357ebb63cf7b9f7016c7d5ca34ef75473205
)

# Path to the real source project (local folder with .vcxproj and src/)
###set(SOURCE_PATH_ROOT [[C:\Users\Chili\Desktop\cpp\ipm-relay]])
set(SOURCE_PATH_IPM "${SOURCE_PATH_ROOT}\\IntelPresentMon")
set(SOURCE_PATH_WRAPPER_COMMON "${SOURCE_PATH_IPM}\\PresentMonAPIWrapperCommon")
set(SOURCE_PATH_WRAPPER "${SOURCE_PATH_IPM}\\PresentMonAPIWrapper")
set(SOURCE_PATH_COMMON_UTILITIES "${SOURCE_PATH_IPM}\\CommonUtilities")

# env for scripts to detect current build mode
set(ENV{PM_VCPKG_MODE} "1")

pm_install_port_msbuild_overlays(
    "${SOURCE_PATH_IPM}"
    "${SOURCE_PATH_COMMON_UTILITIES}"
    "${CMAKE_CURRENT_LIST_DIR}/../presentmon-sdk/msbuild"
    OFF
)
pm_msbuild_port_common_options(_pm_msbuild_opts "${SOURCE_PATH_ROOT}" "${SOURCE_PATH_IPM}" OFF)

###### Build & Install WrapperCommon ######

# Build (and optionally install) the MSBuild project
vcpkg_msbuild_install(
    SOURCE_PATH     "${SOURCE_PATH_IPM}"
    PROJECT_SUBPATH "PresentMonAPIWrapperCommon\\PresentMonAPIWrapperCommon.vcxproj"
    # NO_INSTALL
    ADDITIONAL_LIBS IPMCommonUtilities.lib
    OPTIONS
        ${_pm_msbuild_opts}
    OPTIONS_DEBUG
        /p:vcPortingLibdir=${CURRENT_INSTALLED_DIR}\\debug\\lib
    OPTIONS_RELEASE
        /p:vcPortingLibdir=${CURRENT_INSTALLED_DIR}\\lib
)

# Install all headers recursively from src/
file(COPY "${SOURCE_PATH_WRAPPER_COMMON}/"
     DESTINATION "${CURRENT_PACKAGES_DIR}/include/IntelPresentMon/PresentMonAPIWrapperCommon"
     FILES_MATCHING PATTERN "*.h"
     PATTERN "build" EXCLUDE
     PATTERN ".vs" EXCLUDE)
	 
# preserve build logs
pm_rename_logs("wc")

	 
###### Build & Install Wrapper ######

# Build (and optionally install) the MSBuild project
vcpkg_msbuild_install(
    SOURCE_PATH     "${SOURCE_PATH_IPM}"
    PROJECT_SUBPATH "PresentMonAPIWrapper\\PresentMonAPIWrapper.vcxproj"
    # NO_INSTALL
    ADDITIONAL_LIBS IPMCommonUtilities.lib PresentMonAPIWrapperCommon.lib
    OPTIONS
        ${_pm_msbuild_opts}
)

# Install all headers recursively from src/
file(COPY "${SOURCE_PATH_WRAPPER}/"
     DESTINATION "${CURRENT_PACKAGES_DIR}/include/IntelPresentMon/PresentMonAPIWrapper"
     FILES_MATCHING PATTERN "*.h"
     PATTERN "build" EXCLUDE
     PATTERN ".vs" EXCLUDE)
	 
# preserve build logs
pm_rename_logs("wr")


# Install required sibling headers
file(COPY "${SOURCE_PATH_IPM}\\Interprocess\\source\\IntrospectionDataTypeMapping.h"
     DESTINATION "${CURRENT_PACKAGES_DIR}/include/IntelPresentMon/Interprocess/source")
file(COPY "${SOURCE_PATH_IPM}\\Interprocess\\source\\IntrospectionMacroHelpers.h"
     DESTINATION "${CURRENT_PACKAGES_DIR}/include/IntelPresentMon/Interprocess/source")
file(COPY "${SOURCE_PATH_IPM}\\Interprocess\\source\\metadata\\EnumStatus.h"
     DESTINATION "${CURRENT_PACKAGES_DIR}/include/IntelPresentMon/Interprocess/source/metadata")
file(COPY "${SOURCE_PATH_IPM}\\Interprocess\\source\\metadata\\EnumDataType.h"
     DESTINATION "${CURRENT_PACKAGES_DIR}/include/IntelPresentMon/Interprocess/source/metadata")
file(COPY "${SOURCE_PATH_IPM}\\Interprocess\\source\\metadata\\MasterEnumList.h"
     DESTINATION "${CURRENT_PACKAGES_DIR}/include/IntelPresentMon/Interprocess/source/metadata")
	 
	 
# Prune empty folders after all installs
prune_empty_dirs("${CURRENT_PACKAGES_DIR}/include/IntelPresentMon")

# copyright
vcpkg_install_copyright(FILE_LIST "${SOURCE_PATH_ROOT}/LICENSE.txt")


# cmake support
# Destination roots
set(_pkg_share "${CURRENT_PACKAGES_DIR}/share/${PORT}")

file(MAKE_DIRECTORY "${_pkg_share}")

# Install pre-authored CMake package files
file(INSTALL "${CMAKE_CURRENT_LIST_DIR}/cmake/presentmon-wrapperConfig.cmake"
     DESTINATION "${_pkg_share}")
file(INSTALL "${CMAKE_CURRENT_LIST_DIR}/cmake/presentmon-wrapperTargets.cmake"
     DESTINATION "${_pkg_share}")