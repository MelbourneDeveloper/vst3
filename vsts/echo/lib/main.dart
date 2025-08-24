/// Main entry point for Echo VST3 plugin
/// 
/// This file provides the entry point that registers the echo processor
/// with the VST3 bridge, enabling the pure Dart echo processor to be
/// called from the VST3 plugin.

import 'package:dart_vst3_bridge/dart_vst3_bridge.dart';
import 'src/echo_vst3_processor.dart';

/// Initialize the Echo plugin
/// This must be called when the VST3 plugin is loaded to register
/// the Dart processor with the VST3 bridge
void main() {
  // Register the echo processor with the VST3 bridge
  VST3Bridge.registerProcessor(EchoVST3Processor());
  
  // Register VST3 callbacks with C++ layer
  registerVST3Callbacks();
}

/// Entry point called from C++ when VST3 plugin initializes
/// This ensures the Dart VM and processor are properly set up
void initializeDartEcho() {
  main();
}