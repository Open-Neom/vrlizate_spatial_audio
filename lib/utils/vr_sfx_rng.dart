import 'dart:math' as math;

/// Deterministic 32-bit PRNG used for reproducible procedural sound synthesis.
final class VrSfxRng {
  VrSfxRng(int seed) : _state = seed & 0xFFFFFFFF;
  int _state;

  double nextDouble() {
    _state = (_state + 0x6D2B79F5) & 0xFFFFFFFF;
    var t = _imul32(_state ^ (_state >>> 15), 1 | _state);
    t = (t + _imul32(t ^ (t >>> 7), 61 | t)) ^ t;
    t = (t ^ (t >>> 14)) & 0xFFFFFFFF;
    return t / 4294967296.0;
  }

  double nextGaussian() {
    final u1 = math.max(1e-7, nextDouble());
    final u2 = nextDouble();
    return math.sqrt(-2.0 * math.log(u1)) * math.cos(2.0 * math.pi * u2);
  }

  static int _imul32(int a, int b) {
    final ah = (a >>> 16) & 0xFFFF;
    final al = a & 0xFFFF;
    final bh = (b >>> 16) & 0xFFFF;
    final bl = b & 0xFFFF;
    return ((al * bl) + (((ah * bl + al * bh) & 0xFFFF) << 16)) & 0xFFFFFFFF;
  }
}
