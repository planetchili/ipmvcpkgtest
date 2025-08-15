Generate .sln/.vcxproj with e.g.:
cmake -S . -B build -G "Visual Studio 17 2022" -A x64 -T clangcl

Then build on command line with msbuild or open and build from Visual Studio