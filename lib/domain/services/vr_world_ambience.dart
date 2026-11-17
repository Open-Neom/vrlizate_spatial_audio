// Original Open Neom procedural ambience. MIT; no recordings or external assets.
import 'dart:math' as math;
import 'dart:typed_data';

import 'vr_procedural_sfx.dart';

enum VrWorldAmbienceKind {
  market,
  neon,
  campus,
  enclave,
  waterfallAtrium,
  canalFountain,
  plazaMurmur,
  oceanReef,
  biodiversityWind,
  solarBreeze,
  cavernSpace,
}

/// Offline authoring of short periodic mono loops, not a native audio engine.
/// No speech or music is sampled. Playback remains owned by neom_sound.
abstract final class VrWorldAmbience {
  /// Maps any VRlizate ecosystem, mall, arcade, or `.vrlw` biome identifier to
  /// its matching zero-asset procedural ambient bed for instant offline play.
  static VrWorldAmbienceKind resolveKind(String ecosystemOrWorldId) {
    final id = ecosystemOrWorldId.trim().toLowerCase();
    if (id.contains('dubai') || id.contains('waterfall')) {
      return VrWorldAmbienceKind.waterfallAtrium;
    }
    if (id.contains('marina') ||
        id.contains('canal') ||
        id.contains('artz') ||
        id.contains('oasis')) {
      return VrWorldAmbienceKind.canalFountain;
    }
    if (id.contains('milano') ||
        id.contains('galleria') ||
        id.contains('home') ||
        id.contains('plaza') ||
        id.contains('museum')) {
      return VrWorldAmbienceKind.plazaMurmur;
    }
    if (id.contains('coral') ||
        id.contains('coast') ||
        id.contains('archipelago') ||
        id.contains('harbor') ||
        id.contains('ocean') ||
        id.contains('openworld')) {
      return VrWorldAmbienceKind.oceanReef;
    }
    if (id.contains('wetland') ||
        id.contains('rainforest') ||
        id.contains('forest') ||
        id.contains('grove') ||
        id.contains('sakura') ||
        id.contains('savanna') ||
        id.contains('fungal')) {
      return VrWorldAmbienceKind.biodiversityWind;
    }
    if (id.contains('solar') ||
        id.contains('festival') ||
        id.contains('desert') ||
        id.contains('canyon')) {
      return VrWorldAmbienceKind.solarBreeze;
    }
    if (id.contains('neon') ||
        id.contains('synth') ||
        id.contains('arcade') ||
        id.contains('underrun')) {
      return VrWorldAmbienceKind.neon;
    }
    if (id.contains('campus') || id.contains('tech')) {
      return VrWorldAmbienceKind.campus;
    }
    if (id.contains('enclave') || id.contains('cypher')) {
      return VrWorldAmbienceKind.enclave;
    }
    if (id.contains('urban') || id.contains('market')) {
      return VrWorldAmbienceKind.market;
    }
    return VrWorldAmbienceKind.cavernSpace;
  }

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
        VrWorldAmbienceKind.waterfallAtrium =>
          .22 * _noise(u, 311, seed + 101) +
              .14 * fine * (.75 + .25 * osc(0.5)) +
              .12 * air +
              .06 * osc(54) +
              .08 * _rain(u, seconds, seed + 9),
        VrWorldAmbienceKind.canalFountain =>
          .14 * _noise(u, 251, seed + 211) * (.65 + .35 * osc(0.5)) +
              .09 * air +
              .05 * fine +
              .11 * _rain(u, seconds, seed + 37) +
              .045 * chime(.32, 528),
        VrWorldAmbienceKind.plazaMurmur =>
          .15 * _noise(u, 113, seed + 307) * (.70 + .30 * osc(0.34)) +
              .07 * air +
              .05 * osc(132) +
              .035 * osc(198, .5) +
              .055 * chime(.24, 528) +
              .045 * chime(.74, 660),
        VrWorldAmbienceKind.oceanReef =>
          (.05 + .22 * math.pow(.5 + .5 * osc(0.34), 1.8)) *
                  _noise(u, 347, seed + 401) +
              .08 * air +
              .045 * osc(64) +
              .05 * chime(.52, 440),
        VrWorldAmbienceKind.biodiversityWind =>
          (.08 + .12 * (.5 + .5 * osc(0.5))) * air +
              .06 * _noise(u, 463, seed + 503) +
              .07 * _chirp(u, seconds, seed + 19) +
              .04 * chime(.62, 594),
        VrWorldAmbienceKind.solarBreeze =>
          .11 * air * (.72 + .28 * osc(0.34)) +
              .055 * osc(108) +
              .04 * osc(162, .4) +
              .07 * chime(.20, 432) +
              .055 * chime(.68, 648),
        VrWorldAmbienceKind.cavernSpace =>
          .12 * osc(55) +
              .07 * osc(110, .6) +
              .04 * osc(165, 1.1) +
              .06 * air +
              .065 * chime(.45, 550),
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

  static double _chirp(double u, int seconds, int seed) {
    const calls = 10;
    final cycle = u * calls;
    final index = cycle.floor();
    final t = cycle - index;
    if (t > .32) return 0;
    final norm = t / .32;
    final baseHz = 1150 + _hash(index, seed) * 650;
    final hz = (baseHz * seconds).round();
    final env = math.pow(math.sin(math.pi * norm), 2);
    return env * math.sin(2 * math.pi * hz * u);
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
