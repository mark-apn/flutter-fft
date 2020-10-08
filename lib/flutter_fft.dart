import 'dart:async';

import 'package:flutter/services.dart';

class FlutterFft {
  static const MethodChannel _channel = const MethodChannel("com.slins.flutterfft/record");

  static StreamController<FftResult> _recorderController = StreamController.broadcast();

  Stream<FftResult> get onRecorderStateChanged => _recorderController.stream;

  bool _isRecording = false;

  double _subscriptionDuration = 0.25;
  int _numChannels = 1;
  int _sampleRate = 44100;
  AndroidAudioSource _androidAudioSource = AndroidAudioSource.MIC;
  double _tolerance = 1.0;

  FftResult lastResult;

  final _standardTuning = const <String>["E2", "A2", "D3", "G3", "B3", "E4"];

  bool get getIsRecording => _isRecording;

  Future<void> _setRecorderCallback() async {
    _channel.setMethodCallHandler((MethodCall call) {
      switch (call.method) {
        case "updateRecorderProgress":
          lastResult = FftResult(call.arguments as List);
          _recorderController.add(lastResult);
          break;
        default:
          throw new ArgumentError("Unknown method: ${call.method}");
      }
      return null;
    });
  }

  Future<String> startRecorder({
    List<String> tuning,
    double subscriptionDuration,
    int numChannels,
    int sampleRage,
    int audioSource,
    int tolerance,
  }) async {
    try {
      await _channel.invokeMethod("setSubscriptionDuration", <String, double>{
        'sec': subscriptionDuration ?? _subscriptionDuration,
      });
    } catch (err) {
      print("Could not set subscription duration, error: $err");
    }

    if (this.getIsRecording) {
      throw new RecorderRunningException("Recorder is already running.");
    }

    try {
      String result = await _channel.invokeMethod(
        'startRecorder',
        <String, dynamic>{
          'tuning': tuning ?? _standardTuning,
          'numChannels': numChannels ?? _numChannels,
          'sampleRate': sampleRage ?? _sampleRate,
          'audioSource': audioSource ?? _androidAudioSource.value,
          'tolerance': tolerance ?? _tolerance,
        },
      );
      _setRecorderCallback();
      _isRecording = true;

      return result;
    } catch (err) {
      throw new Exception(err);
    }
  }

  Future<String> stopRecorder() async {
    if (!this.getIsRecording) {
      throw new RecorderStoppedException("Recorder is not running.");
    }

    String result = await _channel.invokeMethod("stopRecorder");

    _isRecording = false;

    // Clear te latest result
    _recorderController.add(null);

    return result;
  }
}

class RecorderRunningException implements Exception {
  final String message;

  RecorderRunningException(this.message);
}

class RecorderStoppedException implements Exception {
  final String message;

  RecorderStoppedException(this.message);
}

class AndroidAudioSource {
  final _value;

  const AndroidAudioSource._internal(this._value);

  toString() => 'AndroidAudioSource.$_value';

  int get value => _value;

  static const DEFAULT = const AndroidAudioSource._internal(0);
  static const MIC = const AndroidAudioSource._internal(1);
  static const VOICE_UPLINK = const AndroidAudioSource._internal(2);
  static const VOICE_DOWNLINK = const AndroidAudioSource._internal(3);
  static const CAMCORDER = const AndroidAudioSource._internal(4);
  static const VOICE_RECOGNITION = const AndroidAudioSource._internal(5);
  static const VOICE_COMMUNICATION = const AndroidAudioSource._internal(6);
  static const REMOTE_SUBMIX = const AndroidAudioSource._internal(7);
  static const UNPROCESSED = const AndroidAudioSource._internal(8);
  static const RADIO_TUNER = const AndroidAudioSource._internal(9);
  static const HOTWORD = const AndroidAudioSource._internal(10);
}

class FftResult {
  /// Tolerance (int) -> data[0]
  final int tolerance;

  /// Frequency (double) -> data[1];
  final double frequency;

  /// Note (string) -> data[2];
  final String note;

  /// Target (double) -> data[3];
  final double target;

  /// Distance (double) -> data[4];
  final double distance;

  /// Octave (int) -> data[5];
  final int octave;

  /// NearestNote (string) -> data[6];
  final String nearestNote;

  /// NearestTarget (double) -> data[7];
  final double nearestTarget;

  /// NearestDistance (double) -> data[8];
  final double nearestDistance;

  /// NearestOctave (int) -> data[9];
  final int nearestOctave;

  /// IsOnPitch (bool) -> data[10];
  final bool isOnPitch;

  FftResult(List data)
      : tolerance = tryCast<double>(data[0]).toInt(),
        frequency = tryCast<double>(data[1]),
        note = tryCast<String>(data[2]),
        target = tryCast<double>(data[3]),
        distance = tryCast<double>(data[4]),
        octave = tryCast<int>(data[5]),
        nearestNote = tryCast<String>(data[6]),
        nearestTarget = tryCast<double>(data[7]),
        nearestDistance = tryCast<double>(data[8]),
        nearestOctave = tryCast<int>(data[9]),
        isOnPitch = tryCast<bool>(data[10]) {
    print(data);
  }
}

T tryCast<T>(dynamic x, {T fallback}) {
  try {
    return (x as T);
  } on TypeError {
    print('CastError when trying to cast $x to $T!');
    return fallback;
  }
}
