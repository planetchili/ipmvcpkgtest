# Compute triplet prefix
get_filename_component(_IMPORT_PREFIX "${CMAKE_CURRENT_LIST_DIR}/../.." ABSOLUTE)

# DLL target with both dll and import lib
add_library(presentmon-sdk::loader SHARED IMPORTED)
set_target_properties(presentmon-sdk::loader PROPERTIES
  IMPORTED_CONFIGURATIONS "Debug;Release"
  IMPORTED_LOCATION_DEBUG   "${_IMPORT_PREFIX}/debug/bin/PresentMonAPI2Loader.dll"
  IMPORTED_IMPLIB_DEBUG     "${_IMPORT_PREFIX}/debug/lib/PresentMonAPI2Loader.lib"
  IMPORTED_LOCATION_RELEASE "${_IMPORT_PREFIX}/bin/PresentMonAPI2Loader.dll"
  IMPORTED_IMPLIB_RELEASE   "${_IMPORT_PREFIX}/lib/PresentMonAPI2Loader.lib"
)
set_property(TARGET presentmon-sdk::loader APPEND PROPERTY
  MAP_IMPORTED_CONFIG_RELWITHDEBINFO Release)
set_property(TARGET presentmon-sdk::loader APPEND PROPERTY
  MAP_IMPORTED_CONFIG_MINSIZEREL Release)

# Static companion lib
add_library(presentmon-sdk::common STATIC IMPORTED)
set_target_properties(presentmon-sdk::common PROPERTIES
  IMPORTED_CONFIGURATIONS "Debug;Release"
  IMPORTED_LOCATION_DEBUG   "${_IMPORT_PREFIX}/debug/lib/IPMCommonUtilities.lib"
  IMPORTED_LOCATION_RELEASE "${_IMPORT_PREFIX}/lib/IPMCommonUtilities.lib"
)
set_property(TARGET presentmon-sdk::common APPEND PROPERTY
  MAP_IMPORTED_CONFIG_RELWITHDEBINFO Release)
set_property(TARGET presentmon-sdk::common APPEND PROPERTY
  MAP_IMPORTED_CONFIG_MINSIZEREL Release)

# Umbrella target consumers link to
add_library(presentmon-sdk::presentmon-sdk INTERFACE IMPORTED)
target_include_directories(presentmon-sdk::presentmon-sdk INTERFACE "${_IMPORT_PREFIX}/include")
target_link_libraries(presentmon-sdk::presentmon-sdk INTERFACE
  presentmon-sdk::loader
  presentmon-sdk::common)