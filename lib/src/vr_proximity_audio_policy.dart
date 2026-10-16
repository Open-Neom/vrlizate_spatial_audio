import 'package:vector_math/vector_math.dart' as vm;
import 'package:vrlizate_world/vrlizate_world.dart' show VrWorldAddress;

import 'vr_spatial_audio_evaluator.dart';

/// Receiver-side proximity policy for a voice or shared environmental emitter.
///
/// Adapters apply the returned gain/pan to existing playback or RTC services.
/// Consent defaults to false; proximity never activates a microphone. Transport
/// authorization and unsubscribing inaudible/blocked voice streams remain the
/// host/backend's responsibility. Muting local playback is not access control.
final class VrProximityAudioPolicy {
  VrProximityAudioPolicy({
    this.minDistance = 1.0,
    this.maxDistance = 25.0,
    this.rolloff = 1.0,
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

  /// [sourceMuted] includes the sender's mute; [listenerMuted] can represent
  /// deafening or that listener's per-participant mute. [blocked] represents a
  /// block in either direction. The host supplies authoritative membership and
  /// consent state; a remote pose packet must not assert these flags.
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
