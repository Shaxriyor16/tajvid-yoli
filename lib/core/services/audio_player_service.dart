import 'dart:async';
import 'package:just_audio/just_audio.dart';
import 'package:rxdart/rxdart.dart';

class AudioPlayerService {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final _currentlyPlayingUrl = BehaviorSubject<String?>.seeded(null);
  int _request = 0;
  bool _disposed = false;

  Stream<String?> get currentlyPlayingUrlStream => _currentlyPlayingUrl.stream;
  Stream<PlayerState> get playerStateStream => _audioPlayer.playerStateStream;

  Future<bool> play(String url) async {
    if (_disposed) return false;
    final request = ++_request;
    try {
      if (_currentlyPlayingUrl.value != url) {
        _currentlyPlayingUrl.add(url);
        await _audioPlayer.setUrl(url).timeout(const Duration(seconds: 15));
      } else if (_audioPlayer.processingState == ProcessingState.completed) {
        await _audioPlayer.seek(Duration.zero);
      }
      if (_disposed || request != _request) return false;
      // just_audio's play Future completes when playback ends. UI actions
      // should finish as soon as the source is ready, not after the entire ayah.
      unawaited(_audioPlayer.play().catchError((Object _) {
        if (!_disposed && request == _request) _currentlyPlayingUrl.add(null);
      }));
      return true;
    } catch (_) {
      if (!_disposed && request == _request) _currentlyPlayingUrl.add(null);
      return false;
    }
  }

  Future<void> pause() async {
    await _audioPlayer.pause();
  }

  Future<void> stop() async {
    ++_request;
    await _audioPlayer.stop();
    _currentlyPlayingUrl.add(null);
  }

  void dispose() {
    _disposed = true;
    ++_request;
    _audioPlayer.dispose();
    _currentlyPlayingUrl.close();
  }
}
