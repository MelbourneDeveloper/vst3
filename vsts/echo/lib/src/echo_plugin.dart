import 'echo_processor.dart';

/// Simple Echo Plugin with obvious delay effect
class DartEchoPlugin {
  static const String pluginName = 'Dart Echo';
  static const String vendor = 'Dart Audio';
  static const String version = '1.0.0';
  static const String category = 'Effect';
  
  EchoProcessor? _processor;
  bool _isActive = false;

  /// Initialize the plugin
  bool initialize() {
    _processor = EchoProcessor();
    return true;
  }

  /// Set up audio processing parameters
  void setupProcessing(double sampleRate, int maxBlockSize) {
    _processor?.initialize(sampleRate, maxBlockSize);
  }

  /// Activate/deactivate the plugin
  void setActive(bool active) {
    if (active && !_isActive) {
      _processor?.reset();
    }
    _isActive = active;
  }

  /// Get plugin information
  Map<String, dynamic> get pluginInfo {
    return {
      'name': pluginName,
      'vendor': vendor,
      'version': version,
      'category': category,
      'type': 'effect',
      'inputs': 2,
      'outputs': 2,
      'parameters': 0,
      'canProcessReplacing': true,
      'hasEditor': false,
    };
  }

  /// Process audio block
  void processAudio(List<List<double>> inputs, List<List<double>> outputs) {
    if (!_isActive || inputs.isEmpty || outputs.isEmpty) {
      return;
    }

    // Ensure we have stereo inputs and outputs
    final inputL = inputs.isNotEmpty ? inputs[0] : <double>[];
    final inputR = inputs.length > 1 ? inputs[1] : inputL;
    
    if (outputs.isEmpty) return;
    final outputL = outputs[0];
    final outputR = outputs.length > 1 ? outputs[1] : outputL;

    if (inputL.isEmpty || outputL.isEmpty) return;

    // Process the audio through the echo effect
    _processor?.processStereo(inputL, inputR, outputL, outputR);
  }

  /// Dispose resources
  void dispose() {
    _isActive = false;
    _processor?.dispose();
  }
}

/// Factory for creating echo plugin instances
class DartEchoFactory {
  /// Create a new plugin instance
  static DartEchoPlugin createInstance() {
    return DartEchoPlugin();
  }

  /// Get plugin class information
  static Map<String, dynamic> getClassInfo() {
    return {
      'name': DartEchoPlugin.pluginName,
      'vendor': DartEchoPlugin.vendor,
      'version': DartEchoPlugin.version,
      'category': DartEchoPlugin.category,
      'classId': 'DartEcho',
      'controllerId': 'DartEchoController',
    };
  }
}