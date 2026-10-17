import 'dart:math';

import 'package:vector_math/vector_math.dart' as vm;

import '../../utils/constants/vr_spatial_audio_constants.dart';

/// Evaluates distance gain and horizontal, head-relative stereo balance.
///
/// Uses inverse-distance attenuation multiplied by a linear fade to silence at
/// the maximum distance. This preserves VRlizate's existing cue curve. It is
/// not HRTF, acoustic simulation, or inverse-square intensity attenuation.
class VrSpatialAudioEvaluator {
  /// Returns `(gain, pan)` in `[0, 1]` and `[-1, 1]`, respectively.
  static (double gain, double pan) evaluate({
    required vm.Vector3 source,
    required vm.Vector3 listener,
    required double listenerYaw,
    double minDistance = VrSpatialAudioConstants.defaultMinDistance,
    double maxDistance = VrSpatialAudioConstants.defaultMaxDistance,
    double rolloff = VrSpatialAudioConstants.defaultRolloff,
  }) {
    validateAttenuation(
      minDistance: minDistance,
      maxDistance: maxDistance,
      rolloff: rolloff,
    );
    _validatePosition(source, VrSpatialAudioConstants.paramSource);
    _validatePosition(listener, VrSpatialAudioConstants.paramListener);
    if (!listenerYaw.isFinite) {
      throw ArgumentError.value(
        listenerYaw,
        VrSpatialAudioConstants.paramListenerYaw,
        VrSpatialAudioConstants.errFinite,
      );
    }

    final diff = source - listener;
    final distance = diff.length;
    if (distance >= maxDistance) return (0.0, 0.0);

    final clampedDist = max(distance, minDistance);
    final distanceGain =
        minDistance / (minDistance + rolloff * (clampedDist - minDistance));
    final windowFalloff = (1.0 - (distance / maxDistance)).clamp(0.0, 1.0);
    final gain = (distanceGain * windowFalloff).clamp(0.0, 1.0);

    final cosYaw = cos(-listenerYaw);
    final sinYaw = sin(-listenerYaw);
    final localX = diff.x * cosYaw - diff.z * sinYaw;
    final localZ = diff.x * sinYaw + diff.z * cosYaw;
    final horizontalDist = sqrt(localX * localX + localZ * localZ);
    if (horizontalDist < VrSpatialAudioConstants.minHorizontalDistanceMeters) {
      return (gain, 0.0);
    }

    final azimuth = atan2(localX, -localZ);
    final pan = sin(azimuth).clamp(-1.0, 1.0);
    return (gain, pan);
  }

  /// Validates a reusable attenuation configuration before entering a tick.
  static void validateAttenuation({
    required double minDistance,
    required double maxDistance,
    required double rolloff,
  }) {
    if (!minDistance.isFinite || minDistance <= 0) {
      throw ArgumentError.value(
        minDistance,
        VrSpatialAudioConstants.paramMinDistance,
        VrSpatialAudioConstants.errMinDistancePositive,
      );
    }
    if (!maxDistance.isFinite || maxDistance <= minDistance) {
      throw ArgumentError.value(
        maxDistance,
        VrSpatialAudioConstants.paramMaxDistance,
        VrSpatialAudioConstants.errMaxDistanceExceedsMin,
      );
    }
    if (!rolloff.isFinite || rolloff < 0) {
      throw ArgumentError.value(
        rolloff,
        VrSpatialAudioConstants.paramRolloff,
        VrSpatialAudioConstants.errRolloffNonNegative,
      );
    }
  }

  static void _validatePosition(vm.Vector3 value, String name) {
    if (!value.x.isFinite || !value.y.isFinite || !value.z.isFinite) {
      throw ArgumentError.value(
        value,
        name,
        VrSpatialAudioConstants.errCoordinateFinite,
      );
    }
  }
}
