import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// Lightweight IPC server exposing:
/// - HTTP GET /health -> { ok: true }
/// - HTTP POST /event  with JSON body to emit events to the app
/// - WebSocket /ws     for bidirectional messaging (broadcast to all clients)
class IpcServer {
  final InternetAddress bindAddress;
  final int port;

  HttpServer? _server;
  final _events = StreamController<Map<String, dynamic>>.broadcast();
  final _wsClients = <WebSocket>{};

  IpcServer({InternetAddress? bindAddress, this.port = 8765})
      : bindAddress = bindAddress ?? InternetAddress.loopbackIPv4;

  Stream<Map<String, dynamic>> get events => _events.stream;

  Future<void> start() async {
    if (_server != null) return;
    _server = await HttpServer.bind(bindAddress, port);
    _server!.listen(_handleRequest, onError: (e, st) {
      // swallow server errors to avoid crashing app
    });
  }

  Future<void> stop() async {
    for (final ws in _wsClients.toList()) {
      try {
        await ws.close(WebSocketStatus.normalClosure, 'Server stopping');
      } catch (_) {}
    }
    _wsClients.clear();
    await _server?.close(force: true);
    _server = null;
    await _events.close();
  }

  void emit(Map<String, dynamic> event) {
    if (!_events.isClosed) {
      _events.add(event);
      // fanout to websocket clients
      final payload = jsonEncode(event);
      for (final ws in _wsClients.toList()) {
        try {
          ws.add(payload);
        } catch (_) {}
      }
    }
  }

  Future<void> _handleRequest(HttpRequest req) async {
    // CORS for simple Java HTTP clients if needed
    req.response.headers.add('Access-Control-Allow-Origin', '*');
    req.response.headers.add('Access-Control-Allow-Headers', '*');
    req.response.headers.add('Access-Control-Allow-Methods', 'GET,POST,OPTIONS');

    if (req.method == 'OPTIONS') {
      req.response.statusCode = HttpStatus.noContent;
      await req.response.close();
      return;
    }

    final path = req.uri.path;
    if (path == '/health') {
      req.response.headers.contentType = ContentType.json;
      req.response.write(jsonEncode({'ok': true, 'port': port}));
      await req.response.close();
      return;
    }

    if (path == '/ws' && WebSocketTransformer.isUpgradeRequest(req)) {
      final socket = await WebSocketTransformer.upgrade(req);
      _wsClients.add(socket);

      socket.listen((data) {
        try {
          final msg = (data is String) ? jsonDecode(data) : data;
          if (msg is Map<String, dynamic>) {
            emit(msg);
          }
        } catch (_) {}
      }, onDone: () {
        _wsClients.remove(socket);
      }, onError: (_) {
        _wsClients.remove(socket);
      });
      return;
    }

    if (path == '/event' && req.method == 'POST') {
      try {
        final body = await utf8.decoder.bind(req).join();
        final data = jsonDecode(body);
        if (data is Map<String, dynamic>) {
          emit(data);
          req.response.statusCode = HttpStatus.accepted;
        } else {
          req.response.statusCode = HttpStatus.badRequest;
        }
      } catch (_) {
        req.response.statusCode = HttpStatus.badRequest;
      }
      await req.response.close();
      return;
    }

    req.response.statusCode = HttpStatus.notFound;
    await req.response.close();
  }
}

