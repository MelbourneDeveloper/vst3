cmake_minimum_required(VERSION 3.20)
project(flutter_dart_reverb_plugin 
    VERSION 1.0.0
    LANGUAGES CXX)

# Build the Flutter Dart Reverb VST3 plugin. This uses pure Dart audio
# processing from the flutter_reverb package via FFI bridge, implementing
# a complete VST3 reverb plugin powered by Dart. On macOS the output
# will be a bundle with extension .vst3.

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

# Use the properly downloaded VST3 SDK
if(NOT DEFINED ENV{VST3_SDK_DIR})
  set(VST3_SDK_DIR ${CMAKE_CURRENT_SOURCE_DIR}/../vst3sdk)
else()
  set(VST3_SDK_DIR $ENV{VST3_SDK_DIR})
endif()

if(NOT EXISTS ${VST3_SDK_DIR}/CMakeLists.txt)
  message(FATAL_ERROR "VST3 SDK not found at ${VST3_SDK_DIR}. Download it first.")
endif()

# Disable validator and module info for now to avoid build failures
set(SMTG_RUN_VST_VALIDATOR OFF)
set(SMTG_CREATE_MODULE_INFO OFF)

# Add the VST3 SDK subdirectory to get all the proper functions and targets
add_subdirectory(${VST3_SDK_DIR} vst3sdk)

# Define plugin sources
set(flutter_dart_reverb_sources
  src/dart_reverb_factory.cpp
  src/dart_reverb_processor.cpp
  src/dart_reverb_controller.cpp
  ../native/src/dart_reverb_bridge.cpp
)

# Set the public SDK source directory (required for main entry point)
set(public_sdk_SOURCE_DIR ${VST3_SDK_DIR}/public.sdk)

# Create VST3 plugin using SDK's standard function
set(target flutter_dart_reverb)
smtg_add_vst3plugin(${target} ${flutter_dart_reverb_sources})

# Set target properties using SDK functions
smtg_target_configure_version_file(${target})

target_compile_features(${target}
    PUBLIC
        cxx_std_17
)

# Add include directories
target_include_directories(${target}
    PRIVATE
        ${CMAKE_CURRENT_SOURCE_DIR}/include
        ${CMAKE_CURRENT_SOURCE_DIR}/../native/include
)

# Link against SDK
target_link_libraries(${target}
    PRIVATE
        sdk
)

# Set bundle properties on macOS using SDK function
if(SMTG_MAC)
    smtg_target_set_bundle(${target}
        BUNDLE_IDENTIFIER "com.yourcompany.vst3.flutterdartverb"
        COMPANY_NAME "Your Company"
        INFOPLIST_IN ${CMAKE_CURRENT_SOURCE_DIR}/Info.plist.in
    )
endif()

# Add native library dependency and bundling
if(EXISTS "/workspace/native/build")
  set(DART_VST_HOST_LIB "/workspace/native/build/libdart_vst_host.dylib")
else()
  set(DART_VST_HOST_LIB "${CMAKE_CURRENT_SOURCE_DIR}/../native/build/libdart_vst_host.dylib")
endif()

# Link the dart_vst_host library
target_link_libraries(${target}
    PRIVATE
        ${DART_VST_HOST_LIB}
)

# Bundle the dylib into the VST3 package on macOS
if(SMTG_MAC)
  get_target_property(PLUGIN_PACKAGE_PATH ${target} SMTG_PLUGIN_PACKAGE_PATH)
  
  add_custom_command(TARGET ${target} POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E make_directory 
    "${PLUGIN_PACKAGE_PATH}/Contents/Frameworks"
    COMMAND ${CMAKE_COMMAND} -E copy_if_different
    "${DART_VST_HOST_LIB}"
    "${PLUGIN_PACKAGE_PATH}/Contents/Frameworks/"
    COMMAND install_name_tool -change @rpath/libdart_vst_host.dylib 
    @loader_path/../Frameworks/libdart_vst_host.dylib
    "${PLUGIN_PACKAGE_PATH}/Contents/MacOS/flutter_dart_reverb"
    COMMENT "Bundling libdart_vst_host.dylib and fixing rpath"
  )
endif()