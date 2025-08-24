import 'package:dart_vst3_bridge/dart_vst3_bridge.dart';
import 'echo_processor.dart';

/// VST3 processor adapter for the Echo plugin
/// This connects the pure Dart echo processor to the VST3 bridge
class EchoVST3Processor extends VST3Processor {
  EchoProcessor? _echoProcessor;
  
  @override
  void initialize(double sampleRate, int maxBlockSize) {
    _echoProcessor = EchoProcessor();
    _echoProcessor!.initialize(sampleRate, maxBlockSize);
  }

  @override
  void processStereo(List<double> inputL, List<double> inputR,
                    List<double> outputL, List<double> outputR) {
    _echoProcessor?.processStereo(inputL, inputR, outputL, outputR);
  }

  @override
  void setParameter(int paramId, double normalizedValue) {
    // Echo has no parameters
  }

  @override
  double getParameter(int paramId) {
    return 0.0;
  }

  @override
  int getParameterCount() {
    return 0;
  }

  @override
  void reset() {
    _echoProcessor?.reset();
  }

  @override
  void dispose() {
    _echoProcessor?.dispose();
    _echoProcessor = null;
  }
}