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