import 'package:vector_math/vector_math.dart' as vm;
import 'package:vrlizate_world/vrlizate_world.dart';

import '../../utils/constants/vr_spatial_audio_constants.dart';
import '../../utils/enums/vr_acoustic_environment.dart';

/// Spherical acoustic zone in a [VrWorldAddress] defining reverb, low-pass
/// filtering, and distance-attenuation scaling.
final class VrAcousticZone {
  factory VrAcousticZone({
    required String id,
    required VrWorldAddress world,
    required vm.Vector3 center,
    required double radiusMeters,
    VrAcousticEnvironment environment = VrAcousticEnvironment.openAir,
    double reverbWetMix = VrSpatialAudioConstants.defaultReverbWetMix,
    double lowPassCutoffHz = VrSpatialAudioConstants.defaultLowPassCutoffHz,
    double attenuationMultiplier =
        VrSpatialAudioConstants.defaultAttenuationMultiplier,
  }) {
    VrWorldValidator.validateIdentifier(id, VrWorldConstants.paramId);
    if (!center.x.isFinite || !center.y.isFinite || !center.z.isFinite) {
      throw ArgumentError.value(
        center,
        VrSpatialAudioConstants.paramCenter,
        VrSpatialAudioConstants.errCoordinateFinite,
      );
    }
    if (!radiusMeters.isFinite || radiusMeters <= 0) {
      throw ArgumentError.value(
        radiusMeters,
        VrSpatialAudioConstants.paramRadiusMeters,
        VrSpatialAudioConstants.errRadiusPositive,
      );
    }
    if (!reverbWetMix.isFinite || reverbWetMix < 0 || reverbWetMix > 1) {
      throw ArgumentError.value(
        reverbWetMix,
        VrSpatialAudioConstants.paramReverbWetMix,
        VrSpatialAudioConstants.errReverbWetMixRange,
      );
    }
    if (!lowPassCutoffHz.isFinite ||
        lowPassCutoffHz < VrSpatialAudioConstants.minLowPassCutoffHz ||
        lowPassCutoffHz > VrSpatialAudioConstants.maxLowPassCutoffHz) {
      throw ArgumentError.value(
        lowPassCutoffHz,
        VrSpatialAudioConstants.paramLowPassCutoffHz,
        VrSpatialAudioConstants.errLowPassCutoffRange,
      );
    }
    if (!attenuationMultiplier.isFinite || attenuationMultiplier <= 0) {
      throw ArgumentError.value(
        attenuationMultiplier,
        VrSpatialAudioConstants.paramAttenuationMultiplier,
        VrSpatialAudioConstants.errAttenuationMultiplierRange,
      );
    }
    return VrAcousticZone._(
      id,
      world,
      center.clone(),
      radiusMeters,
      environment,
      reverbWetMix,
      lowPassCutoffHz,
      attenuationMultiplier,
    );
  }

  /// Creates a [VrAcousticZone] using canonical parameters for [environment].
  factory VrAcousticZone.fromEnvironment({
    required String id,
    required VrWorldAddress world,
    required vm.Vector3 center,
    required double radiusMeters,
    required VrAcousticEnvironment environment,
  }) {
    final (reverb, cutoff, mult) = switch (environment) {
      VrAcousticEnvironment.openAir => (
        VrSpatialAudioConstants.defaultReverbWetMix,
        VrSpatialAudioConstants.defaultLowPassCutoffHz,
        VrSpatialAudioConstants.defaultAttenuationMultiplier,
      ),
      VrAcousticEnvironment.smallRoom => (
        VrSpatialAudioConstants.smallRoomReverbWetMix,
        VrSpatialAudioConstants.smallRoomLowPassCutoffHz,
        VrSpatialAudioConstants.defaultAttenuationMultiplier,
      ),
      VrAcousticEnvironment.concertHall => (
        VrSpatialAudioConstants.concertHallReverbWetMix,
        VrSpatialAudioConstants.concertHallLowPassCutoffHz,
        VrSpatialAudioConstants.concertHallAttenuationMultiplier,
      ),
      VrAcousticEnvironment.corridor => (
        VrSpatialAudioConstants.corridorReverbWetMix,
        VrSpatialAudioConstants.corridorLowPassCutoffHz,
        VrSpatialAudioConstants.defaultAttenuationMultiplier,
      ),
      VrAcousticEnvironment.underwater => (
        VrSpatialAudioConstants.underwaterReverbWetMix,
        VrSpatialAudioConstants.underwaterLowPassCutoffHz,
        VrSpatialAudioConstants.underwaterAttenuationMultiplier,
      ),
      VrAcousticEnvironment.cyberArena => (
        VrSpatialAudioConstants.cyberArenaReverbWetMix,
        VrSpatialAudioConstants.cyberArenaLowPassCutoffHz,
        VrSpatialAudioConstants.concertHallAttenuationMultiplier,
      ),
    };
    return VrAcousticZone(
      id: id,
      world: world,
      center: center,
      radiusMeters: radiusMeters,
      environment: environment,
      reverbWetMix: reverb,
      lowPassCutoffHz: cutoff,
      attenuationMultiplier: mult,
    );
  }

  VrAcousticZone._(
    this.id,
    this.world,
    this._center,
    this.radiusMeters,
    this.environment,
    this.reverbWetMix,
    this.lowPassCutoffHz,
    this.attenuationMultiplier,
  );

  final String id;
  final VrWorldAddress world;
  final vm.Vector3 _center;
  final double radiusMeters;
  final VrAcousticEnvironment environment;
  final double reverbWetMix;
  final double lowPassCutoffHz;
  final double attenuationMultiplier;

  vm.Vector3 get center => _center.clone();

  /// Returns `true` when [position] lies within [radiusMeters] of [center].
  bool contains(vm.Vector3 position) =>
      _center.distanceToSquared(position) <= radiusMeters * radiusMeters;
}
