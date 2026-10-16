import 'dart:math' as math;

import 'package:test/test.dart';
import 'package:vector_math/vector_math.dart' as vm;
import 'package:vrlizate_spatial_audio/vrlizate_spatial_audio.dart';

void main() {
  group('legacy spatial curve', () {
    (double, double) evaluate(vm.Vector3 source, {double yaw = 0}) =>
        VrSpatialAudioEvaluator.evaluate(
          source: source,
          listener: vm.Vector3.zero(),
          listenerYaw: yaw,
          minDistance: 1,
          maxDistance: 20,
        );

    test('preserves existing gain at near, mid and audible boundary', () {
      expect(evaluate(vm.Vector3.zero()), (1.0, 0.0));
      expect(evaluate(vm.Vector3(0, 0, -0.5)).$1, closeTo(.975, 1e-12));
      expect(evaluate(vm.Vector3(0, 0, -1)).$1, closeTo(.95, 1e-12));
      expect(evaluate(vm.Vector3(0, 0, -3)).$1, closeTo(.85 / 3, 1e-12));
      expect(evaluate(vm.Vector3(0, 0, -20)), (0.0, 0.0));
      expect(evaluate(vm.Vector3(0, 0, -21)), (0.0, 0.0));
    });

    test('balance follows head yaw without changing distance gain', () {
      final right = evaluate(vm.Vector3(4, 0, 0));
      final left = evaluate(vm.Vector3(-4, 0, 0));
      final rotated = evaluate(vm.Vector3(4, 0, 0), yaw: math.pi / 2);
      expect(right.$2, closeTo(1, 1e-12));
      expect(left.$2, closeTo(-1, 1e-12));
      expect(rotated.$2, closeTo(0, 1e-12));
      expect(rotated.$1, closeTo(right.$1, 1e-12));
    });

    test(
      'vertical separation attenuates without inventing stereo direction',
      () {
        final above = evaluate(vm.Vector3(0, 4, 0));
        expect(above.$1, closeTo(.2, 1e-12));
        expect(above.$2, 0);
      },
    );

    test('zero rolloff retains the distance fade', () {
      final result = VrSpatialAudioEvaluator.evaluate(
        source: vm.Vector3(0, 0, -5),
        listener: vm.Vector3.zero(),
        listenerYaw: 0,
        maxDistance: 20,
        rolloff: 0,
      );
      expect(result.$1, .75);
    });
  });

  group('untrusted inputs', () {
    for (final invalid in [double.nan, double.infinity, -double.infinity]) {
      test('rejects nonfinite pose and yaw $invalid', () {
        for (var component = 0; component < 3; component++) {
          final malformed = vm.Vector3.zero()..[component] = invalid;
          for (final sourceIsMalformed in [false, true]) {
            expect(
              () => VrSpatialAudioEvaluator.evaluate(
                source: sourceIsMalformed ? malformed : vm.Vector3.zero(),
                listener: sourceIsMalformed ? vm.Vector3.zero() : malformed,
                listenerYaw: 0,
              ),
              throwsArgumentError,
            );
          }
        }
        expect(
          () => VrSpatialAudioEvaluator.evaluate(
            source: vm.Vector3.zero(),
            listener: vm.Vector3.zero(),
            listenerYaw: invalid,
          ),
          throwsArgumentError,
        );
      });
    }

    test('rejects invalid ranges before division', () {
      for (final minDistance in [0.0, -1.0, double.nan, double.infinity]) {
        expect(
          () => VrProximityAudioPolicy(minDistance: minDistance),
          throwsArgumentError,
        );
      }
      for (final maxDistance in [0.0, 1.0, -1.0, double.nan, double.infinity]) {
        expect(
          () => VrProximityAudioPolicy(maxDistance: maxDistance),
          throwsArgumentError,
        );
      }
      for (final rolloff in [-1.0, double.nan, double.infinity]) {
        expect(
          () => VrProximityAudioPolicy(rolloff: rolloff),
          throwsArgumentError,
        );
      }
    });
  });

  group('world and voice policy', () {
    final public = VrWorldAddress(worldId: 'plaza', instanceId: 'public');
    final policy = VrProximityAudioPolicy();

    (double, double) evaluate({
      VrWorldAddress? sourceSpace,
      bool sourceOptedIn = true,
      bool listenerOptedIn = true,
      bool sourceMuted = false,
      bool listenerMuted = false,
      bool blocked = false,
    }) => policy.evaluate(
      sourceSpace: sourceSpace ?? public,
      listenerSpace: public,
      source: vm.Vector3(3, 0, 0),
      listener: vm.Vector3.zero(),
      listenerYaw: 0,
      sourceOptedIn: sourceOptedIn,
      listenerOptedIn: listenerOptedIn,
      sourceMuted: sourceMuted,
      listenerMuted: listenerMuted,
      blocked: blocked,
    );

    test('same world instance can spatialize an opted-in avatar', () {
      final result = evaluate(
        sourceSpace: VrWorldAddress(worldId: 'plaza', instanceId: 'public'),
      );
      expect(result.$1, greaterThan(0));
      expect(result.$2, closeTo(1, 1e-12));
    });

    test('identical coordinates do not cross world or instance boundaries', () {
      expect(
        evaluate(
          sourceSpace: VrWorldAddress(worldId: 'other', instanceId: 'public'),
        ),
        (0.0, 0.0),
      );
      expect(
        evaluate(
          sourceSpace: VrWorldAddress(worldId: 'plaza', instanceId: 'private'),
        ),
        (0.0, 0.0),
      );
    });

    test('each consent, mute and block gate independently silences voice', () {
      expect(evaluate(sourceOptedIn: false), (0.0, 0.0));
      expect(evaluate(listenerOptedIn: false), (0.0, 0.0));
      expect(evaluate(sourceMuted: true), (0.0, 0.0));
      expect(evaluate(listenerMuted: true), (0.0, 0.0));
      expect(evaluate(blocked: true), (0.0, 0.0));
    });

    test('omitted consent never makes a nearby avatar audible', () {
      expect(
        policy.evaluate(
          sourceSpace: public,
          listenerSpace: public,
          source: vm.Vector3.zero(),
          listener: vm.Vector3.zero(),
          listenerYaw: 0,
        ),
        (0.0, 0.0),
      );
    });

    test('empty coordinate-space identity is rejected', () {
      expect(
        () => VrWorldAddress(worldId: '', instanceId: 'public'),
        throwsArgumentError,
      );
      expect(
        () => VrWorldAddress(worldId: 'plaza', instanceId: '  '),
        throwsArgumentError,
      );
    });
  });
}
