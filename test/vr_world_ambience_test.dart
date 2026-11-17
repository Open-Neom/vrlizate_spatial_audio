import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:vrlizate_spatial_audio/vrlizate_spatial_audio.dart';

void main() {
  test(
    'four original loops are deterministic bounded mono PCM with detail',
    () {
      final distinct = <String>{};
      for (final kind in VrWorldAmbienceKind.values) {
        final wav = VrWorldAmbience.wav(kind);
        expect(wav, orderedEquals(VrWorldAmbience.wav(kind)));
        expect(wav.length, 192044);
        final d = ByteData.sublistView(wav);
        expect(ascii.decode(wav.sublist(0, 4)), 'RIFF');
        expect(d.getUint32(4, Endian.little), wav.length - 8);
        expect(d.getUint16(20, Endian.little), 1);
        expect(d.getUint16(22, Endian.little), 1);
        expect(d.getUint32(24, Endian.little), 16000);
        expect(d.getUint32(28, Endian.little), 32000);
        expect(d.getUint16(32, Endian.little), 2);
        expect(d.getUint16(34, Endian.little), 16);
        expect(d.getUint32(40, Endian.little), wav.length - 44);
        var energy = 0.0, peak = 0;
        for (var at = 44; at < wav.length; at += 2) {
          final sample = d.getInt16(at, Endian.little);
          peak = math.max(peak, sample.abs());
          energy += sample * sample;
        }
        expect(peak, inInclusiveRange(20000, 22000));
        expect(math.sqrt(energy / 96000), greaterThan(1500));
        distinct.add(base64Encode(wav));
      }
      expect(distinct, hasLength(VrWorldAmbienceKind.values.length));
    },
  );

  test('loop seam stays within a normal sample step, without an end click', () {
    for (final kind in VrWorldAmbienceKind.values) {
      final wav = VrWorldAmbience.wav(kind);
      final d = ByteData.sublistView(wav);
      var maxStep = 0;
      for (var at = 46; at < wav.length; at += 2) {
        maxStep = math.max(
          maxStep,
          (d.getInt16(at, Endian.little) - d.getInt16(at - 2, Endian.little))
              .abs(),
        );
      }
      final seam =
          (d.getInt16(44, Endian.little) -
                  d.getInt16(wav.length - 2, Endian.little))
              .abs();
      expect(seam, lessThanOrEqualTo(maxStep), reason: kind.name);
    }
  });

  test(
    'alternate seed changes the original sound without exceeding budgets',
    () {
      final a = VrWorldAmbience.wav(VrWorldAmbienceKind.market, seed: 41);
      final b = VrWorldAmbience.wav(VrWorldAmbienceKind.market, seed: 42);
      expect(a, isNot(orderedEquals(b)));
      expect(
        VrWorldAmbience.wav(
          VrWorldAmbienceKind.neon,
          sampleRate: 22050,
          seconds: 5,
        ).length,
        220544,
      );
    },
  );

  test('rate duration byte and seed limits are checked before allocation', () {
    for (final make in <Uint8List Function()>[
      () => VrWorldAmbience.wav(VrWorldAmbienceKind.market, sampleRate: 48000),
      () => VrWorldAmbience.wav(VrWorldAmbienceKind.neon, seconds: 0),
      () => VrWorldAmbience.wav(VrWorldAmbienceKind.campus, seconds: 9),
      () => VrWorldAmbience.wav(
        VrWorldAmbienceKind.enclave,
        sampleRate: 22050,
        seconds: 8,
      ),
      () => VrWorldAmbience.wav(VrWorldAmbienceKind.market, seed: 0),
    ]) {
      expect(make, throwsArgumentError);
    }
  });
}
