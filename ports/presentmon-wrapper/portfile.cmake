# Include helpers
include(${CMAKE_CURRENT_LIST_DIR}/helpers.cmake)

vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH_ROOT
    REPO           GameTechDev/PresentMon
    REF            exp-vport-temp-2
    SHA512         2f6b5607f3f2be62cb3fd669e0439da9b5e0e568031f456dc753808e5b1246b3aed96da75329bfbeef524e8e780f2a94aba18e19cc3f980178e1c617d6857dcd
)

# Path to the real source project (local folder with .vcxproj and src/)
###set(SOURCE_PATH_ROOT [[C:\Users\Chili\Desktop\cpp\ipm-relay]])
set(SOURCE_PATH_IPM "${SOURCE_PATH_ROOT}\\IntelPresentMon")
set(SOURCE_PATH_WRAPPER_COMMON "${SOURCE_PATH_IPM}\\PresentMonAPIWrapperCommon")
set(SOURCE_PATH_WRAPPER "${SOURCE_PATH_IPM}\\PresentMonAPIWrapper")

# env for scripts to detect current build mode
set(ENV{PM_VCPKG_MODE} "1")

###### Build & Install WrapperCommon ######

# Build (and optionally install) the MSBuild project
vcpkg_msbuild_install(
    SOURCE_PATH     "${SOURCE_PATH_WRAPPER_COMMON}"
    PROJECT_SUBPATH "PresentMonAPIWrapperCommon.vcxproj"
    # NO_INSTALL
    OPTIONS
        /p:CustomCommonProps=${SOURCE_PATH_IPM}\\Common.props
        /p:CustomRuntimeControlProps=${SOURCE_PATH_IPM}\\RuntimeControl.props
        /p:vcSiblingIncludeDirectory=${SOURCE_PATH_ROOT}
        /p:vcInstalledIncludeDirectory=${CURRENT_INSTALLED_DIR}\\include
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
    SOURCE_PATH     "${SOURCE_PATH_WRAPPER}"
    PROJECT_SUBPATH "PresentMonAPIWrapper.vcxproj"
    # NO_INSTALL
    OPTIONS
        /p:CustomCommonProps=${SOURCE_PATH_IPM}\\Common.props
        /p:CustomRuntimeControlProps=${SOURCE_PATH_IPM}\\RuntimeControl.props
        /p:vcSiblingIncludeDirectory=${SOURCE_PATH_ROOT}
        /p:vcInstalledIncludeDirectory=${CURRENT_INSTALLED_DIR}\\include
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