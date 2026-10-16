import 'dart:math';

import 'package:vector_math/vector_math.dart' as vm;

/// Evaluates distance gain and horizontal, head-relative stereo balance.
///
/// Uses inverse-distance attenuation multiplied by a linear fade to silence at
/// the maximum distance. This preserves VRlizate's existing cue curve. It is
/// not HRTF, acoustic simulation, or inverse-square intensity attenuation.
class VrSpatialAudioEvaluator {
  /// Returns `(gain, pan)` in `[0, 1]` and `[-1, 1]`, respectively.
  ///
  /// Positions must use the same coordinate space and units, normally meters.
  /// Y is up and -Z is forward when [listenerYaw] is zero. [listenerYaw] uses
  /// the existing VRlizate head-rig convention, in radians.
  ///
  /// [minDistance] clamps the inverse-distance term; the linear fade still
  /// applies inside it. A coincident source has unity gain and centered pan.
  /// [maxDistance] is a hard audible radius and must exceed [minDistance].
  /// [rolloff] is nonnegative; zero leaves only the linear fade.
  ///
  /// Throws [ArgumentError] for invalid/nonfinite parameters. Callers must not
  /// forward unvalidated network coordinates directly to playback backends.
  static (double gain, double pan) evaluate({
    required vm.Vector3 source,
    required vm.Vector3 listener,
    required double listenerYaw,
    double minDistance = 1.0,
    double maxDistance = 25.0,
    double rolloff = 1.0,
  }) {
    validateAttenuation(
      minDistance: minDistance,
      maxDistance: maxDistance,
      rolloff: rolloff,
    );
    _validatePosition(source, 'source');
    _validatePosition(listener, 'listener');
    if (!listenerYaw.isFinite) {
      throw ArgumentError.value(listenerYaw, 'listenerYaw', 'Must be finite');
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
    if (horizontalDist < 1e-4) return (gain, 0.0);

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
        'minDistance',
        'Must be finite and greater than zero',
      );
    }
    if (!maxDistance.isFinite || maxDistance <= minDistance) {
      throw ArgumentError.value(
        maxDistance,
        'maxDistance',
        'Must be finite and exceed minDistance',
      );
    }
    if (!rolloff.isFinite || rolloff < 0) {
      throw ArgumentError.value(
        rolloff,
        'rolloff',
        'Must be finite and nonnegative',
      );
    }
  }

  static void _validatePosition(vm.Vector3 value, String name) {
    if (!value.x.isFinite || !value.y.isFinite || !value.z.isFinite) {
      throw ArgumentError.value(value, name, 'Every coordinate must be finite');
    }
  }
}
