# Compute triplet prefix
get_filename_component(_IMPORT_PREFIX "${CMAKE_CURRENT_LIST_DIR}/../.." ABSOLUTE)

# Interface target that carries includes + libs
add_library(presentmon-wrapper::presentmon-wrapper INTERFACE IMPORTED)

# Includes
target_include_directories(presentmon-wrapper::presentmon-wrapper INTERFACE
  "${_IMPORT_PREFIX}/include"
)

# Link the actual libs; Debug uses debug/lib, others use lib
target_link_libraries(presentmon-wrapper::presentmon-wrapper INTERFACE
  "$<$<CONFIG:Debug>:${_IMPORT_PREFIX}/debug/lib/PresentMonAPIWrapperCommon.lib>"
  "$<$<CONFIG:Debug>:${_IMPORT_PREFIX}/debug/lib/PresentMonAPIWrapper.lib>"
  "$<$<NOT:$<CONFIG:Debug>>:${_IMPORT_PREFIX}/lib/PresentMonAPIWrapperCommon.lib>"
  "$<$<NOT:$<CONFIG:Debug>>:${_IMPORT_PREFIX}/lib/PresentMonAPIWrapper.lib>"

  # pull in the SDK (import lib for the DLL + CommonUtilities)
  presentmon-sdk::presentmon-sdk
  
  # Add any required system libs if needed, e.g.:
  # dxgi dxguid setupapi cfgmgr32 wbemuuid advapi32
)