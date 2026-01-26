/// Stub file for non-web platforms
/// These functions will never be called on mobile/desktop
library;

Future<void> playAudioBytes(
    List<int> audioBytes, {
      Function()? onComplete,
      Function(dynamic)? onError,
    }) async {
  throw UnsupportedError('Web audio is not supported on this platform');
}

Future<void> playAudioUrl(
    String url, {
      Function()? onComplete,
      Function(dynamic)? onError,
    }) async {
  throw UnsupportedError('Web audio is not supported on this platform');
}

void stopAudio() {
  // No-op on non-web platforms
}