# Include helpers
include(${CMAKE_CURRENT_LIST_DIR}/helpers.cmake)

# process features
vcpkg_check_features(OUT_FEATURE_OPTIONS _unused PREFIX FEAT FEATURES
    "custom-log" CUSTOM_LOG
    "dbg-log"  DBG_LOG
)


# Path to the real source project (local folder with .vcxproj and src/)
set(SOURCE_PATH_ROOT [[C:\Users\Chili\Desktop\cpp\ipm-relay]])
set(SOURCE_PATH_IPM "${SOURCE_PATH_ROOT}\\IntelPresentMon")
set(SOURCE_PATH_COMMON_UTILITIES "${SOURCE_PATH_IPM}\\CommonUtilities")
set(SOURCE_PATH_VERSIONING "${SOURCE_PATH_IPM}\\Versioning")
set(SOURCE_PATH_LOADER "${SOURCE_PATH_IPM}\\PresentMonAPI2Loader")

# env for scripts to detect current build mode
set(ENV{PM_VCPKG_MODE} "1")

# remove rogue vcpkg installed dirs (portfile dev convenience)
if(EXISTS "${SOURCE_PATH_COMMON_UTILITIES}\\vcpkg_installed")
	message(STATUS "Removing rogue ${SOURCE_PATH_COMMON_UTILITIES}\\vcpkg_installed")
	file(REMOVE_RECURSE "${SOURCE_PATH_COMMON_UTILITIES}\\vcpkg_installed")
endif()
if(EXISTS "${SOURCE_PATH_LOADER}\\vcpkg_installed")
	message(STATUS "Removing rogue ${SOURCE_PATH_LOADER}\\vcpkg_installed")
	file(REMOVE_RECURSE "${SOURCE_PATH_LOADER}\\vcpkg_installed")
endif()


###### Build & Install CommonUtilities ######

# define extra preprocessor macros based on features
set(preproc_options "")
if(FEAT_DBG_LOG)
    list(APPEND preproc_options "PM_PORT_DEFINE_DBG_CHANNEL_GETTER_")
elseif(FEAT_CUSTOM_LOG)
    # custom-log: no defines so that no GetDefaultChannel implementation is defined
else()
    # default when neither dbg-log nor custom-log is enabled
    list(APPEND preproc_options "PM_PORT_DEFINE_NULL_CHANNEL_GETTER_")
endif()

set(preproc_options_joined "")
if(preproc_options)
    list(JOIN preproc_options ";" preproc_options_joined)
endif()

# Build (and optionally install) the MSBuild project
vcpkg_msbuild_install(
    SOURCE_PATH     "${SOURCE_PATH_COMMON_UTILITIES}"
    PROJECT_SUBPATH "CommonUtilities.vcxproj"
    # NO_INSTALL
    OPTIONS
		/p:vcPreDefs=PM_PORT_DEFINE_NULL_CHANNEL_GETTER_
        /p:CustomVcpkgProps=${SOURCE_PATH_ROOT}\\vcpkg.props
        /p:CustomCommonProps=${SOURCE_PATH_IPM}\\Common.props
        /p:CustomRuntimeControlProps=${SOURCE_PATH_IPM}\\RuntimeControl.props
        /p:vcSiblingIncludeDirectory=${SOURCE_PATH_ROOT}
        /p:vcInstalledIncludeDirectory=${CURRENT_INSTALLED_DIR}\\include
)

# Install all headers recursively from src/
file(COPY "${SOURCE_PATH_COMMON_UTILITIES}/"
     DESTINATION "${CURRENT_PACKAGES_DIR}/include/IntelPresentMon/CommonUtilities"
     FILES_MATCHING PATTERN "*.h"
     PATTERN "build" EXCLUDE
     PATTERN ".vs" EXCLUDE)
	 
# preserve build logs
pm_rename_logs("comu")

	 
###### Build & Install Versioning ######

# Build (and optionally install) the MSBuild project
vcpkg_msbuild_install(
    SOURCE_PATH     "${SOURCE_PATH_VERSIONING}"
    PROJECT_SUBPATH "Versioning.vcxproj"
    # NO_INSTALL
    OPTIONS
        /p:CustomVcpkgProps=${SOURCE_PATH_ROOT}\\vcpkg.props
        /p:CustomCommonProps=${SOURCE_PATH_IPM}\\Common.props
        /p:CustomRuntimeControlProps=${SOURCE_PATH_IPM}\\RuntimeControl.props
        /p:vcSiblingIncludeDirectory=${SOURCE_PATH_ROOT}
        /p:vcInstalledIncludeDirectory=${CURRENT_INSTALLED_DIR}\\include
)

# Install all headers recursively from src/
file(COPY "${SOURCE_PATH_VERSIONING}/"
     DESTINATION "${CURRENT_PACKAGES_DIR}/include/IntelPresentMon/Versioning"
     FILES_MATCHING PATTERN "*.h"
     PATTERN "build" EXCLUDE
     PATTERN ".vs" EXCLUDE)
	 
# preserve build logs
pm_rename_logs("ver")
	 
	 
###### Build & Install Loader ######
vcpkg_msbuild_install(
    SOURCE_PATH     "${SOURCE_PATH_LOADER}"
    PROJECT_SUBPATH "PresentMonAPI2Loader.vcxproj"
    # NO_INSTALL
	ADDITIONAL_LIBS CommonUtilities.lib Versioning.lib
    OPTIONS
        /p:CustomVcpkgProps=${SOURCE_PATH_ROOT}\\vcpkg.props
        /p:CustomCommonProps=${SOURCE_PATH_IPM}\\Common.props
        /p:CustomRuntimeControlProps=${SOURCE_PATH_IPM}\\RuntimeControl.props
        /p:vcSiblingIncludeDirectory=${SOURCE_PATH_ROOT}
        /p:vcInstalledIncludeDirectory=${CURRENT_INSTALLED_DIR}\\include
    OPTIONS_DEBUG
        /p:vcPortingLibdir=${CURRENT_PACKAGES_DIR}\\debug\\lib
    OPTIONS_RELEASE
        /p:vcPortingLibdir=${CURRENT_PACKAGES_DIR}\\lib
)

# Install all headers recursively from src/
file(COPY "${SOURCE_PATH_LOADER}/"
     DESTINATION "${CURRENT_PACKAGES_DIR}/include/IntelPresentMon/PresentMonAPI2Loader"
     FILES_MATCHING PATTERN "*.h"
     PATTERN "build" EXCLUDE
     PATTERN ".vs" EXCLUDE)
	 
# preserve build logs
pm_rename_logs("load")


# Install the API headers
file(COPY "${SOURCE_PATH_IPM}\\PresentMonAPI2\\PresentMonApi.h"
     DESTINATION "${CURRENT_PACKAGES_DIR}/include/IntelPresentMon/PresentMonAPI2")
file(COPY "${SOURCE_PATH_IPM}\\PresentMonAPI2\\PresentMonDiagnostics.h"
     DESTINATION "${CURRENT_PACKAGES_DIR}/include/IntelPresentMon/PresentMonAPI2")
	 
	 
# Prune empty folders after all installs
prune_empty_dirs("${CURRENT_PACKAGES_DIR}/include/IntelPresentMon")


vcpkg_install_copyright(FILE_LIST "${SOURCE_PATH_ROOT}/LICENSE.txt")



# cmake support
# Destination roots
set(_pkg_share "${CURRENT_PACKAGES_DIR}/share/${PORT}")
set(_pkg_vcpkg "${_pkg_share}/vcpkg")

file(MAKE_DIRECTORY "${_pkg_share}")
file(MAKE_DIRECTORY "${_pkg_vcpkg}")

# Install pre-authored CMake package files
file(INSTALL "${CMAKE_CURRENT_LIST_DIR}/cmake/presentmon-sdkConfig.cmake"
     DESTINATION "${_pkg_share}")
file(INSTALL "${CMAKE_CURRENT_LIST_DIR}/cmake/presentmon-sdkTargets.cmake"
     DESTINATION "${_pkg_share}")