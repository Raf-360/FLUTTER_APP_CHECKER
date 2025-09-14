// Cross-platform IPC abstraction with conditional export.
// On IO platforms (Android/iOS/desktop), exports the server implementation.
// On Web, exports a no-op stub.

export 'ipc_stub.dart' if (dart.library.io) 'server_io.dart';
