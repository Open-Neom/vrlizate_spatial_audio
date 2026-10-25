// Original Open Neom procedural ambience. MIT; no recordings or external assets.
import 'dart:math' as math;
import 'dart:typed_data';

import 'vr_procedural_sfx.dart';

enum VrWorldAmbienceKind { market, neon, campus, enclave }

/// Offline authoring of short periodic mono loops, not a native audio engine.
/// No speech or music is sampled. Playback remains owned by neom_sound.
abstract final class VrWorldAmbience {
  static Uint8List wav(
    VrWorldAmbienceKind kind, {
    int sampleRate = 16000,
    int seconds = 6,
    int seed = 20261025,
  }) {
    if (!const {16000, 22050}.contains(sampleRate) ||
        seconds < 1 ||
        seconds > 8 ||
        44 + sampleRate * seconds * 2 > 256 * 1024 ||
        seed < 1 ||
        seed > 2147483646) {
      throw ArgumentError('Use a bounded mono ambient loop.');
    }
    final n = sampleRate * seconds;
    final samples = Float32List(n);
    var peak = 0.0;
    for (var i = 0; i < n; i++) {
      final u = i / n;
      double osc(double hz, [double phase = 0]) =>
          math.sin(2 * math.pi * (hz * seconds).round() * u + phase);
      final air = _noise(u, 79, seed + kind.index * 17);
      final fine = _noise(u, 997, seed + 53 + kind.index * 31);
      double chime(double start, double hz) {
        final t = ((u - start) % 1) * seconds;
        if (t >= .7) return 0;
        final envelope =
            math.pow(math.sin(math.pi * t / .7), 2) * math.exp(-t * 3.5);
        return envelope * (osc(hz) + .35 * osc(hz * 2));
      }

      final value = switch (kind) {
        VrWorldAmbienceKind.market =>
          .18 * air +
              .035 * fine +
              .09 * chime(.18, 528) +
              .07 * chime(.64, 704),
        VrWorldAmbienceKind.neon =>
          .14 * osc(48) +
              .065 * osc(96, .3) +
              .03 * osc(192, .8) +
              (.06 + .035 * osc(1 / seconds)) * fine +
              .045 * air,
        VrWorldAmbienceKind.campus =>
          .09 * osc(60) +
              .035 * osc(120, .8) +
              .055 * air +
              .045 * fine * math.pow(.5 + .5 * osc(2), 2) +
              .035 * chime(.42, 396),
        VrWorldAmbienceKind.enclave =>
          .035 * osc(72) +
              .09 * fine +
              .06 * air +
              .13 * _rain(u, seconds, seed),
      };
      samples[i] = value;
      peak = math.max(peak, value.abs());
    }
    final gain = peak > 0 ? .65 / peak : 0.0;
    for (var i = 0; i < n; i++) {
      samples[i] *= gain;
    }
    return VrProceduralSfx.encodeWavPcm16(
      samples,
      sampleRate: sampleRate,
      channels: 1,
    );
  }

  static double _rain(double u, int seconds, int seed) {
    const drops = 24;
    final cycle = u * drops;
    final index = cycle.floor();
    final t = cycle - index;
    final pitch = 620 + _hash(index, seed) * 420;
    final hz = (pitch * seconds).round();
    // Each pulse starts and ends at zero; its frequency repeats over the loop.
    final envelope = math.pow(math.sin(math.pi * t), 2) * math.exp(-t * 5);
    return envelope * math.sin(2 * math.pi * hz * u);
  }

  static double _noise(double u, int period, int seed) {
    final at = u * period;
    final index = at.floor();
    final f = at - index;
    final t = f * f * (3 - 2 * f);
    return (_hash(index % period, seed) * (1 - t) +
                _hash((index + 1) % period, seed) * t) *
            2 -
        1;
  }

  static double _hash(int index, int seed) {
    var n = ((index + 1) * 374761393 + seed * 668265263) & 0x7fffffff;
    n = ((n ^ (n >> 13)) * 1274126177) & 0x7fffffff;
    return (n ^ (n >> 16)) / 0x7fffffff;
  }
}
