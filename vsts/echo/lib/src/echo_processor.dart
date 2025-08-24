/// Simple echo/delay effect processor
class EchoProcessor {
  static const int _delayBufferSize = 132300; // ~3 seconds at 44.1kHz
  
  final List<double> _delayBufferL = List.filled(_delayBufferSize, 0.0);
  final List<double> _delayBufferR = List.filled(_delayBufferSize, 0.0);
  int _writeIndex = 0;
  
  // Fixed echo parameters for obvious effect
  static const double _delayTime = 0.75; // 750ms delay
  static const double _feedback = 0.6; // Strong feedback
  static const double _wetLevel = 0.8; // High wet mix
  static const double _dryLevel = 0.5; // Moderate dry mix
  
  int _delayInSamples = 0;
  bool _initialized = false;

  /// Initialize the echo processor
  void initialize(double sampleRate, int maxBlockSize) {
    _delayInSamples = (_delayTime * sampleRate).round();
    _initialized = true;
  }

  /// Process stereo audio block with obvious echo
  void processStereo(List<double> inputL, List<double> inputR, 
                    List<double> outputL, List<double> outputR) {
    if (!_initialized || inputL.length != inputR.length ||
        outputL.length != inputL.length || outputR.length != inputL.length) {
      return;
    }
    
    for (int i = 0; i < inputL.length; i++) {
      // Calculate read index for delay
      final readIndex = (_writeIndex - _delayInSamples + _delayBufferSize) % _delayBufferSize;
      
      // Get delayed samples
      final delayedL = _delayBufferL[readIndex];
      final delayedR = _delayBufferR[readIndex];
      
      // Write input + feedback to delay buffer
      _delayBufferL[_writeIndex] = inputL[i] + (delayedL * _feedback);
      _delayBufferR[_writeIndex] = inputR[i] + (delayedR * _feedback);
      
      // Mix dry and wet signals
      outputL[i] = (inputL[i] * _dryLevel) + (delayedL * _wetLevel);
      outputR[i] = (inputR[i] * _dryLevel) + (delayedR * _wetLevel);
      
      // Advance write index
      _writeIndex = (_writeIndex + 1) % _delayBufferSize;
    }
  }

  /// Reset delay buffers
  void reset() {
    _delayBufferL.fillRange(0, _delayBufferSize, 0.0);
    _delayBufferR.fillRange(0, _delayBufferSize, 0.0);
    _writeIndex = 0;
  }

  /// Dispose resources
  void dispose() {
    _initialized = false;
    reset();
  }
}