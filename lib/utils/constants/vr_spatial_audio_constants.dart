abstract final class VrSpatialAudioConstants {
  static const double defaultMinDistance = 1.0;
  static const double defaultMaxDistance = 25.0;
  static const double defaultRolloff = 1.0;
  static const double minHorizontalDistanceMeters = 1e-4;

  static const int defaultSampleRate = 24000;
  static const int defaultClickSeed = 7;
  static const int defaultClackSeed = 11;
  static const int defaultWhooshSeed = 19;
  static const int defaultStepSeed = 23;
  static const int defaultThumpSeed = 31;

  static const double clickDurationSeconds = 0.06;
  static const double clackDurationSeconds = 0.09;
  static const double defaultWhooshDurationSeconds = 0.35;
  static const double minWhooshDurationSeconds = 0.05;
  static const double stepDurationSeconds = 0.05;
  static const double defaultDingDurationSeconds = 0.9;
  static const double minDingDurationSeconds = 0.1;
  static const double popDurationSeconds = 0.18;
  static const double thumpDurationSeconds = 0.35;
  static const double defaultThumpFrequencyHz = 70.0;
  static const double heartbeatFirstFrequencyHz = 55.0;
  static const double heartbeatSecondFrequencyHz = 50.0;
  static const double heartbeatSecondVolume = 0.7;
  static const double heartbeatDelaySeconds = 0.22;

  static const int wavHeaderBytes = 44;
  static const int wavPcmChunkSize = 16;
  static const int wavPcmFormat = 1;
  static const int wavBitsPerSample = 16;
  static const int wavBytesPerSample = 2;
  static const double pcm16Scale = 32767.0;
  static const int pcm16Min = -32768;
  static const int pcm16Max = 32767;
  static const String wavRiffTag = 'RIFF';
  static const String wavWaveTag = 'WAVE';
  static const String wavFmtTag = 'fmt ';
  static const String wavDataTag = 'data';

  static const double defaultReverbWetMix = 0.0;
  static const double smallRoomReverbWetMix = 0.18;
  static const double concertHallReverbWetMix = 0.45;
  static const double corridorReverbWetMix = 0.30;
  static const double underwaterReverbWetMix = 0.55;
  static const double cyberArenaReverbWetMix = 0.38;

  static const double defaultLowPassCutoffHz = 20000.0;
  static const double smallRoomLowPassCutoffHz = 16000.0;
  static const double concertHallLowPassCutoffHz = 14000.0;
  static const double corridorLowPassCutoffHz = 12000.0;
  static const double underwaterLowPassCutoffHz = 900.0;
  static const double cyberArenaLowPassCutoffHz = 18000.0;
  static const double minLowPassCutoffHz = 20.0;
  static const double maxLowPassCutoffHz = 24000.0;

  static const double defaultAttenuationMultiplier = 1.0;
  static const double underwaterAttenuationMultiplier = 0.65;
  static const double concertHallAttenuationMultiplier = 1.15;

  static const int defaultMaxActiveEmitters = 16;
  static const double defaultMinAudibleGain = 0.001;
  static const int defaultEmitterPriority = 0;

  static const String paramSource = 'source';
  static const String paramListener = 'listener';
  static const String paramListenerYaw = 'listenerYaw';
  static const String paramMinDistance = 'minDistance';
  static const String paramMaxDistance = 'maxDistance';
  static const String paramRolloff = 'rolloff';
  static const String paramChannels = 'channels';
  static const String paramRadiusMeters = 'radiusMeters';
  static const String paramReverbWetMix = 'reverbWetMix';
  static const String paramLowPassCutoffHz = 'lowPassCutoffHz';
  static const String paramAttenuationMultiplier = 'attenuationMultiplier';
  static const String paramBaseGain = 'baseGain';
  static const String paramMaxActiveEmitters = 'maxActiveEmitters';
  static const String paramCenter = 'center';
  static const String paramPosition = 'position';

  static const String errFinite = 'Must be finite';
  static const String errMinDistancePositive =
      'Must be finite and greater than zero';
  static const String errMaxDistanceExceedsMin =
      'Must be finite and exceed minDistance';
  static const String errRolloffNonNegative = 'Must be finite and nonnegative';
  static const String errCoordinateFinite = 'Every coordinate must be finite';
  static const String errWavChannels = 'Must be 1 (mono) or 2 (stereo).';
  static const String errRadiusPositive = 'Must be finite and > 0.';
  static const String errReverbWetMixRange = 'Must be finite within [0, 1].';
  static const String errLowPassCutoffRange =
      'Must be finite within [20, 24000].';
  static const String errAttenuationMultiplierRange =
      'Must be finite and > 0.';
  static const String errBaseGainRange = 'Must be finite within [0, 2].';
  static const String errMaxActiveEmitters = 'Must be >= 1.';
}
