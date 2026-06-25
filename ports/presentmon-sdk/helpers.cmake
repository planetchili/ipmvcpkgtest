# Inject port-only MSBuild overlays into fetched PresentMon sources (no upstream edits).
function(pm_install_port_msbuild_overlays source_path_ipm source_path_common_utilities port_msbuild_dir enable_dbg_log)
    file(COPY "${port_msbuild_dir}/commonutilities-port-subset.props"
         DESTINATION "${source_path_common_utilities}")
    file(INSTALL "${port_msbuild_dir}/Directory.Build.CommonUtilities.props"
         DESTINATION "${source_path_common_utilities}"
         RENAME "Directory.Build.props")
    file(INSTALL "${port_msbuild_dir}/Directory.Build.IntelPresentMon.props"
         DESTINATION "${source_path_ipm}"
         RENAME "Directory.Build.props")
    file(INSTALL "${port_msbuild_dir}/Directory.Build.IntelPresentMon.targets"
         DESTINATION "${source_path_ipm}"
         RENAME "Directory.Build.targets")
endfunction()

function(pm_msbuild_port_common_options out_var source_path_root source_path_ipm enable_dbg_log)
    set(_opts
        /p:PM_VCPKG_PORT_BUILD=1
        /p:PM_VCPKG_COMU_PORT_SUBSET=1
        /p:CustomVcpkgProps=${source_path_root}\\vcpkg.props
        /p:CustomCommonProps=${source_path_ipm}\\Common.props
        /p:CustomRuntimeControlProps=${source_path_ipm}\\RuntimeControl.props
        /p:vcSiblingIncludeDirectory=${source_path_root}
        /p:vcInstalledIncludeDirectory=${CURRENT_INSTALLED_DIR}\\include
    )
    if(enable_dbg_log)
        list(APPEND _opts /p:PM_VCPKG_COMU_DBG_LOG=1)
    endif()
    set(${out_var} ${_opts} PARENT_SCOPE)
endfunction()

# Remove empty subdirectories recursively (leaf-first).
function(prune_empty_dirs root)
  # Collect all subdirectories
  file(GLOB_RECURSE _dirs LIST_DIRECTORIES true "${root}/*")

  # Sort deepest-first so we remove leaves before parents
  list(SORT _dirs ORDER DESCENDING)

  foreach(d IN LISTS _dirs)
    if (IS_DIRECTORY "${d}")
      file(GLOB _kids "${d}/*")
      if (_kids STREQUAL "")
        file(REMOVE_RECURSE "${d}")
      endif()
    endif()
  endforeach()

  # Optionally remove root if it ended up empty
  if (EXISTS "${root}")
    file(GLOB _rootkids "${root}/*")
    if (_rootkids STREQUAL "")
      file(REMOVE_RECURSE "${root}")
    endif()
  endif()
endfunction()
# Helper: rename latest msbuild logs to include a label
function(pm_rename_logs label)
    if(NOT label)
        message(FATAL_ERROR "pm_rename_logs(label) requires a non-empty label.")
    endif()

    # Triplet to use
    if(DEFINED TARGET_TRIPLET)
        set(_trip "${TARGET_TRIPLET}")
    else()
        set(_trip "${VCPKG_TARGET_TRIPLET}")
    endif()

    foreach(_cfg IN ITEMS rel dbg)
        set(_src "${CURRENT_BUILDTREES_DIR}/build-${_trip}-${_cfg}-out.log")
        set(_dst "${CURRENT_BUILDTREES_DIR}/xbuild-${_trip}-${label}-${_cfg}-out.log")

        if(EXISTS "${_src}")
            # If a previous run left a file, replace it
            if(EXISTS "${_dst}")
                file(REMOVE "${_dst}")
            endIf()

            file(RENAME "${_src}" "${_dst}")
            message(STATUS "Saved ${label} ${_cfg} log -> ${_dst}")
        else()
            message(STATUS "Log not found (skipping): ${_src}")
        endif()
    endforeach()
endfunction()