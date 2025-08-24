#include "public.sdk/source/vst/vstaudioeffect.h"
#include "public.sdk/source/vst/vsthelpers.h"
#include "pluginterfaces/vst/ivstparameterchanges.h"
#include "base/source/fstreamer.h"
#include "../include/echo_ids.h"
#include <algorithm>

namespace Steinberg {
namespace Vst {

class EchoProcessor : public AudioEffect {
public:
    EchoProcessor();
    virtual ~EchoProcessor();

    static FUnknown* createInstance(void*) {
        return (IAudioProcessor*)new EchoProcessor;
    }

    tresult PLUGIN_API initialize(FUnknown* context) SMTG_OVERRIDE;
    tresult PLUGIN_API setBusArrangements(SpeakerArrangement* inputs, int32 numIns,
                                         SpeakerArrangement* outputs, int32 numOuts) SMTG_OVERRIDE;
    tresult PLUGIN_API canProcessSampleSize(int32 symbolicSampleSize) SMTG_OVERRIDE;
    tresult PLUGIN_API setActive(TBool state) SMTG_OVERRIDE;
    tresult PLUGIN_API process(ProcessData& data) SMTG_OVERRIDE;
    tresult PLUGIN_API setState(IBStream* state) SMTG_OVERRIDE;
    tresult PLUGIN_API getState(IBStream* state) SMTG_OVERRIDE;

private:
    ParamValue delayTime = 0.5;
    ParamValue feedback = 0.3;
    ParamValue mix = 0.5;
    TBool bypass = false;

    // Simple delay buffer
    Sample32* delayBuffer = nullptr;
    int32 bufferSize = 0;
    int32 writePos = 0;
};

EchoProcessor::EchoProcessor() {
    setControllerClass(kEchoControllerUID);
}

EchoProcessor::~EchoProcessor() {
    delete[] delayBuffer;
}

tresult EchoProcessor::initialize(FUnknown* context) {
    tresult result = AudioEffect::initialize(context);
    if (result != kResultOk) return result;

    addAudioInput(STR16("Stereo In"), SpeakerArr::kStereo);
    addAudioOutput(STR16("Stereo Out"), SpeakerArr::kStereo);

    return kResultOk;
}

tresult EchoProcessor::setBusArrangements(SpeakerArrangement* inputs, int32 numIns,
                                         SpeakerArrangement* outputs, int32 numOuts) {
    return (numIns == 1 && numOuts == 1 && inputs[0] == outputs[0] && inputs[0] == SpeakerArr::kStereo) 
           ? kResultOk : kResultFalse;
}

tresult EchoProcessor::canProcessSampleSize(int32 symbolicSampleSize) {
    return (symbolicSampleSize == kSample32) ? kResultOk : kResultFalse;
}

tresult EchoProcessor::setActive(TBool state) {
    if (state) {
        // Allocate delay buffer for 2 seconds at 44.1kHz stereo
        bufferSize = 44100 * 2 * 2; // 2 seconds, stereo
        delayBuffer = new Sample32[bufferSize];
        memset(delayBuffer, 0, bufferSize * sizeof(Sample32));
        writePos = 0;
    } else {
        delete[] delayBuffer;
        delayBuffer = nullptr;
        bufferSize = 0;
    }
    return AudioEffect::setActive(state);
}

tresult EchoProcessor::process(ProcessData& data) {
    if (data.inputs == nullptr || data.outputs == nullptr) return kResultOk;
    if (data.numInputs == 0 || data.numOutputs == 0) return kResultOk;
    if (data.inputs[0].numChannels != 2 || data.outputs[0].numChannels != 2) return kResultOk;
    if (delayBuffer == nullptr) return kResultOk;

    // Process parameters
    if (data.inputParameterChanges) {
        int32 numParamsChanged = data.inputParameterChanges->getParameterCount();
        for (int32 i = 0; i < numParamsChanged; i++) {
            if (IParamValueQueue* paramQueue = data.inputParameterChanges->getParameterData(i)) {
                int32 numPoints = paramQueue->getPointCount();
                int32 sampleOffset;
                ParamValue value;
                if (paramQueue->getPoint(numPoints - 1, sampleOffset, value) == kResultTrue) {
                    switch (paramQueue->getParameterId()) {
                        case kDelayTime: delayTime = value; break;
                        case kFeedback: feedback = value; break;
                        case kMix: mix = value; break;
                        case kBypass: bypass = (value > 0.5); break;
                    }
                }
            }
        }
    }

    // Audio processing
    Sample32** inputs = data.inputs[0].channelBuffers32;
    Sample32** outputs = data.outputs[0].channelBuffers32;
    int32 sampleFrames = data.numSamples;

    int32 delayInSamples = (int32)(delayTime * 44100.0);
    delayInSamples = std::min(delayInSamples, bufferSize / 2 - 1);

    for (int32 i = 0; i < sampleFrames; i++) {
        for (int32 ch = 0; ch < 2; ch++) {
            Sample32 input = inputs[ch][i];
            Sample32 output = input;
            
            if (!bypass && delayInSamples > 0) {
                int32 readPos = (writePos - delayInSamples * 2 + bufferSize) % bufferSize;
                Sample32 delayed = delayBuffer[readPos + ch];
                
                delayBuffer[writePos + ch] = input + delayed * feedback;
                output = input * (1.0f - mix) + delayed * mix;
            }
            
            outputs[ch][i] = output;
        }
        writePos = (writePos + 2) % bufferSize;
    }

    return kResultOk;
}

tresult EchoProcessor::setState(IBStream* state) {
    if (!state) return kResultFalse;
    
    IBStreamer streamer(state, kLittleEndian);
    streamer.readDouble(delayTime);
    streamer.readDouble(feedback);
    streamer.readDouble(mix);
    streamer.readInt8u(bypass);
    
    return kResultOk;
}

tresult EchoProcessor::getState(IBStream* state) {
    if (!state) return kResultFalse;
    
    IBStreamer streamer(state, kLittleEndian);
    streamer.writeDouble(delayTime);
    streamer.writeDouble(feedback);
    streamer.writeDouble(mix);
    streamer.writeInt8u(bypass);
    
    return kResultOk;
}

} // namespace Vst
} // namespace Steinberg