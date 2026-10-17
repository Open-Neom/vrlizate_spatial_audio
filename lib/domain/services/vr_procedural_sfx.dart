import 'dart:math' as math;
import 'dart:typed_data';

import 'package:vector_math/vector_math.dart' as vm;

import '../../utils/constants/vr_spatial_audio_constants.dart';
import '../../utils/vr_sfx_rng.dart';
import 'vr_spatial_audio_evaluator.dart';

/// Procedural foley & spatial sound effect synthesizer in pure Dart.
///
/// Generates crisp, zero-asset mono or spatialized stereo waveforms and
/// encodes ready-to-play 16-bit PCM WAV bytes on the fly.
abstract final class VrProceduralSfx {
  static const int defaultSampleRate =
      VrSpatialAudioConstants.defaultSampleRate;

  /// Tactile UI / plastic snap click (~60 ms).
  static Float32List click({
    double pitch = 1.0,
    double volume = 1.0,
    int sampleRate = defaultSampleRate,
    int seed = VrSpatialAudioConstants.defaultClickSeed,
  }) {
    const duration = VrSpatialAudioConstants.clickDurationSeconds;
    final n = (duration * sampleRate).round();
    final rng = VrSfxRng(seed);
    final tr = _highPass(_noise(n, rng), 2500.0, sampleRate);
    final envTr = _envExp(n, 0.0015, sampleRate);
    final out = Float32List(n);

    final p1 = rng.nextDouble() * 6.0;
    final p2 = rng.nextDouble() * 6.0;
    final p3 = rng.nextDouble() * 6.0;
    for (var i = 0; i < n; i++) {
      final t = i / sampleRate;
      final r1 =
          0.6 *
          math.sin(2.0 * math.pi * 2900.0 * pitch * t + p1) *
          math.exp(-t / 0.012);
      final r2 =
          0.4 *
          math.sin(2.0 * math.pi * 4600.0 * pitch * t + p2) *
          math.exp(-t / 0.008);
      final r3 =
          0.35 *
          math.sin(2.0 * math.pi * 1500.0 * pitch * t + p3) *
          math.exp(-t / 0.018);
      final body =
          0.5 *
          math.sin(2.0 * math.pi * 190.0 * pitch * t) *
          math.exp(-t / 0.01);
      out[i] = tr[i] * envTr[i] * 0.8 + r1 + r2 + r3 + body;
    }
    return _normalize(out, peak: volume);
  }

  /// Wood/plastic block impact clack (~90 ms).
  static Float32List clack({
    double pitch = 1.0,
    double volume = 1.0,
    int sampleRate = defaultSampleRate,
    int seed = VrSpatialAudioConstants.defaultClackSeed,
  }) {
    const duration = VrSpatialAudioConstants.clackDurationSeconds;
    final n = (duration * sampleRate).round();
    final rng = VrSfxRng(seed);
    final p = pitch * (0.85 + rng.nextDouble() * 0.3);
    final tr = _highPass(_noise(n, rng), 1200.0, sampleRate);
    final out = Float32List(n);
    for (var i = 0; i < n; i++) {
      final t = i / sampleRate;
      final r1 =
          0.6 * math.sin(2.0 * math.pi * 1200.0 * p * t) * math.exp(-t / 0.02);
      final r2 =
          0.5 * math.sin(2.0 * math.pi * 2300.0 * p * t) * math.exp(-t / 0.012);
      final r3 =
          0.5 * math.sin(2.0 * math.pi * 380.0 * p * t) * math.exp(-t / 0.03);
      out[i] = tr[i] * math.exp(-t / 0.004) + r1 + r2 + r3;
    }
    return _normalize(out, peak: volume);
  }

  /// Swept bandpass whoosh for VR teleportation, panel transitions, or fast head turns.
  static Float32List whoosh({
    double duration = VrSpatialAudioConstants.defaultWhooshDurationSeconds,
    double volume = 1.0,
    int sampleRate = defaultSampleRate,
    int seed = VrSpatialAudioConstants.defaultWhooshSeed,
  }) {
    final d = math.max(
      VrSpatialAudioConstants.minWhooshDurationSeconds,
      duration,
    );
    final n = (d * sampleRate).round();
    final rng = VrSfxRng(seed);
    final raw = _noise(n, rng);
    final out = Float32List(n);
    final blockSize = math.max(64, (sampleRate * 0.01).round());

    for (var i = 0; i < n; i += blockSize) {
      final hi = math.min(n, i + blockSize);
      final fCenter = 600.0 + 2600.0 * math.sin(math.pi * i / n);
      final startIdx = math.max(0, i - blockSize * 3);
      final slice = Float32List.sublistView(raw, startIdx, hi);
      final filtered = _bandPass(
        slice,
        fCenter * 0.7,
        math.min(fCenter * 1.3, sampleRate * 0.45),
        sampleRate,
      );
      final offset = filtered.length - (hi - i);
      for (var j = i; j < hi; j++) {
        final t = j / sampleRate;
        final win = math.sin(math.pi * t / d);
        out[j] = filtered[offset + (j - i)] * win * win;
      }
    }
    return _normalize(out, peak: volume);
  }

  /// Crisp footstep transient (~50 ms) for VR walking locomotion.
  static Float32List step({
    double volume = 1.0,
    int sampleRate = defaultSampleRate,
    int seed = VrSpatialAudioConstants.defaultStepSeed,
  }) {
    const duration = VrSpatialAudioConstants.stepDurationSeconds;
    final n = (duration * sampleRate).round();
    final rng = VrSfxRng(seed);
    final tr = _highPass(_noise(n, rng), 1800.0, sampleRate);
    final out = Float32List(n);
    for (var i = 0; i < n; i++) {
      final t = i / sampleRate;
      out[i] =
          tr[i] * math.exp(-t / 0.004) +
          0.5 * math.sin(2.0 * math.pi * 2200.0 * t) * math.exp(-t / 0.006);
    }
    return _normalize(out, peak: volume);
  }

  /// Harmonic 5-partial bell chime for gaze dwell selection or task completion.
  static Float32List ding({
    double volume = 1.0,
    double duration = VrSpatialAudioConstants.defaultDingDurationSeconds,
    int sampleRate = defaultSampleRate,
  }) {
    final d = math.max(
      VrSpatialAudioConstants.minDingDurationSeconds,
      duration,
    );
    final n = (d * sampleRate).round();
    final out = Float32List(n);
    const partials = <(double freq, double amp, double tau)>[
      (1318.0, 1.0, 0.6),
      (2637.0, 0.5, 0.35),
      (3951.0, 0.3, 0.2),
      (1976.0, 0.25, 0.5),
      (5274.0, 0.15, 0.1),
    ];
    for (var i = 0; i < n; i++) {
      final t = i / sampleRate;
      var sum = 0.0;
      for (final (f, a, tau) in partials) {
        if (f < sampleRate * 0.48) {
          sum += a * math.sin(2.0 * math.pi * f * t) * math.exp(-t / tau);
        }
      }
      out[i] = sum;
    }
    return _normalize(out, peak: volume);
  }

  /// Upward frequency chirp (`500 Hz -> 1900 Hz`, ~180 ms) for spatial bubble/panel pop-in.
  static Float32List pop({
    double volume = 1.0,
    int sampleRate = defaultSampleRate,
  }) {
    const duration = VrSpatialAudioConstants.popDurationSeconds;
    final n = (duration * sampleRate).round();
    final out = Float32List(n);
    var phase = 0.0;
    for (var i = 0; i < n; i++) {
      final t = i / sampleRate;
      final f = 500.0 + 1400.0 * (t / duration);
      phase += (2.0 * math.pi * f) / sampleRate;
      out[i] = math.sin(phase) * math.exp(-t / 0.05);
    }
    return _normalize(out, peak: volume);
  }

  /// Low-frequency physical thump (~350 ms).
  static Float32List thump({
    double volume = 1.0,
    double frequency = VrSpatialAudioConstants.defaultThumpFrequencyHz,
    int sampleRate = defaultSampleRate,
    int seed = VrSpatialAudioConstants.defaultThumpSeed,
  }) {
    const duration = VrSpatialAudioConstants.thumpDurationSeconds;
    final n = (duration * sampleRate).round();
    final rng = VrSfxRng(seed);
    final lowNoise = _lowPass(_noise(n, rng), 300.0, sampleRate);
    final out = Float32List(n);
    for (var i = 0; i < n; i++) {
      final t = i / sampleRate;
      final sub =
          math.sin(2.0 * math.pi * frequency * t * (1.0 - 0.3 * t)) *
          math.exp(-t / 0.07);
      out[i] = sub + lowNoise[i] * math.exp(-t / 0.02) * 0.5;
    }
    return _normalize(out, peak: volume);
  }

  /// Double-pulse low-frequency heartbeat (`55 Hz` + delayed `50 Hz`).
  static Float32List heartbeat({
    double volume = 1.0,
    int sampleRate = defaultSampleRate,
  }) {
    final first = thump(
      volume: 1.0,
      frequency: VrSpatialAudioConstants.heartbeatFirstFrequencyHz,
      sampleRate: sampleRate,
    );
    final second = thump(
      volume: VrSpatialAudioConstants.heartbeatSecondVolume,
      frequency: VrSpatialAudioConstants.heartbeatSecondFrequencyHz,
      sampleRate: sampleRate,
    );
    final delay = (VrSpatialAudioConstants.heartbeatDelaySeconds * sampleRate)
        .round();
    final out = Float32List.fromList(first);
    for (var i = delay; i < out.length && (i - delay) < second.length; i++) {
      out[i] += second[i - delay];
    }
    return _normalize(out, peak: volume);
  }

  /// Spatializes a mono buffer into interleaved stereo `[L0, R0, L1, R1, ...]`.
  static Float32List spatializeStereo({
    required Float32List mono,
    required vm.Vector3 source,
    required vm.Vector3 listener,
    required double listenerYaw,
    double minDistance = VrSpatialAudioConstants.defaultMinDistance,
    double maxDistance = VrSpatialAudioConstants.defaultMaxDistance,
    double rolloff = VrSpatialAudioConstants.defaultRolloff,
  }) {
    final (gain, pan) = VrSpatialAudioEvaluator.evaluate(
      source: source,
      listener: listener,
      listenerYaw: listenerYaw,
      minDistance: minDistance,
      maxDistance: maxDistance,
      rolloff: rolloff,
    );
    return panMonoToStereo(mono, gain: gain, pan: pan);
  }

  /// Converts a [mono] buffer into interleaved stereo `[L0, R0, L1, R1, ...]`.
  static Float32List panMonoToStereo(
    Float32List mono, {
    double gain = 1.0,
    double pan = 0.0,
  }) {
    final g = gain.clamp(0.0, 2.0);
    final p = pan.clamp(-1.0, 1.0);
    final angle = (p + 1.0) * (math.pi / 4.0);
    final leftGain = g * math.cos(angle);
    final rightGain = g * math.sin(angle);
    final stereo = Float32List(mono.length * 2);
    for (var i = 0; i < mono.length; i++) {
      final s = mono[i];
      stereo[i * 2] = s * leftGain;
      stereo[i * 2 + 1] = s * rightGain;
    }
    return stereo;
  }

  /// Encodes mono (`channels = 1`) or interleaved stereo (`channels = 2`)
  /// `Float32List` samples (`-1.0..1.0`) into a 16-bit PCM RIFF/WAVE buffer.
  static Uint8List encodeWavPcm16(
    Float32List samples, {
    int sampleRate = defaultSampleRate,
    int channels = 1,
  }) {
    if (channels != 1 && channels != 2) {
      throw ArgumentError.value(
        channels,
        VrSpatialAudioConstants.paramChannels,
        VrSpatialAudioConstants.errWavChannels,
      );
    }
    final dataSize = samples.length * VrSpatialAudioConstants.wavBytesPerSample;
    final totalSize = VrSpatialAudioConstants.wavHeaderBytes + dataSize;
    final bytes = ByteData(totalSize);

    void writeAscii(int offset, String text) {
      for (var i = 0; i < text.length; i++) {
        bytes.setUint8(offset + i, text.codeUnitAt(i));
      }
    }

    writeAscii(0, VrSpatialAudioConstants.wavRiffTag);
    bytes.setUint32(4, totalSize - 8, Endian.little);
    writeAscii(8, VrSpatialAudioConstants.wavWaveTag);
    writeAscii(12, VrSpatialAudioConstants.wavFmtTag);
    bytes.setUint32(
      16,
      VrSpatialAudioConstants.wavPcmChunkSize,
      Endian.little,
    );
    bytes.setUint16(20, VrSpatialAudioConstants.wavPcmFormat, Endian.little);
    bytes.setUint16(22, channels, Endian.little);
    bytes.setUint32(24, sampleRate, Endian.little);
    bytes.setUint32(
      28,
      sampleRate * channels * VrSpatialAudioConstants.wavBytesPerSample,
      Endian.little,
    );
    bytes.setUint16(
      32,
      channels * VrSpatialAudioConstants.wavBytesPerSample,
      Endian.little,
    );
    bytes.setUint16(
      34,
      VrSpatialAudioConstants.wavBitsPerSample,
      Endian.little,
    );
    writeAscii(36, VrSpatialAudioConstants.wavDataTag);
    bytes.setUint32(40, dataSize, Endian.little);

    var offset = VrSpatialAudioConstants.wavHeaderBytes;
    for (var i = 0; i < samples.length; i++) {
      final clamped = samples[i].clamp(-1.0, 1.0);
      final pcm = (clamped * VrSpatialAudioConstants.pcm16Scale)
          .round()
          .clamp(
            VrSpatialAudioConstants.pcm16Min,
            VrSpatialAudioConstants.pcm16Max,
          );
      bytes.setInt16(offset, pcm, Endian.little);
      offset += VrSpatialAudioConstants.wavBytesPerSample;
    }
    return bytes.buffer.asUint8List();
  }

  static Float32List _envExp(int n, double tau, int sr) {
    final out = Float32List(n);
    for (var i = 0; i < n; i++) {
      out[i] = math.exp(-(i / sr) / tau);
    }
    return out;
  }

  static Float32List _noise(int n, VrSfxRng rng) {
    final out = Float32List(n);
    for (var i = 0; i < n; i++) {
      out[i] = rng.nextGaussian();
    }
    return out;
  }

  static Float32List _normalize(Float32List x, {double peak = 1.0}) {
    var maxAbs = 0.0;
    for (var i = 0; i < x.length; i++) {
      final a = x[i].abs();
      if (a > maxAbs) maxAbs = a;
    }
    if (maxAbs <= 1e-9) return x;
    final scale = peak / maxAbs;
    for (var i = 0; i < x.length; i++) {
      x[i] = (x[i] * scale).clamp(-1.0, 1.0);
    }
    return x;
  }

  static Float32List _lowPass(Float32List x, double cutoffHz, int sr) {
    final f0 = cutoffHz.clamp(20.0, sr * 0.48);
    final w0 = 2.0 * math.pi * f0 / sr;
    final cosW = math.cos(w0);
    final alpha = math.sin(w0) / math.sqrt2;
    final b0 = (1.0 - cosW) / 2.0;
    final b1 = 1.0 - cosW;
    final b2 = (1.0 - cosW) / 2.0;
    final a0 = 1.0 + alpha;
    final a1 = -2.0 * cosW;
    final a2 = 1.0 - alpha;
    return _biquad(x, b0 / a0, b1 / a0, b2 / a0, a1 / a0, a2 / a0);
  }

  static Float32List _highPass(Float32List x, double cutoffHz, int sr) {
    final f0 = cutoffHz.clamp(20.0, sr * 0.48);
    final w0 = 2.0 * math.pi * f0 / sr;
    final cosW = math.cos(w0);
    final alpha = math.sin(w0) / math.sqrt2;
    final b0 = (1.0 + cosW) / 2.0;
    final b1 = -(1.0 + cosW);
    final b2 = (1.0 + cosW) / 2.0;
    final a0 = 1.0 + alpha;
    final a1 = -2.0 * cosW;
    final a2 = 1.0 - alpha;
    return _biquad(x, b0 / a0, b1 / a0, b2 / a0, a1 / a0, a2 / a0);
  }

  static Float32List _bandPass(
    Float32List x,
    double lowHz,
    double highHz,
    int sr,
  ) {
    final lo = lowHz.clamp(20.0, sr * 0.44);
    final hi = highHz.clamp(lo + 20.0, sr * 0.48);
    final f0 = math.sqrt(lo * hi);
    final bw = math.max(20.0, hi - lo);
    final q = (f0 / bw).clamp(0.25, 12.0);
    final w0 = 2.0 * math.pi * f0 / sr;
    final cosW = math.cos(w0);
    final alpha = math.sin(w0) / (2.0 * q);
    final b0 = alpha;
    const b1 = 0.0;
    final b2 = -alpha;
    final a0 = 1.0 + alpha;
    final a1 = -2.0 * cosW;
    final a2 = 1.0 - alpha;
    return _biquad(x, b0 / a0, b1 / a0, b2 / a0, a1 / a0, a2 / a0);
  }

  static Float32List _biquad(
    Float32List x,
    double b0,
    double b1,
    double b2,
    double a1,
    double a2,
  ) {
    final out = Float32List(x.length);
    var x1 = 0.0;
    var x2 = 0.0;
    var y1 = 0.0;
    var y2 = 0.0;
    for (var i = 0; i < x.length; i++) {
      final x0 = x[i];
      final y0 = b0 * x0 + b1 * x1 + b2 * x2 - a1 * y1 - a2 * y2;
      out[i] = y0;
      x2 = x1;
      x1 = x0;
      y2 = y1;
      y1 = y0;
    }
    return out;
  }
}
