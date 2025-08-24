#include "public.sdk/source/vst/vsteditcontroller.h"
#include "public.sdk/source/vst/vsthelpers.h"
#include "base/source/fstreamer.h"
#include "../include/echo_ids.h"

namespace Steinberg {
namespace Vst {

class EchoController : public EditController {
public:
    EchoController() = default;
    virtual ~EchoController() = default;

    static FUnknown* createInstance(void*) {
        return (IEditController*)new EchoController;
    }

    tresult PLUGIN_API initialize(FUnknown* context) SMTG_OVERRIDE;
    tresult PLUGIN_API setComponentState(IBStream* state) SMTG_OVERRIDE;
};

tresult EchoController::initialize(FUnknown* context) {
    tresult result = EditController::initialize(context);
    if (result != kResultOk) return result;

    // Add parameters
    parameters.addParameter(STR16("Delay Time"), STR16("ms"), 0, 0.5, 
                           ParameterInfo::kCanAutomate, kDelayTime);
    parameters.addParameter(STR16("Feedback"), STR16("%"), 0, 0.3, 
                           ParameterInfo::kCanAutomate, kFeedback);
    parameters.addParameter(STR16("Mix"), STR16("%"), 0, 0.5, 
                           ParameterInfo::kCanAutomate, kMix);
    parameters.addParameter(STR16("Bypass"), nullptr, 1, 0, 
                           ParameterInfo::kCanAutomate | ParameterInfo::kIsBypass, kBypass);

    return kResultOk;
}

tresult EchoController::setComponentState(IBStream* state) {
    if (!state) return kResultFalse;
    
    IBStreamer streamer(state, kLittleEndian);
    ParamValue delayTime, feedback, mix;
    uint8 bypass;
    
    streamer.readDouble(delayTime);
    streamer.readDouble(feedback);
    streamer.readDouble(mix);
    streamer.readInt8u(bypass);
    
    setParamNormalized(kDelayTime, delayTime);
    setParamNormalized(kFeedback, feedback);
    setParamNormalized(kMix, mix);
    setParamNormalized(kBypass, bypass);
    
    return kResultOk;
}

} // namespace Vst
} // namespace Steinberg