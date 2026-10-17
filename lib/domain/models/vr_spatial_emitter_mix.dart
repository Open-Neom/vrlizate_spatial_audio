import '../../utils/enums/vr_acoustic_environment.dart';

/// Evaluated spatial audio mix state for a single [VrSpatialAudioEmitter].
final class VrSpatialEmitterMix {
  const VrSpatialEmitterMix({
    required this.emitterId,
    required this.gain,
    required this.pan,
    required this.distanceMeters,
    required this.reverbWetMix,
    required this.lowPassCutoffHz,
    required this.environment,
  });

  final String emitterId;
  final double gain;
  final double pan;
  final double distanceMeters;
  final double reverbWetMix;
  final double lowPassCutoffHz;
  final VrAcousticEnvironment environment;
}
