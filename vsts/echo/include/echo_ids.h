#pragma once

#include "pluginterfaces/base/funknown.h"
#include "pluginterfaces/vst/vsttypes.h"

namespace Steinberg {
namespace Vst {

// Echo Plugin IDs
static const FUID kEchoProcessorUID(0x12345678, 0x12345678, 0x12345678, 0x12345678);
static const FUID kEchoControllerUID(0x87654321, 0x87654321, 0x87654321, 0x87654321);

// Parameter IDs
enum EchoParams : ParamID {
    kDelayTime = 0,
    kFeedback = 1,
    kMix = 2,
    kBypass = 3
};

} // namespace Vst
} // namespace Steinberg