cmake_minimum_required(VERSION 3.20)
project(echo_plugin 
    VERSION 1.0.0
    LANGUAGES CXX)

# Build the Echo VST3 plugin using dart_vst3_bridge
# This plugin uses pure Dart audio processing via FFI bridge

set(CMAKE_CXX_STANDARD 17)

# Set build type and debug flags
if(NOT CMAKE_BUILD_TYPE)
  set(CMAKE_BUILD_TYPE Release)
endif()

if(CMAKE_BUILD_TYPE STREQUAL "Debug")
  add_compile_definitions(_DEBUG)
else()
  add_compile_definitions(NDEBUG RELEASE)
endif()

# Include the VST3 bridge helper
include(../../dart_vst3_bridge/native/cmake/VST3Bridge.cmake)

# Define plugin-specific sources - factory includes the others
set(echo_sources
  src/echo_factory.cpp
)

# Create the VST3 plugin using the bridge
add_dart_vst3_plugin(echo ${echo_sources}
    BUNDLE_IDENTIFIER "com.yourcompany.vst3.echo"
    COMPANY_NAME "Your Company"
    PLUGIN_NAME "Echo"
)