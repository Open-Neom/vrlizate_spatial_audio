# Changelog

## 1.0.0

- Architecture refactor to Open Neom standard layout (`lib/utils/constants/`, `lib/utils/enums/`, `lib/domain/models/`, `lib/domain/services/`) with one class or enum per file and centralized constants (`VrSpatialAudioConstants`).
- Add `VrAcousticEnvironment` (`openAir`, `smallRoom`, `concertHall`, `corridor`, `underwater`, `cyberArena`) and `VrAcousticZone` for spherical environmental reverb, low-pass filtering, and distance-attenuation scaling.
- Add `VrSpatialAudioEmitter`, `VrSpatialEmitterMix`, and `VrAudioSceneMixer` for multi-emitter spatial evaluation, acoustic zone resolution, and priority-based voice/emitter culling.
- Extract deterministic PRNG `VrSfxRng` into its own utility class.
- Preserve 100% backward-compatible barrel exports under `lib/src/` and `lib/vrlizate_spatial_audio.dart`.

## 0.1.0 — Unreleased

- Add `VrSpatialAudioEvaluator`, `VrProximityAudioPolicy`, and `VrProceduralSfx`.
