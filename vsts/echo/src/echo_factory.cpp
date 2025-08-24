#include "public.sdk/source/main/pluginfactory.h"
#include "public.sdk/source/vst/vstaudioeffect.h"
#include "../include/echo_ids.h"

// Forward declarations
namespace Steinberg {
namespace Vst {
class EchoProcessor;
class EchoController;
}
}

// Plugin factory entry point
BEGIN_FACTORY_DEF("Your Company", "https://www.yourcompany.com", "mailto:info@yourcompany.com")

    DEF_CLASS2(INLINE_UID_FROM_FUID(Steinberg::Vst::kEchoProcessorUID),
               PClassInfo::kManyInstances,
               kVstAudioEffectClass,
               "Echo",
               Vst::kDistributable,
               "Fx",
               FULL_VERSION_STR,
               kVstVersionString,
               Steinberg::Vst::EchoProcessor::createInstance)

    DEF_CLASS2(INLINE_UID_FROM_FUID(Steinberg::Vst::kEchoControllerUID),
               PClassInfo::kManyInstances,
               kVstComponentControllerClass,
               "Echo Controller",
               0,
               "",
               FULL_VERSION_STR,
               kVstVersionString,
               Steinberg::Vst::EchoController::createInstance)

END_FACTORY