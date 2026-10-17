# Changelog

## 0.1.0

- Initial release of `vrlizate_spatial_audio` for the VRlizate SDK.
- Add `VrProceduralSfx` synthesizer (`click`, `clack`, `whoosh`, `step`, `ding`, `pop`, `thump`, `heartbeat`), stereo spatializer (`spatializeStereo`), and in-memory 16-bit PCM WAV encoder (`encodeWavPcm16`).
- Add `VrSpatialAudioEvaluator` with inverse-distance gain attenuation and stereo pan evaluation in Y-up coordinate space.
- Add `VrProximityAudioPolicy` enforcing matching `VrWorldAddress` world/instance and explicit sender/listener opt-in before returning audibility.
