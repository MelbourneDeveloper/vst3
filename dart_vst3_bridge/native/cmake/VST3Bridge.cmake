# VST3Bridge.cmake - Shared CMake configuration for VST3 plugins using dart_vst3_bridge
#
# This file provides common functions and setup for building VST3 plugins that use
# the dart_vst3_bridge package for Dart integration.

# Function to create a VST3 plugin using the bridge
function(add_dart_vst3_plugin target_name plugin_sources)
    # Parse additional arguments
    set(options "")
    set(oneValueArgs BUNDLE_IDENTIFIER COMPANY_NAME PLUGIN_NAME)
    set(multiValueArgs INCLUDE_DIRS LINK_LIBRARIES)
    cmake_parse_arguments(PLUGIN "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    # Set default values if not provided
    if(NOT PLUGIN_BUNDLE_IDENTIFIER)
        set(PLUGIN_BUNDLE_IDENTIFIER "com.yourcompany.vst3.${target_name}")
    endif()
    
    if(NOT PLUGIN_COMPANY_NAME)
        set(PLUGIN_COMPANY_NAME "Your Company")
    endif()
    
    if(NOT PLUGIN_PLUGIN_NAME)
        set(PLUGIN_PLUGIN_NAME "${target_name}")
    endif()

    # Set up VST3 SDK
    if(NOT DEFINED ENV{VST3_SDK_DIR})
        set(VST3_SDK_DIR ${CMAKE_CURRENT_SOURCE_DIR}/../../vst3sdk)
    else()
        set(VST3_SDK_DIR $ENV{VST3_SDK_DIR})
    endif()

    if(NOT EXISTS ${VST3_SDK_DIR}/CMakeLists.txt)
        message(FATAL_ERROR "VST3 SDK not found at ${VST3_SDK_DIR}. Download it first.")
    endif()

    # Disable validator and module info to avoid build failures
    set(SMTG_RUN_VST_VALIDATOR OFF)
    set(SMTG_CREATE_MODULE_INFO OFF)

    # Add the VST3 SDK subdirectory
    if(NOT TARGET sdk)
        add_subdirectory(${VST3_SDK_DIR} vst3sdk)
    endif()

    # Find dart_vst3_bridge native directory
    # Since plugins are in vsts/ and bridge is in dart_vst3_bridge/native/
    # The path from any vst plugin to bridge is ../../dart_vst3_bridge/native/
    set(BRIDGE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/../../dart_vst3_bridge/native")
    get_filename_component(BRIDGE_DIR "${BRIDGE_DIR}" ABSOLUTE)
    
    # Check if bridge sources exist
    set(bridge_sources
        ${BRIDGE_DIR}/src/factory.cpp
        ${BRIDGE_DIR}/src/plugin_controller.cpp
        ${BRIDGE_DIR}/src/plugin_processor.cpp
        ${BRIDGE_DIR}/src/plugin_view.cpp
    )
    
    foreach(src ${bridge_sources})
        if(NOT EXISTS ${src})
            message(FATAL_ERROR "Bridge source file not found: ${src}")
        endif()
    endforeach()
    
    # Combine plugin sources with bridge sources (excluding factory.cpp since plugins provide their own)
    set(bridge_sources_no_factory
        ${BRIDGE_DIR}/src/plugin_controller.cpp
        ${BRIDGE_DIR}/src/plugin_processor.cpp
        ${BRIDGE_DIR}/src/plugin_view.cpp
    )
    
    # Add platform-specific main entry point
    if(SMTG_MAC)
        list(APPEND bridge_sources_no_factory ${VST3_SDK_DIR}/public.sdk/source/main/macmain.cpp)
    elseif(SMTG_WIN)
        list(APPEND bridge_sources_no_factory ${VST3_SDK_DIR}/public.sdk/source/main/dllmain.cpp)
    elseif(SMTG_LINUX)
        list(APPEND bridge_sources_no_factory ${VST3_SDK_DIR}/public.sdk/source/main/linuxmain.cpp)
    endif()
    
    set(all_sources
        ${plugin_sources}
        ${bridge_sources_no_factory}
    )

    # Create VST3 plugin using SDK's standard function
    smtg_add_vst3plugin(${target_name} ${all_sources})

    # Set target properties
    smtg_target_configure_version_file(${target_name})

    target_compile_features(${target_name}
        PUBLIC
            cxx_std_17
    )

    # Add include directories
    target_include_directories(${target_name}
        PRIVATE
            ${CMAKE_CURRENT_SOURCE_DIR}/include
            ${BRIDGE_DIR}/include
            ${CMAKE_CURRENT_SOURCE_DIR}/../../native/include
            ${PLUGIN_INCLUDE_DIRS}
    )

    # Link against SDK and additional libraries
    target_link_libraries(${target_name}
        PRIVATE
            sdk
            ${PLUGIN_LINK_LIBRARIES}
    )

    # Set bundle properties on macOS
    if(SMTG_MAC)
        # Create Info.plist.in if it doesn't exist
        set(INFO_PLIST_PATH "${CMAKE_CURRENT_SOURCE_DIR}/Info.plist.in")
        if(NOT EXISTS ${INFO_PLIST_PATH})
            file(WRITE ${INFO_PLIST_PATH} "<?xml version=\"1.0\" encoding=\"UTF-8\"?>
<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">
<plist version=\"1.0\">
<dict>
    <key>CFBundleExecutable</key>
    <string>${PLUGIN_PLUGIN_NAME}</string>
    <key>CFBundleIconFile</key>
    <string></string>
    <key>CFBundleIdentifier</key>
    <string>${PLUGIN_BUNDLE_IDENTIFIER}</string>
    <key>CFBundleName</key>
    <string>${PLUGIN_PLUGIN_NAME}</string>
    <key>CFBundlePackageType</key>
    <string>BNDL</string>
    <key>CFBundleVersion</key>
    <string>1.0.0</string>
    <key>CFBundleSignature</key>
    <string>????</string>
</dict>
</plist>")
        endif()
        
        smtg_target_set_bundle(${target_name}
            BUNDLE_IDENTIFIER "${PLUGIN_BUNDLE_IDENTIFIER}"
            COMPANY_NAME "${PLUGIN_COMPANY_NAME}"
            INFOPLIST_IN ${INFO_PLIST_PATH}
        )
    endif()

    # Find and link native library
    if(EXISTS "/workspace/native/build")
        set(DART_VST_HOST_LIB "/workspace/native/build/libdart_vst_host.dylib")
    else()
        set(DART_VST_HOST_LIB "${CMAKE_CURRENT_SOURCE_DIR}/../../native/build/libdart_vst_host.dylib")
    endif()

    if(EXISTS ${DART_VST_HOST_LIB})
        target_link_libraries(${target_name}
            PRIVATE
                ${DART_VST_HOST_LIB}
        )

        # Bundle the dylib into the VST3 package on macOS
        if(SMTG_MAC)
            get_target_property(PLUGIN_PACKAGE_PATH ${target_name} SMTG_PLUGIN_PACKAGE_PATH)
            
            add_custom_command(TARGET ${target_name} POST_BUILD
                COMMAND ${CMAKE_COMMAND} -E make_directory 
                "${PLUGIN_PACKAGE_PATH}/Contents/Frameworks"
                COMMAND ${CMAKE_COMMAND} -E copy_if_different
                "${DART_VST_HOST_LIB}"
                "${PLUGIN_PACKAGE_PATH}/Contents/Frameworks/"
                COMMAND install_name_tool -change @rpath/libdart_vst_host.dylib 
                @loader_path/../Frameworks/libdart_vst_host.dylib
                "${PLUGIN_PACKAGE_PATH}/Contents/MacOS/${target_name}"
                COMMENT "Bundling libdart_vst_host.dylib and fixing rpath"
            )
        endif()
    else()
        message(WARNING "libdart_vst_host.dylib not found. Build the native library first.")
    endif()
endfunction()