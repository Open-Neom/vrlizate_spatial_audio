import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:vector_math/vector_math.dart' as vm;
import 'package:vrlizate_spatial_audio/vrlizate_spatial_audio.dart';

void main() {
  group('VrProceduralSfx', () {
    test('synthesizes finite, peak-normalized foley waveforms deterministically', () {
      final clickA = VrProceduralSfx.click(volume: 0.8);
      final clickB = VrProceduralSfx.click(volume: 0.8);
      expect(clickA.length, equals(clickB.length));
      expect(clickA, equals(clickB));
      expect(
        clickA.map((v) => v.abs()).reduce((a, b) => a > b ? a : b),
        closeTo(0.8, 1e-4),
      );

      for (final samples in [
        VrProceduralSfx.clack(),
        VrProceduralSfx.whoosh(duration: 0.2),
        VrProceduralSfx.step(),
        VrProceduralSfx.ding(duration: 0.4),
        VrProceduralSfx.pop(),
        VrProceduralSfx.thump(),
        VrProceduralSfx.heartbeat(),
      ]) {
        expect(samples, isNotEmpty);
        expect(samples.every((s) => s.isFinite && s >= -1.0 && s <= 1.0), isTrue);
      }
    });

    test('spatializeStereo and encodeWavPcm16 produce valid stereo WAV bytes', () {
      final mono = VrProceduralSfx.click(sampleRate: 16000);
      final stereo = VrProceduralSfx.spatializeStereo(
        mono: mono,
        source: vm.Vector3(3.0, 0.0, 0.0), // to the right of listener
        listener: vm.Vector3.zero(),
        listenerYaw: 0.0,
      );
      expect(stereo.length, mono.length * 2);

      // Right channel energy should exceed left channel energy for a source at +X
      var leftEnergy = 0.0;
      var rightEnergy = 0.0;
      for (var i = 0; i < mono.length; i++) {
        leftEnergy += stereo[i * 2].abs();
        rightEnergy += stereo[i * 2 + 1].abs();
      }
      expect(rightEnergy, greaterThan(leftEnergy));

      final wav = VrProceduralSfx.encodeWavPcm16(
        stereo,
        sampleRate: 16000,
        channels: 2,
      );
      expect(wav.length, 44 + stereo.length * 2);
      expect(String.fromCharCodes(wav.sublist(0, 4)), 'RIFF');
      expect(String.fromCharCodes(wav.sublist(8, 12)), 'WAVE');
      final bd = ByteData.sublistView(wav);
      expect(bd.getUint16(22, Endian.little), 2); // 2 channels
      expect(bd.getUint32(24, Endian.little), 16000); // sampleRate
    });
  });
}
