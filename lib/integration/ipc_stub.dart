import 'dart:async';

/// No-op IPC server for web builds.
class IpcServer {
  final int port;
  final _events = StreamController<Map<String, dynamic>>.broadcast();

  IpcServer({this.port = 8765});

  Stream<Map<String, dynamic>> get events => _events.stream;

  Future<void> start() async {
    // No-op on web.
  }

  Future<void> stop() async {
    await _events.close();
  }

  /// Manually inject an event into the stream (useful for tests/UI actions).
  void emit(Map<String, dynamic> event) {
    if (!_events.isClosed) {
      _events.add(event);
    }
  }
}

