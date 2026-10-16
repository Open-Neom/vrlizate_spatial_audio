# vrlizate_spatial_audio

Pure Dart spatial audio policy for the VRlizate SDK. Depends on `vector_math`
and the shared `vrlizate_world` address contract; importing it does not initialize a microphone, player, renderer,
WebRTC connection, or Firebase service.

`VrSpatialAudioEvaluator` computes the existing VRlizate distance-gain and stereo
pan curve. `vrlizate_scene` re-exports it for compatibility. Positions are in a
shared, Y-up coordinate space (normally meters), with -Z forward at zero yaw.
The inverse-distance curve includes a linear fade to silence at `maxDistance`.
It is stereo positioning, not binaural HRTF or simulated room acoustics.

`VrProximityAudioPolicy` additionally requires the same `VrWorldAddress` world and
instance and explicit sender/listener consent. A muted or blocked participant
produces zero gain. It only computes receiver-side audibility: the host must
also enforce membership, media permissions, moderation and subscription limits
at the transport/server boundary. Moving near a person never starts capture.

```dart
final plaza = VrWorldAddress(worldId: 'plaza', instanceId: 'public-01');
final proximity = VrProximityAudioPolicy(maxDistance: 20);
final (gain, pan) = proximity.evaluate(
  sourceSpace: plaza,
  listenerSpace: plaza,
  source: avatarPosition,
  listener: headPosition,
  listenerYaw: headYaw,
  sourceOptedIn: true,
  listenerOptedIn: true,
);
// Apply gain/pan through the host's existing audio adapter.
```

Playback remains in Open Neom modules: `neom_sound` owns effects, recording and
SoLoud volume/pan controls; `neom_audio_player` owns long-form media; `neom_rooms`
owns live WebRTC voice. The current Rooms interface still needs per-participant
gain control; it does not yet expose stereo pan or a decoded-audio bridge. This
package does not claim that live avatar voice is already integrated.

For moving sources, update bounded nearby emitters and coalesce backend updates.
Keep network pose traffic, audio-mix updates and rendering on independent rates.
Stop/unsubscribe remote voice when leaving an instance; do not retain a silent
stream as a substitute for authorization. Each room should release its own
sound handles without deinitializing the shared Open Neom audio engine.
