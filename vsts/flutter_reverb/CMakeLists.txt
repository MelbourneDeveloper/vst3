cmake_minimum_required(VERSION 3.20)
project(flutter_reverb_plugin 
    VERSION 1.0.0
    LANGUAGES CXX)

# Build the Flutter Reverb VST3 plugin using dart_vst3_bridge
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

# Define plugin-specific sources
set(flutter_reverb_sources
  src/reverb_factory.cpp
  src/reverb_processor.cpp
  src/reverb_controller.cpp
  ../../native/src/dart_reverb_bridge.cpp
)

# Create the VST3 plugin using the bridge
add_dart_vst3_plugin(flutter_reverb ${flutter_reverb_sources}
    BUNDLE_IDENTIFIER "com.yourcompany.vst3.flutterreverb"
    COMPANY_NAME "Your Company"
    PLUGIN_NAME "Flutter Reverb"
)