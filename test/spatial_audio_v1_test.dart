import 'package:test/test.dart';
import 'package:vector_math/vector_math.dart' as vm;
import 'package:vrlizate_spatial_audio/vrlizate_spatial_audio.dart';

void main() {
  group('VrAcousticZone', () {
    test('builds presets for all VrAcousticEnvironment values and checks containment', () {
      final world = VrWorldAddress(worldId: 'world.audio', instanceId: 'local');
      for (final env in VrAcousticEnvironment.values) {
        final zone = VrAcousticZone.fromEnvironment(
          id: 'zone.${env.name}',
          world: world,
          center: vm.Vector3(0, 0, 0),
          radiusMeters: 15,
          environment: env,
        );
        expect(zone.environment, equals(env));
        expect(zone.contains(vm.Vector3(5, 0, -5)), isTrue);
        expect(zone.contains(vm.Vector3(25, 0, 0)), isFalse);
      }
    });
  });

  group('VrAudioSceneMixer', () {
    test('applies acoustic zone parameters, culls silent/muted emitters, and caps top-N by priority', () {
      final world = VrWorldAddress(worldId: 'world.club', instanceId: 'main');
      final otherWorld = VrWorldAddress(worldId: 'world.lobby', instanceId: 'main');
      final mixer = VrAudioSceneMixer(maxActiveEmitters: 2)
        ..addZone(
          VrAcousticZone.fromEnvironment(
            id: 'zone.underwater',
            world: world,
            center: vm.Vector3.zero(),
            radiusMeters: 20,
            environment: VrAcousticEnvironment.underwater,
          ),
        );

      final emitters = <VrSpatialAudioEmitter>[
        VrSpatialAudioEmitter(
          id: 'emitter.lowPriorityNear',
          world: world,
          position: vm.Vector3(1, 0, -2),
          priority: 1,
        ),
        VrSpatialAudioEmitter(
          id: 'emitter.highPriorityMid',
          world: world,
          position: vm.Vector3(-3, 0, -4),
          priority: 10,
        ),
        VrSpatialAudioEmitter(
          id: 'emitter.topPriority',
          world: world,
          position: vm.Vector3(0, 0, -3),
          priority: 20,
        ),
        VrSpatialAudioEmitter(
          id: 'emitter.muted',
          world: world,
          position: vm.Vector3(0, 0, -1),
          priority: 100,
          muted: true,
        ),
        VrSpatialAudioEmitter(
          id: 'emitter.otherWorld',
          world: otherWorld,
          position: vm.Vector3(0, 0, -1),
          priority: 100,
        ),
      ];

      final active = mixer.evaluateScene(
        listenerWorld: world,
        listenerPosition: vm.Vector3.zero(),
        listenerYaw: 0,
        emitters: emitters,
      );

      expect(active.length, equals(2));
      expect(active[0].emitterId, equals('emitter.topPriority'));
      expect(active[1].emitterId, equals('emitter.highPriorityMid'));
      expect(active[0].environment, equals(VrAcousticEnvironment.underwater));
      expect(
        active[0].lowPassCutoffHz,
        equals(VrSpatialAudioConstants.underwaterLowPassCutoffHz),
      );
      expect(
        active[0].reverbWetMix,
        equals(VrSpatialAudioConstants.underwaterReverbWetMix),
      );
    });
  });
}
