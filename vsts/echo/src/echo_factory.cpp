#include "public.sdk/source/main/pluginfactory.h"
#include "public.sdk/source/vst/vstaudioeffect.h"
#include "public.sdk/source/vst/vsteditcontroller.h"
#include "../include/echo_ids.h"

#define FULL_VERSION_STR "1.0.0"

// Include actual class definitions
#include "echo_processor.cpp"
#include "echo_controller.cpp"

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