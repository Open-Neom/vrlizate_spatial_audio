# vrlizate_spatial_audio

Pure Dart spatial audio evaluator, acoustic zones, multi-emitter scene mixer, procedural foley SFX, and proximity policy for the **VRlizate SDK**. Depends on `vector_math` and the shared `vrlizate_world` address contract; importing it does not initialize a microphone, player, renderer, WebRTC connection, or Firebase service.

> Current version: **1.0.0**. See [CHANGELOG.md](CHANGELOG.md).

## Components

- **`VrSpatialAudioEvaluator`:** computes VRlizate's inverse-distance gain and horizontal stereo pan curve (`Y` up, `-Z` forward at zero yaw).
- **`VrProximityAudioPolicy`:** enforces shared `VrWorldAddress` world/instance identity and explicit sender/listener consent before returning audible gain/pan.
- **`VrAcousticEnvironment` & `VrAcousticZone`:** spherical environmental acoustic zones (`openAir`, `smallRoom`, `concertHall`, `corridor`, `underwater`, `cyberArena`) with reverb wet mix, low-pass cutoff Hz, and attenuation multipliers.
- **`VrAudioSceneMixer`, `VrSpatialAudioEmitter`, `VrSpatialEmitterMix`:** evaluates multiple emitters against listener pose and active acoustic zones, culling silent sources and returning the top-N prioritized emitters.
- **`VrProceduralSfx`:** zero-asset procedural sound synthesizer (`click`, `clack`, `whoosh`, `step`, `ding`, `pop`, `thump`, `heartbeat`) with stereo spatialization and 16-bit PCM WAV encoding.

```dart
import 'package:vector_math/vector_math.dart' as vm;
import 'package:vrlizate_spatial_audio/vrlizate_spatial_audio.dart';
import 'package:vrlizate_world/vrlizate_world.dart';

final plaza = VrWorldAddress(worldId: 'plaza', instanceId: 'public-01');
final mixer = VrAudioSceneMixer(maxActiveEmitters: 8)
  ..addZone(
    VrAcousticZone.fromEnvironment(
      id: 'zone.hall',
      world: plaza,
      center: vm.Vector3.zero(),
      radiusMeters: 30,
      environment: VrAcousticEnvironment.concertHall,
    ),
  );

final mixes = mixer.evaluateScene(
  listenerWorld: plaza,
  listenerPosition: vm.Vector3(0, 1.6, 0),
  listenerYaw: 0,
  emitters: [
    VrSpatialAudioEmitter(
      id: 'emitter.stage',
      world: plaza,
      position: vm.Vector3(4, 1.6, -6),
      priority: 10,
    ),
  ],
);
```

## Validation

```sh
flutter analyze
flutter test
```
