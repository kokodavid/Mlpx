import 'dart:async';
import 'dart:typed_data';

import 'package:record/record.dart';

class LessonRecordingController {
  static const int sampleRate = 44100;
  static const int numChannels = 1;

  final AudioRecorder _recorder;

  LessonRecordingController() : _recorder = AudioRecorder();

  Future<bool> hasPermission() {
    return _recorder.hasPermission();
  }

  Future<Stream<Uint8List>> startRecording() {
    return _recorder.startStream(
      const RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: sampleRate,
        numChannels: numChannels,
      ),
    );
  }

  Future<String?> stopRecording() {
    return _recorder.stop();
  }

  Future<void> dispose() {
    return _recorder.dispose();
  }
}
