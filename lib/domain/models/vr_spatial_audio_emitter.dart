import 'package:vector_math/vector_math.dart' as vm;
import 'package:vrlizate_world/vrlizate_world.dart';

import '../../utils/constants/vr_spatial_audio_constants.dart';
import '../services/vr_spatial_audio_evaluator.dart';

/// Represents a positional audio emitter in a [VrWorldAddress].
final class VrSpatialAudioEmitter {
  factory VrSpatialAudioEmitter({
    required String id,
    required VrWorldAddress world,
    required vm.Vector3 position,
    double baseGain = 1.0,
    double minDistance = VrSpatialAudioConstants.defaultMinDistance,
    double maxDistance = VrSpatialAudioConstants.defaultMaxDistance,
    double rolloff = VrSpatialAudioConstants.defaultRolloff,
    int priority = VrSpatialAudioConstants.defaultEmitterPriority,
    bool muted = false,
  }) {
    VrWorldValidator.validateIdentifier(id, VrWorldConstants.paramId);
    if (!position.x.isFinite || !position.y.isFinite || !position.z.isFinite) {
      throw ArgumentError.value(
        position,
        VrSpatialAudioConstants.paramPosition,
        VrSpatialAudioConstants.errCoordinateFinite,
      );
    }
    if (!baseGain.isFinite || baseGain < 0 || baseGain > 2.0) {
      throw ArgumentError.value(
        baseGain,
        VrSpatialAudioConstants.paramBaseGain,
        VrSpatialAudioConstants.errBaseGainRange,
      );
    }
    VrSpatialAudioEvaluator.validateAttenuation(
      minDistance: minDistance,
      maxDistance: maxDistance,
      rolloff: rolloff,
    );
    return VrSpatialAudioEmitter._(
      id,
      world,
      position.clone(),
      baseGain,
      minDistance,
      maxDistance,
      rolloff,
      priority,
      muted,
    );
  }

  VrSpatialAudioEmitter._(
    this.id,
    this.world,
    this._position,
    this.baseGain,
    this.minDistance,
    this.maxDistance,
    this.rolloff,
    this.priority,
    this.muted,
  );

  final String id;
  final VrWorldAddress world;
  final vm.Vector3 _position;
  final double baseGain;
  final double minDistance;
  final double maxDistance;
  final double rolloff;
  final int priority;
  final bool muted;

  vm.Vector3 get position => _position.clone();
}
