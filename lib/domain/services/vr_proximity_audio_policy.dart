import 'package:vector_math/vector_math.dart' as vm;
import 'package:vrlizate_world/vrlizate_world.dart' show VrWorldAddress;

import '../../utils/constants/vr_spatial_audio_constants.dart';
import 'vr_spatial_audio_evaluator.dart';

/// Receiver-side proximity policy for a voice or shared environmental emitter.
///
/// Adapters apply the returned gain/pan to existing playback or RTC services.
/// Consent defaults to false; proximity never activates a microphone.
final class VrProximityAudioPolicy {
  VrProximityAudioPolicy({
    this.minDistance = VrSpatialAudioConstants.defaultMinDistance,
    this.maxDistance = VrSpatialAudioConstants.defaultMaxDistance,
    this.rolloff = VrSpatialAudioConstants.defaultRolloff,
  }) {
    VrSpatialAudioEvaluator.validateAttenuation(
      minDistance: minDistance,
      maxDistance: maxDistance,
      rolloff: rolloff,
    );
  }

  final double minDistance;
  final double maxDistance;
  final double rolloff;

  (double gain, double pan) evaluate({
    required VrWorldAddress sourceSpace,
    required VrWorldAddress listenerSpace,
    required vm.Vector3 source,
    required vm.Vector3 listener,
    required double listenerYaw,
    bool sourceOptedIn = false,
    bool listenerOptedIn = false,
    bool sourceMuted = false,
    bool listenerMuted = false,
    bool blocked = false,
  }) {
    if (sourceSpace != listenerSpace ||
        !sourceOptedIn ||
        !listenerOptedIn ||
        sourceMuted ||
        listenerMuted ||
        blocked) {
      return (0.0, 0.0);
    }
    return VrSpatialAudioEvaluator.evaluate(
      source: source,
      listener: listener,
      listenerYaw: listenerYaw,
      minDistance: minDistance,
      maxDistance: maxDistance,
      rolloff: rolloff,
    );
  }
}
