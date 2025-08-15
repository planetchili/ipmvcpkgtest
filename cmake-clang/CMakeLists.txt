cmake_minimum_required(VERSION 3.23)

# establigh vcpkg settings before project
set(CMAKE_TOOLCHAIN_FILE "$ENV{VCPKG_ROOT}/scripts/buildsystems/vcpkg.cmake" CACHE FILEPATH "")
set(VCPKG_TARGET_TRIPLET "x64-windows-static" CACHE STRING "")

project(pmvcex_cmake LANGUAGES CXX)

# compiler settings
set(CMAKE_CXX_STANDARD 23)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>")

add_executable(pmvcex_cmake src/main.cpp)

# consuming the vcpkg ports
find_package(presentmon-wrapper CONFIG REQUIRED)

# link in libs
target_link_libraries(pmvcex_cmake PRIVATE presentmon-wrapper::presentmon-wrapper)
