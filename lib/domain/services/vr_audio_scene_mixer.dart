import 'package:vector_math/vector_math.dart' as vm;
import 'package:vrlizate_world/vrlizate_world.dart';

import '../../utils/constants/vr_spatial_audio_constants.dart';
import '../../utils/enums/vr_acoustic_environment.dart';
import '../models/vr_acoustic_zone.dart';
import '../models/vr_spatial_audio_emitter.dart';
import '../models/vr_spatial_emitter_mix.dart';
import 'vr_spatial_audio_evaluator.dart';

/// Evaluates multiple spatial audio emitters against a listener pose and
/// active [VrAcousticZone]s, culling inaudible emitters and returning the
/// top prioritized [VrSpatialEmitterMix] entries.
final class VrAudioSceneMixer {
  VrAudioSceneMixer({
    this.maxActiveEmitters = VrSpatialAudioConstants.defaultMaxActiveEmitters,
    this.minAudibleGain = VrSpatialAudioConstants.defaultMinAudibleGain,
  }) {
    if (maxActiveEmitters < 1) {
      throw ArgumentError.value(
        maxActiveEmitters,
        VrSpatialAudioConstants.paramMaxActiveEmitters,
        VrSpatialAudioConstants.errMaxActiveEmitters,
      );
    }
  }

  final int maxActiveEmitters;
  final double minAudibleGain;
  final Map<String, VrAcousticZone> _zones = <String, VrAcousticZone>{};

  List<VrAcousticZone> get zones => List.unmodifiable(_zones.values);

  /// Registers or updates an acoustic [zone].
  void addZone(VrAcousticZone zone) {
    _zones[zone.id] = zone;
  }

  /// Removes the acoustic zone with [zoneId].
  bool removeZone(String zoneId) => _zones.remove(zoneId) != null;

  /// Clears all acoustic zones.
  void clearZones() => _zones.clear();

  /// Resolves the smallest-radius [VrAcousticZone] containing [position] in [world].
  VrAcousticZone? resolveZoneAt(VrWorldAddress world, vm.Vector3 position) {
    VrAcousticZone? best;
    for (final zone in _zones.values) {
      if (zone.world != world) continue;
      if (zone.contains(position)) {
        if (best == null || zone.radiusMeters < best.radiusMeters) {
          best = zone;
        }
      }
    }
    return best;
  }

  /// Evaluates [emitters] for a listener in [listenerWorld] at [listenerPosition]
  /// with head orientation [listenerYaw], returning up to [maxActiveEmitters]
  /// audible mixes ordered by descending priority and gain.
  List<VrSpatialEmitterMix> evaluateScene({
    required VrWorldAddress listenerWorld,
    required vm.Vector3 listenerPosition,
    required double listenerYaw,
    required Iterable<VrSpatialAudioEmitter> emitters,
  }) {
    final listenerZone = resolveZoneAt(listenerWorld, listenerPosition);
    final reverbWetMix =
        listenerZone?.reverbWetMix ??
        VrSpatialAudioConstants.defaultReverbWetMix;
    final lowPassCutoffHz =
        listenerZone?.lowPassCutoffHz ??
        VrSpatialAudioConstants.defaultLowPassCutoffHz;
    final environment =
        listenerZone?.environment ?? VrAcousticEnvironment.openAir;
    final attenuationMultiplier =
        listenerZone?.attenuationMultiplier ??
        VrSpatialAudioConstants.defaultAttenuationMultiplier;

    final candidates = <(VrSpatialEmitterMix, int)>[];
    for (final emitter in emitters) {
      if (emitter.muted || emitter.world != listenerWorld) continue;
      final srcPos = emitter.position;
      final effectiveMaxDistance =
          (emitter.maxDistance * attenuationMultiplier).clamp(
            emitter.minDistance + 1e-3,
            double.maxFinite,
          );
      final (rawGain, pan) = VrSpatialAudioEvaluator.evaluate(
        source: srcPos,
        listener: listenerPosition,
        listenerYaw: listenerYaw,
        minDistance: emitter.minDistance,
        maxDistance: effectiveMaxDistance,
        rolloff: emitter.rolloff,
      );
      final finalGain = (rawGain * emitter.baseGain).clamp(0.0, 1.0);
      if (finalGain < minAudibleGain) continue;

      final mix = VrSpatialEmitterMix(
        emitterId: emitter.id,
        gain: finalGain,
        pan: pan,
        distanceMeters: srcPos.distanceTo(listenerPosition),
        reverbWetMix: reverbWetMix,
        lowPassCutoffHz: lowPassCutoffHz,
        environment: environment,
      );
      candidates.add((mix, emitter.priority));
    }

    candidates.sort((a, b) {
      final pCmp = b.$2.compareTo(a.$2);
      if (pCmp != 0) return pCmp;
      final gCmp = b.$1.gain.compareTo(a.$1.gain);
      if (gCmp != 0) return gCmp;
      return a.$1.emitterId.compareTo(b.$1.emitterId);
    });

    final count = candidates.length < maxActiveEmitters
        ? candidates.length
        : maxActiveEmitters;
    return List.unmodifiable([
      for (var i = 0; i < count; i++) candidates[i].$1,
    ]);
  }
}
