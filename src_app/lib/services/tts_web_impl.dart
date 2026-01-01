import 'dart:html' as html;
import 'dart:typed_data';

/// Current audio element being played
html.AudioElement? _currentAudio;

/// Play audio from bytes on web using Blob URL
Future<void> playAudioBytes(
    List<int> audioBytes, {
      Function()? onComplete,
      Function(dynamic)? onError,
    }) async {
  try {
    // Stop any currently playing audio
    stopAudio();

    // Create Blob from bytes
    final blob = html.Blob([Uint8List.fromList(audioBytes)], 'audio/mpeg');
    final url = html.Url.createObjectUrlFromBlob(blob);

    // Create Audio element
    final audio = html.AudioElement(url);
    _currentAudio = audio;

    // Listen for completion
    audio.onEnded.listen((_) {
      html.Url.revokeObjectUrl(url);  // Free memory
      _currentAudio = null;
      onComplete?.call();
    });

    // Listen for errors
    audio.onError.listen((event) {
      html.Url.revokeObjectUrl(url);
      _currentAudio = null;
      onError?.call(event);
    });

    // Play audio
    await audio.play();

  } catch (e) {
    _currentAudio = null;
    onError?.call(e);
    rethrow;
  }
}

/// Play audio from URL on web
Future<void> playAudioUrl(
    String url, {
      Function()? onComplete,
      Function(dynamic)? onError,
    }) async {
  try {
    // Stop any currently playing audio
    stopAudio();

    // Create Audio element
    final audio = html.AudioElement(url);
    _currentAudio = audio;

    // Listen for completion
    audio.onEnded.listen((_) {
      _currentAudio = null;
      onComplete?.call();
    });

    // Listen for errors
    audio.onError.listen((event) {
      _currentAudio = null;
      onError?.call(event);
    });

    // Play audio
    await audio.play();

  } catch (e) {
    _currentAudio = null;
    onError?.call(e);
    rethrow;
  }
}

/// Stop currently playing audio
void stopAudio() {
  if (_currentAudio != null) {
    _currentAudio!.pause();
    _currentAudio!.currentTime = 0;
    _currentAudio = null;
  }
}