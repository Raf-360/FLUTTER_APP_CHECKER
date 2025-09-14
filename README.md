# chess_advanced_app

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Java Game Integration

This app now exposes a lightweight IPC layer for integrating with a Java-based game or service.

- Protocols: HTTP (REST) and WebSocket
- Default bind: `127.0.0.1:8765` (non-web builds only)
- Endpoints:
  - `GET /health` -> `{ ok: true, port: 8765 }`
  - `POST /event` with JSON body to send events to the app
  - `WS /ws` bidirectional; any JSON message received is emitted to the app and broadcast to clients

### Example JSON messages

Send control events:

```json
{"action":"increment"}
{"action":"reset"}
{"action":"set","value":42}
```

### Java client example

See `integration/java/JavaClientExample.java` for a minimal Java 11 example using `java.net.http` to:

- POST an event to `/event`
- Connect to `ws://127.0.0.1:8765/ws` and send/receive messages

Compile and run (Java 11+):

```bash
javac integration/java/JavaClientExample.java && java -cp integration/java JavaClientExample
```

### Notes

- IPC server runs only on IO platforms (Android/iOS/Windows/macOS/Linux). Web builds use a no-op stub.
- On Android emulators, `127.0.0.1` refers to the emulator. From host, use `adb reverse` or connect from inside the device/emulator.
- You can change the port/address by editing `lib/integration/server_io.dart` and the `IpcServer` initialization in `lib/main.dart`.
